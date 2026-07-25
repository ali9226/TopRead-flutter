import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';

/// 提现页样式常量。
///
/// 统一收口页面里的尺寸、圆角、间距和动画时长，
/// 后续只需要改这里就能整体微调页面密度。
class WithdrawStyle {
  static const double pageHorizontalPadding = LayoutConfig.page_horizontal_padding;
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
  static const double headerBottomFadeSpacing = 22;

  /// 固定头部渐变层的不透明度起点。
  static const double headerGradientStartOpacity = 0.98;

  /// 固定头部渐变层的中间透明度。
  static const double headerGradientMiddleOpacity = 0.82;

  static const List<Color> darkBackgroundGradient = [
    Color(0xFF181B29),
    Color(0xFF11131D),
    Color(0xFF0C0D14),
  ];

  static const List<Color> lightBackgroundGradient = [
    Color(0xFFFFF2BE),
    Color(0xFFF7F7F3),
    Color(0xFFFFFFFF),
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

  static const double sectionSpacing = 16;
  static const double cardRadius = 26;
  static const EdgeInsets cardPadding = EdgeInsets.fromLTRB(18, 18, 18, 18);
  static const double cardShadowBlur = 24;
  static const double cardShadowOffsetY = 10;
  static const double cardShadowDarkOpacity = 0.18;
  static const double cardShadowLightOpacity = 0.06;

  static const List<Color> darkCardGradient = [
    Color(0xFF171926),
    Color(0xFF1C2230),
  ];

  static const List<Color> lightCardGradient = [
    Color(0xFFFFFCF6),
    Color(0xFFFFFFFF),
  ];

  static const double headerAccentWidth = 26;
  static const double headerAccentHeight = 4;
  static const double headerAccentRadius = 999;

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
  static const double amountFieldRadius = 20;
  static const EdgeInsets amountFieldPadding = EdgeInsets.fromLTRB(
    16,
    0,
    16,
    0,
  );
  static const double amountFieldDarkOpacity = 0.05;
  static const double amountFieldLightOpacity = 0.03;
  static const double amountInputSize = 24;
  static final FontWeight amountInputWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double amountInputSuffixSize = 13;

  static const double sliderTopSpacing = 18;
  static const double shortcutTopSpacing = 16;
  static const double shortcutGap = 10;
  static const double shortcutHeight = 46;
  static const double shortcutRadius = 18;
  static const double sliderLabelTopSpacing = 4;
  static const double sliderLabelSize = 11;
  static const double shortcutBorderDarkOpacity = 0.18;
  static const double shortcutBorderLightOpacity = 0.16;

  static const double typeChipGap = 10;
  static const double typeChipRadius = 18;
  static const EdgeInsets typeChipPadding = EdgeInsets.fromLTRB(14, 12, 14, 12);
  static const double typeChipBorderDarkOpacity = 0.16;
  static const double typeChipBorderLightOpacity = 0.14;
  static const double addressSectionTopSpacing = 18;
  static const double addressTitleBottomSpacing = 8;
  static const double addressFieldHeight = 58;
  static const double addressFieldRadius = 20;
  static const EdgeInsets addressFieldPadding = EdgeInsets.fromLTRB(
    16,
    10,
    10,
    10,
  );
  static const double addressFieldDarkOpacity = 0.05;
  static const double addressFieldLightOpacity = 0.03;
  static const double addressInputSize = 14;
  static final FontWeight addressInputWeight = FontConfig.adjustedWeight(FontWeight.w700);
  static const double pasteButtonHeight = 38;
  static const double pasteButtonRadius = 16;
  static const EdgeInsets pasteButtonPadding = EdgeInsets.symmetric(
    horizontal: 12,
  );
  static const double addressActionGap = 8;
  static const double addressClearButtonSize = 28;
  static const double addressClearIconSize = 14;
  static const double recordButtonHeight = 34;
  static const EdgeInsets recordButtonPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );
  static const double recordButtonRadius = 999;
  static const double submitTipsTopSpacing = 12;
  static const double submitTipsBottomSpacing = 10;
  static const double submitTipsItemSpacing = 6;
  static const double submitTipsTitleSize = 12;
  static const double submitTipsFontSize = 12;
  static const double confirmDialogRadius = 24;
  static const EdgeInsets confirmDialogPadding = EdgeInsets.fromLTRB(
    18,
    18,
    18,
    16,
  );
  static const double confirmDialogTitleSize = 17;
  static const double confirmDialogSummaryRadius = 18;
  static const EdgeInsets confirmDialogSummaryPadding = EdgeInsets.fromLTRB(
    14,
    14,
    14,
    14,
  );
  static const double confirmDialogSummaryGap = 12;
  static const double confirmDialogFieldGap = 10;
  static const double confirmDialogValueTopSpacing = 4;
  static const double confirmDialogPrimaryAmountSize = 70;
  static const double confirmDialogPrimaryAmountDecimalSize = 34;
  static const double confirmDialogWalletValueSize = 14;
  static const double confirmDialogButtonHeight = 46;
  static const double confirmDialogButtonRadius = 16;

  static const EdgeInsets summaryWrapPadding = EdgeInsets.fromLTRB(
    14,
    14,
    14,
    14,
  );
  static const double summaryWrapRadius = 18;
  static const double summaryWrapDarkOpacity = 0.05;
  static const double summaryWrapLightOpacity = 0.04;

  static const double bottomButtonBottom = 28;
}
