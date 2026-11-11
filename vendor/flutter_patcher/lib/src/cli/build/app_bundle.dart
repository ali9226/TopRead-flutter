import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../core.dart';
import '../patch/resources.dart';
import 'android_abi.dart';
import 'android_pages.dart';

const strippedEngineFlutterVersion = '3.47.9';
const strippedEngineFlutterMessage =
    '''Release app bundle failed to strip debug symbols from native libraries.
Please run flutter doctor and ensure that the Android toolchain does not
report any issues.

Otherwise, file an issue at https://github.com/flutter/flutter/issues.''';

class AppBundleBuild {
  const AppBundleBuild(
    this.path, {
    this.prestrippedEngineCompatibility = false,
  });
  final String path;
  final bool prestrippedEngineCompatibility;
}

/// TODO Verify actual ELF sections instead of inventing debug-symbol files for a prestripped engine.
bool isStrippedArm64Elf(List<int> bytes) {
  if (bytes.length < 64) return false;
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  if (data.getUint32(0, Endian.big) != 0x7f454c46 ||
      bytes[4] != 2 ||
      bytes[5] != 1 ||
      data.getUint16(16, Endian.little) != 3 ||
      data.getUint16(18, Endian.little) != 183) {
    return false;
  }
  final offset = data.getUint64(40, Endian.little);
  final size = data.getUint16(58, Endian.little);
  final count = data.getUint16(60, Endian.little);
  final namesIndex = data.getUint16(62, Endian.little);
  if (offset < 64 ||
      size < 64 ||
      count == 0 ||
      namesIndex >= count ||
      offset + size * count > bytes.length) {
    return false;
  }
  final namesHeader = offset + namesIndex * size;
  final namesOffset = data.getUint64(namesHeader + 24, Endian.little);
  final namesSize = data.getUint64(namesHeader + 32, Endian.little);
  if (namesSize == 0 || namesOffset + namesSize > bytes.length) return false;
  for (var index = 0; index < count; index++) {
    final nameOffset = data.getUint32(offset + index * size, Endian.little);
    if (nameOffset >= namesSize) return false;
    final start = namesOffset + nameOffset;
    var end = start;
    while (end < namesOffset + namesSize && bytes[end] != 0) {
      end++;
    }
    if (end == namesOffset + namesSize) return false;
    final name = String.fromCharCodes(bytes.sublist(start, end));
    if (name == '.symtab' ||
        name == '.gnu_debugdata' ||
        name.startsWith('.debug') ||
        name.startsWith('.zdebug')) {
      return false;
    }
  }
  return true;
}

bool acceptsPrestrippedEngineCheck({
  required String flutterVersion,
  required int exitCode,
  required String output,
  required bool freshBundle,
  required Archive archive,
}) {
  if (flutterVersion != strippedEngineFlutterVersion ||
      exitCode != 1 ||
      !freshBundle ||
      !output.trimRight().endsWith(strippedEngineFlutterMessage)) {
    return false;
  }
  for (final name in ['libflutter.so', 'libapp.so']) {
    final files = archive
        .where((file) => file.isFile && file.name == 'base/lib/arm64-v8a/$name')
        .toList();
    if (files.length != 1 || !isStrippedArm64Elf(files.single.content)) {
      return false;
    }
  }
  return true;
}

/// TODO Use an existing bundletool installation; never download tools or alter Gradle configuration.
class Bundletool {
  Bundletool(this.java, this.classpath);
  final String java;
  final List<String> classpath;

