import 'package:app/config/layout_config.dart';

/// 调试页面样式常量。
class Style {
  /// 页面水平内边距。
  static const double pageHorizontalPadding =
      LayoutConfig.page_horizontal_padding;

  /// 页面顶部内边距。
  static const double pageTopPadding = LayoutConfig.space_16;

  /// 页面底部内边距。
  static const double pageBottomPadding = LayoutConfig.space_32;

  /// 操作项圆角半径。
  static const double itemRadius = LayoutConfig.radius_14;

  /// 操作项水平内边距。
  static const double itemHorizontalPadding = LayoutConfig.space_16;

  /// 操作项垂直内边距。
  static const double itemVerticalPadding = LayoutConfig.space_16;

  /// 操作项之间的间距。
  static const double itemSpacing = LayoutConfig.space_12;

  /// 图标容器尺寸。
  static const double iconContainerSize = 42;

  /// 图标容器圆角半径。
  static const double iconContainerRadius = LayoutConfig.radius_12;

  /// 图标尺寸。
  static const double iconSize = LayoutConfig.icon_compact;
}
