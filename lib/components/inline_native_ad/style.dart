/// 正文原生广告公共样式。
class InlineNativeAdStyle {
  const InlineNativeAdStyle._();

  /// 广告位进入视口后允许挂载平台视图的最小可见高度。
  static const double minimum_visible_extent = 1;

  /// 为下一布局帧和快速滚动预留余量，不在视口边缘突然插入广告。
  static const double insertion_safety_spacing = 96;

  /// 原生卡片外部间距，与阅读广告组件共用，防止误判空白为广告可见。
  static const double spacing_top = 12;
  static const double spacing_bottom = 16;
  static const double hint_spacing = 18;
  static const double hint_font_size = 12;
  static const double hint_height = 1.4;
}
