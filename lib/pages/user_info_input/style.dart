// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/color_config.dart';

/// `UserInfoInput` 页面样式常量。
class Style {
  /// 页面主体横向留白。
  static const double page_horizontal_padding =
      LayoutConfig.page_horizontal_padding;

  /// 页面首屏内容顶部间距。
  static const double page_top_spacing = LayoutConfig.space_96;

  /// 页面底部留白。
  static const double page_bottom_spacing = LayoutConfig.space_28;

  /// 顶部主装饰球尺寸。
  static const double top_glow_size = 240;

  /// 顶部主装饰球顶部偏移。
  static const double top_glow_top = -92;

  /// 顶部主装饰球右侧偏移。
  static const double top_glow_right = -56;

  /// 底部装饰球尺寸。
  static const double bottom_glow_size = 220;

  /// 底部装饰球左侧偏移。
  static const double bottom_glow_left = -60;

  /// 底部装饰球底部偏移。
  static const double bottom_glow_bottom = -90;

  /// 背景纹理间距。
  static const double texture_gap = LayoutConfig.space_34;

  /// 背景纹理点半径。
  static const double texture_dot_radius = 1.2;

  /// 主表单卡片内边距。
  static const EdgeInsets form_card_padding = EdgeInsets.fromLTRB(
    LayoutConfig.space_16,
    LayoutConfig.space_16,
    LayoutConfig.space_16,
    LayoutConfig.space_16,
  );

  /// 主表单卡片圆角。
  static const double form_card_radius = LayoutConfig.radius_28;

  /// 页面标题与卡片间距。
  static const double title_bottom_spacing = LayoutConfig.space_12;

  /// 页面标题头部内边距。
  static const EdgeInsets title_wrap_padding = EdgeInsets.fromLTRB(
    LayoutConfig.space_14,
    LayoutConfig.space_14,
    LayoutConfig.space_14,
    LayoutConfig.space_14,
  );

  /// 页面标题头部圆角。
  static const double title_wrap_radius = LayoutConfig.radius_22;

  /// 页面标题装饰条宽度。
  static const double title_accent_width = 42;

  /// 页面标题装饰条高度。
  static const double title_accent_height = 6;

  /// 页面标题装饰条圆角。
  static const double title_accent_radius = LayoutConfig.radius_pill;

  /// 页面标题主文案上间距。
  static const double title_text_top_spacing = LayoutConfig.space_10;

  /// 页面标题字号。
  static const double page_title_font_size = 24;

  /// 页面标题字重。
  static final FontWeight page_title_font_weight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 输入框之间间距。
  static const double input_spacing = LayoutConfig.space_12;

  /// helper 卡片内边距。
  static const EdgeInsets helper_card_padding = EdgeInsets.fromLTRB(
    LayoutConfig.space_14,
    LayoutConfig.space_12,
    LayoutConfig.space_14,
    LayoutConfig.space_12,
  );

  /// helper 卡片圆角。
  static const double helper_card_radius = LayoutConfig.radius_16;

  /// helper 与输入区间距。
  static const double helper_bottom_spacing = LayoutConfig.space_12;

  /// helper 文字字号。
  static const double helper_text_font_size = 13;

  /// helper 文字字重。
  static final FontWeight helper_text_font_weight = FontConfig.adjustedWeight(FontWeight.w700);

  /// 输入承载区内边距。
  static const EdgeInsets input_shell_padding = EdgeInsets.fromLTRB(
    LayoutConfig.space_16,
    LayoutConfig.space_18,
    LayoutConfig.space_16,
    LayoutConfig.space_18,
  );

  /// 输入承载区圆角。
  static const double input_shell_radius = LayoutConfig.radius_20;

  /// 输入框文字字号。
  static const double input_font_size = 16;

  /// 输入框提示字号。
  static const double input_hint_font_size = 15;

  /// 输入框尾部最小宽度。
  static const double suffix_action_wrap_min_width = 24;

  /// 输入框尾部最小高度。
  static const double suffix_action_wrap_min_height = 24;

  /// 输入框尾部图标尺寸。
  static const double field_action_icon_size = LayoutConfig.icon_medium;

  /// 提交按钮上方间距。
  static const double submit_top_spacing = LayoutConfig.space_22;

  /// 提交按钮高度。
  static const double submit_button_height = 54;

