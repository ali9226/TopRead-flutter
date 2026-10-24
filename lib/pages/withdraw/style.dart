import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/config/color_config.dart';

/// 提现页样式常量。
///
/// 统一收口页面里的尺寸、圆角、间距和动画时长，
/// 后续只需要改这里就能整体微调页面密度。
class WithdrawStyle {
  static const double pageHorizontalPadding =
      LayoutConfig.page_horizontal_padding;
  static const double pageBottomPadding = 132;

  /// 顶部首屏内容起始间距。
  ///
  /// 提现页这里和账单页保持同一档顶部节奏，
  /// 让首屏卡片不会贴得太近，同时仍然保留上滑进入状态栏区域的能力。
  static const double contentTopPadding = 118;

  /// 固定头部渐变向下额外延展的距离。
  ///
  /// 头部如果只包住 `LanguageSelection` 本身，高度会显得过短，
  /// 滚动内容和固定标题之间的过渡会偏硬。
  /// 这里额外补一段底部渐变，让固定头部节奏更柔和。
  static const double headerBottomFadeSpacing = LayoutConfig.space_22;

  /// 固定头部渐变层的不透明度起点。
  static const double headerGradientStartOpacity = 0.98;

  /// 固定头部渐变层的中间透明度。
  static const double headerGradientMiddleOpacity = 0.82;


  static const List<Color> lightBackgroundGradient = [
    ColorConstants.pages_withdraw_style_tone_fffff2be,
    ColorConstants.warm_page_gradient_end,
    ColorConstants.whiteColor,
  ];

  static const double decorCircleOneSize = 220;
  static const double decorCircleOneTop = -86;
  static const double decorCircleOneRight = -44;
  static const double decorCircleOneDarkOpacity = 0.10;
  static const double decorCircleOneLightOpacity = 0.16;

  static const double decorCircleTwoSize = 170;
  static const double decorCircleTwoTop = 76;
  static const double decorCircleTwoLeft = -54;
  static const double decorCircleTwoOpacity = 0.08;

  static const double sectionSpacing = LayoutConfig.space_16;
  static const double cardRadius = LayoutConfig.radius_26;
  static const EdgeInsets cardPadding = EdgeInsets.fromLTRB(
    LayoutConfig.space_18,
    LayoutConfig.space_18,
    LayoutConfig.space_18,
    LayoutConfig.space_18,
  );
  static const double cardShadowBlur = 24;
  static const double cardShadowOffsetY = 10;
  static const double cardShadowDarkOpacity = 0.18;
  static const double cardShadowLightOpacity = 0.06;

  static const List<Color> darkCardGradient = [
    ColorConstants.nightHighlightColor,
    ColorConstants.pages_bill_widgets_bill_record_card_tone,
  ];

  static const List<Color> lightCardGradient = [
    ColorConstants.warm_card_gradient_start,
    ColorConstants.whiteColor,
  ];

  static const double headerAccentWidth = 26;
  static const double headerAccentHeight = 4;
  static const double headerAccentRadius = LayoutConfig.radius_pill;

  static const double titleSize = 16;
  static final FontWeight titleWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double subtitleSize = 12;
  static final FontWeight subtitleWeight = FontConfig.adjustedWeight(FontWeight.w400);
  static const double subtitleDarkOpacity = 0.68;
  static const double inlineBalanceSize = 13;
  static final FontWeight inlineBalanceWeight = FontConfig.adjustedWeight(FontWeight.w500);

  static const double balanceValueSize = 34;
  static final FontWeight balanceValueWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double balanceHintSize = 12;
  static final FontWeight balanceHintWeight = FontConfig.adjustedWeight(FontWeight.w400);

  static const double amountFieldHeight = 58;
  static const double amountFieldRadius = LayoutConfig.radius_20;
  static const EdgeInsets amountFieldPadding = EdgeInsets.fromLTRB(
    LayoutConfig.space_16,
    0,
    LayoutConfig.space_16,
    0,
  );
  static const double amountFieldDarkOpacity = 0.05;
  static const double amountFieldLightOpacity = 0.03;
  static const double amountInputSize = 24;
  static final FontWeight amountInputWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double amountInputSuffixSize = 13;

