// TODO 项目发布工具新增标识符遵循 snake_case。
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core.dart';
import 'host.dart';

/// Android SDK root: `ANDROID_HOME`, then `ANDROID_SDK_ROOT`, then the
/// location Android Studio uses on each host. Returns null when none holds a
/// `build-tools` directory.
String? locateAndroidSdk(
  HostIdentity host, {
  Map<String, String>? environment,
}) {
  final env = environment ?? Platform.environment;
  final home = env['HOME'] ?? env['USERPROFILE'];
  final candidates = <String?>[
    env['ANDROID_HOME'],
    env['ANDROID_SDK_ROOT'],
    if (host.isWindows && env['LOCALAPPDATA'] != null)
      p.join(env['LOCALAPPDATA']!, 'Android', 'Sdk'),
    if (host.os == 'macos' && home != null)
      p.join(home, 'Library', 'Android', 'sdk'),
    if (host.os == 'linux' && home != null) p.join(home, 'Android', 'Sdk'),
  ];
  for (final candidate in candidates) {
    if (candidate != null &&
        candidate.isNotEmpty &&
        Directory(p.join(candidate, 'build-tools')).existsSync()) {
      return candidate;
    }
  }
  return null;
}

/// The Android SDK the way Flutter itself resolves it: `flutter config
/// --android-sdk` first, then [locateAndroidSdk]. Gradle builds use Flutter's
/// choice, so the CLI must not reject a host where only the config is set.
Future<String> resolveAndroidSdk(
  Commands commands,
  HostIdentity host,
  String flutterLauncher,
) async {
  final result = await commands.runResult(flutterLauncher, [
    '--suppress-analytics',
    'config',
    '--machine',
  ]);
  final value = _flutterConfig(result)?['android-sdk'];
  final configured = value is String ? value : null;
  final sdk =
      configured != null &&
          Directory(p.join(configured, 'build-tools')).existsSync()
      ? configured
      : locateAndroidSdk(host);
  require(
    sdk != null,
    'ANDROID_SDK_MISSING',
    'No Android SDK: select one with flutter config --android-sdk or ANDROID_HOME.',
  );
  return sdk!;
}

/// TODO 解析 Flutter 的机器配置，兼容配置 JSON 前面的启动或缓存日志。
Map<String, dynamic>? _flutterConfig(CommandResult result) {
  if (result.exitCode != 0) return null;
  final start = result.stdout.indexOf('{');
  if (start < 0) return null;
  try {
    final value = jsonDecode(result.stdout.substring(start));
    return value is Map<String, dynamic> ? value : null;
  } on FormatException {
    return null;
  }
}

/// TODO Flutter 选中的同一套 JDK，供 Android 构建与产物签名验证复用。
class JavaToolchain {
  const JavaToolchain(this.home, this.java, this.jarsigner);

  static const _guidance =
      'Select a complete JDK with flutter config --jdk-dir=<path>.';

  /// TODO Flutter 最终选择的 JDK 根目录，不受当前 IDE 的 JAVA_HOME 覆盖。
  final String home;

  /// TODO 所选 JDK 的 Java 启动程序。
  final String java;

  /// TODO 所选 JDK 的签名验证程序；仅在需要 AAB 验签时要求其存在。
  final String jarsigner;

  /// TODO 从 Flutter 最终配置解析 JDK，并在构建前检查必要工具是否存在。
  static JavaToolchain fromFlutterConfig(
    CommandResult result,
    HostIdentity host, {
    bool require_signer = false,
  }) {
    final configured = _flutterConfig(result)?['jdk-dir'];
    require(
      configured is String && configured.trim().isNotEmpty,
      'BUILD_JDK_TOOLS_MISSING',
      'Flutter config --machine did not provide a JDK directory'
          '${result.exitCode == 0 ? '' : ' (exit ${result.exitCode})'}. '
          '$_guidance',
    );
    return fromHome(configured as String, host, require_signer: require_signer);
  }

  /// TODO 校验 Flutter 或 PATH Java 报告的同一 JDK，不混用其他目录中的工具。
  static JavaToolchain fromHome(
    String home,
    HostIdentity host, {
    bool require_signer = false,
  }) {
    final java = p.join(home, 'bin', host.exe('java'));
    final jarsigner = p.join(home, 'bin', host.exe('jarsigner'));
    final missing = <String>[
      if (!File(java).existsSync()) java,
      if (require_signer && !File(jarsigner).existsSync()) jarsigner,
    ];
    require(
      missing.isEmpty,
      'BUILD_JDK_TOOLS_MISSING',
      'Flutter-selected JDK is missing required tools: '
          '${missing.join(', ')}. $_guidance',
    );
    return JavaToolchain(home, java, jarsigner);
  }
}

