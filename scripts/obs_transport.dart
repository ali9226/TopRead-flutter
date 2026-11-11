import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:xml/xml.dart';

/// TODO 原生 OBS 错误保留服务端状态；不输出授权头或访问密钥。
class ObsFailure implements Exception {
  ObsFailure(this.code, this.status);
  final String code;
  final int status;
  @override
  String toString() => 'OBS $code (HTTP $status)';
}

/// TODO 原生 OBS 头域签名，参数编码与华为云 Header Authentication 规则一致。
String obs_authorization({
  required String method,
  required String bucket,
  required String key,
  required String access_key,
  required String secret_key,
  required Map<String, String> headers,
  String subresource = '',
}) {
  final names = headers.keys.where((name) => name.startsWith('x-obs-')).toList()
    ..sort();
  final canonical_headers = names
      .map((name) => '$name:${headers[name]!.trim()}\n')
      .join();
  final resource = '/$bucket/$key${subresource.isEmpty ? '' : '?$subresource'}';
  final text =
      '$method\n${headers['content-md5'] ?? ''}\n${headers['content-type'] ?? ''}\n${headers.containsKey('x-obs-date') ? '' : headers['date'] ?? ''}\n$canonical_headers$resource';
  final signature = base64.encode(
    Hmac(sha1, utf8.encode(secret_key)).convert(utf8.encode(text)).bytes,
  );
  return 'OBS $access_key:$signature';
}

/// TODO TLS 使用区域端点的有效证书，HTTP Host 使用桶虚拟域名。
/// TODO 这样带点号的历史桶也无需通配证书、HTTP 降级或关闭证书校验。
class ObsTransport {
  ObsTransport({
    required Uri endpoint,
    required this.bucket,
    required this.access_key,
    required this.secret_key,
    this.security_token = '',
    HttpClient? client,
  }) : endpoint = validate_obs_endpoint(endpoint),
       _client = client ?? HttpClient() {
    if (!RegExp(r'^[a-z0-9][a-z0-9.-]*[a-z0-9]$').hasMatch(bucket)) {
      throw const FormatException('OBS bucket 无效');
    }
    if (access_key.isEmpty || secret_key.isEmpty) {
      throw const FormatException('OBS 凭据缺失');
    }
    _client.connectionTimeout = const Duration(seconds: 20);
    _client.idleTimeout = const Duration(seconds: 30);
    // TODO 只影响当前发布进程，供已确认系统代理断流的环境显式直连。
    if (Platform.environment['HOT_PATCH_OBS_DIRECT'] == '1') {
      _client.findProxy = (_) => 'DIRECT';
    }
  }

  final Uri endpoint;
  final String bucket;
  final String access_key;
  final String secret_key;
  final String security_token;
  final HttpClient _client;

  void close() => _client.close(force: true);

  /// TODO 请求不自动跳转，避免授权头发送到配置之外的地址。
  Future<HttpClientResponse> _request(
    String method,
    String key, {
    Map<String, String> headers = const {},
    Map<String, String> query = const {},
    String subresource = '',
    File? body,
  }) async {
    if (key.split('/').contains('..') || key.startsWith('/')) {
      throw const FormatException('OBS key 无效');
    }
    final uri = endpoint.replace(
      pathSegments: key.split('/'),
      queryParameters: query.isEmpty ? null : query,
    );
    final signed_headers = <String, String>{
      'date': HttpDate.format(DateTime.now().toUtc()),
      if (security_token.isNotEmpty) 'x-obs-security-token': security_token,
      ...headers,
    };
    final request = await _client
        .openUrl(method, uri)
        .timeout(const Duration(seconds: 30));
    request.followRedirects = false;
    request.headers.set(HttpHeaders.hostHeader, '$bucket.${endpoint.host}');
    signed_headers.forEach(request.headers.set);
    request.headers.set(
      HttpHeaders.authorizationHeader,
      obs_authorization(
        method: method,
        bucket: bucket,
        key: key,
        access_key: access_key,
        secret_key: secret_key,
        headers: signed_headers,
        subresource: subresource,
      ),
    );
    late final HttpClientResponse response;
    try {
      if (body != null) {
        request.contentLength = await body.length();
        await request
            .addStream(body.openRead())
            .timeout(const Duration(minutes: 3));
      }
      response = await request.close().timeout(const Duration(seconds: 60));
    } catch (error) {
      request.abort(error);
      rethrow;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final xml = await utf8.decoder.bind(_body(response)).join();
      String code = 'HttpError';
      try {
        code = XmlDocument.parse(xml).findAllElements('Code').first.innerText;
      } catch (_) {
        /* TODO HEAD 无错误体。 */
      }
      if (response.statusCode == 404 && code == 'HttpError') code = '404';
      if (response.statusCode == 412 || code == 'ObjectAlreadyExists') {
        code = 'PreconditionFailed';
      }
      throw ObsFailure(code, response.statusCode);
    }
    return response;
  }

  bool _transient(Object error) =>
      error is SocketException ||
      error is HttpException ||
      error is TimeoutException ||
      (error is ObsFailure && (error.status == 429 || error.status >= 500));

