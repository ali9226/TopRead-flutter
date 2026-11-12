import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_patcher/src/cli/progress.dart';
import 'package:xml/xml.dart';

typedef ObsProgressFactory =
    CliProgress Function(String label, {int? total_bytes, bool show_bytes});

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
    this.progress_factory,
    this.upload_idle_timeout = const Duration(seconds: 30),
    this.upload_total_timeout = const Duration(minutes: 30),
    HttpClient? client,
  }) : endpoint = validate_obs_endpoint(endpoint),
       _client = client ?? HttpClient() {
    if (!RegExp(r'^[a-z0-9][a-z0-9.-]*[a-z0-9]$').hasMatch(bucket)) {
      throw const FormatException('OBS bucket 无效');
    }
    if (access_key.isEmpty || secret_key.isEmpty) {
      throw const FormatException('OBS 凭据缺失');
    }
    if (upload_idle_timeout <= Duration.zero ||
        upload_total_timeout <= Duration.zero) {
      throw const FormatException('OBS 上传超时必须大于零');
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
  final ObsProgressFactory? progress_factory;
  final Duration upload_idle_timeout;
  final Duration upload_total_timeout;
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
    CliProgress? upload_progress,
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
        upload_progress?.set_note('传输文件');
        await _send_body(request, body, upload_progress);
        upload_progress?.set_note('文件已送出，等待服务器确认');
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

  /// TODO 按真实流消费刷新无进展计时；持续传输的大文件不再被三分钟总时限截断。
  Future<void> _send_body(
    HttpClientRequest request,
    File body,
    CliProgress? progress,
  ) async {
    final stalled = Completer<void>();
    Timer? watchdog;
    void reset_watchdog() {
      watchdog?.cancel();
      watchdog = Timer(upload_idle_timeout, () {
        final error = TimeoutException('OBS 上传长时间没有字节进展', upload_idle_timeout);
        if (!stalled.isCompleted) stalled.completeError(error);
        request.abort(error);
      });
    }

    reset_watchdog();
    final sending = () async {
      await request.addStream(
        body.openRead().map((chunk) {
          progress?.add_bytes(chunk.length);
          reset_watchdog();
          return chunk;
        }),
      );
      await request.flush();
    }();
    try {
      await Future.any<void>([
        sending,
        stalled.future,
      ]).timeout(upload_total_timeout);
    } catch (error) {
      request.abort(error);
      rethrow;
    } finally {
      watchdog?.cancel();
    }
  }

  CliProgress _progress(
    String label, {
    int? total_bytes,
    bool show_bytes = true,
  }) =>
      progress_factory?.call(
        label,
        total_bytes: total_bytes,
        show_bytes: show_bytes,
      ) ??
      CliProgress(label, total_bytes: total_bytes, show_bytes: show_bytes);

  /// TODO 每次重试有独立进度，失败不会伪装成完成或把百分比沿用到下一次请求。
  Future<T> _observe<T>(
    String label,
    Future<T> Function(CliProgress progress) operation, {
    int? total_bytes,
    bool show_bytes = true,
  }) async {
    final progress = _progress(
      label,
      total_bytes: total_bytes,
      show_bytes: show_bytes,
    );
    try {
      final result = await operation(progress);
      progress.complete();
      return result;
    } catch (error) {
      progress.fail(
        error is ObsFailure && error.status == 404 ? '对象不存在' : '失败',
      );
      rethrow;
    }
  }

  String _file_name(String key) => key.split('/').last;

  /// TODO 本地摘要也按实际读取字节展示，保持原有 MD5 和 SHA256 校验算法不变。
  Future<Digest> _file_digest(File file, Hash algorithm, String label) async =>
      _observe(
        '$label ${file.uri.pathSegments.last}',
        (progress) =>
            algorithm.bind(progress.track_stream(file.openRead())).first,
        total_bytes: await file.length(),
      );

  void _retry_notice(String label, int attempt, Object error) {
    final reason = error is TimeoutException
        ? '请求超时'
        : error is ObsFailure
        ? 'HTTP ${error.status}'
        : '网络连接中断';
    stderr.writeln('[进度] $label：$reason，准备第 ${attempt + 2}/3 次尝试');
  }

  bool _transient(Object error) =>
      error is SocketException ||
      error is HttpException ||
      error is TimeoutException ||
      (error is ObsFailure && (error.status == 429 || error.status >= 500));

  /// TODO 仅对幂等读取做有限重试；格式、签名、权限和不存在错误立即返回。
  Future<T> _retry<T>(
    Future<T> Function() operation, {
    String label = 'OBS 请求',
  }) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await operation();
      } catch (error) {
        if (attempt >= 2 || !_transient(error)) rethrow;
        _retry_notice(label, attempt, error);
        await Future<void>.delayed(
          Duration(milliseconds: 250 * (1 << attempt)),
        );
      }
    }
  }

  Stream<List<int>> _body(HttpClientResponse response) =>
      response.timeout(const Duration(seconds: 30));

  Future<void> head_bucket() => _retry(
    () => _observe(
      '检查 OBS 桶',
      (_) async => (await _request('HEAD', '')).drain<void>(),
      show_bytes: false,
    ),
    label: '检查 OBS 桶',
  );
  Future<void> head_object(String key) => _retry(
    () => _observe(
      '检查 OBS 对象 ${_file_name(key)}',
      (_) async => (await _request('HEAD', key)).drain<void>(),
      show_bytes: false,
    ),
    label: '检查 OBS 对象',
  );

  /// TODO 禁止覆盖在启用/暂停多版本时失效，必须先明确排除。
  Future<void> require_atomic_writes() => _retry(
    () => _observe('检查 OBS 原子写入条件', (_) async {
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
    }, show_bytes: false),
    label: '检查 OBS 原子写入条件',
  );

  /// TODO 写入只允许原子禁止覆盖；连接丢失后的412须验证完整对象SHA256才能确认前次成功。
  Future<void> put_immutable(String key, File file) async {
    await require_atomic_writes();
    final digest = await _file_digest(file, md5, '计算上传 MD5');
    final total_bytes = await file.length();
    var uncertain = false;
    for (var attempt = 0; ; attempt++) {
      final progress = _progress(
        'OBS 上传 ${_file_name(key)}（第 ${attempt + 1}/3 次）',
        total_bytes: total_bytes,
      );
      try {
        final response = await _request(
          'PUT',
          key,
          body: file,
          upload_progress: progress,
          headers: {
            'content-type': 'application/octet-stream',
            'content-md5': base64.encode(digest.bytes),
            'x-obs-forbid-overwrite': 'true',
          },
        );
        await response.drain<void>().timeout(const Duration(seconds: 30));
        progress.complete('服务器已确认上传');
        return;
      } catch (error) {
        if (error is ObsFailure && error.code == 'PreconditionFailed') {
          progress.complete('对象已存在，保留原对象并校验一致性');
          // TODO SDK 会回读并比较已有基线；原子拒绝覆盖不是网络上传失败。
          if (!uncertain) rethrow;
          final expected = (await _file_digest(
            file,
            sha256,
            '计算本地 SHA256',
          )).toString();
          if (await object_sha256(key) == expected) {
            stderr.writeln(
              '[进度] OBS 上传 ${_file_name(key)}：前次上传已通过完整 SHA256 校验',
            );
            return;
          }
          stderr.writeln('[进度] OBS 上传 ${_file_name(key)}：失败，已有对象 SHA256 不一致');
          rethrow;
        }
        progress.fail();
        if (attempt >= 2 || !_transient(error)) rethrow;
        _retry_notice('OBS 上传 ${_file_name(key)}', attempt, error);
        uncertain = true;
        await Future<void>.delayed(
          Duration(milliseconds: 250 * (1 << attempt)),
        );
      }
    }
  }

  /// TODO 完整流式SHA256验证包含响应读完阶段，断流重试不会信任部分字节。
  Future<String> object_sha256(String key) => _retry(
    () => _observe('OBS 回读 SHA256 ${_file_name(key)}', (progress) async {
      final response = await _request('GET', key);
      progress.set_total_bytes(
        response.contentLength < 0 ? null : response.contentLength,
      );
      return (await sha256.bind(progress.track_stream(_body(response))).first)
          .toString();
    }),
    label: 'OBS 回读 SHA256 ${_file_name(key)}',
  );

  /// TODO 每次重试写独立临时文件，只有完整下载后才提交到最终路径。
  Future<void> get_object(String key, File destination, {String? range}) async {
    if (await destination.exists()) throw const FormatException('下载目标已存在');
    await destination.parent.create(recursive: true);
    await _retry(
      () => _observe('OBS 下载 ${_file_name(key)}', (progress) async {
        final temporary = File(
          '${destination.path}.obs-part-$pid-${DateTime.now().microsecondsSinceEpoch}',
        );
        try {
          final response = await _request(
            'GET',
            key,
            headers: {'range': ?range},
          );
          progress.set_total_bytes(
            response.contentLength < 0 ? null : response.contentLength,
          );
          final sink = temporary.openWrite();
          try {
            await sink.addStream(progress.track_stream(_body(response)));
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
      }),
      label: 'OBS 下载 ${_file_name(key)}',
    );
  }

  /// TODO 分页读取逐页有限重试，避免失败页重试造成重复列表。
  Future<List<String>> list_keys(String prefix) async {
    final keys = <String>[];
    var marker = '';
    while (true) {
      final document = await _retry(
        () => _observe('读取 OBS 对象列表', (_) async {
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
        }, show_bytes: false),
        label: '读取 OBS 对象列表',
      );
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
