import 'package:app/config/layout_config.dart';

/// 页面级返回顶部组件样式常量。
class FloatingBackToTopStyle {
  /// 普通页面显示时距离底部的偏移。
  static const double page_bottom = LayoutConfig.space_22;

  /// 显示时，按钮相对底部导航顶部的纵向偏移。
  static const double offset_from_bottom_nav = -34;

  /// 隐藏时的底部偏移。
  static const double hidden_offset = -72;
}
