import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/color_config.dart';

/// image_text 页面样式常量。
class Style {
  const Style._();

  /// 页面左右基础边距。
  static const double page_horizontal_padding =
      LayoutConfig.page_horizontal_padding;

  /// 页面底部基础边距。
  static const double page_bottom_padding = LayoutConfig.space_28;

  /// 标题卡片圆角。
  static const double title_card_radius = LayoutConfig.radius_22;

  /// 标题字号。
  static const double title_font_size = 24;

  /// 标题行高。
  static const double title_line_height = 1.25;

  /// 标题字重。
  static final FontWeight title_font_weight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 内容卡片圆角。
  static const double content_card_radius = LayoutConfig.radius_20;

  /// 文章标题与正文统一内容边距。
  static const EdgeInsets article_content_padding = EdgeInsets.fromLTRB(
    LayoutConfig.space_1,
    LayoutConfig.space_2,
    LayoutConfig.space_1,
    0,
  );

  /// HTML 默认字体大小。
  static const double html_default_font_size = 16;

  /// HTML 默认行高。
  static const double html_default_line_height = 1.7;

  /// 加载文案字号。
  static const double loading_font_size = 14;

  /// 页面右上角装饰圆尺寸。
  /// 右上光斑顶部偏移。
  static const double decor_circle_one_top = -40;

  /// 右上光斑右侧偏移。
  static const double decor_circle_one_right = -24;

  /// 左侧光斑顶部偏移。
  static const double decor_circle_two_top = 120;

  /// 左侧光斑左侧偏移。
  static const double decor_circle_two_left = -36;

  static const double decor_circle_one_size = 220;

  /// 页面左侧装饰圆尺寸。
  static const double decor_circle_two_size = 150;

  /// 装饰圆透明度。
  static const double decor_circle_opacity = 0.10;

  /// 标题区与内容区间距。
  static const double title_to_content_spacing = LayoutConfig.space_14;

  /// 回到顶部按钮触发阈值占屏高比。
  static const double back_to_top_threshold_ratio = 0.5;

  /// 回到顶部按钮右边距。
  static const double back_to_top_right = 20;

  /// 回到顶部按钮下边距。
  static const double back_to_top_bottom = 22;

  /// 回到顶部按钮位移动画时长。
  static const int back_to_top_slide_duration_ms = 220;

  /// 回到顶部按钮透明动画时长。
  static const int back_to_top_opacity_duration_ms = 180;

  /// 回到顶部隐藏时 Y 方向位移。
  static const double back_to_top_hidden_offset_y = 1.1;

  /// 回到顶部滚动动画时长。
  static const int scroll_to_top_duration_ms = 360;

  /// 默认高亮色。
  static final Color accent_color = ColorConstants.themeColor;
}