  /// 提交按钮圆角。
  static const double submit_button_radius = LayoutConfig.radius_18;

  /// 提交按钮字体大小。
  static const double submit_button_font_size = 16;

  /// 提交按钮字体字重。
  static final FontWeight submit_button_font_weight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 提交按钮 loading 尺寸。
  static const double submit_loading_size = 22;

  /// 提交按钮 loading 线宽。
  static const double submit_loading_stroke_width = 2.2;

  /// 页面背景色。
  static Color background_color({required bool is_dark}) {
    return is_dark
        ? ColorConstants.nightBackgroundColor
        : ColorConstants.pages_user_info_input_style_tone;
  }

  /// 页面背景渐变。
  static List<Color> page_background_gradient({required bool is_dark}) {
    return is_dark
        ? <Color>[
            ColorConstants.pages_user_info_input_style_tone_ff0f1520,
            ColorConstants.pages_user_info_input_style_tone_ff141c28,
            ColorConstants.pages_user_info_input_style_tone_ff141c28,
          ]
        : <Color>[
            ColorConstants.pages_user_info_input_style_tone_fffff8e6,
            ColorConstants.pages_user_info_input_style_tone_fffff4de,
            ColorConstants.pages_user_info_input_style_tone_fffff4de,
          ];
  }

  /// 顶部装饰球渐变。
  static List<Color> top_glow_gradient({required bool is_dark}) {
    return <Color>[
      (is_dark ? ColorConstants.util_dialog_show_upgrade_dialog_tone_ff8db7ff : ColorConstants.message_type_accent_color_list).withValues(
        alpha: is_dark ? 0.18 : 0.24,
      ),
      ColorConstants.transparent,
    ];
  }

  /// 底部装饰球渐变。
  static List<Color> bottom_glow_gradient({required bool is_dark}) {
    return <Color>[
      (is_dark ? ColorConstants.message_type_accent_color_list_ffff9e80 : ColorConstants.util_dialog_show_upgrade_dialog_tone_ff8db7ff).withValues(
        alpha: is_dark ? 0.10 : 0.14,
      ),
      ColorConstants.transparent,
    ];
  }

  /// 背景纹理线条颜色。
  static Color texture_line_color({required bool is_dark}) {
    return is_dark
        ? ColorConstants.pages_user_info_input_style_tone_9ffffff
        : ColorConstants.pages_user_info_input_style_tone_ff0f172a.withValues(alpha: 0.035);
  }

  /// 背景纹理点颜色。
  static Color texture_dot_color({required bool is_dark}) {
    return is_dark
        ? ColorConstants.pages_change_password_style_tone_fff6d76a.withValues(alpha: 0.08)
        : ColorConstants.themeColor.withValues(alpha: 0.08);
  }

  /// 主卡片背景色。
  static Color card_background_color({required bool is_dark}) {
    return is_dark
        ? ColorConstants.pages_user_info_input_style_tone_ff141c28.withValues(alpha: 0.92)
        : ColorConstants.pages_user_info_input_style_tone_fffff4de.withValues(alpha: 0.96);
  }

