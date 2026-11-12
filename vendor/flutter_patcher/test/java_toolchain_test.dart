// TODO 项目发布工具新增标识符遵循 snake_case。
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:flutter_patcher/src/cli/core.dart';
import 'package:flutter_patcher/src/cli/sdk/android.dart';
import 'package:flutter_patcher/src/cli/sdk/host.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// TODO 假 Flutter 命令仅返回本地配置，记录参数且不启动真实进程。
class _FlutterConfigCommands extends Commands {
  _FlutterConfigCommands(this.result, {this.java_result, this.java_failure})
    : super(Directory.systemTemp.path);

  final CommandResult result;
  final CommandResult? java_result;
  final Failure? java_failure;
  String? executable;
  List<String>? arguments;
  final executables = <String>[];

  @override
  Future<CommandResult> runResult(
    String executable,
    List<String> args, {
    String? cwd,
    List<int>? inputBytes,
    String code = 'TOOL_FAILED',
    Duration timeout = const Duration(minutes: 15),
    Map<String, String>? extraEnvironment,
    String? logPath,
    bool forward_progress = false,
  }) async {
    this.executable = executable;
    arguments = List<String>.of(args);
    executables.add(executable);
    if (executable == 'java') {
      if (java_failure != null) throw java_failure!;
      return java_result ?? CommandResult(1, '', 'Java was not found');
    }
    return result;
  }
}

