// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:app/pages/login/logic.dart';
import 'package:app/util/dialog/aes_encryption.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage_directory;

  setUpAll(() async {
    storage_directory = Directory.systemTemp.createTempSync(
      'login_cache_lifecycle_test_',
    );
    // 这些测试只读取缓存，初始化空文件避免 GetStorage 自动异步备份。
    File('${storage_directory.path}/GetStorage.gs').writeAsStringSync('{}');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storage_directory.path,
    );
    await GetStorage('GetStorage', storage_directory.path).initStorage;
  });

  setUp(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storage_directory.path,
    );
    GetStorage().writeInMemory(accountKey, aesEncryption('cached_reader'));
    GetStorage().writeInMemory(passwordKey, aesEncryption('cached_password'));
  });

  tearDownAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await storage_directory.delete(recursive: true);
  });

  test('离开登录页后缓存读取不能访问已释放的输入控制器', () async {
    final account_controller = TextEditingController();
    final password_controller = TextEditingController();
    final logic = Logic()
      ..accountController = account_controller
      ..passwordController = password_controller;
    final pending = logic.init();
    logic.dispose();
    account_controller.dispose();
    password_controller.dispose();

    await expectLater(pending, completes);
    expect(logic.account, isEmpty);
    expect(logic.password, isEmpty);
  });

  test('读取缓存期间输入新账号不能被旧账号和密码覆盖', () async {
    final logic = Logic();
    addTearDown(logic.dispose);
    final pending = logic.init();
    logic.account = 'new_reader';
    logic.password = 'new_password';

    await pending;
    expect(logic.account, 'new_reader');
    expect(logic.password, 'new_password');
  });

  test('正常打开登录页仍恢复匹配的账号和密码', () async {
    final logic = Logic();
    addTearDown(logic.dispose);

    await logic.init();
    expect(logic.account, 'cached_reader');
    expect(logic.password, 'cached_password');
  });
}