  /// 主卡片渐变。
  static Gradient card_gradient({required bool is_dark}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: is_dark
          ? <Color>[
              ColorConstants.pages_user_info_input_style_tone_ff141c28.withValues(alpha: 0.94),
              ColorConstants.pages_user_info_input_style_tone_ff141c28.withValues(alpha: 0.88),
            ]
          : <Color>[
              ColorConstants.pages_user_info_input_style_tone_fffff4de.withValues(alpha: 0.98),
              ColorConstants.pages_user_info_input_style_tone_fffff4de.withValues(alpha: 0.94),
            ],
    );
  }

  /// 主卡片边框颜色。
  static Color card_border_color({required bool is_dark}) {
    return is_dark ? ColorConstants.pages_user_info_input_style_tone_228db7ff : ColorConstants.pages_change_password_style_tone_1fbfa55a;
  }

  /// 主卡片阴影。
  static List<BoxShadow> card_shadow({required bool is_dark}) {
    return <BoxShadow>[
      BoxShadow(
        color: is_dark
            ? ColorConstants.shadowColor.withValues(alpha: 0.1412)
            : ColorConstants.pages_user_info_input_style_tone_ffbfa55a.withValues(alpha: 0.06),
        blurRadius: is_dark ? 18 : 16,
        offset: const Offset(0, 8),
      ),
    ];
  }

  /// 页面标题颜色。
  static Color page_title_color({required bool is_dark}) {
    return is_dark ? ColorConstants.whiteColor : ColorConstants.lightTextColor;
  }

  /// 页面标题头部渐变。
  static Gradient title_wrap_gradient({required bool is_dark}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: is_dark
          ? <Color>[
              ColorConstants.pages_user_info_input_style_tone_ff1a2432.withValues(alpha: 0.90),
              ColorConstants.pages_user_info_input_style_tone_ff141c28.withValues(alpha: 0.88),
            ]
          : <Color>[
              ColorConstants.pages_user_info_input_style_tone_fffff6e4.withValues(alpha: 0.96),
              ColorConstants.pages_user_info_input_style_tone_fffff4de.withValues(alpha: 0.94),
            ],
    );
  }

  /// 页面标题头部边框颜色。
  static Color title_wrap_border_color({required bool is_dark}) {
    return is_dark ? ColorConstants.pages_user_info_input_style_tone_268db7ff : ColorConstants.pages_user_info_input_style_tone_22d8b24a;
  }

  /// 页面标题标签背景色。
  static Color title_chip_background_color({required bool is_dark}) {
    return is_dark ? ColorConstants.pages_user_info_input_style_tone_29f6d76a : ColorConstants.pages_user_info_input_style_tone_ffffe08a;
  }

  /// helper 卡片渐变。
  static Gradient helper_card_gradient({required bool is_dark}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: is_dark
          ? <Color>[ColorConstants.pages_user_info_input_style_tone_22f6d76a, ColorConstants.pages_user_info_input_style_tone_118db7ff]
          : <Color>[ColorConstants.pages_user_info_input_style_tone_fffff3c8, ColorConstants.pages_user_info_input_style_tone_fffffbeb],
    );
  }

  /// helper 卡片边框颜色。
  static Color helper_card_border_color({required bool is_dark}) {
    return is_dark ? ColorConstants.pages_user_info_input_style_tone_33f6d76a : ColorConstants.pages_user_info_input_style_tone_ffefd784;
  }

  /// helper 文案颜色。
  static Color helper_text_color({required bool is_dark}) {
    return is_dark ? ColorConstants.pages_user_info_input_style_tone_fff8e28e : ColorConstants.lightTextColor;
  }

  /// 输入承载区背景色。
  static Color input_shell_background_color({required bool is_dark}) {
    return is_dark ? ColorConstants.pages_change_password_style_tone_ff121a25 : ColorConstants.pages_change_password_style_tone_fffffcf2;
  }

  /// 输入承载区边框颜色。
  static Color input_shell_border_color({required bool is_dark}) {
    return is_dark
        ? ColorConstants.util_dialog_show_upgrade_dialog_tone_fffffff
        : ColorConstants.pages_change_password_style_tone_ffe8e0c8;
  }

  /// 输入框文字颜色。
  static Color input_text_color({required bool is_dark}) {
    return is_dark ? ColorConstants.whiteColor : ColorConstants.lightTextColor;
  }

  /// 输入框提示文字颜色。
  static Color input_hint_color({required bool is_dark}) {
    return is_dark
        ? ColorConstants.whiteColor.withValues(alpha: 0.38)
        : ColorConstants.hintColor.withValues(alpha: 0.92);
  }

  /// 输入框尾部图标颜色。
  static Color field_action_icon_color({required bool is_dark}) {
    return is_dark
        ? ColorConstants.pages_bookshelf_widgets_bookshelf_book_card_tone_b8ffffff
        : ColorConstants.hintColor;
  }

  /// 提交按钮渐变。
  static Gradient submit_button_gradient({required bool is_dark}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: is_dark
          ? const <Color>[ColorConstants.pages_change_password_style_tone_fff6d76a, ColorConstants.gold_button_gradient_end]
          : const <Color>[ColorConstants.pages_change_password_style_tone_ffffd861, ColorConstants.common_style_submit_button_style_tone],
    );
  }

  /// 提交按钮阴影。
  static List<BoxShadow> submit_button_shadow({required bool is_dark}) {
    return <BoxShadow>[
      BoxShadow(
        color: (is_dark ? ColorConstants.pages_change_password_style_tone_fff6d76a : ColorConstants.common_style_submit_button_style_tone)
            .withValues(alpha: 0.30),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ];
  }
}
