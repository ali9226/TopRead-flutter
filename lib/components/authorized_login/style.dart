// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 授权登录组件样式配置。
class AuthorizedLoginStyle {
  /// 两边的渐变条的宽度
  static const double slogan_width = 50;

  /// 两边的渐变条的高度
  static const double slogan_height = 2;

  /// 图标尺寸
  static const double icon_size = 30;

  /// 网络图标圆角。
  static const double icon_border_radius = 6;

  /// 标题容器高度。
  static const double title_container_height = 30;

  /// 标题左右间距。
  static const double title_horizontal_spacing = 10;

  /// 列表顶部间距。
  static const double list_top_spacing = 12;

  /// 单个客服项宽度。
  static const double item_width = 72;

  /// 客服项横向间距。
  static const double item_horizontal_spacing = 16;

  /// 客服项纵向间距。
  static const double item_vertical_spacing = 12;

  /// 其他认证流程进行时，非当前授权入口的透明度。
  static const double disabled_item_opacity = 0.38;

  /// 授权入口启用状态切换动画时长。
  static const Duration item_state_duration = Duration(milliseconds: 180);

  /// 图标和标题之间的间距。
  static const double icon_bottom_spacing = 4;

  /// 标题字号。
  static const double title_font_size = 12;

  /// 客服项标题字号。
  static const double item_title_font_size = 12;

  /// 客服项标题最大行数。
  static const int item_title_max_lines = 2;

  /// 左侧渐变标记。
  static const String left_side = 'left';

  /// 右侧渐变标记。
  static const String right_side = 'right';

  /// 根据参数生成两边的渐变条。
  static BoxDecoration slogan_gradient_bar({
    required bool is_dark,
    required String side,
  }) {
    Color startColor;
    Color endColor = ColorConstants.themeColor;

    if (is_dark) {
      startColor = ColorConstants.nightHighlightColor;
    } else {
      startColor = ColorConstants.whiteColor;
    }

    return BoxDecoration(
      gradient: LinearGradient(
        colors: [startColor, endColor],
        begin: side == "left" ? Alignment.centerLeft : Alignment.centerRight,
        end: side == "left" ? Alignment.centerRight : Alignment.centerLeft,
      ),
    );
  }
}
