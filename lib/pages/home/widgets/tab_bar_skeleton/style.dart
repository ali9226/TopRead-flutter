import 'package:app/pages/home/widgets/home_tab_bar/style.dart';

/// 首页 Tab 栏骨架屏样式常量。
class TabBarSkeletonStyle {
  /// 动画时长。
  static const Duration animation_duration = Duration(milliseconds: 1500);

  /// 左侧起始内边距（与 TabBar 的 labelPadding 对齐）。
  static const double start_padding = HomeTabBarStyle.tab_label_padding_left_cjk;

  /// 骨架屏项数量。
  static const int item_count = 6;

  /// 骨架屏项之间间距（与 TabBar labelPadding 一致）。
  static const double item_spacing = HomeTabBarStyle.tab_label_padding_left_cjk;

  /// 骨架屏项高度（与 TabBar 文字行高一致，略高一点更饱满）。
  static const double item_height = 20.0;

  /// 骨架屏项圆角。
  static const double item_radius = 6.0;

  /// 骨架屏项宽度列表（模拟不同标题长度，参考真实 Tab 文字宽度）。
  static const List<double> item_width_list = <double>[
    36.0,
    48.0,
    44.0,
    52.0,
    40.0,
    56.0,
  ];
}
