// TODO 项目发布工具新增标识符遵循 snake_case。
// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:flutter_patcher/src/cli/baseline/store.dart';
import 'package:flutter_patcher/src/cli/build/host_policy.dart';
import 'package:flutter_patcher/src/cli/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// TODO 假S3命令只记录HEAD参数，不执行任何外部程序或网络请求。
class _HeadCommands extends Commands {
  _HeadCommands(this.result) : super(Directory.systemTemp.path) {
    environment.remove('FLUTTER_PATCHER_S3_ENDPOINT');
  }
  final CommandResult result;
  List<String>? arguments;

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
    arguments = args;
    return result;
  }
}

/// TODO 自定义存储验证兼容回退只清理本次临时文件，包括失败分支。
class _CustomStore implements BaselineStore {
  _CustomStore({this.found = true, this.fail = false});
  final bool found;
  final bool fail;
  String? destination;
  @override
  Future<void> probe() async {}
  @override
  Future<bool> put(String name, String source) => throw UnimplementedError();
  @override
  Future<bool> get(String name, String destination) async {
    this.destination = destination;
    await File(destination).writeAsString('partial fixture');
    if (fail) throw StateError('fixture failure');
    return found;
  }
}

void main() {
  const name = 'release-default-30-arm64-v8a.tar.gz';

  test('S3只做HEAD；成功存在、明确404不存在，权限和连接错误拒绝继续', () async {
    final present = _HeadCommands(CommandResult(0, '{}', ''));
    expect(
      await baselineObjectExists(
        S3BaselineStore(Uri.parse('s3://fixture/baselines'), present),
        name,
      ),
      isTrue,
    );
    expect(present.arguments, [
      's3api',
      'head-object',
      '--bucket',
      'fixture',
      '--key',
      'baselines/$name',
    ]);
    for (final code in ['NoSuchKey', 'NotFound', '404']) {
      final commands = _HeadCommands(
        CommandResult(254, '', 'An error occurred ($code)'),
      );
      expect(
        await baselineObjectExists(
          S3BaselineStore(Uri.parse('s3://fixture'), commands),
          name,
        ),
        isFalse,
      );
    }
    for (final error in [
      'An error occurred (AccessDenied)',
      'An error occurred (403)',
      'network unavailable',
    ]) {
      final commands = _HeadCommands(CommandResult(254, '', error));
      await expectLater(
        baselineObjectExists(
          S3BaselineStore(Uri.parse('s3://fixture'), commands),
          name,
        ),
        throwsA(
          isA<Failure>().having(
            (e) => e.code,
            'code',
            'BASELINE_STORE_UNREACHABLE',
          ),
        ),
      );
    }
  });

  test('File存在性检查不读取或复制对象，拒绝目录和越界名称', () async {
    final root = await Directory.systemTemp.createTemp('baseline_head_file_');
    addTearDown(() => root.delete(recursive: true));
    final store = FileBaselineStore(await root.resolveSymbolicLinks());
    expect(await baselineObjectExists(store, name), isFalse);
    await File(p.join(store.root, name)).writeAsString('fixture');
    expect(await baselineObjectExists(store, name), isTrue);
    await Directory(p.join(store.root, 'release-default-31-arm64-v8a.tar.gz'))
        .create();
    await expectLater(
      baselineObjectExists(store, 'release-default-31-arm64-v8a.tar.gz'),
      throwsA(isA<Failure>()),
    );
    await expectLater(
      baselineObjectExists(store, '../$name'),
      throwsA(isA<Failure>()),
    );
  });

  test('HTTP使用HEAD，404与403/500分别处理，不下载基线', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var status = 200;
    final methods = <String>[];
    server.listen((request) async {
      methods.add(request.method);
      expect(request.uri.path, '/baselines/$name');
      request.response.statusCode = status;
      await request.response.close();
    });
    final store = HttpBaselineStore(
      Uri.parse('http://127.0.0.1:${server.port}/baselines'),
    );
    expect(await baselineObjectExists(store, name), isTrue);
    status = 404;
    expect(await baselineObjectExists(store, name), isFalse);
    for (final code in [403, 500]) {
      status = code;
      await expectLater(
        baselineObjectExists(store, name),
        throwsA(
          isA<Failure>().having(
            (e) => e.code,
            'code',
            'BASELINE_STORE_UNREACHABLE',
          ),
        ),
      );
    }
    expect(methods, everyElement('HEAD'));
  });

  test('自定义存储兼容回退清理自己的临时目录，包含下载失败分支', () async {
    for (final store in [
      _CustomStore(),
      _CustomStore(found: false),
      _CustomStore(fail: true),
    ]) {
      if (store.fail) {
        await expectLater(baselineObjectExists(store, name), throwsStateError);
      } else {
        expect(await baselineObjectExists(store, name), store.found);
      }
      expect(await File(store.destination!).exists(), isFalse);
      expect(await File(store.destination!).parent.exists(), isFalse);
    }
  });

  test('已归档新旧release格式在SDK准备与编译前拒绝，版本和原对象保持不变', () async {
    final fixtures = await Directory(
      p.join(Directory.current.path, '.dart_tool', 'flutter_patcher'),
    ).create(recursive: true);
    final temporary = await fixtures.createTemp('baseline_guard_cli_');
    addTearDown(() => temporary.delete(recursive: true));
    final root = await temporary.resolveSymbolicLinks();
    final cli_file = [
      File('vendor/flutter_patcher/bin/flutter_patcher.dart'),
      File('bin/flutter_patcher.dart'),
    ].firstWhere((file) => file.existsSync());
    final cli = await cli_file.resolveSymbolicLinks();
    for (final suffix in ['tar.gz', 'json']) {
      final project = await Directory(p.join(root, suffix)).create();
      await Directory(p.join(project.path, 'lib')).create();
      await File(p.join(project.path, 'lib/main.dart'))
          .writeAsString('void main() {}');
      final pubspec = File(p.join(project.path, 'pubspec.yaml'));
      const version = 'name: fixture\nversion: 1.2.7+30\n';
      await pubspec.writeAsString(version);
      final policy = File(p.join(project.path, 'policy.json'));
      await policy.writeAsString(
        HostPolicy({
          'schema': '2',
          'strategy': 'bytecode',
          'application_id': 'com.fixture.app',
          'channel': 'production',
          'flavor': 'default',
          'version_code': '30',
          'abi': 'arm64-v8a',
          'fptc_key': '-',
        }).canonical,
      );
      final baselines = await Directory(p.join(project.path, 'baselines'))
          .create();
      final archived = File(
        p.join(baselines.path, 'release-default-30-arm64-v8a.$suffix'),
      );
      await archived.writeAsString('first archived fixture');
      final cache = p.join(project.path, 'cache');
      final result = await Process.run('fvm', [
        'dart',
        'run',
        cli,
        'build',
        'android',
        '--project',
        project.path,
        '--host-policy',
        policy.path,
        '--baseline-store',
        baselines.uri.toString(),
        '--cache-dir',
        cache,
        '--flutter-sdk',
        p.join(root, 'must_not_start_sdk'),
        '--out',
        p.join(project.path, 'must_not_build'),
      ]);
      expect(result.exitCode, 2, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stderr, contains('BASELINE_ALREADY_ARCHIVED'));
      expect(result.stderr, contains('Dart 修复请使用 patch'));
      expect(await File(p.join(cache, 'doctor.lock')).exists(), isFalse);
      expect(
        await Directory(p.join(project.path, 'must_not_build')).exists(),
        isFalse,
      );
      expect(await pubspec.readAsString(), version);
      expect(await archived.readAsString(), 'first archived fixture');
    }
  });
}
