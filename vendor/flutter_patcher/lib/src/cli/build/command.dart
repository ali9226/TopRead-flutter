// TODO 项目发布工具新增标识符遵循 snake_case。
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import '../core.dart';
import '../progress.dart';
import '../crypto/ed25519.dart';
import '../sdk/android.dart';
import '../sdk/artifacts.dart';
import '../sdk/host.dart';
import '../sdk/environment.dart';
import '../baseline/repository.dart';
import '../baseline/store.dart';
import '../baseline/split.dart';
import 'pipeline.dart';
import 'host_policy.dart';
import 'app_bundle.dart';
import '../project.dart';

Future<int> buildCommand(ArgResults args) async {
  RandomAccessFile? lock;
  CliProgress? setup_progress;
  try {
    require(
      args.rest.length == 1 &&
          const ['android', 'ios'].contains(args.rest.single),
      'USAGE_ERROR',
      'Use build android or build ios.',
    );
    final platform = args.rest.single;

    final host = requireSupportedHost(target: platform);

    final cache = managedCache(args['cache-dir'] as String?);
    await rejectLinks(cache);
    await Directory(cache).create(recursive: true);
    final commands = Commands(cache);
    final project = p.absolute(
      args['project'] as String? ?? Directory.current.path,
    );
    final config = await ProjectConfig.load(project);
    final policy = args['host-policy'] == null
        ? await HostPolicy.of(
            project,
            config,
            platform: platform,
            applicationId: args['application-id'] as String?,
            versionCode: args['version-code'] as String?,
            flavor: args['flavor'] as String?,
            channel: args['channel'] as String?,
            strategy: args['strategy'] as String?,
          )
        : HostPolicy.read(
            await File(args['host-policy'] as String).readAsString(),
          );
    // The patch public key: what the host verifies envelopes with.
    final key = args['public-key'] == null
        ? policy.fields['fptc_key']!
        : (await File(args['public-key'] as String).readAsString()).trim();
    require(
      key == '-' || rawEd25519Key(key) != null,
      'BUILD_CONFIG_INVALID',
      '--public-key must hold a raw Ed25519 public key in base64, or -.',
    );
    final request = BuildRequest(
      project: project,
      output: p.absolute(
        args['out'] as String? ??
            p.join(
              project,
              '.dart_tool/flutter_patcher/releases',
              DateTime.now().microsecondsSinceEpoch.toString(),
            ),
      ),
      publicKey: key,
      hostPolicy: policy,
      target: args['target'] as String,
      flavor: args['flavor'] as String?,
      versionCode: args['version-code'] as String?,
      exportMethod: args['export-method'] as String?,
      androidFormat: args['android-format'] as String,
      url: config.url,
    );
    require(
      request.platform == platform,
      'BUILD_CONFIG_INVALID',
      'The host policy ABI is for ${request.platform}; use build ${request.platform}.',
    );
    // Apple ships the iOS toolchain (Xcode, codesign) for macOS only.
    require(
      platform == 'android' || host.os == 'macos',
      'HOST_UNSUPPORTED',
      'build ios requires macOS with Xcode; patch ios runs on every host.',
    );
    await request.validate();
    setup_progress = CliProgress('检查基线仓库、Flutter SDK 与补丁引擎', show_bytes: false);
    final offline = args['offline'] == true;
    final baselineUri = Uri.parse(
      args['baseline-store'] as String? ?? config.baselineStore,
    );
    final baselineStore = BaselineStore.open(
      baselineUri,
      commands,
      offline: offline,
    );
    if (args['baseline-store'] == null && config.baselinesInProject) {
      stderr.writeln(
        'WARNING: BASELINE_STORE_LOCAL: this host\'s baseline is '
        'kept only in ${config.baselineStore}; every patch of the host needs '
        'it, so set baseline_store in ${ProjectConfig.file} to a durable store.',
      );
    }
    if (!policy.signed) {
      stderr.writeln(
        'WARNING: UNSIGNED: this host accepts patch files that are not '
        'signed, so whoever can hand the app a file can run code in it. To '
        'sign, set trust.enabled to true in ${ProjectConfig.file} (run '
        '`flutter_patcher init` first if it names no key) and build again.',
      );
    }
    // build archives a host's first baseline, so a new file store starts here.
    if (baselineUri.scheme == 'file') {
      await rejectLinks(baselineUri.toFilePath());
      await Directory(baselineUri.toFilePath()).create(recursive: true);
    }
    await baselineStore.probe();
    // TODO 一个build只绑定首次成功的宿主；必须在SDK准备和编译前发现重复发布。
    final slot = releaseSlot(
      policy.fields['flavor']!,
      policy.fields['version_code']!,
      policy.fields['abi']!,
    );
    for (final suffix in ['tar.gz', 'json']) {
      final name = 'release-$slot.$suffix';
      require(
        !await baselineObjectExists(baselineStore, name),
        'BASELINE_ALREADY_ARCHIVED',
        '当前宿主 build ${policy.fields['version_code']} 已归档（$name），'
            '不能重新构建并替换。请使用首次成功生成的安装包；'
            '制作新整包时手动设置新的 build，Dart 修复请使用 patch 命令。'
            '脚本不会自动修改版本号，也不会覆盖已有基线。',
      );
    }
    await rejectLinks(p.join(cache, 'doctor.lock'));
    lock = await File(p.join(cache, 'doctor.lock')).open(mode: FileMode.append);
    await lock.lock(FileLock.blockingExclusive);
    final sdk = await identify(
      await Directory(findFlutter(args['flutter-sdk'] as String?))
          .resolveSymbolicLinks(),
      commands,
    );
    require(
      sdk.root != p.join(cache, 'flutter', sdk.version),
      'CONFIG_INVALID',
      'Select the stock Flutter SDK.',
    );
    var aapt = '';
    Bundletool? app_bundle_tool;
    if (platform == 'android') {
      final android = await resolveAndroidSdk(commands, host, sdk.flutter);
      final java_tools = await resolveJavaToolchain(
        commands,
        host,
        sdk.flutter,
        require_signer: request.androidFormat == 'both',
      );
      commands.environment['JAVA_HOME'] = java_tools.home;
      commands.environment['PATH'] =
          '${p.dirname(java_tools.java)}${Platform.isWindows ? ';' : ':'}${commands.environment['PATH'] ?? ''}';
      stderr.writeln('[进度] Android 构建与验签使用同一 Flutter JDK：${java_tools.home}');
      await commands.run(java_tools.java, ['-version']);
      if (request.androidFormat == 'both') {
        await commands.run(java_tools.jarsigner, ['-help']);
        try {
          app_bundle_tool = await Bundletool.locate(
            cache,
            environment: commands.environment,
          );
          final version = (await app_bundle_tool.run(commands, [
            'version',
          ])).trim();
          stderr.writeln('[进度] JDK、jarsigner 和 bundletool $version 预检通过');
        } on Failure catch (error) {
          // TODO 首次 Gradle 构建会补齐 AGP 自带的工具缓存；显式配置错误仍前置拒绝。
          if (error.code != 'BUILD_BUNDLETOOL_MISSING' ||
              commands.environment.containsKey('BUNDLETOOL_JAR') ||
              commands.environment.containsKey('BUNDLETOOL_CLASSPATH')) {
            rethrow;
          }
          stderr.writeln(
            '[进度] JDK 与 jarsigner 预检通过；Gradle 构建后将解析 bundletool 缓存',
          );
        }
      }
      aapt = await selectAapt(android, host);
    }
    final artifacts = ArtifactStore(
      cache,
      Uri.parse(args['artifacts-url'] as String),
      Uri.parse(args['index-url'] as String),
      Downloads(offline: offline),
    );
    // A new host uses the current releases; its baseline records them.
    await artifacts.selectCurrent(sdk.version);
    final engine = await artifacts.obtain(
      platform == 'ios' ? 'engine-ios' : 'engine',
      sdk,
    );
    await artifacts.obtain('tools', sdk);
    final environment = EnvironmentBuilder(cache, commands, offline: offline);
    final managed = await (platform == 'ios'
        ? environment.prepare(sdk, artifacts, ios: engine)
        : environment.prepare(sdk, artifacts, android: engine));
    final pipeline = BuildPipeline(
      commands,
      sdk,
      managed,
      artifacts.file(sdk, 'tools', 'flutter_patcher_tools-${sdk.version}.dill'),
      cache,
      aapt,
      engine,
      BaselineRepository(p.join(cache, 'baselines'), baselineStore),
      artifacts.selected,
      app_bundle_tool: app_bundle_tool,
    );
    setup_progress.complete();
    setup_progress = null;
    final result = request.hostPolicy.fields['strategy'] == 'so'
        ? await pipeline.buildSo(request)
        : await pipeline.build(request);
    stdout.writeln(
      jsonEncode(
        await buildSummary(
          p.normalize(p.absolute(request.output)),
          result,
          policy,
        ),
      ),
    );
    return 0;
  } catch (error) {
    setup_progress?.fail();
    final failure = error is Failure
        ? error
        : unexpectedFailure('BUILD_FAILED', 'Build', error);
    stderr.writeln(
      jsonEncode({
        'command': 'build',
        'status': 'failed',
        'code': failure.code,
        'message': failure.message,
      }),
    );
    return 2;
  } finally {
    if (lock != null) {
      await lock.unlock();
      await lock.close();
    }
  }
}

/// What build tells the terminal: the app to install and the host it is.
/// The whole report is build.json beside the app in [output].
Future<Map<String, Object?>> buildSummary(
  String output,
  Map<String, dynamic> result,
  HostPolicy policy,
) async {
  final app = await Directory(output)
      .list()
      .map((e) => e.path)
      .firstWhere(
        (path) => path.endsWith('.apk') || path.endsWith('.ipa'),
        orElse: () => '',
      );
  return {
    'command': 'build',
    'status': result['status'],
    'app': app,
    'android_format': result['android_format'],
    if (result['android_bundle'] != null)
      'bundle': p.join(output, 'app-release.aab'),
    'application_id': policy.fields['application_id'],
    'version_code': policy.fields['version_code'],
    'strategy': policy.fields['strategy'],
    'signed': policy.signed,
    'fingerprint': result['fingerprint'],
    'report': p.join(output, 'build.json'),
  };
}
