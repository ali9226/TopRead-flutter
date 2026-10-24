import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/layout_config.dart';

/// 更新昵称页面样式配置。
///
/// 统一管理页面的颜色、尺寸、间距、圆角等视觉参数，
/// 支持日间/夜间主题切换。
class Style {
  // ======================== 背景渐变 ========================

  /// 日间模式页面背景渐变。
  static const List<Color> lightBackgroundGradient = <Color>[
    ColorConstants.pages_change_password_style_tone,
    ColorConstants.pages_user_info_input_style_tone_fffff4de,
    ColorConstants.whiteColor,
  ];


  // ======================== 装饰光斑 ========================

  /// 右上装饰光斑。
  static const double decorCircleOneTop = -80.0;
  static const double decorCircleOneRight = -50.0;
  static const double decorCircleOneSize = 220.0;
  static const double decorCircleOneDarkOpacity = 0.10;
  static const double decorCircleOneLightOpacity = 0.18;

  /// 左侧辅助光斑。
  static const double decorCircleTwoTop = 280.0;
  static const double decorCircleTwoLeft = -52.0;
  static const double decorCircleTwoSize = 160.0;
  static const double decorCircleTwoOpacity = 0.08;

  // ======================== 页面布局 ========================

  /// 页面水平内边距。
  static const double pageHorizontalPadding =
      LayoutConfig.page_horizontal_padding;

  /// 页面底部内边距。
  static const double pageBottomPadding = LayoutConfig.space_32;

  /// 内容区域顶部偏移（导航栏下方）。
  static const double contentTopOffset = 16.0;

  // ======================== 英雄区域（标题+小猫） ========================

  /// 英雄区域顶部偏移。
  static const double heroTopOffset = 16.0;

  /// 英雄区域底部间距。
  static const double heroBottomSpacing = LayoutConfig.space_20;

  /// 页面主标题字号。
  static const double heroTitleSize = 28.0;

  /// 页面主标题字重。
  static final FontWeight heroTitleWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 页面副标题字号。
  static const double heroSubtitleSize = 14.0;

  /// 页面副标题行高（CJK 语系）。
  ///
  /// 中文字符方正紧凑，1.6 行高足够。
  static const double heroSubtitleHeightCjk = 1.6;

  /// 页面副标题行高（非 CJK 语系）。
  ///
  /// 英文字母有升部降部（b, d, p, y），需要更大行高保证可读性。
  static const double heroSubtitleHeightAlphabetic = 1.75;

  /// 页面副标题字重。
  static final FontWeight heroSubtitleWeight = FontConfig.adjustedWeight(FontWeight.w400);

  /// 英雄区域右侧装饰宽度。
  static const double heroDecorationWidth = 180.0;

  /// 英雄区域右侧装饰高度。
  static const double heroDecorationHeight = 130.0;

  // ======================== 表单卡片 ========================

  /// 表单卡片水平内边距。
  static const double formCardHorizontalPadding = LayoutConfig.space_20;

  /// 表单卡片垂直内边距。
  static const double formCardVerticalPadding = LayoutConfig.space_24;

  /// 表单卡片圆角。
  static const double formCardRadius = LayoutConfig.radius_22;

  /// 表单卡片阴影。
  static const double formCardShadowBlur = 18.0;
  static const double formCardShadowOffsetY = 8.0;
  static const double formCardShadowDarkOpacity = 0.14;
  static const double formCardShadowLightOpacity = 0.06;

  // ======================== 当前昵称行 ========================

  /// 当前昵称标签字体大小。
  static const double currentNicknameLabelSize = 15.0;

  /// 当前昵称值字体大小。
  static const double currentNicknameValueSize = 15.0;

  /// 当前昵称值字重。
  static final FontWeight currentNicknameValueWeight =
      FontConfig.adjustedWeight(FontWeight.w400);

  // ======================== 分割线 ========================

  /// 分割线上方间距。
  static const double dividerTopSpacing = LayoutConfig.space_18;

  /// 分割线下方间距。
  static const double dividerBottomSpacing = LayoutConfig.space_18;

  /// 分割线圆圈尺寸。
  static const double dividerCircleSize = 32.0;

  /// 分割线圆圈内图标大小。
  static const double dividerIconSize = LayoutConfig.icon_small;

  // ======================== 输入区域 ========================

  /// 输入标签字体大小。
  static const double inputLabelSize = 15.0;

  /// 字符计数器字体大小。
  static const double counterSize = 13.0;

