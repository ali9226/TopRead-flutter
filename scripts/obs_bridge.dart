import 'dart:convert';
import 'dart:io';

import 'obs_transport.dart';

/// TODO flutter_patcher 所需 S3 CLI 子集映射到原生 OBS HTTPS API。
Future<void> main(List<String> args) async {
  ObsTransport? transport;
  try {
    final values = <String, String>{};
    final positional = <String>[];
    for (var index = 0; index < args.length; index++) {
      if (args[index].startsWith('--')) {
        final key = args[index].substring(2);
        if (index + 1 >= args.length) throw FormatException('缺少 --$key 参数');
        values[key] = args[++index];
      } else {
        positional.add(args[index]);
      }
    }
    if (positional.length < 2 || positional.first != 's3api') {
      throw const FormatException('OBS 桥接仅支持 s3api');
    }
    var access_key = Platform.environment['AWS_ACCESS_KEY_ID'] ?? '';
    var secret_key = Platform.environment['AWS_SECRET_ACCESS_KEY'] ?? '';
    var token = Platform.environment['AWS_SESSION_TOKEN'] ?? '';
    if (access_key.isEmpty || secret_key.isEmpty) {
      final real_aws = Platform.environment['FLUTTER_PATCHER_REAL_AWS'];
      if (real_aws == null || real_aws.isEmpty) {
        throw const FormatException('未提供 OBS 凭据');
      }
      final exported = await Process.run(real_aws, [
        'configure',
        'export-credentials',
        '--format',
        'process',
      ]);
      if (exported.exitCode != 0) throw const FormatException('无法读取 AWS 标准凭据链');
      final credentials =
          jsonDecode(exported.stdout as String) as Map<String, dynamic>;
      access_key = credentials['AccessKeyId'] as String;
      secret_key = credentials['SecretAccessKey'] as String;
      token = credentials['SessionToken'] as String? ?? '';
    }
    transport = ObsTransport(
      endpoint: Uri.parse(values['endpoint-url'] ?? ''),
      bucket: values['bucket'] ?? '',
      access_key: access_key,
      secret_key: secret_key,
      security_token: token,
    );
    switch (positional[1]) {
      case 'head-bucket':
        await transport.head_bucket();
        break;
      case 'head-object':
        await transport.head_object(values['key'] ?? '');
        break;
      case 'get-object':
        if (positional.length != 3) {
          throw const FormatException('get-object 缺少本地目标文件');
        }
        await transport.get_object(
          values['key'] ?? '',
          File(positional[2]),
          range: values['range'],
        );
        break;
      case 'put-object':
        if (values['if-none-match'] != '*') {
          throw const FormatException('OBS 桥接只允许原子不可覆盖写入');
        }
        await transport.put_immutable(
          values['key'] ?? '',
          File(values['body'] ?? ''),
        );
        break;
      case 'get-bucket-versioning':
        await transport.require_atomic_writes();
        break;
      case 'list-objects-v2':
        final keys = await transport.list_keys(values['prefix'] ?? '');
        stdout.writeln(
          jsonEncode({
            'Contents': keys.map((key) => {'Key': key}).toList(),
          }),
        );
        return;
      default:
        throw FormatException('不支持的 OBS 操作：${positional[1]}');
    }
    stdout.writeln('{}');
  } on ObsFailure catch (error) {
    stderr.writeln(
      'An error occurred (${error.code}) when calling OBS: HTTP ${error.status}',
    );
    exitCode = 254;
  } catch (error) {
    stderr.writeln('OBS 桥接失败：$error');
    exitCode = 1;
  } finally {
    transport?.close();
  }
}