  static Future<Bundletool> locate(
    String cache, {
    Map<String, String>? environment,
  }) async {
    final env = environment ?? Platform.environment;
    final home = env['HOME'] ?? env['USERPROFILE'] ?? '';
    final javaHome = env['JAVA_HOME'];
    final javaName = Platform.isWindows ? 'java.exe' : 'java';
    final studioJava = p.join(
      home,
      'Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java',
    );
    final java =
        javaHome != null && File(p.join(javaHome, 'bin', javaName)).existsSync()
        ? p.join(javaHome, 'bin', javaName)
        : File(studioJava).existsSync()
        ? studioJava
        : 'java';
    final explicit = env['BUNDLETOOL_CLASSPATH'];
    final jar = env['BUNDLETOOL_JAR'];
    if (explicit != null || jar != null) {
      final paths = explicit?.split(Platform.isWindows ? ';' : ':') ?? [jar!];
      require(
        paths.isNotEmpty && paths.every((path) => File(path).existsSync()),
        'BUILD_BUNDLETOOL_MISSING',
        'BUNDLETOOL_CLASSPATH/BUNDLETOOL_JAR must name existing local jars.',
      );
      return Bundletool(java, paths);
    }
    final roots =
        <String>{
              if (env['GRADLE_USER_HOME'] case final String root) root,
              p.join(cache, 'gradle'),
              p.join(home, '.gradle'),
            }
            .map((root) => p.join(root, 'caches/modules-2/files-2.1'))
            .where((root) => Directory(root).existsSync())
            .toList();
    final selected = <String, String>{};
    final paths = <String>[];
    final pending = <List<String>>[
      ['com.android.tools.build', 'bundletool', ''],
    ];
    while (pending.isNotEmpty) {
      final dependency = pending.removeAt(0);
      final key = '${dependency[0]}:${dependency[1]}';
      if (selected.containsKey(key)) continue;
      final candidates = <Directory>[];
      for (final root in roots) {
        final module = Directory(p.join(root, dependency[0], dependency[1]));
        if (module.existsSync()) {
          candidates.addAll(module.listSync().whereType<Directory>());
        }
      }
      candidates.sort(
        (a, b) => _compareVersion(p.basename(b.path), p.basename(a.path)),
      );
      final exact = candidates.where(
        (directory) => p.basename(directory.path) == dependency[2],
      );
      final major = dependency[2].split('.').first;
      final compatible = candidates.where(
        (directory) => p.basename(directory.path).split('.').first == major,
      );
      final ordered = [...exact, ...compatible, ...candidates];
      Directory? chosen;
      File? artifact;
      for (final directory in ordered) {
        final jars = directory
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (file) =>
                  file.path.endsWith('.jar') &&
                  !file.path.endsWith('-sources.jar') &&
                  !file.path.endsWith('-javadoc.jar'),
            )
            .toList();
        if (jars.isNotEmpty) {
          chosen = directory;
          artifact = jars.first;
          break;
        }
      }
      require(
        chosen != null && artifact != null,
        'BUILD_BUNDLETOOL_MISSING',
        'Missing cached bundletool dependency $key. Set BUNDLETOOL_JAR to an existing all.jar or BUNDLETOOL_CLASSPATH.',
      );
      selected[key] = p.basename(chosen!.path);
      paths.add(artifact!.path);
      final poms = chosen
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.pom'));
      if (poms.isEmpty) continue;
      final source = (await poms.first.readAsString())
          .replaceAll(
            RegExp(r'<dependencyManagement>[\s\S]*?</dependencyManagement>'),
            '',
          )
          .replaceAll(RegExp(r'<profiles>[\s\S]*?</profiles>'), '')
          .replaceAll(RegExp(r'<build>[\s\S]*?</build>'), '')
          .replaceAll(r'${project.groupId}', dependency[0])
          .replaceAll(r'${project.version}', selected[key]!);
      String value(String block, String tag) =>
          RegExp('<$tag>([^<]+)</$tag>').firstMatch(block)?.group(1)?.trim() ??
          '';
      for (final match in RegExp(
        r'<dependency>([\s\S]*?)</dependency>',
      ).allMatches(source)) {
        final block = match[1]!;
        if ([
              'test',
              'provided',
              'system',
              'import',
            ].contains(value(block, 'scope')) ||
            value(block, 'optional') == 'true') {
          continue;
        }
        final group = value(block, 'groupId'),
            name = value(block, 'artifactId');
        if (group.isEmpty || name.isEmpty || value(block, 'type') == 'pom') {
          continue;
        }
        pending.add([group, name, value(block, 'version')]);
      }
    }
    return Bundletool(java, paths);
  }

  Future<String> run(Commands commands, List<String> args) =>
      commands.run(java, [
        '-cp',
        classpath.join(Platform.isWindows ? ';' : ':'),
        'com.android.tools.build.bundletool.BundleToolMain',
        ...args,
      ], code: 'BUILD_AAB_INVALID');
}

