import 'dart:io';
import 'package:mysql_client/mysql_client.dart';

/// TODO 数据库连接配置（生产/本地）。
class DbConfig {
  DbConfig({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.name,
    required this.label,
  });
  final String host;
  final int port;
  final String user;
  final String password;
  final String name;
  final String label;
}

/// TODO OBS 对象存储配置（目标库 image_config 表，与 file/add 上传同一来源）。
class ObsConfig {
  ObsConfig({
    required this.access_key_id,
    required this.secret_access_key,
    required this.server,
    required this.bucket,
    required this.base_url,
  });
  final String access_key_id;
  final String secret_access_key;
  final String server;
  final String bucket;
  final String base_url;
}

/// TODO 从正则中取第一个捕获组；取不到返回空串。
String regex_first(String source, String pattern) {
  return RegExp(pattern).firstMatch(source)?.group(1) ?? '';
}

/// TODO 独立发布配置可指定隧道端口；缺省仍使用 MySQL 3306，非法值在连接前拒绝。
int _db_port(String source, {bool declaration = false}) {
  var raw = regex_first(
    source,
    declaration
        ? r'\blet\s+database_port\s*=\s*([^;\n]+)'
        : r'\bdatabase_port\s*=\s*([^;\n]+)',
  ).trim();
  if (raw.isEmpty) return 3306;
  if (raw.length >= 2 &&
      ['`', "'", '"'].contains(raw[0]) &&
      raw[raw.length - 1] == raw[0]) {
    raw = raw.substring(1, raw.length - 1);
  }
  final port = int.tryParse(raw);
  if (port == null || port < 1 || port > 65535) {
    throw const FormatException('database_port 必须为 1-65535 的整数');
  }
  return port;
}

/// TODO 从后端配置文件解析数据库配置（避免凭据在脚本里写死）。
({DbConfig prod, DbConfig local}) load_backend_config(Directory backend_dir) {
  final File env_file = File('${backend_dir.path}/config/data_environment.js');
  if (!env_file.existsSync()) {
    throw FormatException('找不到后端配置：${env_file.path}');
  }
  final String env_source = env_file.readAsStringSync();

  // TODO 生产库：data_environment.js 顶部的 let 赋值（config.dev 会改写的是本地值）
  final DbConfig prod = DbConfig(
    host: regex_first(env_source, r'let database_address = `([^`]+)`'),
    port: _db_port(env_source, declaration: true),
    user: regex_first(env_source, r'let account = `([^`]+)`'),
    password: regex_first(env_source, r'let password = `([^`]+)`'),
    name: regex_first(env_source, r'let database_name = `([^`]+)`'),
    label: '生产',
  );

  // TODO 本地库：if (config.dev) 块里的赋值
  final String dev_block =
      RegExp(
        r'if \(config\.dev\) \{([\s\S]*?)\}',
      ).firstMatch(env_source)?.group(1) ??
      '';
  DbConfig local = DbConfig(
    host: regex_first(dev_block, r"database_address = `([^`]+)`"),
    port: _db_port(dev_block),
    user: regex_first(dev_block, r"account = `([^`]+)`"),
    password: regex_first(dev_block, r"password = `([^`]+)`"),
    name: regex_first(dev_block, r"database_name = `([^`]+)`"),
    label: '本地',
  );
  // TODO 0.0.0.0 不是可连接地址，映射回 127.0.0.1（与后端迁移脚本同口径）
  if (local.host == '0.0.0.0' || local.host.isEmpty) {
    local = DbConfig(
      host: '127.0.0.1',
      port: local.port,
      user: local.user,
      password: local.password,
      name: local.name,
      label: local.label,
    );
  }

  if (prod.host.isEmpty) {
    throw FormatException('后端配置解析失败（数据库字段缺失）');
  }
  return (prod: prod, local: local);
}

/// TODO 从目标库 image_config 表读取 OBS 上传配置（与 file/add 上传同一来源）。
///
/// [conn] 已连接的 MySQL 连接；[label] 报错提示用（生产/本地）。
Future<ObsConfig> load_obs_config(MySQLConnection conn, String label) async {
  final IResultSet rows = await conn.execute(
    'SELECT region, access_key_id, access_key_secret, bucket, domain_name '
    'FROM image_config ORDER BY id LIMIT 1',
  );
  if (rows.rows.isEmpty) {
    throw FormatException('$label库 image_config 表无配置行（后台「图片配置」维护）');
  }
  final row = rows.rows.first;
  final ObsConfig obs = ObsConfig(
    access_key_id: row.colByName('access_key_id') ?? '',
    secret_access_key: row.colByName('access_key_secret') ?? '',
    server: row.colByName('region') ?? '',
    bucket: row.colByName('bucket') ?? '',
    base_url: row.colByName('domain_name') ?? '',
  );
  if (obs.server.isEmpty ||
      obs.bucket.isEmpty ||
      obs.access_key_id.isEmpty ||
      obs.secret_access_key.isEmpty) {
    throw FormatException(
      '$label库 image_config 配置不完整（region/bucket/access_key_id 必填）',
    );
  }
  return obs;
}

/// TODO 连接 MySQL（mysql_client，支持 MySQL 8/9 的 caching_sha2_password）。
Future<MySQLConnection> connect_db(DbConfig config) async {
  require_loopback_db(config);
  // TODO 仅连接本机数据库或 SSH 隧道；驱动无法校验远端证书，不能用它公网直连。
  // TODO 本机隧道由 SSH 保护，允许在隧道内兼容未开启 MySQL TLS 的服务器。
  for (final bool secure in [true, false]) {
    try {
      final MySQLConnection conn = await MySQLConnection.createConnection(
        host: config.host.toLowerCase() == 'localhost'
            ? '127.0.0.1'
            : config.host,
        port: config.port,
        userName: config.user,
        password: config.password,
        databaseName: config.name,
        secure: secure,
      );
      await conn.connect();
      return conn;
    } catch (e) {
      if (secure) continue;
      throw FormatException(
        '数据库连接失败（${config.label} ${config.host}/${config.name}）：$e',
      );
    }
  }
  throw FormatException('数据库连接失败（${config.label}）');
}

/// TODO mysql_client 0.0.27 内部接受坏证书；发布连接须通过本机 SSH 隧道认证远端。
void require_loopback_db(DbConfig config) {
  if (!{'127.0.0.1', 'localhost', '::1'}.contains(config.host.toLowerCase())) {
    throw FormatException(
      config.label == '本地'
          ? '--local只允许loopback数据库，请提供独立本地HOT_PATCH_BACKEND_DIR配置；未连接数据库'
          : '生产数据库请通过SSH隧道映射至127.0.0.1，并在独立HOT_PATCH_BACKEND_DIR配置中指定database_port；未连接数据库',
    );
  }
}
