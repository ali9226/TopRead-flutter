import 'package:app/config/layout_config.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

/// 阅读主操作以浅金高光、主题金和柔和尾部形成材质；收藏保持低对比玻璃层。
class WorkReadingActionsStyle {
  const WorkReadingActionsStyle._();

  static const double height = 48;
  static const double radius = LayoutConfig.radius_24;

  /// 标题列内的紧凑操作保持44dp触控范围，文案仍可随缩放自然增高。
  static const double compact_height = 44;
  static const double compact_radius = LayoutConfig.radius_22;
  static const double compact_vertical_padding = LayoutConfig.space_8;
  static const double compact_gap = LayoutConfig.space_8;
  static const double compact_icon_size = 18;
  static const double compact_icon_gap = LayoutConfig.space_8;
  static const double compact_font_size_cjk = 13;
  static const double compact_font_size_alphabetic = 12.5;
  static const double compact_min_inline_width = 164;
  static const double compact_favorite_radius = LayoutConfig.radius_22;
  static const double compact_spinner_size = 16;
  static const double compact_top_highlight_inset = LayoutConfig.space_22;
  static const double horizontal_padding = LayoutConfig.space_14;
  static const double compact_horizontal_padding = LayoutConfig.space_10;
  static const double vertical_padding = LayoutConfig.space_8;
  static const double gap = LayoutConfig.space_10;
  static const double icon_size = 18;
  static const double icon_gap = LayoutConfig.space_8;
  static const double font_size_cjk = 14;
  static const double font_size_alphabetic = 13;
  static const double line_height_cjk = 1.35;
  static const double line_height_alphabetic = 1.4;
  static final FontWeight label_weight = FontConfig.adjustedWeight(FontWeight.w600);
  static const double min_inline_width = 240;
  static const double min_trailing_width = 160;
  static const double trailing_extent = 30;
  static const double trailing_icon_size = LayoutConfig.icon_medium;
  static const double trailing_gap = LayoutConfig.space_10;
  static const double border_width = 0.8;
  static const double top_highlight_inset = LayoutConfig.space_28;
  static const double top_highlight_offset = 1;
  static const double top_highlight_height = 1;
  static const double favorite_radius = LayoutConfig.radius_24;
  static const double spinner_size = 18;
  static const double spinner_stroke = 2;
  static const double secondary_alpha = 0.09;
  static const double disabled_alpha = 0.45;
  static const Color primary_text = ColorConstants.primary_text_ff29240f;
  static const Color primary_edge = ColorConstants.primary_edge_bffff0af;
  static const Color top_highlight = ColorConstants.top_highlight_d9fff8d5;
  static const Color trailing_background = ColorConstants.trailing_background_66fffade;
  static const Color trailing_border = ColorConstants.trailing_border_66fff6c9;
  static const Color trailing_foreground = ColorConstants.trailing_foreground_ff4e3d0e;
  static const List<double> primary_gradient_stops = [0, 0.5, 1];

  static Color get primary => ColorConstants.themeColor;
  static LinearGradient get primary_gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ColorConstants.components_work_reading_actions_style_tone, primary, ColorConstants.components_work_reading_actions_style_tone_fff2be27],
    stops: primary_gradient_stops,
  );

  /// 阴影只交代按钮离背景的距离，金色材质依靠渐变和顶沿高光呈现。
  static List<BoxShadow> primary_shadows(bool on_hero, bool dark) => [
    BoxShadow(
      color: ColorConstants.shadowColor.withValues(alpha: on_hero || dark ? 0.16 : 0.09),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static Color secondary_background(bool on_hero, bool dark) =>
      (on_hero || dark ? ColorConstants.whiteColor : ColorConstants.lightTextColor).withValues(
        alpha: secondary_alpha,
      );

  static LinearGradient secondary_gradient(bool on_hero, bool dark) {
    final foreground = on_hero || dark ? ColorConstants.whiteColor : ColorConstants.lightTextColor;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        foreground.withValues(alpha: on_hero || dark ? 0.17 : 0.065),
        foreground.withValues(alpha: on_hero || dark ? 0.065 : 0.025),
      ],
    );
  }

  static Color secondary_border(bool on_hero, bool dark) =>
      (on_hero || dark ? ColorConstants.whiteColor : ColorConstants.lightTextColor).withValues(
        alpha: on_hero || dark ? 0.14 : 0.075,
      );
  static Color secondary_foreground(bool on_hero, bool dark) =>
      on_hero || dark ? ColorConstants.components_work_reading_actions_style_tone_ffe2e5eb : ColorConstants.components_work_reading_actions_style_tone_ff656e7a;
  static Color selected_foreground(bool on_hero, bool dark) =>
      on_hero || dark ? primary : ColorConstants.components_work_reading_actions_style_tone_ff987416;
}
