import 'dart:io';

import 'package:mysql_client/mysql_client.dart';
import 'package:flutter_patcher/src/cli/progress.dart';

import 'check_managed_sdk.dart';
import 'hot_patch_config.dart';
import 'hot_patch_support.dart';
import 'obs_transport.dart';

// TODO 脚本以自身所在目录定位工程，不依赖终端工作目录。
final app_dir = File(Platform.script.toFilePath()).parent.parent;
final backend_dir = Directory(
  Platform.environment['HOT_PATCH_BACKEND_DIR'] ?? '${app_dir.parent.path}/后端',
);

/// TODO 一键构建与登记默认双端、本地库和草稿；生产部署与商店提交仍由发布者操作。
Future<void> main(List<String> args) async {
  try {
    if (args.isEmpty || args.contains('--help')) {
      _usage();
      return;
    }
    final command = args.first;
    final options = _options(command, args.skip(1).toList());
    final version = _version();
    final production = options.containsKey('prod');
    final dry_run = options.containsKey('dry-run');
    if (options.containsKey('local') && production) {
      throw const FormatException('--local 与 --prod 不能同时使用');
    }
    final platforms = target_platforms(options['os']);
    if (options.containsKey('android-format') &&
        (!platforms.contains('android') ||
            !['apk', 'both'].contains(options['android-format']))) {
      throw const FormatException('--android-format 只支持 apk|both，且须包含 Android');
    }
    final channel = options['channel'] ?? 'production';
    if (!RegExp(r'^[A-Za-z0-9_]{1,32}$').hasMatch(channel)) {
      throw const FormatException('--channel 只接受1-32位字母、数字、下划线');
    }
    if (options['export-method'] != null &&
        ![
          'app-store',
          'ad-hoc',
          'development',
          'enterprise',
        ].contains(options['export-method'])) {
      throw const FormatException(
        '--export-method 只支持 app-store|ad-hoc|development|enterprise',
      );
    }
    if ((options['remark'] ?? '').length > 255) {
      throw const FormatException('--remark 不能超过255字符');
    }
    final vc = options['vc'] == null
        ? version.build
        : int.tryParse(options['vc']!);
    if (vc == null || vc <= 0 || vc > 0xffffffff) {
      throw const FormatException('--vc 必须为uint32正整数');
    }
    if (options['status'] != null && options['status'] != 'draft') {
      throw const FormatException('脚本仅登记草稿；请在后台显式灰度发布或激活回滚');
    }
    if (options['file'] == null && vc != version.build) {
      throw const FormatException('当前 build 与目标 VC 不一致，请先检出对应版本；脚本不会修改商店版本');
    }
    stdout.writeln(
      '当前版本 ${version.version}+${version.build}；目标${production ? '生产' : '本地'}；${platforms.join('+')}',
    );
    if (command == 'release' && platforms.contains('ios')) {
      await require_generated_ios_host_trust(
        File('${app_dir.path}/ios/Runner/Info.plist'),
      );
    }
    if (dry_run) {
      await _dry_run(command, options, platforms, vc);
      return;
    }
    final production_prompt = switch (command) {
      'release' =>
        '将按当前版本 ${version.version}+${version.build} 构建生产正式包并归档基线，继续？',
      'migrate' => '将更新生产数据库结构并回填热更统计，继续？',
      _ => '将对生产环境执行 $command（补丁登记为草稿），继续？',
    };
    if (production &&
        command != 'check' &&
        !_confirm(production_prompt, options)) {
      stdout.writeln('已取消');
      return;
    }
    switch (command) {
      case 'check':
        await _check(options, production);
        break;
      case 'migrate':
        await _run('node', [
          'database/migrations/20261110_app_patch.js',
          if (production) '--production',
        ], directory: backend_dir.path);
        break;
      case 'release':
        if (!production &&
            !_confirm(
              '将按当前版本 ${version.version}+${version.build} 构建正式包并归档基线，继续？',
              options,
            )) {
          stdout.writeln('已取消');
          return;
        }
        await _release(options, production, platforms);
        break;
      case 'patch':
      case 'withdraw':
        await _patch(command, options, production, platforms, vc);
        break;
    }
  } catch (error) {
    stderr.writeln('失败：$error');
    // TODO 失败退出必须关闭进程内残留网络请求，避免终端显示失败后仍无限等待。
    await stderr.flush();
    exit(1);
  }
}

