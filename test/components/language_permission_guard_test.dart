// ignore_for_file: non_constant_identifier_names, constant_identifier_names, depend_on_referenced_packages

import 'dart:io';

import 'package:app/components/language_permission_guard/index.dart';
import 'package:app/models/user_info.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/language_util/language_change_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage_directory;
  late GetStorage storage;
  late UserInformation user_information;
  late LanguageRefreshSubscription refresh_subscription;
  late List<String> refreshed_languages;

  setUpAll(() async {
    storage_directory = Directory.systemTemp.createTempSync(
      'novel_language_guard_test_',
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storage_directory.path,
    );
    storage = GetStorage('GetStorage', storage_directory.path);
    await storage.initStorage;
    await LanguageUtil.load_asset_language_code_list();
  });

  setUp(() async {
    Get.testMode = true;
    storage.writeInMemory(LanguageStore.language_key, 'en');
    storage.writeInMemory(LanguageStore.language_list_key, <dynamic>[]);
    binding.platformDispatcher.localesTestValue = const <Locale>[
      Locale('zh', 'CN'),
    ];
    // EasyLocalization 的旧缓存独立于应用 language 缓存，故意制造冲突。
    SharedPreferences.setMockInitialValues(<String, Object>{'locale': 'zh'});
    await EasyLocalization.ensureInitialized();
    user_information = Get.put<UserInformation>(UserInformation());
    LanguageChangeHandler.sync_initial_language('en');
    refreshed_languages = <String>[];
    refresh_subscription = LanguageChangeHandler.register_refresh_task(
      phase: LanguageRefreshPhase.configuration,
      on_refresh: (LanguageRefreshContext context) async {
        refreshed_languages.add(context.language_code);
      },
    );
  });

  tearDown(() {
    refresh_subscription.dispose();
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

  testWidgets('旧 EasyLocalization 中文缓存不会闪现，中文设备首屏最终为英语', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_build_test_app());

    // 标准 Finder 会跳过 Offstage，检查用户真正能看到的首帧。
    expect(find.text('中文'), findsNothing);
    await _settle_guard(tester, storage, 'English', forbid_chinese: true);

    expect(find.text('English'), findsOneWidget);
    expect(find.text('中文'), findsNothing);
    expect(storage.read<String>(LanguageStore.language_key), 'en');
    expect(LanguageChangeHandler.current_language_code, 'en');
    expect(refreshed_languages, anyOf(isEmpty, orderedEquals(<String>['en'])));
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('locale'), isNull);
  });

  testWidgets('debug=2 显示中文，同账号权限撤销切英语且保留当前页面 State', (
    WidgetTester tester,
  ) async {
    user_information.saveUserInfo(_build_user_info(debug: 2));
    storage.writeInMemory(LanguageStore.language_key, 'zh');
    LanguageChangeHandler.sync_initial_language('zh');
    final GlobalKey<_ReadingProbeState> reading_key =
        GlobalKey<_ReadingProbeState>();
    await tester.pumpWidget(_build_test_app(reading_key: reading_key));
    await _settle_guard(tester, storage, '中文');

    expect(find.text('中文'), findsOneWidget);
    await tester.tap(find.text('advance'));
    await tester.pump();
    await tester.tap(find.text('advance'));
    await tester.pump();
    expect(find.text('count:2'), findsOneWidget);
    final _ReadingProbeState original_state = reading_key.currentState!;
    final int identity_revision = user_information.auth_identity_revision;
    refreshed_languages.clear();

    user_information.saveUserInfo(_build_user_info(debug: 1));
    await tester.pump();
    expect(find.text('中文'), findsNothing);
    await _settle_guard(tester, storage, 'English', forbid_chinese: true);

    expect(user_information.auth_identity_revision, identity_revision);
    expect(reading_key.currentState, same(original_state));
    expect(find.text('count:2'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(storage.read<String>(LanguageStore.language_key), 'en');
    expect(refreshed_languages, <String>['en']);
  });

  for (final String language_code in <String>['fr', 'sw']) {
    testWidgets('旧中文 localization 缓存不会覆盖 $language_code 历史偏好', (
      WidgetTester tester,
    ) async {
      storage.writeInMemory(LanguageStore.language_key, language_code);
      LanguageChangeHandler.sync_initial_language(language_code);
      final String expected_label = language_code == 'fr'
          ? 'Français'
          : 'Kiswahili';

      await tester.pumpWidget(_build_test_app());
      expect(find.text('中文'), findsNothing);
      await _settle_guard(
        tester,
        storage,
        expected_label,
        forbid_chinese: true,
      );

      expect(find.text(expected_label), findsOneWidget);
      expect(storage.read<String>(LanguageStore.language_key), language_code);
      expect(LanguageChangeHandler.current_language_code, language_code);
      expect(
        refreshed_languages,
        anyOf(isEmpty, orderedEquals(<String>[language_code])),
      );
    });
  }
}

/// 仅挂载真实语种守卫与本地探针，不初始化业务 Store、Firebase 或网络。
Widget _build_test_app({GlobalKey<_ReadingProbeState>? reading_key}) {
  return EasyLocalization(
    supportedLocales: const <Locale>[
      Locale('en'),
      Locale('zh'),
      Locale('fr'),
      Locale('sw'),
    ],
    path: 'assets/i18n',
    assetLoader: const _GuardAssetLoader(),
    saveLocale: false,
    startLocale: const Locale('en'),
    fallbackLocale: const Locale('en'),
    child: Builder(
      builder: (BuildContext context) => MaterialApp(
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        home: Scaffold(
          body: LanguagePermissionGuard(child: _ReadingProbe(key: reading_key)),
        ),
      ),
    ),
  );
}

/// 允许真实临时文件缓存完成写入，每一帧都检查受限中文不会可见。
Future<void> _settle_guard(
  WidgetTester tester,
  GetStorage storage,
  String expected_label, {
  bool forbid_chinese = false,
}) async {
  const int maximum_frames = 12;
  for (int frame = 0; frame < maximum_frames; frame++) {
    await tester.pump();
    if (forbid_chinese) expect(find.text('中文'), findsNothing);
    await tester.runAsync(() async => storage.save());
    await tester.pump();
    if (forbid_chinese) expect(find.text('中文'), findsNothing);
    if (find.text(expected_label).evaluate().length == 1 &&
        !LanguageChangeHandler.is_refreshing.value) {
      expect(tester.takeException(), isNull);
      return;
    }
  }
  expect(find.text(expected_label), findsOneWidget);
  expect(LanguageChangeHandler.is_refreshing.value, isFalse);
  expect(tester.takeException(), isNull);
}

/// 可交互页面模拟阅读状态；语种切换必须保留计数及同一 State 实例。
class _ReadingProbe extends StatefulWidget {
  const _ReadingProbe({super.key});

  @override
  State<_ReadingProbe> createState() => _ReadingProbeState();
}

class _ReadingProbeState extends State<_ReadingProbe> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(context.tr('language_label')),
        Text('count:$_count'),
        TextButton(
          onPressed: () => setState(() => _count++),
          child: const Text('advance'),
        ),
      ],
    );
  }
}

/// 只提供测试必需的四种文字，避免加载业务翻译或外部资源。
class _GuardAssetLoader extends AssetLoader {
  const _GuardAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    const Map<String, String> labels = <String, String>{
      'en': 'English',
      'zh': '中文',
      'fr': 'Français',
      'sw': 'Kiswahili',
    };
    return <String, dynamic>{'language_label': labels[locale.languageCode]};
  }
}

/// 使用相同账号 ID 区分权限资料刷新与真正的账号切换。
UserInfo _build_user_info({required int debug}) {
  return UserInfo(
    id: 1,
    account: 'reader',
    invitationCode: 'reader_code',
    name: 'reader',
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
