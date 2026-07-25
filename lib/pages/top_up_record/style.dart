import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/color_config.dart';

/// 充值记录页的样式常量集中区。
///
/// 原则：
/// 1. 能提成变量的视觉值，尽量不要散落在 UI 文件里直接写死。
/// 2. 页面级、卡片级、按钮级尺寸和透明度统一集中管理。
/// 3. 后续如果要统一调视觉密度、圆角、阴影或间距，只需要改这里。
class TopUpRecordStyle {
  /// 每次分页请求的默认条数。
  static const int pageSize = 20;

  /// 距离底部多远时，提前触发自动加载更多。
  static const double autoLoadMoreTriggerDistance = 300;

  /// 返回顶部按钮出现的滚动阈值比例。
  /// 当前滚动距离超过“视口高度 * 该比例”时显示按钮。
  static const double backToTopThresholdRatio = 0.5;

  /// 页面左右基础边距。
  static const double pageHorizontalPadding = 18;

  /// 顶部首屏内容起始间距。
  ///
  /// 这里直接参考账单页的顶部留白节奏，
  /// 让 Hero 卡片和列表内容在首屏拥有更稳定的呼吸空间。
  static const double contentTopPadding = 118;

  /// 页面底部边距，给底部状态和悬浮按钮留出呼吸空间。
  static const double pageBottomPadding = 28;

  /// Hero 卡片与列表内容之间的间距。
  static const double heroBottomSpacing = 18;

  /// 列表底部状态区域和上一个卡片之间的间距。
  static const double listBottomSpacing = 10;

  /// 固定头部渐变层的起始透明度。
  static const double headerGradientStartOpacity = 0.98;

  /// 固定头部渐变层的中段透明度。
  static const double headerGradientMiddleOpacity = 0.82;

  /// 固定头部渐变向下额外延展的距离。
  ///
  /// 只让渐变包住标题栏本体会显得像一条硬边，
  /// 适当往下延展能让 Hero 卡片滚到顶部时过渡更顺。
  static const double headerBottomFadeSpacing = 22;

  /// 全屏 loading 遮罩透明度。
  static const double loadingMaskOpacity = 0.12;

  /// loading 小卡片内边距。
  static const EdgeInsets loadingCardPadding = EdgeInsets.all(18);

  /// loading 小卡片圆角。
  static const double loadingCardRadius = 18;
  static const Color darkLoadingCardColor = Color(0xFF1A1D2B);
  static const Color lightLoadingCardColor = Colors.white;

  /// 返回顶部按钮距离右侧的基础间距。
  static const double backToTopRight = 18;

  /// 返回顶部按钮距离底部的基础间距。
  static const double backToTopBottom = 26;

  /// 返回顶部按钮滑入滑出的动画时长。
  static const int backToTopSlideDurationMs = 240;

  /// 返回顶部按钮透明度动画时长。
  static const int backToTopOpacityDurationMs = 180;

  /// 返回顶部按钮隐藏时的纵向偏移量。
  static const double backToTopHiddenOffsetY = 1.6;

  /// 平滑滚回顶部的动画时长。
  static const int scrollToTopDurationMs = 420;

  /// 深色背景渐变色组。
  static const List<Color> darkBackgroundGradient = [
    Color(0xFF181B29),
    Color(0xFF11131D),
    Color(0xFF0C0D14),
  ];

  /// 浅色背景渐变色组。
  static const List<Color> lightBackgroundGradient = [
    Color(0xFFFFF3C1),
    Color(0xFFF7F7F2),
    Color(0xFFFFFFFF),
  ];

  /// 右上装饰光斑的位置和尺寸。
  static const double decorCircleOneTop = -80;
  static const double decorCircleOneRight = -40;
  static const double decorCircleOneSize = 220;
  static const double decorCircleOneDarkOpacity = 0.10;
  static const double decorCircleOneLightOpacity = 0.18;

  /// 左上辅助光斑的位置和尺寸。
  static const double decorCircleTwoTop = 60;
  static const double decorCircleTwoLeft = -50;
  static const double decorCircleTwoSize = 160;
  static const double decorCircleTwoOpacity = 0.08;

  /// Hero 卡片基础样式。
  static const EdgeInsets heroPadding = EdgeInsets.fromLTRB(20, 18, 20, 18);
  static const double heroRadius = 28;
  static const double heroShadowBlur = 24;
  static const double heroShadowOffsetY = 12;
  static const double heroShadowDarkOpacity = 0.22;
  static const double heroShadowLightOpacity = 0.07;
  static const List<Color> darkHeroGradient = [
    Color(0xFF262B3F),
    Color(0xFF181C29),
  ];
  static const List<Color> lightHeroGradient = [
    Color(0xFFFFF2B2),
    Color(0xFFF1D875),
  ];
  static const double heroTitleSize = 24;
  static final FontWeight heroTitleWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double heroSubtitleSize = 13;
  static final FontWeight heroSubtitleWeight = FontConfig.adjustedWeight(FontWeight.w400);
  static const double heroSubtitleHeight = 1.5;
  static const double heroSubtitleDarkOpacity = 0.68;
  static const double heroTitleBottomSpacing = 8;