  /// 输入框圆角。
  static const double inputRadius = LayoutConfig.radius_14;

  /// 输入框内边距。
  static const EdgeInsets inputPadding = EdgeInsets.fromLTRB(
    LayoutConfig.space_14,
    LayoutConfig.space_1,
    LayoutConfig.space_2,
    LayoutConfig.space_1,
  );

  /// 输入框高度。
  static const double inputHeight = 50.0;

  /// 输入框文字字号。
  static const double inputTextSize = 15.0;

  /// 输入框提示文本字号。
  static const double inputHintSize = 14.0;

  // ======================== 提交按钮 ========================

  /// 按钮区域顶部间距。
  static const double submitTopSpacing = LayoutConfig.space_28;

  /// 按钮高度。
  static const double submitButtonHeight = LayoutConfig.prominent_button_height;

  /// 按钮圆角。
  static const double submitButtonRadius = LayoutConfig.radius_28;

  /// 按钮文字大小。
  static const double submitButtonFontSize = 17.0;

  /// 按钮文字字重。
  static final FontWeight submitButtonFontWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 按钮阴影。
  static const double submitButtonShadowBlur = 18.0;
  static const double submitButtonShadowOffsetY = 8.0;
  static const double submitButtonShadowDarkOpacity = 0.28;
  static const double submitButtonShadowLightOpacity = 0.25;

  /// loading 指示器大小。
  static const double submitLoadingSize = 22.0;
  static const double submitLoadingStrokeWidth = 2.2;

  // ======================== 图标尺寸 ========================

  /// 场景图标大小。
  static const double sceneIconSize = LayoutConfig.icon_compact;

  /// 场景图标容器大小。
  static const double sceneIconContainerSize = 38.0;

  // ======================== 颜色方法 ========================

  /// 页面背景色。
  static Color backgroundColor({required bool isDark}) {
    return isDark
        ? ColorConstants.nightBackgroundColor
        : ColorConstants.lightBackgroundColor;
  }

  /// 标题颜色。
  static Color titleColor({required bool isDark}) {
    return isDark ? ColorConstants.whiteColor : ColorConstants.common_style_submit_button_style_tone_ff3d2e1a;
  }

  /// 副标题颜色。
  static Color subtitleColor({required bool isDark}) {
    return isDark
        ? ColorConstants.whiteColor.withValues(alpha: 0.65)
        : ColorConstants.components_cute_mascot_index_tone_ff8b7355;
  }

