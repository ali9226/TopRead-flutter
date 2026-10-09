// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:app/api/dio_client.dart';
import 'package:app/api/post_request.dart';
import 'package:app/config/constant.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage_directory;
  late Interceptor interceptor;
  final Map<String, String> captured_authorizations = <String, String>{};

  setUpAll(() async {
    // 使用独立空缓存，测试不会读写开发设备的真实登录凭证。
    storage_directory = Directory.systemTemp.createTempSync(
      'post_request_authorization_',
    );
    File('${storage_directory.path}/GetStorage.gs').writeAsStringSync('{}');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storage_directory.path,
    );
    await GetStorage('GetStorage', storage_directory.path).initStorage;
  });

  setUp(() {
    captured_authorizations.clear();
    GetStorage().writeInMemory(Constant.tokenKey, 'current-account');
    // 在网络发送前截获凭证，直接返回空响应，禁止任何真实网络请求。
    interceptor = InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        captured_authorizations[options.path] =
            options.headers['Authorization']?.toString() ?? '';
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: <String, dynamic>{},
          ),
        );
      },
    );
    DioClient().instance.interceptors.add(interceptor);
  });

  tearDown(() {
    DioClient().instance.interceptors.remove(interceptor);
  });

  tearDownAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await storage_directory.delete(recursive: true);
  });

  test('固定账号请求不会使用异步准备期间切换后的缓存凭证', () async {
    final request = postRequest<void>(
      path: 'authorization_snapshot',
      authorization_token: 'reward-owner',
      showTips: false,
    );
    GetStorage().writeInMemory(Constant.tokenKey, 'switched-account');
    await request;

    expect(captured_authorizations.values.single, 'Bearer reward-owner');
  });

  test('明确访客请求不会继承设备当前登录账号', () async {
    await postRequest<void>(
      path: 'guest_authorization',
      authorization_token: '',
      showTips: false,
    );

    expect(captured_authorizations.values.single, isEmpty);
  });

  test('未指定凭证的既有请求继续读取当前账号', () async {
    await postRequest<void>(path: 'default_authorization', showTips: false);

    expect(captured_authorizations.values.single, 'Bearer current-account');
  });

  test('并发账号与访客请求的固定凭证相互隔离', () async {
    await Future.wait(<Future<dynamic>>[
      postRequest<void>(
        path: 'parallel_account',
        authorization_token: 'reward-owner',
        showTips: false,
      ),
      postRequest<void>(
        path: 'parallel_guest',
        authorization_token: '',
        showTips: false,
      ),
    ]);

    expect(
      captured_authorizations['${Constant.prefix}parallel_account'],
      'Bearer reward-owner',
    );
    expect(
      captured_authorizations['${Constant.prefix}parallel_guest'],
      isEmpty,
    );
  });
}