  /// TODO 仅对幂等读取做有限重试；格式、签名、权限和不存在错误立即返回。
  Future<T> _retry<T>(Future<T> Function() operation) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await operation();
      } catch (error) {
        if (attempt >= 2 || !_transient(error)) rethrow;
        await Future<void>.delayed(
          Duration(milliseconds: 250 * (1 << attempt)),
        );
      }
    }
  }

  Stream<List<int>> _body(HttpClientResponse response) =>
      response.timeout(const Duration(seconds: 30));

  Future<void> head_bucket() =>
      _retry(() async => (await _request('HEAD', '')).drain<void>());
  Future<void> head_object(String key) =>
      _retry(() async => (await _request('HEAD', key)).drain<void>());

  /// TODO 禁止覆盖在启用/暂停多版本时失效，必须先明确排除。
  Future<void> require_atomic_writes() => _retry(() async {
    final response = await _request(
      'GET',
      '',
      query: {'versioning': ''},
      subresource: 'versioning',
    );
    final document = XmlDocument.parse(
      await utf8.decoder.bind(_body(response)).join(),
    );
    final states = document
        .findAllElements('Status')
        .map((element) => element.innerText.trim());
    if (states.any((state) => state.isNotEmpty)) {
      throw const FormatException('OBS 桶已启用或暂停多版本，禁止覆盖头不保证原子性；拒绝写入');
    }
  });

  /// TODO 写入只允许原子禁止覆盖；连接丢失后的412须验证完整对象SHA256才能确认前次成功。
  Future<void> put_immutable(String key, File file) async {
    await require_atomic_writes();
    final digest = await md5.bind(file.openRead()).first;
    var uncertain = false;
    for (var attempt = 0; ; attempt++) {
      try {
        final response = await _request(
          'PUT',
          key,
          body: file,
          headers: {
            'content-type': 'application/octet-stream',
            'content-md5': base64.encode(digest.bytes),
            'x-obs-forbid-overwrite': 'true',
          },
        );
        await response.drain<void>().timeout(const Duration(seconds: 30));
        return;
      } catch (error) {
        if (uncertain &&
            error is ObsFailure &&
            error.code == 'PreconditionFailed') {
          final expected = (await sha256.bind(file.openRead()).first)
              .toString();
          if (await object_sha256(key) == expected) return;
          rethrow;
        }
        if (attempt >= 2 || !_transient(error)) rethrow;
        uncertain = true;
        await Future<void>.delayed(
          Duration(milliseconds: 250 * (1 << attempt)),
        );
      }
    }
  }

  /// TODO 完整流式SHA256验证包含响应读完阶段，断流重试不会信任部分字节。
  Future<String> object_sha256(String key) => _retry(() async {
    final response = await _request('GET', key);
    return (await sha256.bind(_body(response)).first).toString();
  });

  /// TODO 每次重试写独立临时文件，只有完整下载后才提交到最终路径。
  Future<void> get_object(String key, File destination, {String? range}) async {
    if (await destination.exists()) throw const FormatException('下载目标已存在');
    await destination.parent.create(recursive: true);
    await _retry(() async {
      final temporary = File(
        '${destination.path}.obs-part-$pid-${DateTime.now().microsecondsSinceEpoch}',
      );
      try {
        final response = await _request('GET', key, headers: {'range': ?range});
        final sink = temporary.openWrite();
        try {
          await sink.addStream(_body(response));
        } finally {
          await sink.close();
        }
        if (await destination.exists()) {
          throw const FormatException('下载目标已存在，拒绝覆盖');
        }
        await temporary.rename(destination.path);
      } finally {
        if (await temporary.exists()) await temporary.delete();
      }
    });
  }

  /// TODO 分页读取逐页有限重试，避免失败页重试造成重复列表。
  Future<List<String>> list_keys(String prefix) async {
    final keys = <String>[];
    var marker = '';
    while (true) {
      final document = await _retry(() async {
        final response = await _request(
          'GET',
          '',
          query: {
            'prefix': prefix,
            'max-keys': '1000',
            if (marker.isNotEmpty) 'marker': marker,
          },
        );
        return XmlDocument.parse(
          await utf8.decoder.bind(_body(response)).join(),
        );
      });
      final page = document
          .findAllElements('Contents')
          .map((entry) => entry.findElements('Key').single.innerText)
          .toList();
      keys.addAll(page);
      if (!document
          .findAllElements('IsTruncated')
          .any((entry) => entry.innerText == 'true')) {
        break;
      }
      if (page.isEmpty) throw const FormatException('OBS 分页缺少 marker');
      marker = page.last;
    }
    return keys;
  }
}

/// TODO 仅支持华为官方区域 HTTPS 端点，凭据不向任意配置 URL 发送。
Uri validate_obs_endpoint(Uri endpoint) {
  if (endpoint.scheme != 'https' ||
      !RegExp(
        r'^obs\.[a-z0-9-]+\.myhuaweicloud\.(com|eu)$',
      ).hasMatch(endpoint.host) ||
      endpoint.userInfo.isNotEmpty ||
      endpoint.hasQuery ||
      endpoint.hasFragment ||
      (endpoint.path.isNotEmpty && endpoint.path != '/') ||
      (endpoint.hasPort && endpoint.port != 443)) {
    throw const FormatException('仅支持华为 OBS 官方区域 HTTPS 端点');
  }
  return endpoint;
}
