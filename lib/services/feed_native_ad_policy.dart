// ignore_for_file: constant_identifier_names

/// 列表原生广告的请求与缓存边界，避免失败后反复请求和无限保留素材。
class FeedNativeAdPolicy {
  const FeedNativeAdPolicy._();

  /// 失败后允许下一次尝试的间隔；只重试仍有页面监听的槽位。
  static const Duration retry_delay = Duration(seconds: 30);

  /// 隐私许可完成后，SDK 初始化、素材与真实尺寸必须在此期限内就绪。
  /// 用户正在操作 UMP 表单的时间不计入，避免超时打断必要的隐私流程。
  static const Duration preparation_timeout = Duration(seconds: 30);

  /// 未展示素材最多保留一小时，超过后重新向 SDK 获取新广告。
  /// Google 官方原生广告缓存建议：https://developers.google.com/admob/android/native
  static const Duration maximum_cache_age = Duration(hours: 1);

  /// 全局池最多保留的控制器数；正在使用的控制器不会被强制淘汰。
  static const int maximum_retained_controllers = 32;

  /// 布局亚像素抖动不应引发新的广告请求。
  static const double layout_tolerance = 0.5;
}
