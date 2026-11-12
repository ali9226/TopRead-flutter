import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/hot_patch_config.dart';

DbConfig fixture_config(String host, String label) => DbConfig(
  host: host,
  port: 3306,
  user: 'fixture',
  password: 'fixture',
  name: 'fixture',
  label: label,
);

void main() {
  test('生产端口与本地端口分别读取，缺省保持3306', () async {
    final root = await Directory.systemTemp.createTemp('patch_db_port_');
    addTearDown(() => root.delete(recursive: true));
    final config = File('${root.path}/config/data_environment.js');
    await config.parent.create();
    const source = '''
let database_address = `127.0.0.1`;
let account = `fixture`;
let password = `fixture`;
let database_name = `fixture`;
if (config.dev) {
database_address = `127.0.0.1`;
account = `local`;
password = `fixture`;
database_name = `local`;
database_port = 23306;
}
''';
    await config.writeAsString(source);
    expect(load_backend_config(root).prod.port, 3306);
    expect(load_backend_config(root).local.port, 23306);
    await config.writeAsString('let database_port = 13306;\n$source');
    expect(load_backend_config(root).prod.port, 13306);
    expect(load_backend_config(root).local.port, 23306);
    for (final port in ['0', '65536', '`invalid`']) {
      await config.writeAsString('let database_port = $port;\n$source');
      expect(() => load_backend_config(root), throwsFormatException);
    }
  });
  test('默认及本地模式拒绝LAN、外网和伪localhost，配置标签不能绕过限制', () {
    for (final host in [
      '192.168.31.66',
      'production.example.invalid',
      'localhost.example.invalid',
      '0.0.0.0',
    ]) {
      for (final label in ['本地', '生产']) {
        final config = fixture_config(host, label);
        expect(() => require_db_connection(config), throwsFormatException);
        expect(
          () => require_db_connection(config, production: false),
          throwsFormatException,
        );
      }
    }
    for (final host in ['127.0.0.1', 'localhost', '::1']) {
      expect(
        () => require_loopback_db(fixture_config(host, '本地')),
        returnsNormally,
      );
      expect(
        () => require_db_connection(fixture_config(host, '本地')),
        returnsNormally,
      );
    }
    expect(
      () => require_loopback_db(
        fixture_config('production.example.invalid', '生产'),
      ),
      throwsFormatException,
    );
    expect(
      () => require_loopback_db(fixture_config('127.0.0.1', '生产')),
      returnsNormally,
    );
  });
  test('显式生产模式允许配置中的生产数据库地址，检查过程不连接网络', () {
    for (final host in [
      '192.168.31.66',
      'production.example.invalid',
      '203.0.113.10',
    ]) {
      expect(
        () =>
            require_db_connection(fixture_config(host, '生产'), production: true),
        returnsNormally,
      );
    }
  });
}