int _compareVersion(String a, String b) {
  final left = RegExp(r'\d+')
      .allMatches(a)
      .map((match) => int.parse(match[0]!))
      .toList();
  final right = RegExp(r'\d+')
      .allMatches(b)
      .map((match) => int.parse(match[0]!))
      .toList();
  for (var index = 0; index < left.length || index < right.length; index++) {
    final order = (index < left.length ? left[index] : 0).compareTo(
      index < right.length ? right[index] : 0,
    );
    if (order != 0) return order;
  }
  return a.compareTo(b);
}

/// TODO Validate the AAB against the actual APK baseline, including all Flutter assets.
/// The immutable APK receipt remains authoritative; a bundle never replaces its baseline.
void verifyBundleArchive(
  Archive archive,
  Map<String, dynamic> engine, {
  required String libappHash,
  required String hostTrust,
  required Map<String, dynamic> resources,
}) {
  verifyArm64NativeLibraries(archive, bundle: true);
  verifyAndroidPageAlignment(archive, bundle: true);
  final normalized = Archive();
  final names = <String>{};
  for (final file in archive) {
    require(names.add(file.name), 'BUILD_AAB_INVALID', 'Duplicate AAB entry.');
    if (file.isFile && file.name.startsWith('base/')) {
      normalized.addFile(
        ArchiveFile(file.name.substring(5), file.content.length, file.content),
      );
    }
  }
  ArchiveFile entry(String name) {
    final rows = normalized
        .where((file) => file.isFile && file.name == name)
        .toList();
    require(rows.length == 1, 'BUILD_AAB_INVALID', 'AAB is missing $name.');
    return rows.single;
  }

  final expected =
      ((engine['files'] as List).singleWhere(
                (row) => row['role'] == 'engine',
              )['contents']
              as List)
          .single;
  final engineBytes = entry('lib/arm64-v8a/libflutter.so').content;
  require(
    engineBytes.length == expected['size'] &&
        sha256.convert(engineBytes).toString() == expected['sha256'],
    'ENGINE_INJECTION_FAILED',
    'AAB engine differs from the verified engine manifest.',
  );
  final libraries = normalized
      .where(
        (file) =>
            file.name.startsWith('lib/') && file.name.endsWith('/libapp.so'),
      )
      .toList();
  require(
    archive
                .where(
                  (file) => file.isFile && file.name.endsWith('/libapp.so'),
                )
                .length ==
            1 &&
        libraries.length == 1 &&
        libraries.single.name == 'lib/arm64-v8a/libapp.so' &&
        sha256.convert(libraries.single.content).toString() == libappHash,
    'BUILD_AAB_INVALID',
    'AAB libapp.so differs from the canonical APK baseline.',
  );
  require(
    utf8.decode(entry('assets/flutter_patcher/host-trust.json').content) ==
        hostTrust,
    'BUILD_AAB_INVALID',
    'AAB host trust differs from the canonical APK.',
  );
  final actual = resourceReceipt(normalized);
  require(
    _canonical(actual) == _canonical(resources),
    'BUILD_AAB_INVALID',
    'AAB Flutter assets differ from the canonical APK.',
  );
}

String _canonical(Object? value) {
  Object? sorted(Object? item) => switch (item) {
    Map() => {
      for (final key in item.keys.map((key) => key.toString()).toList()..sort())
        key: sorted(item[key]),
    },
    List() => item.map(sorted).toList(),
    _ => item,
  };
  return jsonEncode(sorted(value));
}