void _usage() => stdout.writeln('''
fvm dart run scripts/hot_patch.dart <check|release|patch|withdraw|migrate> [选项]
  --local | --prod                默认本地；生产在任何写入前确认，--yes 跳过确认
  --os both|android|ios           默认双端
  --channel production|verification  默认production；本地验证建议verification
  --vc N                         默认当前 pubspec build；不修改商店版本
  --file <SDK规范名称.fptc>       跳过构建，校验并登记现成文件
  --remark 文本                  草稿说明
  --baseline-store file:///路径  本地默认local_baselines；生产默认yaml持久仓库
  --dry-run                      只展示计划/校验已有文件，不连接数据库、不构建、不写配置
  --android-format both|apk      仅 release 使用；Android 默认同时生成 AAB 与 APK
release 使用当前 pubspec.yaml 版本；整包发版前请手动配置版本号和 build。
所有补丁和回滚只登记草稿，发布/灰度/回滚激活请在管理后台操作。
''');

/// TODO 未知选项直接拒绝，避免环境或草稿参数拼写错误导致意外发布。
Map<String, String> _options(String command, List<String> args) {
  const common = {'local', 'prod', 'yes', 'dry-run'};
  const supported = {
    'check': <String>{'baseline-store'},
    'migrate': <String>{},
    'release': <String>{
      'os',
      'baseline-store',
      'export-method',
      'channel',
      'android-format',
    },
    'patch': <String>{
      'os',
      'vc',
      'file',
      'remark',
      'baseline-store',
      'status',
      'channel',
    },
    'withdraw': <String>{
      'os',
      'vc',
      'file',
      'remark',
      'baseline-store',
      'channel',
    },
  };
  if (!supported.containsKey(command)) throw FormatException('未知命令：$command');
  final values = <String, String>{};
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (!arg.startsWith('--')) throw FormatException('未知参数：$arg');
    final key = arg.substring(2);
    if (key == 'bump' || key.startsWith('bump=')) {
      throw const FormatException(
        '--bump 已停用；请手动修改 pubspec.yaml 的版本号和 build，并移除 --bump 参数；未构建、未连接数据库',
      );
    }
    if (!common.contains(key) && !supported[command]!.contains(key)) {
      throw FormatException('不支持选项：$arg');
    }
    if (values.containsKey(key)) throw FormatException('重复选项：$arg');
    if (common.contains(key)) {
      values[key] = 'true';
      continue;
    }
    if (index + 1 == args.length || args[index + 1].startsWith('--')) {
      throw FormatException('缺少 $arg 的值');
    }
    values[key] = args[++index];
  }
  return values;
}

({String version, int build}) _version() {
  final text = File('${app_dir.path}/pubspec.yaml').readAsStringSync();
  final match = RegExp(
    r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$',
    multiLine: true,
  ).firstMatch(text);
  if (match == null) throw const FormatException('pubspec version 必须为 X.Y.Z+N');
  return (version: match[1]!, build: int.parse(match[2]!));
}

bool _confirm(String prompt, Map<String, String> options) {
  if (options.containsKey('yes')) return true;
  stdout.write('$prompt [y/N] ');
  return ['y', 'yes'].contains(stdin.readLineSync()?.trim().toLowerCase());
}

/// TODO 演练在加载凭据之前结束，且不创建输出目录、不修改全局 AWS 配置。
Future<void> _dry_run(
  String command,
  Map<String, String> options,
  List<String> platforms,
  int vc,
) async {
  if (command != 'migrate') {
    stdout.writeln('[dry-run] baseline=${_baseline_store(options)}');
  }
  if (options['file'] != null) {
    final file = File(options['file']!);
    final target = parse_patch_target(file.uri.pathSegments.last);
    final envelope = parse_patch_envelope(await file.readAsBytes());
    _validate_type(command, envelope);
    _validate_target(target, vc, platforms, options['channel'] ?? 'production');
    stdout.writeln(
      '[dry-run] ${target.file_name} seq=${envelope.seq}；草稿；商店版本保持不变',
    );
  } else {
    if (command == 'release' && platforms.contains('android')) {
      stdout.writeln(
        '[dry-run] Android格式=${options['android-format'] ?? 'both'}；AAB与APK使用同一受控宿主基线',
      );
    }
    stdout.writeln(
      '[dry-run] $command ${platforms.join('+')} VC=$vc；仅展示计划，未构建/上传/写库',
    );
  }
}

