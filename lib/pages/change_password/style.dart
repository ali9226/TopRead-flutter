import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/layout_config.dart';

/// 修改密码页面样式常量。
///
/// 集中管理所有尺寸、颜色、间距、圆角等视觉参数，
/// 子组件通过静态方法读取，支持日间/夜间主题切换。
class Style {
  // ==================== 背景渐变 ====================

  /// 日间模式页面背景渐变色。
  static const List<Color> lightBackgroundGradient = <Color>[
    ColorConstants.pages_change_password_style_tone,
    ColorConstants.pages_change_password_style_tone_fffff3e0,
    ColorConstants.whiteColor,
  ];


  // ==================== 装饰光斑 ====================

  /// 右上装饰光斑尺寸。
  static const double decorCircleOneSize = 180;

  /// 右上装饰光斑顶部偏移。
  static const double decorCircleOneTop = -60;

  /// 右上装饰光斑右侧偏移。
  static const double decorCircleOneRight = -30;

  /// 日间模式右上光斑透明度。
  static const double decorCircleOneLightOpacity = 0.18;

  /// 夜间模式右上光斑透明度。
  static const double decorCircleOneDarkOpacity = 0.10;

  /// 左侧辅助光斑尺寸。
  static const double decorCircleTwoSize = 120;

  /// 左侧辅助光斑顶部偏移。
  static const double decorCircleTwoTop = 200;

  /// 左侧辅助光斑左侧偏移。
  static const double decorCircleTwoLeft = -40;

  /// 左侧辅助光斑透明度。
  static const double decorCircleTwoOpacity = 0.08;

  // ==================== 页面布局 ====================

  /// 页面水平内边距。
  static const double pageHorizontalPadding =
      LayoutConfig.page_horizontal_padding;

  /// 页面底部安全区内边距。
  static const double pageBottomPadding = LayoutConfig.space_28;

  /// 顶部边缘淡出高度。
  static const double pageEdgeFadeHeight = 40;

  // ==================== 英雄区域（标题+吉祥物） ====================

  /// 英雄区域顶部偏移。
  static const double heroTopOffset = 16;

  /// 英雄区域底部间距。
  static const double heroBottomSpacing = LayoutConfig.space_20;

  /// 页面主标题字号。
  static const double heroTitleSize = 28;

  /// 页面主标题字重。
  static final FontWeight heroTitleWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 页面副标题字号。
  static const double heroSubtitleSize = 14;

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
  static const double heroDecorationWidth = 180;

  /// 英雄区域右侧装饰高度。
  static const double heroDecorationHeight = 130;

  // ==================== 表单卡片 ====================

  /// 表单卡片圆角。
  static const double formCardRadius = LayoutConfig.radius_24;

  /// 表单卡片内边距。
  static const EdgeInsets formCardPadding = EdgeInsets.fromLTRB(
    LayoutConfig.space_18,
    LayoutConfig.space_20,
    LayoutConfig.space_18,
    LayoutConfig.space_20,
  );

  /// 表单卡片间距。
  static const double formCardSpacing = LayoutConfig.space_16;

  /// 日间模式表单卡片背景色。
  static const Color formCardLightBg = ColorConstants.pages_bill_widgets_bill_record_card_tone_fffffbf0;

  /// 夜间模式表单卡片背景色。
  static const Color formCardDarkBg = ColorConstants.pages_comics_detail_style_tone_ff1a1e2e;

  /// 日间模式表单卡片边框色。
  static const Color formCardLightBorder = ColorConstants.pages_change_password_style_tone_1fbfa55a;

  /// 夜间模式表单卡片边框色。
  static const Color formCardDarkBorder = ColorConstants.pages_user_info_input_style_tone_228db7ff;

  // ==================== 字段标签 ====================

  /// 字段标签字号。
  static const double fieldLabelSize = 14;

  /// 字段标签字重。
  static final FontWeight fieldLabelWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 字段标签底部间距。
  static const double fieldLabelBottomSpacing = LayoutConfig.space_10;

  /// 字段标签左侧图标尺寸。
  static const double fieldLabelIconSize = 18;

  /// 字段标签左侧图标与文字间距。
  static const double fieldLabelIconGap = LayoutConfig.space_6;

  // ==================== 输入框 ====================

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
  static const double inputHeight = 50;

  /// 输入框文字字号。
  static const double inputTextSize = 15;

  /// 输入框提示文字字号。
  static const double inputHintSize = 14;

  /// 输入框右侧图标尺寸。
  static const double inputIconSize = LayoutConfig.icon_medium;

