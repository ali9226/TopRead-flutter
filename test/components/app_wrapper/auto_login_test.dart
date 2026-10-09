// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:io';

import 'package:app/api/results_type.dart';
import 'package:app/components/app_wrapper/auto_login/auto_login.dart';
import 'package:app/config/constant.dart';
import 'package:app/models/login.dart';
import 'package:app/models/user_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/stores/authorized_login_store.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage_directory;
  late UserInformation user_information;

  setUpAll(() async {
    storage_directory = Directory.systemTemp.createTempSync('auto_login_test_');
    File('${storage_directory.path}/GetStorage.gs').writeAsStringSync('{}');
    File('${storage_directory.path}/GetStorage.bak').writeAsStringSync('{}');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storage_directory.path,
    );
    await GetStorage('GetStorage', storage_directory.path).initStorage;
  });
  setUp(() {
    Get.testMode = true;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storage_directory.path,
    );
    GetStorage().writeInMemory(Constant.tokenKey, 'original-token');
    user_information = Get.put(UserInformation());
  });
  tearDown(() async {
    Get.reset();
    // 先排空本次 flush 发起的备份通道调用，测试隔离时再清除 mock。
    await Future<void>.delayed(Duration.zero);
  });

  test('网络失败保留缓存凭证，不将结果未知当成失效', () async {
    int guest_count = 0;
    await autoLogin(
      load_user: () async => ResultsType<Login>(),
      synchronize_guest: () async => guest_count++,
    );

    expect(await StorageUtil.getData(Constant.tokenKey), 'original-token');
    expect(guest_count, 0);
    expect(user_information.userInfo.value, isNull);
  });

  test('服务端明确拒绝原凭证时清缓存并切换访客', () async {
    int guest_count = 0;
    await autoLogin(
      load_user: () async => ResultsType<Login>()..serverRejected = true,
      synchronize_guest: () async => guest_count++,
    );

    expect(await StorageUtil.getData(Constant.tokenKey), isNull);
    expect(guest_count, 1);
  });

  for (final bool success in [false, true]) {
    test('手动登录新账号后忽略自动登录旧响应 success=$success', () async {
      final Completer<ResultsType<Login>> response = Completer();
      final Completer<void> started = Completer();
      int guest_count = 0;
      int completed_count = 0;
      final Future<void> pending = autoLogin(
        load_user: () {
          started.complete();
          return response.future;
        },
        synchronize_guest: () async => guest_count++,
        on_login_completed: () => completed_count++,
      );
      await started.future;
      await user_information.save_auth_credentials_if_current(
        token: 'new-token',
        info: _user(2),
        request_revision: user_information.auth_revision,
      );
      response.complete(
        success
            ? _login_result(1)
            : (ResultsType<Login>()..serverRejected = true),
      );
      await pending;

      expect(await StorageUtil.getData(Constant.tokenKey), 'new-token');
      expect(user_information.userInfo.value?.id, 2);
      expect(guest_count, 0);
      expect(completed_count, 0);
    });
  }

  test('正常自动登录原子保存凭证和用户后才完成同步', () async {
    int completed_count = 0;
    await autoLogin(
      load_user: () async => _login_result(1),
      on_login_completed: () => completed_count++,
    );

    expect(await StorageUtil.getData(Constant.tokenKey), 'token-1');
    expect(user_information.userInfo.value?.id, 1);
    expect(completed_count, 1);
  });

  test('手动认证尚未返回时自动登录不能抢先提交或删除凭证', () async {
    final authentication = Get.put(AuthorizedLoginStore());
    final Completer<ResultsType<Login>> response = Completer();
    final Completer<void> started = Completer();
    final pending = autoLogin(
      load_user: () {
        started.complete();
        return response.future;
      },
    );
    await started.future;
    authentication.try_start_authentication('login');
    response.complete(_login_result(1));
    await pending;

    expect(user_information.userInfo.value, isNull);
    expect(await StorageUtil.getData(Constant.tokenKey), 'original-token');
    expect(authentication.loading.value, isTrue);
  });
}

UserInfo _user(int id) =>
    UserInfo.fromJson({'id': id, 'account': 'reader-$id'});
ResultsType<Login> _login_result(int id) => ResultsType<Login>()
  ..status = true
  ..content = Login(userInfo: _user(id), token: 'token-$id');