/// TODO 使用当前受管理 Flutter 的最终 JDK，避免构建和验签选择不同的 Java。
Future<JavaToolchain> resolveJavaToolchain(
  Commands commands,
  HostIdentity host,
  String flutter, {
  bool require_signer = false,
}) async {
  final result = await commands.runResult(flutter, [
    '--suppress-analytics',
    'config',
    '--machine',
  ], code: 'BUILD_JDK_TOOLS_MISSING');
  final config = _flutterConfig(result);
  final configured = config?['jdk-dir'];
  if (config == null ||
      configured != null && configured is! String ||
      configured is String && configured.trim().isNotEmpty) {
    return JavaToolchain.fromFlutterConfig(
      result,
      host,
      require_signer: require_signer,
    );
  }

  /// TODO Flutter 仅从 PATH 找到 Java 时没有 javaHome；查询该 Java 自身的目录。
  CommandResult java_settings;
  try {
    java_settings = await commands.runResult('java', [
      '-XshowSettings:properties',
      '-version',
    ], code: 'BUILD_JDK_TOOLS_MISSING');
  } on Failure {
    throw Failure(
      'BUILD_JDK_TOOLS_MISSING',
      'Cannot query the JDK directory from PATH java. '
          '${JavaToolchain._guidance}',
    );
  }
  final match = RegExp(
    r'^[ \t]*java\.home[ \t]*=[ \t]*([^\r\n]*)',
    multiLine: true,
  ).firstMatch('${java_settings.stdout}\n${java_settings.stderr}');
  final home = match?.group(1)?.trim();
  require(
    java_settings.exitCode == 0 && home != null && home.isNotEmpty,
    'BUILD_JDK_TOOLS_MISSING',
    'PATH java did not report a usable java.home'
        '${java_settings.exitCode == 0 ? '' : ' (exit ${java_settings.exitCode})'}. '
        '${JavaToolchain._guidance}',
  );
  return JavaToolchain.fromHome(home!, host, require_signer: require_signer);
}

/// Numeric build-tools ordering: `34.0.0` sorts after `9.0.0`, and
/// pre-release suffixes (`35.0.0-rc1`) sort before the matching release.
int compareBuildToolsVersions(String a, String b) {
  List<Object> parts(String v) {
    final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:-(.+))?$').firstMatch(v);
    if (match == null) return [-1, -1, -1, v];
    return [
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
      match[4] ?? '~', // '~' sorts after any rc tag
    ];
  }

  final x = parts(a), y = parts(b);
  for (var i = 0; i < 4; i++) {
    final c = x[i] is int
        ? (x[i] as int).compareTo(y[i] as int)
        : (x[i] as String).compareTo(y[i] as String);
    if (c != 0) return c;
  }
  return 0;
}

/// Newest build-tools directory that ships `aapt` for this host.
Future<String> selectAapt(String androidSdk, HostIdentity host) async {
  final buildTools = await Directory(p.join(androidSdk, 'build-tools'))
      .list()
      .where((f) => f is Directory)
      .map((d) => d.path)
      .toList();
  buildTools.sort(
    (a, b) => compareBuildToolsVersions(p.basename(b), p.basename(a)),
  );
  for (final directory in buildTools) {
    final aapt = p.join(directory, host.exe('aapt'));
    if (File(aapt).existsSync()) return aapt;
  }
  throw Failure('ANDROID_SDK_MISSING', 'Android build-tools aapt is missing.');
}

/// `flutter build apk` finds a JDK through JAVA_HOME, `flutter config
/// --jdk-dir` or Android Studio's bundled runtime, so the JDK is only checked
/// when JAVA_HOME is set and would otherwise mislead Gradle.
void checkJavaHome(HostIdentity host, {Map<String, String>? environment}) {
  final javaHome = (environment ?? Platform.environment)['JAVA_HOME'];
  if (javaHome == null || javaHome.isEmpty) return;
  require(
    File(p.join(javaHome, 'bin', host.exe('java'))).existsSync(),
    'JAVA_HOME_INVALID',
    'JAVA_HOME does not contain bin/java: $javaHome',
  );
}
