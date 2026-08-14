// ignore_for_file: non_constant_identifier_names, constant_identifier_names

/// 苹果审核模式下快捷登录按钮的样式配置。
///
/// 为了通过 Apple App Store 审核，快捷登录按钮必须符合 Apple HIG 规范：
/// - 每行一个按钮，占据接近全宽
/// - 图标在左，文字居中
/// - 最小高度 44pt（实际使用 50pt 保证视觉舒适）
/// - 明确的圆角矩形按钮外观
class AppleReviewStyle {
  /// 按钮高度，满足 Apple HIG 最小 44pt 触摸目标要求。
  static const double button_height = 50;

  /// 按钮左右外边距。
  static const double button_horizontal_margin = 32;

  /// 按钮圆角半径。
  static const double button_border_radius = 12;

  /// 按钮之间的垂直间距。
  static const double button_vertical_spacing = 12;

  /// 按钮内部左侧内边距（图标距左边的距离）。
  static const double button_padding_left = 16;

  /// 图标与文字之间的间距。
  static const double icon_text_spacing = 12;

  /// 图标尺寸。
  static const double icon_size = 24;

  /// 网络图标圆角。
  static const double icon_border_radius = 4;

  /// 按钮文字字号。
  static const double button_font_size = 16;

  /// 标题容器高度。
  static const double title_container_height = 30;

  /// 标题左右间距。
  static const double title_horizontal_spacing = 10;

  /// 标题字号。
  static const double title_font_size = 12;

  /// 列表顶部间距。
  static const double list_top_spacing = 12;

  /// 按钮列表底部间距。
  static const double list_bottom_spacing = 16;

  /// 两边的渐变条的宽度。
  static const double slogan_width = 50;

  /// 两边的渐变条的高度。
  static const double slogan_height = 2;

  /// 左侧渐变标记。
  static const String left_side = 'left';

  /// 右侧渐变标记。
  static const String right_side = 'right';

  /// 其他认证流程进行时，非当前按钮的透明度。
  static const double disabled_opacity = 0.38;

  /// 按钮状态切换动画时长。
  static const Duration state_duration = Duration(milliseconds: 180);
}
