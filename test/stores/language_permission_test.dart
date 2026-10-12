// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:io';
import 'dart:ui';

import 'package:app/models/language_info.dart';
import 'package:app/models/user_info.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/language_util/language_permission.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// 后端故意将中文设为默认，验证接口配置不能授予中文权限。
const List<LanguageInfo> _backend_language_list = <LanguageInfo>[
  LanguageInfo(id: 2, title: '中文', code: 'zh-CN', default_language: 2),
  LanguageInfo(id: 1, title: 'English', code: 'en'),
  LanguageInfo(id: 4, title: 'Français', code: 'fr'),
  LanguageInfo(id: 3, title: 'Kiswahili', code: 'sw'),
];

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage_directory;
  late GetStorage storage;
  late UserInformation user_information;

  setUpAll(() async {
    storage_directory = Directory.systemTemp.createTempSync(
      'novel_language_permission_test_',
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storage_directory.path,
    );
    storage = GetStorage('GetStorage', storage_directory.path);
    await storage.initStorage;
    await LanguageUtil.load_asset_language_code_list();
  });

  setUp(() {
    Get.testMode = true;
    storage.writeInMemory(LanguageStore.language_key, '');
    storage.writeInMemory(LanguageStore.language_list_key, <dynamic>[]);
    binding.platformDispatcher.localesTestValue = const <Locale>[
      Locale('en', 'US'),
    ];
    user_information = Get.put<UserInformation>(UserInformation());
  });

  tearDown(() async {
    binding.platformDispatcher.clearLocalesTestValue();
    Get.reset();
  });

  tearDownAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await storage_directory.delete(recursive: true);
  });

  test('尚未注册用户仓库时按游客拒绝中文', () {
    Get.delete<UserInformation>();

    expect(LanguagePermission.can_use_chinese, isFalse);
    expect(LanguagePermission.resolve_language_code('zh-CN'), 'en');
  });

  test('游客和所有非 debug=2 用户都不能通过接口列表展示中文', () {
    final LanguageStore language_store = _register_language_store();
    language_store.save_language_list(_backend_language_list, persist: false);

    _expect_chinese_hidden(language_store);
    for (final int debug in <int>[0, 1, 3]) {
      user_information.saveUserInfo(_build_user_info(debug: debug));

      expect(LanguagePermission.can_use_chinese, isFalse);
      _expect_chinese_hidden(language_store);
    }
    expect(language_store.default_language_code, 'en');
  });

  test('资料带 debug=2 但没有有效登录身份不能使用中文', () {
    final LanguageStore language_store = _register_language_store();
    language_store.save_language_list(_backend_language_list, persist: false);
    user_information.saveUserInfo(_build_user_info(id: 0, debug: 2));
    user_information.isLoggedIn.value = true;

    expect(LanguagePermission.can_use_chinese, isFalse);
    _expect_chinese_hidden(language_store);

    user_information.saveUserInfo(_build_user_info(debug: 2));
    user_information.isLoggedIn.value = false;

    expect(LanguagePermission.can_use_chinese, isFalse);
    _expect_chinese_hidden(language_store);
  });

  test('历史缓存包含中文时所有公开列表依然过滤中文', () {
    storage.writeInMemory(
      LanguageStore.language_list_key,
      _backend_language_list.map((item) => item.to_json()).toList(),
    );
    final LanguageStore language_store = _register_language_store();

    expect(language_store.loaded.value, isTrue);
    _expect_chinese_hidden(language_store);
    expect(language_store.default_language_code, 'en');
  });

  test('登录 debug=2 用户后从保留的接口数据恢复中文', () {
    final LanguageStore language_store = _register_language_store();
    language_store.save_language_list(_backend_language_list, persist: false);
    _expect_chinese_hidden(language_store);

    user_information.saveUserInfo(_build_user_info(debug: 2));

    expect(LanguagePermission.can_use_chinese, isTrue);
    for (final List<LanguageInfo> list in <List<LanguageInfo>>[
      language_store.language_list,
      language_store.supported_language_list,
      language_store.visible_language_list,
    ]) {
      expect(list.map((item) => item.language_code), contains('zh'));
    }
    expect(language_store.default_language_code, 'zh');
    expect(LanguagePermission.resolve_language_code('zh_Hant'), 'zh');
  });

  test('同账号 debug 降级立即隐藏中文并重新计算英语默认语种', () {
    user_information.saveUserInfo(_build_user_info(debug: 2));
    final LanguageStore language_store = _register_language_store();
    language_store.save_language_list(_backend_language_list, persist: false);
    final int identity_revision = user_information.auth_identity_revision;

    user_information.saveUserInfo(_build_user_info(debug: 1));

    expect(user_information.auth_identity_revision, identity_revision);
    expect(LanguagePermission.can_use_chinese, isFalse);
    _expect_chinese_hidden(language_store);
    expect(language_store.default_language_code, 'en');
  });

  test('退出后隐藏中文，后续登录 debug=2 可以再次恢复', () {
    user_information.saveUserInfo(_build_user_info(debug: 2));
    final LanguageStore language_store = _register_language_store();
    language_store.save_language_list(_backend_language_list, persist: false);

    user_information.begin_logout();

    _expect_chinese_hidden(language_store);
    expect(language_store.default_language_code, 'en');

    user_information.saveUserInfo(_build_user_info(debug: 2));
    expect(
      language_store.visible_language_list.map((item) => item.language_code),
      contains('zh'),
    );
  });

  test('接口只有中文或尚无列表时回退英语', () {
    final LanguageStore language_store = _register_language_store();
    expect(language_store.default_language_code, 'en');

    language_store.save_language_list(<LanguageInfo>[
      _backend_language_list.first,
    ], persist: false);

    expect(language_store.visible_language_list, isEmpty);
    expect(language_store.default_language_code, 'en');
    expect(LanguageUtil.get_fallback_language_code(), 'en');
  });

  test('中文区域代码和旧别名均不能绕过权限', () {
    for (final String code in <String>[
      'zh',
      'zh-CN',
      'zh_Hant',
      ' CN ',
      'Chinese',
    ]) {
      expect(LanguagePermission.is_chinese(code), isTrue);
      expect(LanguagePermission.resolve_language_code(code), 'en');
    }
    expect(LanguagePermission.resolve_language_code('fr-FR'), 'fr');
    expect(LanguagePermission.resolve_language_code('sw_TZ'), 'sw');
  });

  test('历史中文偏好覆盖为英语，不再次使用中文设备语种', () async {
    binding.platformDispatcher.localesTestValue = const <Locale>[
      Locale('zh', 'CN'),
    ];
    for (final String code in <String>['zh', 'zh-CN', 'zh_Hant', 'cn']) {
      storage.writeInMemory(LanguageStore.language_key, code);

      expect(await LanguageUtil.get_language(), 'en');
      expect(storage.read<String>(LanguageStore.language_key), 'en');
    }
    expect(await LanguageUtil.get_language_id(), 1);
  });

  test('没有历史偏好时中文设备即使还有其他语种也默认英语', () async {
    binding.platformDispatcher.localesTestValue = const <Locale>[
      Locale('zh', 'CN'),
      Locale('fr', 'FR'),
    ];
    _register_language_store().save_language_list(
      _backend_language_list,
      persist: false,
    );

    expect(await LanguageUtil.get_language(), 'en');
    expect(storage.read<String>(LanguageStore.language_key), 'en');
    expect(await LanguageUtil.get_language_id(), 1);
  });

  test('debug=2 用户可以保留中文偏好，同账号降级后偏好变英语', () async {
    user_information.saveUserInfo(_build_user_info(debug: 2));
    _register_language_store().save_language_list(
      _backend_language_list,
      persist: false,
    );
    storage.writeInMemory(LanguageStore.language_key, 'zh');

    expect(await LanguageUtil.get_language(), 'zh');
    expect(await LanguageUtil.get_language_id(), 2);

    user_information.saveUserInfo(_build_user_info(debug: 1));

    expect(await LanguageUtil.get_language(), 'en');
    expect(storage.read<String>(LanguageStore.language_key), 'en');
    expect(await LanguageUtil.get_language_id(), 1);
  });

  test('退出后旧中文偏好不会继续用于请求', () async {
    user_information.saveUserInfo(_build_user_info(debug: 2));
    storage.writeInMemory(LanguageStore.language_key, 'zh');
    expect(await LanguageUtil.get_language(), 'zh');

    user_information.begin_logout();

    expect(await LanguageUtil.get_language(), 'en');
    expect(await LanguageUtil.get_language_id(), 1);
    expect(storage.read<String>(LanguageStore.language_key), 'en');
  });

  test('法语和斯瓦希里语历史偏好不受中文权限限制', () async {
    binding.platformDispatcher.localesTestValue = const <Locale>[
      Locale('zh', 'CN'),
    ];
    _register_language_store().save_language_list(
      _backend_language_list,
      persist: false,
    );
    for (final String code in <String>['fr', 'sw']) {
      storage.writeInMemory(LanguageStore.language_key, code);

      expect(await LanguageUtil.get_language(), code);
      expect(storage.read<String>(LanguageStore.language_key), code);
    }
  });

  test('法语和斯瓦希里语设备匹配照常工作', () async {
    _register_language_store().save_language_list(
      _backend_language_list,
      persist: false,
    );
    for (final String code in <String>['fr', 'sw']) {
      storage.writeInMemory(LanguageStore.language_key, '');
      binding.platformDispatcher.localesTestValue = <Locale>[Locale(code)];

      expect(await LanguageUtil.get_language(), code);
    }
  });
}