  /// 空状态卡片样式。
  static const EdgeInsets emptyCardPadding = EdgeInsets.fromLTRB(
    24,
    36,
    24,
    28,
  );
  static const double emptyCardRadius = 26;
  static const double emptyCardBorderDarkOpacity = 0.06;
  static const double emptyCardBorderLightOpacity = 0.05;
  static const double emptyCardShadowDarkOpacity = 0.20;
  static const double emptyCardShadowLightOpacity = 0.05;
  static const double emptyCardShadowBlur = 24;
  static const double emptyCardShadowOffsetY = 10;
  static const double emptyCircleSize = 72;
  static const double emptyCircleDarkOpacity = 0.14;
  static const double emptyCircleLightOpacity = 0.20;
  static const double emptyNumberSize = 28;
  static final FontWeight emptyNumberWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double emptyTitleSize = 18;
  static final FontWeight emptyTitleWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double emptyTitleBottomSpacing = 8;
  static const double emptyCircleBottomSpacing = 18;
  static const double emptySubtitleSize = 13;
  static const double emptySubtitleHeight = 1.55;
  static final FontWeight emptySubtitleWeight = FontConfig.adjustedWeight(FontWeight.w400);
  static const double emptySubtitleDarkOpacity = 0.62;

  /// 单条记录卡片外层样式。
  static const double cardBottomMargin = 14;
  static const EdgeInsets cardPadding = EdgeInsets.fromLTRB(18, 18, 18, 16);
  static const double cardRadius = 24;
  static const double cardBorderDarkOpacity = 0.06;
  static const double cardBorderLightOpacity = 0.04;
  static const double cardShadowDarkOpacity = 0.18;
  static const double cardShadowLightOpacity = 0.05;
  static const double cardShadowBlur = 20;
  static const double cardShadowOffsetY = 10;
  static const double cardGlowOneSize = 108;
  static const double cardGlowOneTop = -26;
  static const double cardGlowOneRight = -18;
  static const double cardGlowTwoSize = 82;
  static const double cardGlowTwoBottom = -20;
  static const double cardGlowTwoLeft = -10;
  static const double cardGlowDarkOpacity = 0.07;
  static const double cardGlowLightOpacity = 0.09;
  static const List<Color> darkCardGradient = [
    Color(0xFF1A1E2D),
    Color(0xFF151826),
  ];
  static const List<Color> lightCardGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFFFFCF2),
  ];

  static const double cardTitleSize = 16;
  static final FontWeight cardTitleWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double statusChipHorizontal = 10;
  static const double statusChipVertical = 6;
  static const double statusChipRadius = 999;
  static const double statusChipDarkOpacity = 0.18;
  static const double statusChipLightOpacity = 0.12;
  static const double statusTextSize = 12;
  static final FontWeight statusTextWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 卡片内各区块之间的间距。
  static const double sectionSpacing = 14;
  static const double rowSpacing = 12;
  static const double lineSpacing = 10;
  static const int expirableAreaAnimationMs = 240;
  static const double hintDarkOpacity = 0.60;
  static const double addressTopSpacing = 12;
  static const double inlineCountdownIconSize = 16;
  static const EdgeInsets addressWrapPadding = EdgeInsets.fromLTRB(
    14,
    12,
    12,
    12,
  );
  static const double addressWrapRadius = 18;
  static const double addressWrapDarkOpacity = 0.05;
  static const double addressWrapLightOpacity = 0.03;
  static const double addressLabelSize = 11;
  static final FontWeight addressLabelWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double addressLabelBottomSpacing = 6;
  static const double addressTextSize = 13;
  static const double addressTextHeight = 1.45;
  static final FontWeight addressTextWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double addressActionGap = 8;
  static final Color countdownTextColor = ColorConstants.dangerColor;
  static final Color countdownIconColor = ColorConstants.dangerColor;
  static const double addressIconWrapSize = 34;
  static const double addressIconWrapRadius = 12;
  static const double addressIconWrapDarkOpacity = 0.16;
  static const double addressIconWrapLightOpacity = 0.12;
  static const double addressIconSize = 17;
  static const EdgeInsets qrDialogPadding = EdgeInsets.fromLTRB(20, 20, 20, 18);
  static const double qrDialogRadius = 24;
  static const double qrDialogTitleSize = 16;
  static final FontWeight qrDialogTitleWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double qrDialogTitleBottomSpacing = 16;
  static const double qrDialogQrWrapPadding = 14;
  static const double qrDialogQrWrapRadius = 22;
  static const double qrDialogQrSize = 220;
  static const double qrDialogAddressTopSpacing = 14;
  static const double qrDialogAddressSize = 13;
  static const double qrDialogAddressHeight = 1.5;
  static final FontWeight qrDialogAddressWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double qrDialogButtonTopSpacing = 16;
  static const double qrDialogButtonHeight = 48;

  /// 上方金额信息块样式。
  static const EdgeInsets infoBlockPadding = EdgeInsets.fromLTRB(
    14,
    12,
    14,
    12,
  );
  static const double infoBlockRadius = 18;
  static const double infoBlockDarkOpacity = 0.04;
  static const Color infoBlockLightColor = Color(0xFFFFF8DD);
  static const double infoLabelSize = 11;
  static final FontWeight infoLabelWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double infoLabelBottomSpacing = 6;
  static const double infoValueSize = 16;
  static final FontWeight infoValueWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 纵向信息行样式。
  static const double lineLabelWidth = 102;
  static const double lineLabelSize = 12;
  static final FontWeight lineLabelWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double lineValueSize = 13;
  static const double lineValueHeight = 1.45;
  static final FontWeight lineValueWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double lineGap = 10;

  /// 底部“加载更多 / 没有更多”提示样式。
  static const double bottomActionVertical = 18;
  static const double bottomActionTopSpacing = 8;
  static const double bottomActionTextSize = 12;
  static final FontWeight bottomActionTextWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double bottomActionDarkOpacity = 0.68;

  /// 处理中状态颜色。
  static const Color pendingStatusDarkColor = Color(0xFFFFD166);
  static const Color pendingStatusLightColor = Color(0xFFE2A400);
  static const Color failedStatusColor = Color(0xFFE85D75);

  /// 默认未知状态在深色模式下的透明度。
  static const double defaultStatusDarkOpacity = 0.72;
}