void main() {
  const host = HostIdentity('macos', 'arm64');
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('java_toolchain_');
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  /// TODO 只创建空工具文件验证选择和前置检查，不执行 Java 或访问全局配置。
  Future<String> create_jdk(
    String name, {
    HostIdentity platform = host,
    bool java = true,
    bool jarsigner = true,
  }) async {
    final home = p.join(directory.path, name);
    await Directory(p.join(home, 'bin')).create(recursive: true);
    for (final tool in [if (java) 'java', if (jarsigner) 'jarsigner']) {
      await File(p.join(home, 'bin', platform.exe(tool))).writeAsString('');
    }
    return home;
  }

  CommandResult config_result(String home, {String prefix = ''}) =>
      CommandResult(0, '$prefix${jsonEncode({'jdk-dir': home})}', '');

  test('Flutter-selected JDK takes precedence over IDE JAVA_HOME', () async {
    final configured = await create_jdk('configured_jdk');
    final ide_runtime = await create_jdk('ide_runtime', jarsigner: false);
    final commands = _FlutterConfigCommands(config_result(configured));
    commands.environment['JAVA_HOME'] = ide_runtime;

    final toolchain = await resolveJavaToolchain(
      commands,
      host,
      '/managed Flutter/bin/flutter',
      require_signer: true,
    );

    expect(toolchain.home, configured);
    expect(toolchain.java, p.join(configured, 'bin', 'java'));
    expect(toolchain.jarsigner, p.join(configured, 'bin', 'jarsigner'));
    expect(commands.executable, '/managed Flutter/bin/flutter');
    expect(commands.arguments, ['--suppress-analytics', 'config', '--machine']);
    expect(commands.environment['JAVA_HOME'], ide_runtime);
  });

  test('JBR without jarsigner is rejected before AAB signing', () async {
    final home = await create_jdk('IDE Runtime', jarsigner: false);
    final commands = _FlutterConfigCommands(config_result(home));

    await expectLater(
      resolveJavaToolchain(commands, host, 'flutter', require_signer: true),
      throwsA(
        isA<Failure>()
            .having((error) => error.code, 'code', 'BUILD_JDK_TOOLS_MISSING')
            .having(
              (error) => error.message,
              'missing tool path',
              contains(p.join(home, 'bin', 'jarsigner')),
            )
            .having(
              (error) => error.message,
              'configuration guidance',
              contains('flutter config --jdk-dir=<path>'),
            ),
      ),
    );

    final toolchain = await resolveJavaToolchain(commands, host, 'flutter');
    expect(toolchain.home, home);
  });

  test('JDK paths containing spaces are preserved', () async {
    final home = await create_jdk('Full Java Development Kit/Contents/Home');
    final toolchain = await resolveJavaToolchain(
      _FlutterConfigCommands(config_result(home)),
      host,
      'flutter',
      require_signer: true,
    );

    expect(toolchain.java, p.join(home, 'bin', 'java'));
    expect(toolchain.jarsigner, p.join(home, 'bin', 'jarsigner'));
  });

  test('Flutter startup logs before machine JSON are accepted', () async {
    final home = await create_jdk('jdk');
    final toolchain = await resolveJavaToolchain(
      _FlutterConfigCommands(
        config_result(home, prefix: 'Rebuilding local git cache...\n'),
      ),
      host,
      'flutter',
      require_signer: true,
    );

    expect(toolchain.home, home);
  });

  test('java must exist even when jarsigner is not required', () async {
    final home = await create_jdk('invalid_jdk', java: false);
    await expectLater(
      resolveJavaToolchain(
        _FlutterConfigCommands(config_result(home)),
        host,
        'flutter',
      ),
      throwsA(
        isA<Failure>()
            .having((error) => error.code, 'code', 'BUILD_JDK_TOOLS_MISSING')
            .having(
              (error) => error.message,
              'missing tool path',
              contains(p.join(home, 'bin', 'java')),
            ),
      ),
    );
  });

  test('Windows hosts require tools with executable suffixes', () async {
    const windows = HostIdentity('windows', 'x64');
    final home = await create_jdk('windows_jdk', platform: windows);
    final toolchain = await resolveJavaToolchain(
      _FlutterConfigCommands(config_result(home)),
      windows,
      'flutter.bat',
      require_signer: true,
    );

    expect(toolchain.java, p.join(home, 'bin', 'java.exe'));
    expect(toolchain.jarsigner, p.join(home, 'bin', 'jarsigner.exe'));
  });

  test(
    'unreadable or invalid Flutter JDK configuration is not guessed',
    () async {
      for (final result in [
        CommandResult(0, '{"jdk-dir":42}', ''),
        CommandResult(0, 'invalid JSON', ''),
        CommandResult(0, '{invalid JSON}', ''),
        CommandResult(1, '{"jdk-dir":"ignored"}', 'Flutter config failed'),
      ]) {
        await expectLater(
          resolveJavaToolchain(_FlutterConfigCommands(result), host, 'flutter'),
          throwsA(
            isA<Failure>()
                .having(
                  (error) => error.code,
                  'code',
                  'BUILD_JDK_TOOLS_MISSING',
                )
                .having(
                  (error) => error.message,
                  'configuration guidance',
                  contains('flutter config --jdk-dir=<path>'),
                ),
          ),
        );
      }
    },
  );

  test('PATH java.home supports absent or empty configured JDK', () async {
    final home = await create_jdk('PATH JDK/Contents/Home');
    final properties = 'Property settings:\n    java.home = $home\n';
    for (final config in [
      '{}',
      '{"jdk-dir":null}',
      '{"jdk-dir":""}',
      '{"jdk-dir":"   "}',
    ]) {
      for (final on_stderr in [false, true]) {
        final commands = _FlutterConfigCommands(
          CommandResult(0, config, ''),
          java_result: CommandResult(
            0,
            on_stderr ? '' : properties,
            on_stderr ? properties : 'openjdk version',
          ),
        );
        final toolchain = await resolveJavaToolchain(
          commands,
          host,
          '/managed/flutter',
          require_signer: true,
        );

        expect(toolchain.home, home);
        expect(toolchain.java, p.join(home, 'bin', 'java'));
        expect(toolchain.jarsigner, p.join(home, 'bin', 'jarsigner'));
        expect(commands.executables, ['/managed/flutter', 'java']);
        expect(commands.arguments, ['-XshowSettings:properties', '-version']);
      }
    }
  });

  test('PATH Java failures do not disclose system properties', () async {
    const private_property = 'user.home = private-system-property';
    for (final commands in [
      _FlutterConfigCommands(
        CommandResult(0, '{}', ''),
        java_result: CommandResult(1, private_property, private_property),
      ),
      _FlutterConfigCommands(
        CommandResult(0, '{}', ''),
        java_result: CommandResult(0, private_property, ''),
      ),
      _FlutterConfigCommands(
        CommandResult(0, '{}', ''),
        java_result: CommandResult(
          0,
          '    java.home =   \n$private_property\n',
          '',
        ),
      ),
      _FlutterConfigCommands(
        CommandResult(0, '{}', ''),
        java_failure: Failure('BUILD_JDK_TOOLS_MISSING', private_property),
      ),
    ]) {
      await expectLater(
        resolveJavaToolchain(commands, host, 'flutter'),
        throwsA(
          isA<Failure>()
              .having((error) => error.code, 'code', 'BUILD_JDK_TOOLS_MISSING')
              .having(
                (error) => error.message,
                'configuration guidance',
                contains('flutter config --jdk-dir=<path>'),
              )
              .having(
                (error) => error.message,
                'no system properties',
                isNot(contains(private_property)),
              ),
        ),
      );
    }
  });

  test('explicit invalid JDK is not replaced by PATH Java', () async {
    final invalid_home = await create_jdk('missing_java', java: false);
    final fallback_home = await create_jdk('PATH_JDK');
    final commands = _FlutterConfigCommands(
      config_result(invalid_home),
      java_result: CommandResult(0, 'java.home = $fallback_home\n', ''),
    );

    await expectLater(
      resolveJavaToolchain(commands, host, 'flutter', require_signer: true),
      throwsA(isA<Failure>()),
    );
    expect(commands.executables, ['flutter']);
  });

  test('PATH runtime without jarsigner is rejected for AAB', () async {
    final home = await create_jdk('PATH JBR', jarsigner: false);
    final commands = _FlutterConfigCommands(
      CommandResult(0, '{"jdk-dir":null}', ''),
      java_result: CommandResult(0, '', '    java.home = $home\n'),
    );

    await expectLater(
      resolveJavaToolchain(commands, host, 'flutter', require_signer: true),
      throwsA(
        isA<Failure>()
            .having((error) => error.code, 'code', 'BUILD_JDK_TOOLS_MISSING')
            .having(
              (error) => error.message,
              'missing signer path',
              contains(p.join(home, 'bin', 'jarsigner')),
            ),
      ),
    );
  });
}
