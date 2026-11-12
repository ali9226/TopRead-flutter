import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_patcher/src/cli/progress.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scripts/obs_transport.dart';
import 'obs_transport_retry_test.dart' show LocalObsHttpClient;

// TODO 哈希读取保持正常，上传读取按小块延迟，验证真实请求的无进展超时。
class ThrottledSourceFile implements File {
  ThrottledSourceFile(this.file, this.chunk_delay);
  final File file;
  final Duration chunk_delay;
  int reads = 0;

  @override
  Uri get uri => file.uri;
  @override
  Future<int> length() => file.length();
  @override
  Stream<List<int>> openRead([int? start, int? end]) {
    if (reads++ == 0) return file.openRead(start, end);
    return () async* {
      final content = await file.readAsBytes();
      for (var offset = 0; offset < content.length; offset += 1024) {
        if (offset > 0) await Future<void>.delayed(chunk_delay);
        yield content.sublist(offset, offset + 1024);
      }
    }();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('首次PUT遇到已有对象时保留原子冲突，但进度不误报网络上传失败', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final directory = await Directory.systemTemp.createTemp('obs_existing_');
    final source = await File('${directory.path}/source').writeAsString('new');
    var puts = 0;
    server.listen((request) async {
      if (request.uri.queryParameters.containsKey('versioning')) {
        request.response.write('<VersioningConfiguration/>');
      } else {
        puts++;
        await request.drain<void>();
        request.response.statusCode = 412;
        request.response.write(
          '<Error><Code>PreconditionFailed</Code></Error>',
        );
      }
      await request.response.close();
    });
    final output = <String>[];
    final transport = ObsTransport(
      endpoint: Uri.parse('https://obs.af-south-1.myhuaweicloud.com'),
      bucket: 'test.bucket',
      access_key: 'fixture',
      secret_key: 'fixture',
      client: LocalObsHttpClient(server.port),
      progress_factory: (label, {total_bytes, show_bytes = true}) =>
          CliProgress(
            label,
            total_bytes: total_bytes,
            show_bytes: show_bytes,
            write: output.add,
            automatic_heartbeat: false,
          ),
    );
    addTearDown(() async {
      transport.close();
      await server.close(force: true);
      await directory.delete(recursive: true);
    });
    await expectLater(
      transport.put_immutable('verification/object', source),
      throwsA(
        isA<ObsFailure>().having((e) => e.code, 'code', 'PreconditionFailed'),
      ),
    );
    expect(puts, 1);
    expect(output.join(), contains('对象已存在'));
    expect(output.join(), isNot(contains('失败')));
    expect(output.join(), isNot(contains('服务器已确认上传')));
  });
  test('本机实际上传、下载、回读摘要的进度与处理字节一致，授权内容不进入日志', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final directory = await Directory.systemTemp.createTemp('obs_progress_');
    final content = List<int>.generate(96 * 1024, (index) => index % 251);
    final source = await File('${directory.path}/source').writeAsBytes(content);
    final destination = File('${directory.path}/download');
    List<int>? stored;
    server.listen((request) async {
      if (request.uri.queryParameters.containsKey('versioning')) {
        request.response.write('<VersioningConfiguration/>');
      } else if (request.method == 'PUT') {
        expect(request.headers.value('x-obs-forbid-overwrite'), 'true');
        expect(request.headers.value('content-md5'), isNotEmpty);
        stored = await request.fold<List<int>>(
          [],
          (all, chunk) => all..addAll(chunk),
        );
      } else {
        request.response.contentLength = stored!.length;
        request.response.add(stored!);
      }
      await request.response.close();
    });
    final output = <String>[];
    final progresses = <CliProgress>[];
    final transport = ObsTransport(
      endpoint: Uri.parse('https://obs.af-south-1.myhuaweicloud.com'),
      bucket: 'test.bucket',
      access_key: 'fixture-access-never-log',
      secret_key: 'fixture-secret-never-log',
      client: LocalObsHttpClient(server.port),
      progress_factory: (label, {total_bytes, show_bytes = true}) {
        final progress = CliProgress(
          label,
          total_bytes: total_bytes,
          show_bytes: show_bytes,
          terminal: false,
          write: output.add,
          automatic_heartbeat: false,
        );
        progresses.add(progress);
        return progress;
      },
    );
    addTearDown(() async {
      transport.close();
      await server.close(force: true);
      await directory.delete(recursive: true);
    });
    await transport.put_immutable('verification/object', source);
    expect(
      await transport.object_sha256('verification/object'),
      sha256.convert(content).toString(),
    );
    await transport.get_object('verification/object', destination);
    expect(await destination.readAsBytes(), content);
    final transfers = progresses
        .where((progress) => progress.show_bytes)
        .toList();
    expect(transfers.length, 4);
    for (final progress in transfers) {
      expect(progress.processed_bytes, content.length);
      expect(progress.total_bytes, content.length);
      expect(progress.is_closed, isTrue);
    }
    expect(output.join(), contains('OBS 上传 object'));
    expect(output.join(), contains('OBS 下载 object'));
    expect(output.join(), contains('OBS 回读 SHA256 object'));
    expect(output.join(), contains('100.0%'));
    expect(output.join(), isNot(contains('fixture-access-never-log')));
    expect(output.join(), isNot(contains('fixture-secret-never-log')));
  });

  test('持续收到新字节的慢上传可完成，停止产出字节时及时超时并有限重试', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final directory = await Directory.systemTemp.createTemp(
      'obs_idle_timeout_',
    );
    final source = await File(
      '${directory.path}/source',
    ).writeAsBytes(List<int>.filled(8 * 1024, 17));
    var successful_puts = 0;
    server.listen((request) async {
      try {
        if (request.uri.queryParameters.containsKey('versioning')) {
          request.response.write('<VersioningConfiguration/>');
        } else {
          await request.drain<void>();
          successful_puts++;
        }
        await request.response.close();
      } catch (_) {
        // TODO 超时用例主动中止请求，服务器读到断流属于预期结果。
      }
    });
    final output = <String>[];
    final transport = ObsTransport(
      endpoint: Uri.parse('https://obs.af-south-1.myhuaweicloud.com'),
      bucket: 'test.bucket',
      access_key: 'fixture-access',
      secret_key: 'fixture-secret',
      client: LocalObsHttpClient(server.port),
      upload_idle_timeout: const Duration(milliseconds: 80),
      upload_total_timeout: const Duration(seconds: 2),
      progress_factory: (label, {total_bytes, show_bytes = true}) =>
          CliProgress(
            label,
            total_bytes: total_bytes,
            show_bytes: show_bytes,
            write: output.add,
            terminal: false,
            automatic_heartbeat: false,
          ),
    );
    addTearDown(() async {
      transport.close();
      await server.close(force: true);
      await directory.delete(recursive: true);
    });
    await transport.put_immutable(
      'verification/slow',
      ThrottledSourceFile(source, const Duration(milliseconds: 25)),
    );
    expect(successful_puts, 1);
    await expectLater(
      transport.put_immutable(
        'verification/stalled',
        ThrottledSourceFile(source, const Duration(milliseconds: 150)),
      ),
      throwsA(isA<TimeoutException>()),
    );
    expect(successful_puts, 1);
    expect(output.join(), contains('第 3/3 次'));
  });
}