String _baseline_store(Map<String, String> options) {
  final override =
      options['baseline-store'] ??
      Platform.environment['HOT_PATCH_BASELINE_STORE'];
  if (override != null) return canonical_baseline_store(override);
  if (!options.containsKey('prod')) {
    return canonical_baseline_store(
      Directory(
        '${app_dir.path}/.dart_tool/flutter_patcher/local_baselines',
      ).uri.toString(),
    );
  }
  final text = File('${app_dir.path}/flutter_patcher.yaml').readAsStringSync();
  final value = RegExp(
    r'^baseline_store:\s*(\S+)',
    multiLine: true,
  ).firstMatch(text)?[1];
  if (value == null) throw const FormatException('未配置 baseline_store');
  return canonical_baseline_store(value);
}

Map<String, String> _environment(ObsConfig? obs) => {
  ...Platform.environment,
  'PATH': '${app_dir.path}/scripts/shims:${Platform.environment['PATH'] ?? ''}',
  if (obs != null) ...{
    // TODO 使用选定数据库的配置，不能混入终端遗留的另一环境凭据。
    'AWS_ACCESS_KEY_ID': obs.access_key_id,
    'AWS_SECRET_ACCESS_KEY': obs.secret_access_key,
    'AWS_SESSION_TOKEN': '',
    'FLUTTER_PATCHER_S3_ENDPOINT': _endpoint(obs).toString(),
  },
};

Uri _endpoint(ObsConfig obs) => validate_obs_endpoint(
  Uri.parse(obs.server.contains('://') ? obs.server : 'https://${obs.server}'),
);
ObsTransport _transport(ObsConfig obs) => ObsTransport(
  endpoint: _endpoint(obs),
  bucket: obs.bucket,
  access_key: obs.access_key_id,
  secret_key: obs.secret_access_key,
);

