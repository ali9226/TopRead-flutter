// ignore_for_file: non_constant_identifier_names

import 'package:app/util/device/app_environment.dart';

/// App 内支持的广告业务场景。
enum AdPlacement {
  /// 短篇小说正文原生广告。
  short_story_native,

  /// 长篇小说正文原生广告。
  long_story_native,

  /// 首页推荐瀑布流原生广告。
  masonry,

  /// 短篇小说列表原生广告。
  short_story_tab,

  /// App 开屏广告。
  splash_screen,
}

/// 固定广告类型配置。
///
/// `ads_type` 是后端约定的稳定业务类型，不会随广告单元 ID 的更新而变化。
/// App 使用该映射从 `redis/get.ads_ids` 中选择当前平台的广告配置。
class AdTypeConfig {
  const AdTypeConfig._();

  /// Google AdMob 广告商类型。
  static const int google_advertiser = 1;

  /// Android 原生 App 对应的广告类型。
  static const Map<AdPlacement, int> _android_types = <AdPlacement, int>{
    AdPlacement.short_story_native: 3,
    AdPlacement.long_story_native: 5,
    AdPlacement.masonry: 7,
    AdPlacement.short_story_tab: 17,
    AdPlacement.splash_screen: 19,
  };

  /// iOS 原生 App 对应的广告类型。
  static const Map<AdPlacement, int> _ios_types = <AdPlacement, int>{
    AdPlacement.short_story_native: 4,
    AdPlacement.long_story_native: 6,
    AdPlacement.masonry: 8,
    AdPlacement.short_story_tab: 18,
    AdPlacement.splash_screen: 20,
  };

  /// 获取指定场景和平台对应的固定广告类型。
  ///
  /// 浏览器与桌面端没有移动广告类型，返回 null。
  static int? resolve_type(
    AdPlacement placement, {
    AppEnvironment? environment,
  }) {
    final AppEnvironment target_environment = environment ?? currentEnvironment;
    if (target_environment == AppEnvironment.android) {
      return _android_types[placement];
    }
    if (target_environment == AppEnvironment.ios) {
      return _ios_types[placement];
    }
    return null;
  }
}