  // ==================== 密码强度条 ====================

  /// 密码强度条高度。
  static const double strengthBarHeight = 6;

  /// 密码强度条圆角。
  static const double strengthBarRadius = LayoutConfig.radius_3;

  /// 密码强度条总段数。
  static const int strengthBarSegments = 4;

  /// 密码强度条段间距。
  static const double strengthBarSegmentGap = LayoutConfig.space_4;

  /// 密码强度标签字号。
  static const double strengthLabelSize = 12;

  /// 密码强度标签字重。
  static final FontWeight strengthLabelWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 密码强度标签与强度条间距。
  static const double strengthLabelGap = LayoutConfig.space_8;

  /// 密码强度标签与色块间距。
  static const double strengthLabelBarGap = LayoutConfig.space_10;

  // ==================== 密码小贴士卡片 ====================

  /// 小贴士卡片圆角。
  static const double tipsCardRadius = LayoutConfig.radius_20;

  /// 小贴士卡片内边距。
  static const EdgeInsets tipsCardPadding = EdgeInsets.fromLTRB(
    LayoutConfig.space_16,
    LayoutConfig.space_16,
    LayoutConfig.space_16,
    LayoutConfig.space_16,
  );

  /// 小贴士标题字号。
  static const double tipsTitleSize = 14;

  /// 小贴士标题字重。
  static final FontWeight tipsTitleWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 小贴士内容项字号。
  static const double tipsItemSize = 13;

  /// 小贴士内容项行高。
  static const double tipsItemHeight = 1.6;

  /// 小贴士内容项间距。
  static const double tipsItemSpacing = LayoutConfig.space_6;

  /// 小贴士标题与内容间距。
  static const double tipsTitleBottomSpacing = LayoutConfig.space_10;

  /// 小贴士右侧装饰宽度。
  static const double tipsDecorationWidth = 80;

  /// 小贴士右侧装饰高度。
  static const double tipsDecorationHeight = 80;

  // ==================== 提交按钮 ====================

  /// 提交按钮高度。
  static const double submitButtonHeight = 54;

  /// 提交按钮圆角。
  static const double submitButtonRadius = LayoutConfig.radius_27;

  /// 提交按钮字号。
  static const double submitButtonFontSize = 17;

  /// 提交按钮字重。
  static final FontWeight submitButtonFontWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 提交按钮loading尺寸。
  static const double submitLoadingSize = 22;

  /// 提交按钮loading线宽。
  static const double submitLoadingStrokeWidth = 2.2;

  /// 提交按钮顶部间距。
  static const double submitTopSpacing = LayoutConfig.space_20;

  // ==================== 吉祥物 ====================

  /// 吉祥物尺寸。
  static const double mascotSize = 120;

  /// 吉祥物眼睛遮挡动画时长。
  static const Duration mascotAnimationDuration = Duration(milliseconds: 300);

  // ==================== 颜色方法 ====================

  /// 页面背景色。
  static Color backgroundColor({required bool isDark}) {
    return isDark
        ? ColorConstants.nightBackgroundColor
        : ColorConstants.pages_change_password_style_tone;
  }

  /// 标题颜色。
  static Color titleColor({required bool isDark}) {
    return isDark ? ColorConstants.whiteColor : ColorConstants.lightTextColor;
  }

  /// 副标题颜色。
  static Color subtitleColor({required bool isDark}) {
    return isDark
        ? ColorConstants.whiteColor.withValues(alpha: 0.65)
        : ColorConstants.hintColor;
  }

  /// 表单卡片背景色。
  static Color formCardBackground({required bool isDark}) {
    return isDark ? formCardDarkBg : formCardLightBg;
  }

  /// 表单卡片边框色。
  static Color formCardBorder({required bool isDark}) {
    return isDark ? formCardDarkBorder : formCardLightBorder;
  }

  /// 表单卡片阴影。
  static List<BoxShadow> formCardShadow({required bool isDark}) {
    return <BoxShadow>[
      BoxShadow(
        color: ColorConstants.shadowColor.withValues(alpha: isDark ? 0.12 : 0.05),
        blurRadius: isDark ? 16 : 14,
        offset: const Offset(0, 6),
      ),
    ];
  }

  /// 字段标签颜色。
  static Color fieldLabelColor({required bool isDark}) {
    return isDark
        ? ColorConstants.whiteColor.withValues(alpha: 0.85)
        : ColorConstants.lightTextColor.withValues(alpha: 0.88);
  }

