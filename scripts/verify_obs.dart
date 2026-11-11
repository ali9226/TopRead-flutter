import 'dart:io';

import 'package:crypto/crypto.dart';

import 'hot_patch_config.dart';
import 'hot_patch_support.dart';
import 'obs_transport.dart';

/// TODO 本地配置下的隔离存储验证：保留远端测试对象，不操作任何生产登记或基线。
Future<void> main() async {
  final app_dir = File(Platform.script.toFilePath()).parent.parent;
  final config = load_backend_config(Directory('${app_dir.parent.path}/后端'));
  final conn = await connect_db(config.local);
  final obs = await load_obs_config(conn, '本地');
  await conn.close();
  final transport = ObsTransport(
    endpoint: Uri.parse(
      obs.server.contains('://') ? obs.server : 'https://${obs.server}',
    ),
    bucket: obs.bucket,
    access_key: obs.access_key_id,
    secret_key: obs.secret_access_key,
  );
  final temp = await Directory.systemTemp.createTemp('topread_obs_verify_');
  final key = 'flutter_patcher/verification/${publication_id()}/atomic.txt';
  try {
    await transport.head_bucket();
    await transport.require_atomic_writes();
    final files = [
      File('${temp.path}/first.txt'),
      File('${temp.path}/second.txt'),
    ];
    await files[0].writeAsString('TopRead immutable verification A\n');
    await files[1].writeAsString('TopRead immutable verification B\n');
    final results = await Future.wait(
      files.map((file) async {
        try {
          await transport.put_immutable(key, file);
          return true;
        } on ObsFailure catch (error) {
          if (error.code == 'PreconditionFailed') return false;
          rethrow;
        }
      }),
    );
    if (results.where((success) => success).length != 1) {
      throw StateError('原子禁覆盖验证失败：$results');
    }
    final winner = files[results.indexOf(true)];
    final expected = (await sha256.bind(winner.openRead()).first).toString();
    if (await transport.object_sha256(key) != expected) {
      throw StateError('回读哈希与成功上传的对象不同');
    }
    // TODO 验证实际被flutter_patcher调用的aws桥接，不仅验证传输类。
    final environment = <String, String>{
      'AWS_ACCESS_KEY_ID': obs.access_key_id,
      'AWS_SECRET_ACCESS_KEY': obs.secret_access_key,
      'AWS_SESSION_TOKEN': '',
    };
    final prefix = [
      '${app_dir.path}/scripts/shims/aws',
      '--endpoint-url',
      transport.endpoint.toString(),
      's3api',
    ];
    final duplicate = await Process.run(
      'bash',
      [
        ...prefix,
        'put-object',
        '--bucket',
        obs.bucket,
        '--key',
        key,
        '--body',
        winner.path,
        '--if-none-match',
        '*',
      ],
      environment: environment,
      workingDirectory: app_dir.path,
    );
    if (duplicate.exitCode != 254 ||
        !(duplicate.stderr as String).contains('(PreconditionFailed)')) {
      throw StateError('AWS桥接未正确保留PreconditionFailed语义：${duplicate.stderr}');
    }
    final downloaded = File('${temp.path}/bridge-download.txt');
    final get = await Process.run(
      'bash',
      [
        ...prefix,
        'get-object',
        '--bucket',
        obs.bucket,
        '--key',
        key,
        '--range',
        'bytes=0-10000',
        downloaded.path,
      ],
      environment: environment,
      workingDirectory: app_dir.path,
    );
    if (get.exitCode != 0 ||
        (await sha256.bind(downloaded.openRead()).first).toString() != expected) {
      throw StateError('AWS桥接下载/回读失败：${get.stderr}');
    }
    stdout.writeln('HTTPS证书校验通过；并发上传恰有一个成功；重复写被拒绝；回读SHA256一致。');
    stdout.writeln('AWS桥接条件写失败码与Range下载验证通过。');
    stdout.writeln('保留验证对象：s3://${obs.bucket}/$key');
  } finally {
    transport.close();
    await temp.delete(recursive: true);
  }
}