  static const double sliderTopSpacing = LayoutConfig.space_18;
  static const double shortcutTopSpacing = LayoutConfig.space_16;
  static const double shortcutGap = LayoutConfig.space_10;
  static const double shortcutHeight = 46;
  static const double shortcutRadius = LayoutConfig.radius_18;
  static const double sliderLabelTopSpacing = LayoutConfig.space_4;
  static const double sliderLabelSize = 11;
  static const double shortcutBorderDarkOpacity = 0.18;
  static const double shortcutBorderLightOpacity = 0.16;

  static const double typeChipGap = LayoutConfig.space_10;
  static const double typeChipRadius = LayoutConfig.radius_18;
  static const EdgeInsets typeChipPadding = EdgeInsets.fromLTRB(
    LayoutConfig.space_14,
    LayoutConfig.space_12,
    LayoutConfig.space_14,
    LayoutConfig.space_12,
  );
  static const double typeChipBorderDarkOpacity = 0.16;
  static const double typeChipBorderLightOpacity = 0.14;
  static const double addressSectionTopSpacing = LayoutConfig.space_18;
  static const double addressTitleBottomSpacing = LayoutConfig.space_8;
  static const double addressFieldHeight = 58;
  static const double addressFieldRadius = LayoutConfig.radius_20;
  static const EdgeInsets addressFieldPadding = EdgeInsets.fromLTRB(
    LayoutConfig.space_16,
    LayoutConfig.space_10,
    LayoutConfig.space_10,
    LayoutConfig.space_10,
  );
  static const double addressFieldDarkOpacity = 0.05;
  static const double addressFieldLightOpacity = 0.03;
  static const double addressInputSize = 14;
  static final FontWeight addressInputWeight = FontConfig.adjustedWeight(FontWeight.w700);
  static const double pasteButtonHeight = 38;
  static const double pasteButtonRadius = LayoutConfig.radius_16;
  static const EdgeInsets pasteButtonPadding = EdgeInsets.symmetric(
    horizontal: LayoutConfig.space_12,
  );
  static const double addressActionGap = LayoutConfig.space_8;
  static const double addressClearButtonSize = 28;
  static const double addressClearIconSize = 14;
  static const double recordButtonHeight = 34;
  static const EdgeInsets recordButtonPadding = EdgeInsets.symmetric(
    horizontal: LayoutConfig.space_12,
    vertical: LayoutConfig.space_8,
  );
  static const double recordButtonRadius = LayoutConfig.radius_pill;
  static const double submitTipsTopSpacing = LayoutConfig.space_12;
  static const double submitTipsBottomSpacing = LayoutConfig.space_10;
  static const double submitTipsItemSpacing = LayoutConfig.space_6;
  static const double submitTipsTitleSize = 12;
  static const double submitTipsFontSize = 12;
  static const double confirmDialogRadius = LayoutConfig.radius_24;
  static const EdgeInsets confirmDialogPadding = EdgeInsets.fromLTRB(
    LayoutConfig.space_18,
    LayoutConfig.space_18,
    LayoutConfig.space_18,
    LayoutConfig.space_16,
  );
  static const double confirmDialogTitleSize = 17;
  static const double confirmDialogSummaryRadius = LayoutConfig.radius_18;
  static const EdgeInsets confirmDialogSummaryPadding = EdgeInsets.fromLTRB(
    LayoutConfig.space_14,
    LayoutConfig.space_14,
    LayoutConfig.space_14,
    LayoutConfig.space_14,
  );
  static const double confirmDialogSummaryGap = LayoutConfig.space_12;
  static const double confirmDialogFieldGap = LayoutConfig.space_10;
  static const double confirmDialogValueTopSpacing = LayoutConfig.space_4;
  static const double confirmDialogPrimaryAmountSize = 70;
  static const double confirmDialogPrimaryAmountDecimalSize = 34;
  static const double confirmDialogWalletValueSize = 14;
  static const double confirmDialogButtonHeight = 46;
  static const double confirmDialogButtonRadius = LayoutConfig.radius_16;

  static const EdgeInsets summaryWrapPadding = EdgeInsets.fromLTRB(
    LayoutConfig.space_14,
    LayoutConfig.space_14,
    LayoutConfig.space_14,
    LayoutConfig.space_14,
  );
  static const double summaryWrapRadius = LayoutConfig.radius_18;
  static const double summaryWrapDarkOpacity = 0.05;
  static const double summaryWrapLightOpacity = 0.04;

  static const double bottomButtonBottom = 28;
}