/// 注册包含本地四种翻译资源的语种仓库。
LanguageStore _register_language_store() {
  return Get.put<LanguageStore>(
    LanguageStore(asset_language_code_list: <String>['en', 'zh', 'fr', 'sw']),
  );
}

/// 同时验证三种公开列表，避免其他菜单读取未过滤的原始数据。
void _expect_chinese_hidden(LanguageStore language_store) {
  for (final List<LanguageInfo> list in <List<LanguageInfo>>[
    language_store.language_list,
    language_store.supported_language_list,
    language_store.visible_language_list,
  ]) {
    expect(
      list.map((item) => item.language_code),
      orderedEquals(<String>['en', 'fr', 'sw']),
    );
  }
}

/// 构造明确的身份和 debug 权限；其余资料仅满足真实用户模型。
UserInfo _build_user_info({int id = 1, required int debug}) {
  return UserInfo(
    id: id,
    account: 'account_$id',
    invitationCode: 'code_$id',
    name: 'reader_$id',
    type: 1,
    avatarUrl: '',
    balance: 0,
    onlineStatus: 1,
    onlineStatusUpdateTime: '',
    shareRatio: 0,
    memberExpiryTime: '',
    roleName: '',
    notViewed: 0,
    followCount: 0,
    fansCount: 0,
    likesCount: 0,
    debug: debug,
  );
}
