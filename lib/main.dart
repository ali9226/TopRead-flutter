// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get/get.dart';
import 'package:app/stores/bottom_navigation_info.dart';
import 'package:app/stores/app_global_config.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/stores/shell_tab_info.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:oktoast/oktoast.dart';
import 'package:app/components/app_wrapper/index.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/stores/redis_request.dart';
import 'package:app/stores/customer_service_store.dart';
import 'package:app/stores/customer_service_chat_history_store.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/home_store.dart';
import 'package:app/stores/authorized_login_store.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:app/stores/short_story_catalog_store.dart';
import 'package:app/stores/preference_store.dart';
import 'package:app/stores/share_store.dart';
import 'package:app/stores/message_store.dart';
import 'package:app/util/router/web_url_strategy.dart';
import 'package:app/util/device/get_theme_mode.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app/firebase_options.dart';
import 'package:app/fcm/fcm_service.dart';
import 'package:app/util/language_util/language_change_handler.dart';
import 'package:auto_hyphenating_text/auto_hyphenating_text.dart';
import 'package:app/util/app_update/index.dart';
import 'package:app/config/constant.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await EasyLocalization.ensureInitialized();

  // TODO 初始化 GetStorage（必须在 runApp 之前）
  await GetStorage.init();
  await LanguageUtil.load_asset_language_code_list();

  // TODO 初始化应用版本号（从 pubspec.yaml 读取）
  await Constant.getAppVersion();

  // TODO 初始化自动断词（字母语种排版优化）
  await initHyphenation();

  // TODO 初始化语种变化处理器
  await LanguageChangeHandler.init();

  setWebUrlStrategy(); // TODO Web 优化：移除 hash 路由

  // TODO 注入全局状态
  Get.put(UserInformation());
  Get.put(DeviceInfo());
  Get.put(BottomNavigationInfo());
  Get.put(ShellTabInfo());
  Get.put(CustomerServiceStore());
  Get.put(CustomerServiceChatHistoryStore(), permanent: true);
  Get.put(
    LanguageStore(
      asset_language_code_list: LanguageUtil.asset_language_code_list,
    ),
  );
  Get.put(AppGlobalConfigStore());
  final RedisRequestStore redisRequestStore = Get.put(RedisRequestStore());
  Get.put(HomeBannerStore());
  Get.put(AuthorizedLoginStore());
  Get.put(NovelReadingStore());
  Get.put(ShortStoryCatalogStore());
  Get.put(PreferenceStore());
  Get.put(ShareStore());
  Get.put(MessageStore());
  // TODO 初始化主题
  await getThemeMode();

  /// 获取本地保存的语种
  final String lang = await LanguageUtil.get_language();
  final String fallback_language_code =
      LanguageUtil.get_fallback_language_code();

  /// TODO 语种保存到本地
  await StorageUtil.saveData(LanguageStore.language_key, lang);

  // 【临时修复】Flutter 3.44.2 框架内部 semantics 断言 bug（node.built is not true），
  // 用 ExcludeSemantics 跳过无障碍树构建来规避。不影响 release 模式。
  runApp(
    ExcludeSemantics(
      child: OKToast(
        child: EasyLocalization(
          supportedLocales: LanguageUtil.supported_locales,
          path: 'assets/i18n',

          // TODO 启动时优先按本地已保存语种，否则按设备语种匹配结果启动。
          startLocale: Locale(lang),

          // TODO 如果无法识别语种，统一回退英文。
          fallbackLocale: Locale(fallback_language_code),

          child: AppWrapper(),
        ),
      ),
    ),
  );

  redisRequestStore.fetch_redis_data();

  // TODO 检查 App 版本更新（浏览器环境自动跳过）
  checkAppUpdate();

  // TODO 初始化推送通知服务
  final FcmService fcm_service = FcmService();
  await fcm_service.init();
}