Future<void> _run(
  String executable,
  List<String> args, {
  String? directory,
  Map<String, String>? environment,
}) async {
  stdout.writeln('▶ $executable ${args.join(' ')}');
  final process = await Process.start(
    executable,
    args,
    workingDirectory: directory ?? app_dir.path,
    environment: environment,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await process.exitCode;
  if (code != 0) throw ProcessException(executable, args, '子进程失败', code);
}

Future<MySQLConnection> _database(bool production) async {
  final config = load_backend_config(backend_dir);
  return connect_db(
    production ? config.prod : config.local,
    production: production,
  );
}

Future<ObsConfig> _obs(bool production) async {
  final conn = await _database(production);
  try {
    return await load_obs_config(conn, production ? '生产' : '本地');
  } finally {
    await conn.close();
  }
}

/// TODO 检查只访问选定环境，不修改 AWS 寻址配置、不自动访问生产数据库。
Future<void> _check(Map<String, String> options, bool production) async {
  await check_managed_sdk(app_dir);
  final conn = await _database(production);
  try {
    await _require_schema(conn);
    final obs = await load_obs_config(conn, production ? '生产' : '本地');
    final transport = _transport(obs);
    try {
      await transport.head_bucket();
      await transport.require_atomic_writes();
      stdout.writeln('OBS HTTPS 证书、桶权限与原子写入前提检查通过');
      final store = Uri.parse(_baseline_store(options));
      if (store.scheme == 's3') {
        if (store.host != obs.bucket) {
          throw const FormatException('baseline bucket 与所选环境 OBS bucket 不一致');
        }
        final keys = await transport.list_keys(
          store.path.replaceFirst(RegExp(r'^/'), ''),
        );
        stdout.writeln('baseline 对象数：${keys.length}');
      } else {
        stdout.writeln('本地 baseline：${store.toFilePath()}');
      }
    } finally {
      transport.close();
    }
  } finally {
    await conn.close();
  }
}

/// TODO 按用户配置的当前版本构建并归档基线，始终保留 pubspec.yaml 版本。
Future<void> _release(
  Map<String, String> options,
  bool production,
  List<String> platforms,
) async {
  final store = _baseline_store(options);
  final preflight = CliProgress('检查发布配置、数据库与 OBS 权限', show_bytes: false);
  ObsConfig? obs;
  try {
    obs = Uri.parse(store).scheme == 's3' ? await _obs(production) : null;
    if (obs != null) {
      final transport = _transport(obs);
      try {
        await transport.head_bucket();
        await transport.require_atomic_writes();
      } finally {
        transport.close();
      }
    }
    preflight.complete();
  } catch (_) {
    preflight.fail();
    rethrow;
  }
  final id = publication_id();
  for (final platform in platforms) {
    final out =
        '${app_dir.path}/.dart_tool/flutter_patcher/releases/$id-$platform';
    await _run('bash', [
      'scripts/patcher_run.sh',
      'fvm',
      'dart',
      'run',
      'flutter_patcher',
      'build',
      platform,
      '--out',
      out,
      '--baseline-store',
      store,
      '--channel',
      options['channel'] ?? 'production',
      if (platform == 'android') ...[
        '--android-format',
        options['android-format'] ?? 'both',
      ],
      if (platform == 'ios') ...[
        '--export-method',
        options['export-method'] ?? 'app-store',
      ],
    ], environment: _environment(obs));
    final extensions = platform == 'ios'
        ? ['ipa']
        : (options['android-format'] ?? 'both') == 'both'
        ? ['apk', 'aab']
        : ['apk'];
    for (final extension in extensions) {
      final artifact = File('$out/app-release.$extension');
      if (!await artifact.exists() || await artifact.length() == 0) {
        throw FileSystemException('构建缺少正式产物', artifact.path);
      }
      stdout.writeln('正式产物：${artifact.path}');
    }
  }
}

void _validate_type(String command, PatchEnvelope envelope) {
  if (command == 'withdraw' && envelope.patch_type != 2) {
    throw const FormatException('withdraw 只能登记 SDK 生成的回滚文件');
  }
  if (command == 'patch' && envelope.patch_type != 1) {
    throw const FormatException('回滚文件请使用 withdraw 命令登记');
  }
}

void _validate_target(
  PatchTarget target,
  int vc,
  List<String> platforms,
  String channel,
) {
  if (target.version_code != vc) {
    throw const FormatException('文件目标版本与 --vc/当前 build 不一致');
  }
  if (!platforms.contains(target.platform)) {
    throw const FormatException('文件平台与 --os 不一致');
  }
  if (target.channel != channel) {
    throw const FormatException('补丁channel与请求channel不一致，请选择对应baseline');
  }
}

/// TODO 每端指定独立 --out，再精确读取该目录，绝不扫描历史“最新目录”。
Future<void> _patch(
  String command,
  Map<String, String> options,
  bool production,
  List<String> platforms,
  int vc,
) async {
  final id = publication_id();
  ObsConfig? obs;
  final files = <File>[];
  if (options['file'] != null) {
    files.add(File(options['file']!));
  } else {
    obs = await _obs(production);
    final store = _baseline_store(options);
    for (final platform in platforms) {
      final out = Directory(
        '${app_dir.path}/.dart_tool/flutter_patcher/patches/$id-$platform',
      );
      await _run('bash', [
        'scripts/patcher_run.sh',
        'fvm',
        'dart',
        'run',
        'flutter_patcher',
        'patch',
        platform,
        '--version-code',
        '$vc',
        '--out',
        out.path,
        '--baseline-store',
        store,
        if (command == 'withdraw') '--withdraw',
      ], environment: _environment(obs));
      files.addAll(
        await collect_patch_outputs(out, platform: platform, version_code: vc),
      );
    }
  }
  // TODO 全部文件预检成功后才开始对象上传，避免第二端格式错误造成半发布。
  final prepared =
      <({File file, PatchTarget target, PatchEnvelope envelope})>[];
  for (final file in files) {
    final target = parse_patch_target(file.uri.pathSegments.last);
    final envelope = parse_patch_envelope(await file.readAsBytes());
    _validate_type(command, envelope);
    _validate_target(target, vc, platforms, options['channel'] ?? 'production');
    prepared.add((file: file, target: target, envelope: envelope));
  }
  obs ??= await _obs(production);
  final schema_conn = await _database(production);
  try {
    await _require_schema(schema_conn);
  } finally {
    await schema_conn.close();
  }
  final transport = _transport(obs);
  try {
    for (final item in prepared) {
      await _register(
        transport,
        obs,
        item.file,
        item.target,
        item.envelope,
        production,
        id,
        options['remark'] ?? '',
      );
    }
  } finally {
    transport.close();
  }
  stdout.writeln(
    '完成：${prepared.length} 个${command == 'withdraw' ? '回滚' : '补丁'}草稿；商店版本未改变。请在后台显式发布。',
  );
}

/// TODO 旧表存在不代表迁移完成；登记前核对发布水位、诊断幂等与成功安装去重结构。
Future<void> _require_schema(MySQLConnection conn) async {
  const required = {
    'app_patch': {'hotfix_version', 'ever_published'},
    'app_patch_boot_report': {
      'diagnostic_id',
      'patch_seq',
      'target_version_code',
      'fingerprint',
      'abi',
      'recorded_at',
      'identity_verified',
    },
    'app_patch_install': {'patch_id', 'device_id'},
  };
  final columns = await conn.execute(
    "SELECT table_name AS patch_table_name,column_name AS patch_column_name FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name IN ('app_patch','app_patch_boot_report','app_patch_install')",
  );
  final present = columns.rows
      .map(
        (row) =>
            '${row.colByName('patch_table_name')}.${row.colByName('patch_column_name')}',
      )
      .toSet();
  final missing = [
    for (final table in required.entries)
      for (final column in table.value)
        if (!present.contains('${table.key}.$column')) '${table.key}.$column',
  ];
  if (missing.isNotEmpty) {
    throw FormatException('补丁schema未就绪，请重跑 migrate：${missing.join(', ')}');
  }
  final index = await conn.execute(
    "SELECT column_name AS patch_column_name FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='app_patch_boot_report' AND index_name='uk_device_diagnostic' AND non_unique=0 ORDER BY seq_in_index",
  );
  if (index.rows.map((row) => row.colByName('patch_column_name')).join(',') !=
      'device_id,diagnostic_id') {
    throw const FormatException('诊断幂等唯一键未就绪，请重跑 migrate');
  }
}

/// TODO 宿主锁与后台完全同口径；先查重再上传，事务内分配独立热更版本。
Future<void> _register(
  ObsTransport transport,
  ObsConfig obs,
  File file,
  PatchTarget target,
  PatchEnvelope envelope,
  bool production,
  String id,
  String remark,
) async {
  // TODO 已登记文件先短连接确认，重复执行不重新上传；最终仍在发布锁下复查。
  final precheck = await _database(production);
  try {
    final existing = await precheck
        .execute(
          'SELECT id,sha256,fingerprint,remove_status FROM app_patch WHERE platform=:platform AND abi=:abi AND version_code=:vc AND seq=:seq AND COALESCE(NULLIF(flavor,""),"default")=:flavor AND COALESCE(NULLIF(channel,""),"production")=:channel LIMIT 1',
          {
            'platform': target.platform,
            'abi': target.abi,
            'vc': target.version_code,
            'seq': envelope.seq,
            'flavor': target.flavor,
            'channel': target.channel,
          },
        )
        .timeout(const Duration(seconds: 20));
    if (existing.rows.isNotEmpty) {
      final row = existing.rows.first;
      if (row.colByName('sha256') == envelope.sha256_hex &&
          row.colByName('fingerprint') == envelope.fingerprint &&
          row.colByName('remove_status') == '1') {
        stdout.writeln('已登记 id=${row.colByName('id')}，跳过上传（幂等）');
        return;
      }
      throw const FormatException('目标与seq已存在，拒绝覆盖或复活已删除记录');
    }
  } finally {
    await precheck.close();
  }
  final key = patch_object_key(target, envelope, id, local: !production);
  final base = Uri.parse(obs.base_url);
  if (base.scheme != 'https' ||
      base.host.isEmpty ||
      base.hasQuery ||
      base.hasFragment ||
      base.userInfo.isNotEmpty) {
    throw const FormatException('OBS 公开域名必须为 HTTPS');
  }
  final file_url = '${obs.base_url.replaceFirst(RegExp(r'/+$'), '')}/$key';
  if (file_url.length > 255) {
    throw const FormatException('对象 URL 超过数据库255字符限制');
  }
  await transport.put_immutable(key, file);
  if (await transport.object_sha256(key) != envelope.sha256_hex) {
    throw const FormatException('上传回读 SHA256 不匹配，未登记');
  }
  // TODO 文件传输结束后才建立短连接并持锁，避免公网连接在上传期间闲置失效。
  stdout.writeln('[进度] 文件校验完成，正在连接数据库登记补丁草稿');
  final conn = await _database(production);
  try {
    await _register_record(
      conn,
      file,
      target,
      envelope,
      file_url,
      remark,
    ).timeout(const Duration(seconds: 45));
  } finally {
    try {
      await conn.close().timeout(const Duration(seconds: 5));
    } catch (_) {
      // TODO 保留原始登记错误，主入口失败退出会回收残留连接。
    }
  }
}

/// TODO 数据库登记短事务；唯一约束、宿主锁和重复文件校验保持不变。
Future<void> _register_record(
  MySQLConnection conn,
  File file,
  PatchTarget target,
  PatchEnvelope envelope,
  String file_url,
  String remark,
) async {
  // TODO 先开启事务以固定数据库代理的后端会话，锁在事务结束前释放。
  final registered = await conn.transactional((_) async {
    final lock_name = target.lock_name(envelope.fingerprint);
    final locked = await conn.execute(
      'SELECT GET_LOCK(:name, 15) AS acquired',
      {'name': lock_name},
    );
    if (locked.rows.first.colByName('acquired') != '1') {
      throw const FormatException('无法获得宿主发布锁');
    }
    stdout.writeln('[进度] 已取得宿主发布锁，正在写入补丁草稿');
    final params = <String, dynamic>{
      'platform': target.platform,
      'abi': target.abi,
      'version_code': target.version_code,
      'flavor': target.flavor,
      'channel': target.channel,
      'fingerprint': envelope.fingerprint,
      'seq': envelope.seq,
    };
    const scope =
        "platform=:platform AND abi=:abi AND version_code=:version_code AND COALESCE(NULLIF(flavor,''),'default')=:flavor AND COALESCE(NULLIF(channel,''),'production')=:channel";
    try {
      final existing = await conn.execute(
        'SELECT id, seq, sha256, fingerprint, remove_status FROM app_patch WHERE $scope FOR UPDATE',
        params,
      );
      final matches = existing.rows.where(
        (row) => row.colByName('seq') == '${envelope.seq}',
      );
      if (matches.isNotEmpty) {
        final old = matches.first;
        if (old.colByName('sha256') == envelope.sha256_hex &&
            old.colByName('fingerprint') == envelope.fingerprint &&
            old.colByName('remove_status') == '1') {
          stdout.writeln('已登记 id=${old.colByName('id')}，跳过上传（幂等）');
          return null;
        }
        throw const FormatException('目标与 seq 已存在；拒绝上传覆盖或复活已删除记录');
      }
      final registered = await (() async {
        final transaction = conn;
        var hotfix_version = 0;
        if (envelope.patch_type == 1) {
          final max = await transaction.execute(
            'SELECT COALESCE(MAX(hotfix_version),0) AS max_version FROM app_patch WHERE $scope AND fingerprint=:fingerprint AND patch_type=1',
            params,
          );
          hotfix_version =
              int.parse(max.rows.first.colByName('max_version')!) + 1;
        }
        final inserted = await transaction.execute(
          'INSERT INTO app_patch (created_by,platform,abi,version_code,flavor,channel,fingerprint,seq,hotfix_version,patch_type,file_name,file_url,file_size,sha256,gray,status,remark,remove_status) VALUES (0,:platform,:abi,:version_code,:flavor,:channel,:fingerprint,:seq,:hotfix_version,:patch_type,:file_name,:file_url,:file_size,:sha256,0,1,:remark,1)',
          {
            ...params,
            'hotfix_version': hotfix_version,
            'patch_type': envelope.patch_type,
            'file_name': target.file_name,
            'file_url': file_url,
            'file_size': await file.length(),
            'sha256': envelope.sha256_hex,
            'remark': remark,
          },
        );
        return (id: inserted.lastInsertID, hotfix_version: hotfix_version);
      })();
      return registered;
    } finally {
      await conn
          .execute('SELECT RELEASE_LOCK(:name)', {'name': lock_name})
          .timeout(const Duration(seconds: 5));
    }
  });
  if (registered != null) {
    stdout.writeln('[进度] 数据库事务提交成功');
    stdout.writeln(
      '草稿 id=${registered.id} ${target.platform} 热更版本=${registered.hotfix_version}\n$file_url',
    );
  }
}