/// TODO Jarsigner can exit successfully for unsigned jars, so require both signature entries and a verified result.
void verifyBundleSignatureEntries(Archive archive) {
  final names = archive
      .where((file) => file.isFile)
      .map((file) => file.name.toUpperCase())
      .toSet();
  final signers = names
      .where((name) => RegExp(r'^META-INF/[^/]+\.SF$').hasMatch(name))
      .map((name) => name.substring(0, name.length - 3));
  require(
    names.contains('META-INF/MANIFEST.MF') &&
        signers.any(
          (signer) => [
            'RSA',
            'DSA',
            'EC',
          ].any((extension) => names.contains('$signer.$extension')),
        ),
    'BUILD_AAB_UNSIGNED',
    'App bundle must contain a JAR manifest and a matching signature pair.',
  );
}

Future<void> verifyBundleSignature(
  String path,
  Archive archive,
  Commands commands,
  Bundletool bundletool,
) async {
  verifyBundleSignatureEntries(archive);
  final jarsigner = p.isAbsolute(bundletool.java)
      ? p.join(
          p.dirname(bundletool.java),
          Platform.isWindows ? 'jarsigner.exe' : 'jarsigner',
        )
      : 'jarsigner';
  final output = await commands.run(jarsigner, [
    '-J-Duser.language=en',
    '-J-Duser.country=US',
    '-verify',
    path,
  ], code: 'BUILD_AAB_SIGNATURE_INVALID');
  require(
    RegExp(r'(^|\r?\n)jar verified\.(\r?\n|$)').hasMatch(output) &&
        !output.toLowerCase().contains('unsigned entries'),
    'BUILD_AAB_SIGNATURE_INVALID',
    'Jarsigner did not confirm a verified bundle signature.',
  );
}

/// TODO bundletool validates protobuf manifests, package identity and actual build number.
Future<Map<String, dynamic>> verifyBuildBundle(
  String path,
  Commands commands,
  Bundletool bundletool,
  Map<String, dynamic> engine,
  Map<String, dynamic> apkReceipt,
  String hostTrust,
) async {
  require(
    await File(path).exists(),
    'BUILD_AAB_INVALID',
    'App bundle was not produced.',
  );
  final archive = ZipDecoder().decodeBytes(await File(path).readAsBytes());
  verifyBundleArchive(
    archive,
    engine,
    libappHash: apkReceipt['libapp_sha256'] as String,
    hostTrust: hostTrust,
    resources: Map<String, dynamic>.from(apkReceipt['resources'] as Map),
  );
  await verifyBundleSignature(path, archive, commands, bundletool);
  await bundletool.run(commands, ['validate', '--bundle=$path']);
  final config = jsonDecode(
    await bundletool.run(commands, ['dump', 'config', '--bundle=$path']),
  ) as Map<String, dynamic>;
  verifyBundlePageAlignment(config);
  Future<String> manifest(String xpath) async => (await bundletool.run(
    commands,
    ['dump', 'manifest', '--bundle=$path', '--module=base', '--xpath=$xpath'],
  )).trim().replaceAll('"', '');
  final applicationId = await manifest('/manifest/@package');
  final versionCode = await manifest('/manifest/@android:versionCode');
  require(
    applicationId == apkReceipt['application_id'] &&
        versionCode == apkReceipt['version_code'],
    'BUILD_AAB_INVALID',
    'App bundle manifest differs from the immutable APK baseline.',
  );
  return {
    'file': 'app-release.aab',
    'sha256': await hashFile(path),
    'application_id': applicationId,
    'version_code': versionCode,
    'engine_build_id': engine['build_id'],
    'host_payload_verified': true,
    'signed': true,
    'signature_verified': true,
    'native_elf_alignments': verifyAndroidPageAlignment(archive, bundle: true),
    'bundle_page_alignment': 'PAGE_ALIGNMENT_16K',
    'bundletool_version': (await bundletool.run(commands, ['version'])).trim(),
    'device_verified': false,
  };
}
