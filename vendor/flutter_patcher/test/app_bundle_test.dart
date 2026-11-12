// TODO 新增测试标识符遵循项目 snake_case 约定。
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_patcher/src/cli/build/app_bundle.dart';
import 'package:flutter_patcher/src/cli/build/android_abi.dart';
import 'package:flutter_patcher/src/cli/build/android_pages.dart';
import 'package:flutter_patcher/src/cli/core.dart';
import 'package:flutter_patcher/src/cli/patch/resources.dart';

class JarVerificationOutput extends Commands {
  JarVerificationOutput(this.output) : super(Directory.systemTemp.path);
  final String output;
  String? last_executable;

  @override
  Future<String> run(
    String executable,
    List<String> args, {
    String? cwd,
    List<int>? inputBytes,
    String code = 'TOOL_FAILED',
    Duration timeout = const Duration(minutes: 15),
    Map<String, String>? extraEnvironment,
  }) async {
    last_executable = executable;
    return output;
  }
}

void main() {
  Uint8List elf({String section = '.text', int alignment = 16384}) {
    final names = utf8.encode('\u0000.shstrtab\u0000$section\u0000');
    final bytes = Uint8List(384 + names.length);
    final data = ByteData.sublistView(bytes);
    data.setUint32(0, 0x7f454c46, Endian.big);
    bytes[4] = 2;
    bytes[5] = 1;
    data.setUint16(16, 3, Endian.little);
    data.setUint16(18, 183, Endian.little);
    data.setUint64(32, 64, Endian.little);
    data.setUint16(54, 56, Endian.little);
    data.setUint16(56, 1, Endian.little);
    data.setUint32(64, 1, Endian.little);
    data.setUint64(64 + 32, bytes.length, Endian.little);
    data.setUint64(64 + 40, bytes.length, Endian.little);
    data.setUint64(64 + 48, alignment, Endian.little);
    data.setUint64(40, 128, Endian.little);
    data.setUint16(58, 64, Endian.little);
    data.setUint16(60, 3, Endian.little);
    data.setUint16(62, 1, Endian.little);
    data.setUint32(192, 1, Endian.little);
    data.setUint64(192 + 24, 384, Endian.little);
    data.setUint64(192 + 32, names.length, Endian.little);
    data.setUint32(256, 11, Endian.little);
    bytes.setRange(384, bytes.length, names);
    return bytes;
  }

  test(
    'Android ELF rejects 4 KB and incongruent or truncated load segments',
    () {
      expect(verifyElfPageAlignment(elf()), [16384]);
      expect(verifyElfPageAlignment(elf(alignment: 65536)), [65536]);
      expect(
        () => verifyElfPageAlignment(elf(alignment: 4096)),
        throwsA(isA<Failure>()),
      );
      final base = elf();
      final mixedLoads = Uint8List(base.length + 112)
        ..setRange(0, base.length, base);
      final mixedData = ByteData.sublistView(mixedLoads);
      mixedData.setUint64(32, base.length, Endian.little);
      mixedData.setUint16(56, 2, Endian.little);
      mixedLoads.setRange(base.length, base.length + 56, base.sublist(64, 120));
      mixedLoads.setRange(
        base.length + 56,
        base.length + 112,
        base.sublist(64, 120),
      );
      mixedData.setUint64(base.length + 56 + 48, 4096, Endian.little);
      expect(() => verifyElfPageAlignment(mixedLoads), throwsA(isA<Failure>()));
      final incongruent = elf();
      ByteData.sublistView(incongruent).setUint64(64 + 16, 4096, Endian.little);
      expect(
        () => verifyElfPageAlignment(incongruent),
        throwsA(isA<Failure>()),
      );
      expect(
        () => verifyElfPageAlignment(elf().sublist(0, 63)),
        throwsA(isA<Failure>()),
      );
      final noLoads = elf();
      ByteData.sublistView(noLoads).setUint32(64, 0, Endian.little);
      expect(() => verifyElfPageAlignment(noLoads), throwsA(isA<Failure>()));
    },
  );
  test('AAB must request uncompressed PAGE_ALIGNMENT_16K splits', () {
    Map<String, dynamic> config(String alignment, {bool enabled = true}) => {
      'optimizations': {
        'uncompressNativeLibraries': {
          'enabled': enabled,
          'alignment': alignment,
        },
      },
    };
    verifyBundlePageAlignment(config('PAGE_ALIGNMENT_16K'));
    expect(
      () => verifyBundlePageAlignment(config('PAGE_ALIGNMENT_4K')),
      throwsA(isA<Failure>()),
    );
    expect(
      () => verifyBundlePageAlignment(
        config('PAGE_ALIGNMENT_16K', enabled: false),
      ),
      throwsA(isA<Failure>()),
    );
    expect(() => verifyBundlePageAlignment({}), throwsA(isA<Failure>()));
  });

  Archive stripped({String section = '.text'}) => Archive()
    ..addFile(
      ArchiveFile('base/lib/arm64-v8a/libflutter.so', elf().length, elf()),
    )
    ..addFile(
      ArchiveFile(
        'base/lib/arm64-v8a/libapp.so',
        elf(section: section).length,
        elf(section: section),
      ),
    );

  test('prestripped engine compatibility rejects every unrelated failure', () {
    bool accepts({
      String version = '3.47.9',
      int code = 1,
      String output = strippedEngineFlutterMessage,
      bool fresh = true,
      String section = '.text',
    }) => acceptsPrestrippedEngineCheck(
      flutterVersion: version,
      exitCode: code,
      output: output,
      freshBundle: fresh,
      archive: stripped(section: section),
    );
    expect(accepts(), isTrue);
    expect(accepts(version: '3.47.10'), isFalse);
    expect(accepts(code: 2), isFalse);
    expect(accepts(fresh: false), isFalse);
    expect(accepts(output: 'Gradle failed'), isFalse);
    expect(
      accepts(output: '$strippedEngineFlutterMessage\nOther failure'),
      isFalse,
    );
    for (final section in [
      '.symtab',
      '.debug_info',
      '.zdebug_info',
      '.gnu_debugdata',
    ]) {
      expect(accepts(section: section), isFalse);
    }
    expect(isStrippedArm64Elf([1, 2, 3]), isFalse);
  });

  final engineBytes = elf();
  final libappBytes = elf(section: '.app');
  const trust = '{"fingerprint":"same-host","policy_sha256":"same-policy"}';
  final engine = <String, dynamic>{
    'build_id': 'same-build',
    'files': [
      {
        'role': 'engine',
        'contents': [
          {
            'size': engineBytes.length,
            'sha256': sha256.convert(engineBytes).toString(),
          },
        ],
      },
    ],
  };
  Archive bundle({
    bool badEngine = false,
    bool badCode = false,
    bool badTrust = false,
    bool badAsset = false,
    bool extraAbi = false,
    bool extraPluginAbi = false,
    bool badPluginAlignment = false,
  }) {
    final archive = Archive();
    void add(String name, List<int> bytes) =>
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
    add(
      'base/lib/arm64-v8a/libflutter.so',
      badEngine ? [...engineBytes, 1] : engineBytes,
    );
    add(
      'base/lib/arm64-v8a/libapp.so',
      badCode ? [...libappBytes, 2] : libappBytes,
    );
    add(
      'base/assets/flutter_patcher/host-trust.json',
      utf8.encode(badTrust ? 'other-host' : trust),
    );
    add(
      'base/assets/flutter_assets/test.txt',
      utf8.encode(badAsset ? 'different' : 'same-asset'),
    );
    if (extraAbi) add('feature/lib/x86_64/libapp.so', libappBytes);
    if (extraPluginAbi) add('base/lib/armeabi-v7a/libplugin.so', [1, 2]);
    if (badPluginAlignment) {
      add('base/lib/arm64-v8a/libplugin.so', elf(alignment: 4096));
    }
    return archive;
  }

  final apkAssets = Archive()
    ..addFile(
      ArchiveFile(
        'assets/flutter_assets/test.txt',
        10,
        utf8.encode('same-asset'),
      ),
    );
  void verify(Archive archive) => verifyBundleArchive(
    archive,
    engine,
    libappHash: sha256.convert(libappBytes).toString(),
    hostTrust: trust,
    resources: resourceReceipt(apkAssets),
  );

  test(
    'AAB accepts the exact APK engine, libapp, host trust and assets',
    () => verify(bundle()),
  );
  for (final entry in <String, Archive Function()>{
    'stock engine': () => bundle(badEngine: true),
    'different Dart payload': () => bundle(badCode: true),
    'different host trust': () => bundle(badTrust: true),
    'different assets': () => bundle(badAsset: true),
    'extra feature ABI payload': () => bundle(extraAbi: true),
    'unsupported plugin ABI without Flutter engine': () =>
        bundle(extraPluginAbi: true),
    '4 KB plugin load segments beside valid 16 KB Flutter libraries': () =>
        bundle(badPluginAlignment: true),
  }.entries) {
    test(
      'AAB rejects ${entry.key}',
      () => expect(() => verify(entry.value()), throwsA(isA<Failure>())),
    );
  }
  test('APK rejects unsupported plugin ABIs even without another libapp', () {
    final archive = Archive()
      ..addFile(ArchiveFile('lib/arm64-v8a/libplugin.so', 1, [1]));
    verifyArm64NativeLibraries(archive);
    archive.addFile(ArchiveFile('lib/x86_64/libplugin.so', 1, [1]));
    expect(() => verifyArm64NativeLibraries(archive), throwsA(isA<Failure>()));
  });
  test('unsigned and unmatched JAR signature entries are rejected', () {
    final unsigned = bundle();
    expect(
      () => verifyBundleSignatureEntries(unsigned),
      throwsA(isA<Failure>()),
    );
    unsigned.addFile(ArchiveFile('META-INF/MANIFEST.MF', 1, [1]));
    unsigned.addFile(ArchiveFile('META-INF/CERT.SF', 1, [1]));
    unsigned.addFile(ArchiveFile('META-INF/OTHER.RSA', 1, [1]));
    expect(
      () => verifyBundleSignatureEntries(unsigned),
      throwsA(isA<Failure>()),
    );
    unsigned.addFile(ArchiveFile('META-INF/CERT.RSA', 1, [1]));
    verifyBundleSignatureEntries(unsigned);
  });
  test(
    'jarsigner exit zero must explicitly verify every bundle entry',
    () async {
      final archive = Archive()
        ..addFile(ArchiveFile('META-INF/MANIFEST.MF', 1, [1]))
        ..addFile(ArchiveFile('META-INF/CERT.SF', 1, [1]))
        ..addFile(ArchiveFile('META-INF/CERT.RSA', 1, [1]));
      Future<void> verify(String output) => verifyBundleSignature(
        'fixture.aab',
        archive,
        JarVerificationOutput(output),
        Bundletool('java', []),
      );
      await expectLater(verify('jar is unsigned.\n'), throwsA(isA<Failure>()));
      await expectLater(
        verify('jar verified.\nWarning: This jar contains unsigned entries.\n'),
        throwsA(isA<Failure>()),
      );
      await verify(
        'jar verified.\nWarning: The signer certificate is self-signed.\n',
      );
    },
  );
  test(
    'bundletool resolves only existing explicit jars and rejects missing tools',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'bundletool_contract_',
      );
      try {
        final jar = File('${directory.path}/bundletool-all.jar');
        await jar.writeAsBytes([1, 2]);
        final tool = await Bundletool.locate(
          directory.path,
          environment: {'BUNDLETOOL_JAR': jar.path},
        );
        expect(tool.classpath, [jar.path]);
        await expectLater(
          Bundletool.locate(
            directory.path,
            environment: {'BUNDLETOOL_JAR': '${jar.path}.missing'},
          ),
          throwsA(isA<Failure>()),
        );
        await expectLater(
          Bundletool.locate(
            directory.path,
            environment: {'HOME': directory.path},
          ),
          throwsA(isA<Failure>()),
        );
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );

  test('AAB签名校验使用显式选定的JDK工具，不从IDE运行时重新推导', () async {
    final archive = Archive()
      ..addFile(ArchiveFile('META-INF/MANIFEST.MF', 1, [1]))
      ..addFile(ArchiveFile('META-INF/CERT.SF', 1, [1]))
      ..addFile(ArchiveFile('META-INF/CERT.RSA', 1, [1]));
    final commands = JarVerificationOutput('jar verified.\n');
    await verifyBundleSignature(
      'fixture.aab',
      archive,
      commands,
      Bundletool(
        '/IDE runtime/bin/java',
        [],
        jarsigner: '/selected full JDK/bin/jarsigner',
      ),
    );
    expect(commands.last_executable, '/selected full JDK/bin/jarsigner');
  });

  test('只有java的JRE在AAB工具预检时失败，完整JDK保留同目录验签工具', () async {
    final root = await Directory.systemTemp.createTemp('bundle_jdk_');
    addTearDown(() => root.delete(recursive: true));
    final bin = await Directory('${root.path}/full JDK/bin')
        .create(recursive: true);
    final java = File(
      '${bin.path}/${Platform.isWindows ? 'java.exe' : 'java'}',
    );
    final signer = File(
      '${bin.path}/${Platform.isWindows ? 'jarsigner.exe' : 'jarsigner'}',
    );
    final jar = File('${root.path}/bundletool.jar');
    await java.writeAsString('fixture');
    await jar.writeAsString('fixture');
    final environment = {
      'JAVA_HOME': bin.parent.path,
      'BUNDLETOOL_JAR': jar.path,
    };
    await expectLater(
      Bundletool.locate(root.path, environment: environment),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          'BUILD_JDK_TOOLS_MISSING',
        ),
      ),
    );
    await signer.writeAsString('fixture');
    final tool = await Bundletool.locate(root.path, environment: environment);
    expect(tool.java, java.path);
    expect(tool.jarsigner, signer.path);
  });
}
