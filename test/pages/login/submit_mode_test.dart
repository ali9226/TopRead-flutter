// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:app/common_style/submit_button/index.dart';
import 'package:app/pages/login/index.dart';
import 'package:app/stores/authorized_login_store.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage_directory;

  setUpAll(() async {
    storage_directory = Directory.systemTemp.createTempSync(
      'submit_mode_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => storage_directory.path,
        );
    await GetStorage('GetStorage', storage_directory.path).initStorage;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (MethodCall call) async =>
              call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
    await LanguageUtil.load_asset_language_code_list();
  });

  setUp(() {
    Get.testMode = true;
    Get.put<AuthorizedLoginStore>(_RecordingAuthenticationStore());
    Get.put<DeviceInfo>(_TestDeviceInfo());
    Get.put(LanguageStore(asset_language_code_list: <String>['zh']));
    Get.put(ProjectConfigStore());
  });

  tearDown(Get.reset);

  tearDownAll(() async {
    await GetStorage().erase();
    await storage_directory.delete(recursive: true);
  });

  for (final bool registered in <bool>[true, false]) {
    final String expected_type = registered ? 'login' : 'register';
    testWidgets('${registered ? "已注册" : "未注册"}账号键盘完成键与主按钮提交模式一致', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_build_test_app());
      await tester.pumpAndSettle();

      // 直接设置验证结果，避免注册查询或认证接口影响提交入口的回归验证。
      final dynamic state = tester.state(find.byType(Login));
      state.setState(() {
        state.logic.account = 'reader';
        state.accountController.text = 'reader';
        state.logic.isAccountRegistered = registered;
      });
      await tester.pumpAndSettle();
      final _RecordingAuthenticationStore store =
          Get.find<AuthorizedLoginStore>() as _RecordingAuthenticationStore;
      final Finder password_field = find.byWidgetPredicate(
        (Widget widget) => widget is TextField && widget.obscureText,
      );

      await tester.enterText(password_field, 'password');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(store.attempts, <String>[expected_type]);

      final Finder submit_button = find.byType(CommonSubmitButton);
      await tester.ensureVisible(submit_button);
      await tester.pumpAndSettle();
      await tester.tap(submit_button);
      await tester.pumpAndSettle();
      expect(store.attempts, <String>[expected_type, expected_type]);
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _build_test_app() => EasyLocalization(
  supportedLocales: const <Locale>[Locale('zh')],
  path: 'assets/i18n',
  assetLoader: const _SubmitModeAssetLoader(),
  startLocale: const Locale('zh'),
  fallbackLocale: const Locale('zh'),
  child: Builder(
    builder: (BuildContext context) => MaterialApp(
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: const Login(),
    ),
  ),
);

/// 记录真实页面选择的认证流程，拒绝获取锁以阻止后续网络请求。
class _RecordingAuthenticationStore extends AuthorizedLoginStore {
  final List<String> attempts = <String>[];

  @override
  bool try_start_authentication(String authentication_type) {
    attempts.add(authentication_type);
    return false;
  }
}

/// 页面测试只需主题状态，不订阅原生网络连接事件。
class _TestDeviceInfo extends DeviceInfo {
  // DeviceInfo.onInit 会查询并订阅原生连接事件，页面测试仅使用主题状态。
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _SubmitModeAssetLoader extends AssetLoader {
  const _SubmitModeAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'UserInfo': {'login': '登录'},
    'login': {
      'slogan': '阅读好故事',
      'account': '账号',
      'account_tips': '请输入账号',
      'password': '密码',
      'password_tips': '请输入密码',
      'account_not_registered': '尚未注册',
      'remember_password': '记住密码',
      'forgot_password': '忘记密码',
      'register_now': '立即注册',
      'no_account_tips': '还没有账号',
    },
    'register': {
      'invitation_code': '邀请码',
      'invitation_code_input_tips': '请输入邀请码',
      'account_tips': '已有账号',
      'login_now': '立即登录',
    },
  };
}
