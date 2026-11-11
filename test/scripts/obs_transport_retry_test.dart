import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scripts/obs_transport.dart';

class LocalObsHttpClient implements HttpClient {
  LocalObsHttpClient(this.port);
  final int port;
  final HttpClient delegate = HttpClient();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) => delegate.openUrl(
    method,
    url.replace(scheme: 'http', host: '127.0.0.1', port: port),
  );
  @override
  set connectionTimeout(Duration? value) {
    delegate.connectionTimeout = value;
  }

  @override
  set idleTimeout(Duration value) {
    delegate.idleTimeout = value;
  }

  @override
  void close({bool force = false}) => delegate.close(force: force);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('PUT已写入但响应丢失，412后完整哈希一致才确认成功；读取断流自动重试', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final dir = await Directory.systemTemp.createTemp('obs_retry_fixture_');
    final content = utf8.encode('signed-object-complete-content');
    final source = await File('${dir.path}/source').writeAsBytes(content);
    List<int>? stored;
    var puts = 0;
    var gets = 0;
    server.listen((request) async {
      if (request.uri.queryParameters.containsKey('versioning')) {
        request.response.write('<VersioningConfiguration/>');
        await request.response.close();
        return;
      }
      if (request.method == 'PUT') {
        puts++;
        expect(request.headers.value('x-obs-forbid-overwrite'), 'true');
        final received = await request.fold<List<int>>(
          [],
          (bytes, chunk) => bytes..addAll(chunk),
        );
        if (stored != null) {
          request.response.statusCode = 409;
          request.response.write(
            '<Error><Code>ObjectAlreadyExists</Code></Error>',
          );
          await request.response.close();
          return;
        }
        stored = received;
        final socket = await request.response.detachSocket(writeHeaders: false);
        socket.destroy();
        return;
      }
      gets++;
      request.response.contentLength = stored!.length;
      if (gets == 1) {
        final socket = await request.response.detachSocket(writeHeaders: false);
        socket.write(
          'HTTP/1.1 200 OK\r\nContent-Length: ${stored!.length}\r\nConnection: close\r\n\r\n',
        );
        socket.add(stored!.sublist(0, 3));
        await socket.flush();
        socket.destroy();
        return;
      }
      request.response.add(stored!);
      await request.response.close();
    });
    final transport = ObsTransport(
      endpoint: Uri.parse('https://obs.af-south-1.myhuaweicloud.com'),
      bucket: 'test.bucket',
      access_key: 'fixture-ak',
      secret_key: 'fixture-sk',
      client: LocalObsHttpClient(server.port),
    );
    addTearDown(() async {
      transport.close();
      await server.close(force: true);
      await dir.delete(recursive: true);
    });
    await transport.put_immutable('verification/object', source);
    expect(puts, 2);
    expect(gets, 2);
    expect(stored, content);
    expect(
      await transport.object_sha256('verification/object'),
      sha256.convert(content).toString(),
    );
  });

  test('PUT结果不明后冲突对象哈希不同，拒绝接受且不覆盖；GET最多三次', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final dir = await Directory.systemTemp.createTemp('obs_conflict_fixture_');
    final source = await File('${dir.path}/source').writeAsString('expected');
    var puts = 0;
    var bad_gets = 0;
    server.listen((request) async {
      if (request.uri.queryParameters.containsKey('versioning')) {
        request.response.write('<VersioningConfiguration/>');
        await request.response.close();
        return;
      }
      if (request.method == 'PUT') {
        puts++;
        await request.drain<void>();
        if (puts == 1) {
          final socket = await request.response.detachSocket(
            writeHeaders: false,
          );
          socket.destroy();
          return;
        }
        request.response.statusCode = 409;
        request.response.write(
          '<Error><Code>ObjectAlreadyExists</Code></Error>',
        );
      } else if (request.uri.path == '/unavailable') {
        bad_gets++;
        request.response.statusCode = 503;
        request.response.write(
          '<Error><Code>ServiceUnavailable</Code></Error>',
        );
      } else {
        request.response.write('different-content');
      }
      await request.response.close();
    });
    final transport = ObsTransport(
      endpoint: Uri.parse('https://obs.af-south-1.myhuaweicloud.com'),
      bucket: 'test.bucket',
      access_key: 'fixture-ak',
      secret_key: 'fixture-sk',
      client: LocalObsHttpClient(server.port),
    );
    addTearDown(() async {
      transport.close();
      await server.close(force: true);
      await dir.delete(recursive: true);
    });
    await expectLater(
      transport.put_immutable('verification/object', source),
      throwsA(
        isA<ObsFailure>().having(
          (error) => error.code,
          'code',
          'PreconditionFailed',
        ),
      ),
    );
    expect(puts, 2);
    await expectLater(
      transport.object_sha256('unavailable'),
      throwsA(isA<ObsFailure>()),
    );
    expect(bad_gets, 3);
  });
}