  /// 表单卡片背景。
  static Gradient formCardGradient({required bool isDark}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? <Color>[
              ColorConstants.pages_change_nickname_style_tone_ff1c2436.withValues(alpha: 0.94),
              ColorConstants.pages_change_nickname_style_tone_ff161d2a.withValues(alpha: 0.90),
            ]
          : <Color>[
              ColorConstants.pages_change_nickname_style_tone_faffffff,
              ColorConstants.pages_change_nickname_style_tone_fffffbf2.withValues(alpha: 0.96),
            ],
    );
  }

  /// 表单卡片边框色。
  static Color formCardBorderColor({required bool isDark}) {
    return isDark
        ? ColorConstants.util_dialog_show_upgrade_dialog_tone_14ffffff
        : ColorConstants.pages_change_nickname_style_tone_ffe8dcc8;
  }

  /// 表单卡片阴影色列表。
  static List<BoxShadow> formCardShadow({required bool isDark}) {
    return <BoxShadow>[
      BoxShadow(
        color: ColorConstants.shadowColor.withValues(alpha: isDark
              ? formCardShadowDarkOpacity
              : formCardShadowLightOpacity),
        blurRadius: formCardShadowBlur,
        offset: const Offset(0, formCardShadowOffsetY),
      ),
    ];
  }

  /// 场景图标背景色。
  static Color sceneIconBackground({required bool isDark}) {
    return isDark
        ? ColorConstants.pages_change_password_style_tone_fff6d76a.withValues(alpha: 0.18)
        : ColorConstants.pages_change_nickname_style_tone_fff8e4b8;
  }

  /// 场景图标颜色。
  static Color sceneIconColor({required bool isDark}) {
    return isDark ? ColorConstants.pages_change_password_style_tone_fff6d76a : ColorConstants.pages_change_nickname_style_tone_ffe8a830;
  }

  /// 当前昵称标签颜色。
  static Color currentNicknameLabelColor({required bool isDark}) {
    return isDark
        ? ColorConstants.whiteColor.withValues(alpha: 0.68)
        : ColorConstants.hintColor;
  }

  /// 当前昵称值颜色。
  static Color currentNicknameValueColor({required bool isDark}) {
    return isDark ? ColorConstants.whiteColor : ColorConstants.common_style_submit_button_style_tone_ff3d2e1a;
  }

  /// 输入标签颜色。
  static Color inputLabelColor({required bool isDark}) {
    return isDark
        ? ColorConstants.whiteColor.withValues(alpha: 0.85)
        : ColorConstants.pages_change_nickname_style_tone_ff5a4a36;
  }

  /// 字符计数器颜色。
  static Color counterColor({required bool isDark}) {
    return isDark
        ? ColorConstants.whiteColor.withValues(alpha: 0.45)
        : ColorConstants.hintColor;
  }

  /// 输入框背景色。
  static Color inputBackgroundColor({required bool isDark}) {
    return isDark ? ColorConstants.pages_change_password_style_tone_ff121a25 : ColorConstants.pages_author_center_widgets_creator_header_tone_fffffcf0;
  }

  /// 输入框边框色。
  static Color inputBorderColor({required bool isDark}) {
    return isDark
        ? ColorConstants.util_dialog_show_upgrade_dialog_tone_14ffffff
        : ColorConstants.pages_change_nickname_style_tone_ffe8dcc8;
  }

  /// 输入框聚焦边框色。
  static Color inputFocusBorderColor({required bool isDark}) {
    return isDark
        ? ColorConstants.pages_change_password_style_tone_fff6d76a.withValues(alpha: 0.5)
        : ColorConstants.pages_change_nickname_style_tone_ffe8a830.withValues(alpha: 0.6);
  }

  /// 输入文本颜色。
  static Color inputTextColor({required bool isDark}) {
    return isDark ? ColorConstants.whiteColor : ColorConstants.common_style_submit_button_style_tone_ff3d2e1a;
  }

  /// 输入提示文本颜色。
  static Color inputHintColor({required bool isDark}) {
    return isDark
        ? ColorConstants.whiteColor.withValues(alpha: 0.35)
        : ColorConstants.hintColor.withValues(alpha: 0.85);
  }

  /// 分割线颜色。
  static Color dividerColor({required bool isDark}) {
    return isDark
        ? ColorConstants.components_fixed_bottom_navigation_widgets_night_panel_decor_tone
        : ColorConstants.pages_change_nickname_style_tone_ffe0d4c0;
  }

  /// 分割线圆圈背景色。
  static Color dividerCircleColor({required bool isDark}) {
    return isDark ? ColorConstants.pages_change_nickname_style_tone_ff2a3040 : ColorConstants.pages_user_info_input_style_tone_fffff4de;
  }

  /// 分割线圆圈图标颜色。
  static Color dividerIconColor({required bool isDark}) {
    return isDark ? ColorConstants.pages_change_password_style_tone_fff6d76a : ColorConstants.pages_change_nickname_style_tone_ffd4a840;
  }

  /// 提交按钮渐变。
  static Gradient submitButtonGradient({required bool isDark}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const <Color>[ColorConstants.pages_change_password_style_tone_fff6d76a, ColorConstants.gold_button_gradient_end]
          : const <Color>[ColorConstants.pages_change_password_style_tone_ffffd861, ColorConstants.common_style_submit_button_style_tone],
    );
  }

  /// 提交按钮文字颜色。
  static Color submitButtonTextColor({required bool isDark}) {
    return isDark ? ColorConstants.common_style_submit_button_style_tone_ff3d2e1a : ColorConstants.common_style_submit_button_style_tone_ff3d2e1a;
  }

  /// 提交按钮阴影。
  static List<BoxShadow> submitButtonShadow({required bool isDark}) {
    return <BoxShadow>[
      BoxShadow(
        color: (isDark ? ColorConstants.pages_change_password_style_tone_fff6d76a : ColorConstants.common_style_submit_button_style_tone)
            .withValues(
              alpha: isDark
                  ? submitButtonShadowDarkOpacity
                  : submitButtonShadowLightOpacity,
            ),
        blurRadius: submitButtonShadowBlur,
        offset: const Offset(0, submitButtonShadowOffsetY),
      ),
    ];
  }

  /// loading 指示器颜色。
  static Color submitLoadingColor({required bool isDark}) {
    return isDark ? ColorConstants.common_style_submit_button_style_tone_ff3d2e1a : ColorConstants.common_style_submit_button_style_tone_ff3d2e1a;
  }
}