  /// 字段标签图标颜色。
  static Color fieldLabelIconColor({required bool isDark}) {
    return isDark ? ColorConstants.pages_change_password_style_tone_ffffd861 : ColorConstants.themeColor;
  }

  /// 输入框背景色。
  static Color inputBackground({required bool isDark}) {
    return isDark ? ColorConstants.pages_change_password_style_tone_ff121a25 : ColorConstants.pages_change_password_style_tone_fffffcf2;
  }

  /// 输入框边框色。
  static Color inputBorder({required bool isDark}) {
    return isDark
        ? ColorConstants.util_dialog_show_upgrade_dialog_tone_fffffff
        : ColorConstants.pages_change_password_style_tone_ffe8e0c8;
  }

  /// 输入框聚焦边框色。
  static Color inputFocusBorder({required bool isDark}) {
    return isDark ? ColorConstants.pages_change_password_style_tone_ffffd861 : ColorConstants.themeColor;
  }

  /// 输入框文字颜色。
  static Color inputTextColor({required bool isDark}) {
    return isDark ? ColorConstants.whiteColor : ColorConstants.lightTextColor;
  }

  /// 输入框提示文字颜色。
  static Color inputHintColor({required bool isDark}) {
    return isDark
        ? ColorConstants.whiteColor.withValues(alpha: 0.35)
        : ColorConstants.hintColor.withValues(alpha: 0.9);
  }

  /// 输入框右侧图标颜色。
  static Color inputIconColor({required bool isDark}) {
    return isDark
        ? ColorConstants.components_load_more_footer_index_tone
        : ColorConstants.hintColor;
  }

  /// 密码强度标签颜色。
  static Color strengthLabelColor({required bool isDark}) {
    return isDark
        ? ColorConstants.whiteColor.withValues(alpha: 0.6)
        : ColorConstants.hintColor;
  }

  /// 密码强度条未激活段颜色。
  static Color strengthBarInactive({required bool isDark}) {
    return isDark
        ? ColorConstants.components_fixed_bottom_navigation_widgets_night_panel_decor_tone
        : ColorConstants.customer_service_sheet_style_drag_bar_color_light;
  }

  /// 密码强度条弱颜色。
  static const Color strengthWeak = ColorConstants.dangerColor;

  /// 密码强度条一般颜色。
  static const Color strengthFair = ColorConstants.strength_fair_ffff9e3d;

  /// 密码强度条良好颜色。
  static const Color strengthGood = ColorConstants.successColor;

  /// 密码强度条强颜色。
  static const Color strengthStrong = ColorConstants.strength_strong_ff409eff;

  /// 小贴士卡片背景色。
  static Color tipsCardBackground({required bool isDark}) {
    return isDark
        ? ColorConstants.pages_comics_detail_style_tone_ff1a1e2e.withValues(alpha: 0.8)
        : ColorConstants.pages_change_password_style_tone.withValues(alpha: 0.9);
  }

  /// 小贴士卡片边框色。
  static Color tipsCardBorder({required bool isDark}) {
    return isDark
        ? ColorConstants.util_dialog_show_upgrade_dialog_tone_fffffff
        : ColorConstants.pages_change_password_style_tone_1fbfa55a;
  }

  /// 小贴士标题颜色。
  static Color tipsTitleColor({required bool isDark}) {
    return isDark ? ColorConstants.whiteColor : ColorConstants.lightTextColor;
  }

  /// 小贴士内容颜色。
  static Color tipsItemColor({required bool isDark}) {
    return isDark
        ? ColorConstants.whiteColor.withValues(alpha: 0.7)
        : ColorConstants.lightTextColor.withValues(alpha: 0.7);
  }

  /// 小贴士勾选图标颜色。
  static Color tipsCheckColor({required bool isDark}) {
    return isDark ? ColorConstants.pages_change_password_style_tone_ffffd861 : ColorConstants.themeColor;
  }

  /// 提交按钮渐变色。
  static Gradient submitButtonGradient({required bool isDark}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const <Color>[ColorConstants.pages_change_password_style_tone_fff6d76a, ColorConstants.gold_button_gradient_end]
          : const <Color>[ColorConstants.pages_change_password_style_tone_ffffd861, ColorConstants.common_style_submit_button_style_tone],
    );
  }

  /// 提交按钮阴影。
  static List<BoxShadow> submitButtonShadow({required bool isDark}) {
    return <BoxShadow>[
      BoxShadow(
        color: (isDark ? ColorConstants.pages_change_password_style_tone_fff6d76a : ColorConstants.common_style_submit_button_style_tone)
            .withValues(alpha: 0.30),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ];
  }
}
