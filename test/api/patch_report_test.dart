import 'dart:io';

import 'package:app/api/dio_client.dart';
import 'package:app/api/patch.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage_directory;
  late Interceptor interceptor;
  Map<String, dynamic>? captured;
  bool business_success = true;
  int http_status = 200;

  setUpAll(() async {
    // TODO 使用隔离缓存和请求拦截，测试不访问真实网络或设备凭证。
    storage_directory = Directory.systemTemp.createTempSync('patch_report_');
    File('${storage_directory.path}/GetStorage.gs').writeAsStringSync('{}');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storage_directory.path,
    );
    await GetStorage('GetStorage', storage_directory.path).initStorage;
  });

  setUp(() {
    captured = null;
    business_success = true;
    http_status = 200;
    interceptor = InterceptorsWrapper(
      onRequest: (options, handler) {
        expect(options.path, '/api/app_patch/report');
        final envelope = options.data as Map;
        captured = Map<String, dynamic>.from(
          JWT.decode((envelope['encryption'] as String).split(' ').last).payload
              as Map,
        );
        final response = JWT(<String, dynamic>{
          'status': business_success,
          'message': '',
          'content': <String, dynamic>{},
        }).sign(SecretKey('isolated_test_response'));
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: http_status,
            data: <String, dynamic>{'encryption': response},
          ),
        );
      },
    );
    DioClient().instance.interceptors.add(interceptor);
  });

  tearDown(() => DioClient().instance.interceptors.remove(interceptor));
  tearDownAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await storage_directory.delete(recursive: true);
  });

  Future<bool> report() => report_app_patch(
    patch_id: 7,
    device_id: 'device-1',
    is_healthy: false,
    boot_status: 'droppedCircuitBreaker',
    diagnostic_id: 'diagnostic-1',
    patch_seq: '101',
    target_version_code: '25',
    recorded_at: 123456789,
    fingerprint: 'original-host',
    abi: 'ios-arm64',
  );

  test('加密报告完整保留实际补丁身份和幂等字段', () async {
    expect(await report(), isTrue);
    expect(captured, containsPair('diagnostic_id', 'diagnostic-1'));
    expect(captured, containsPair('patch_seq', '101'));
    expect(captured, containsPair('target_version_code', '25'));
    expect(captured, containsPair('recorded_at', 123456789));
    expect(captured, containsPair('fingerprint', 'original-host'));
    expect(captured, containsPair('abi', 'ios-arm64'));
    expect(captured, containsPair('is_healthy', false));
  });

  test('业务拒绝和HTTP错误均返回false供持久化队列重试', () async {
    business_success = false;
    expect(await report(), isFalse);
    http_status = 503;
    expect(await report(), isFalse);
  });
}
