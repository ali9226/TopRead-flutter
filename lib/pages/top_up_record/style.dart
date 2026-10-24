import 'package:app/config/layout_config.dart';
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
  static const double pageHorizontalPadding =
      LayoutConfig.page_horizontal_padding;

  /// 顶部首屏内容起始间距。
  ///
  /// 这里直接参考账单页的顶部留白节奏，
  /// 让 Hero 卡片和列表内容在首屏拥有更稳定的呼吸空间。
  static const double contentTopPadding = 118;

  /// 页面底部边距，给底部状态和悬浮按钮留出呼吸空间。
  static const double pageBottomPadding = LayoutConfig.space_28;

  /// Hero 卡片与列表内容之间的间距。
  static const double heroBottomSpacing = LayoutConfig.space_18;

  /// 列表底部状态区域和上一个卡片之间的间距。
  static const double listBottomSpacing = LayoutConfig.space_10;

  /// 固定头部渐变层的起始透明度。
  static const double headerGradientStartOpacity = 0.98;

  /// 固定头部渐变层的中段透明度。
  static const double headerGradientMiddleOpacity = 0.82;

  /// 固定头部渐变向下额外延展的距离。
  ///
  /// 只让渐变包住标题栏本体会显得像一条硬边，
  /// 适当往下延展能让 Hero 卡片滚到顶部时过渡更顺。
  static const double headerBottomFadeSpacing = LayoutConfig.space_22;

  /// 全屏 loading 遮罩透明度。
  static const double loadingMaskOpacity = 0.12;

  /// loading 小卡片内边距。
  static const EdgeInsets loadingCardPadding = EdgeInsets.all(
    LayoutConfig.space_18,
  );

  /// loading 小卡片圆角。
  static const double loadingCardRadius = LayoutConfig.radius_18;
  static const Color darkLoadingCardColor = ColorConstants.pages_bill_widgets_bill_page_loading_overlay_tone;
  static const Color lightLoadingCardColor = ColorConstants.whiteColor;

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


  /// 浅色背景渐变色组。
  static const List<Color> lightBackgroundGradient = [
    ColorConstants.gold_page_gradient_start,
    ColorConstants.warm_page_gradient_end_alt,
    ColorConstants.whiteColor,
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
  static const EdgeInsets heroPadding = EdgeInsets.fromLTRB(
    LayoutConfig.space_20,
    LayoutConfig.space_18,
    LayoutConfig.space_20,
    LayoutConfig.space_18,
  );
  static const double heroRadius = LayoutConfig.radius_28;
  static const double heroShadowBlur = 24;
  static const double heroShadowOffsetY = 12;
  static const double heroShadowDarkOpacity = 0.22;
  static const double heroShadowLightOpacity = 0.07;
  static const List<Color> darkHeroGradient = [
    ColorConstants.night_hero_card_top,
    ColorConstants.night_hero_gradient_deep,
  ];
  static const List<Color> lightHeroGradient = [
    ColorConstants.gold_gradient_start,
    ColorConstants.gold_gradient_end,
  ];
  static const double heroTitleSize = 24;
  static final FontWeight heroTitleWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double heroSubtitleSize = 13;
  static final FontWeight heroSubtitleWeight = FontConfig.adjustedWeight(FontWeight.w400);
  static const double heroSubtitleHeight = 1.5;
  static const double heroSubtitleDarkOpacity = 0.68;
  static const double heroTitleBottomSpacing = LayoutConfig.space_8;

  /// 空状态卡片样式。
  static const EdgeInsets emptyCardPadding = EdgeInsets.fromLTRB(
    LayoutConfig.space_24,
    LayoutConfig.space_36,
    LayoutConfig.space_24,
    LayoutConfig.space_28,
  );
  static const double emptyCardRadius = LayoutConfig.radius_26;
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
  static const double emptyTitleBottomSpacing = LayoutConfig.space_8;
  static const double emptyCircleBottomSpacing = LayoutConfig.space_18;
  static const double emptySubtitleSize = 13;
  static const double emptySubtitleHeight = 1.55;
  static final FontWeight emptySubtitleWeight = FontConfig.adjustedWeight(FontWeight.w400);
  static const double emptySubtitleDarkOpacity = 0.62;

  /// 单条记录卡片外层样式。
  static const double cardBottomMargin = LayoutConfig.space_14;
  static const EdgeInsets cardPadding = EdgeInsets.fromLTRB(
    LayoutConfig.space_18,
    LayoutConfig.space_18,
    LayoutConfig.space_18,
    LayoutConfig.space_16,
  );
  static const double cardRadius = LayoutConfig.radius_24;
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
    ColorConstants.light_loading_card_color_ff1a1e2d,
    ColorConstants.light_loading_card_color_ff151826,
  ];
  static const List<Color> lightCardGradient = [
    ColorConstants.whiteColor,
    ColorConstants.pages_change_password_style_tone_fffffcf2,
  ];

  static const double cardTitleSize = 16;
  static final FontWeight cardTitleWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double statusChipHorizontal = 10;
  static const double statusChipVertical = 6;
  static const double statusChipRadius = LayoutConfig.radius_pill;
  static const double statusChipDarkOpacity = 0.18;
  static const double statusChipLightOpacity = 0.12;
  static const double statusTextSize = 12;
  static final FontWeight statusTextWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 卡片内各区块之间的间距。
  static const double sectionSpacing = LayoutConfig.space_14;
  static const double rowSpacing = LayoutConfig.space_12;
  static const double lineSpacing = LayoutConfig.space_10;
  static const int expirableAreaAnimationMs = 240;
  static const double hintDarkOpacity = 0.60;
  static const double addressTopSpacing = LayoutConfig.space_12;
  static const double inlineCountdownIconSize = LayoutConfig.icon_small;
  static const EdgeInsets addressWrapPadding = EdgeInsets.fromLTRB(
    LayoutConfig.space_14,
    LayoutConfig.space_12,
    LayoutConfig.space_12,
    LayoutConfig.space_12,
  );
  static const double addressWrapRadius = LayoutConfig.radius_18;
  static const double addressWrapDarkOpacity = 0.05;
  static const double addressWrapLightOpacity = 0.03;
  static const double addressLabelSize = 11;
  static final FontWeight addressLabelWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double addressLabelBottomSpacing = LayoutConfig.space_6;
  static const double addressTextSize = 13;
  static const double addressTextHeight = 1.45;
  static final FontWeight addressTextWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double addressActionGap = LayoutConfig.space_8;
  static final Color countdownTextColor = ColorConstants.dangerColor;
  static final Color countdownIconColor = ColorConstants.dangerColor;
  static const double addressIconWrapSize = 34;
  static const double addressIconWrapRadius = LayoutConfig.radius_12;
  static const double addressIconWrapDarkOpacity = 0.16;
  static const double addressIconWrapLightOpacity = 0.12;
  static const double addressIconSize = 17;
  static const EdgeInsets qrDialogPadding = EdgeInsets.fromLTRB(
    LayoutConfig.space_20,
    LayoutConfig.space_20,
    LayoutConfig.space_20,
    LayoutConfig.space_18,
  );
  static const double qrDialogRadius = LayoutConfig.radius_24;
  static const double qrDialogTitleSize = 16;
  static final FontWeight qrDialogTitleWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double qrDialogTitleBottomSpacing = LayoutConfig.space_16;
  static const double qrDialogQrWrapPadding = LayoutConfig.space_14;
  static const double qrDialogQrWrapRadius = LayoutConfig.radius_22;
  static const double qrDialogQrSize = 220;
  static const double qrDialogAddressTopSpacing = LayoutConfig.space_14;
  static const double qrDialogAddressSize = 13;
  static const double qrDialogAddressHeight = 1.5;
  static final FontWeight qrDialogAddressWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double qrDialogButtonTopSpacing = LayoutConfig.space_16;
  static const double qrDialogButtonHeight = LayoutConfig.button_height;

  /// 上方金额信息块样式。
  static const EdgeInsets infoBlockPadding = EdgeInsets.fromLTRB(
    LayoutConfig.space_14,
    LayoutConfig.space_12,
    LayoutConfig.space_14,
    LayoutConfig.space_12,
  );
  static const double infoBlockRadius = LayoutConfig.radius_18;
  static const double infoBlockDarkOpacity = 0.04;
  static const Color infoBlockLightColor = ColorConstants.pages_top_up_qr_code_widgets_top_up_qr_content_card_tone;
  static const double infoLabelSize = 11;
  static final FontWeight infoLabelWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double infoLabelBottomSpacing = LayoutConfig.space_6;
  static const double infoValueSize = 16;
  static final FontWeight infoValueWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 纵向信息行样式。
  static const double lineLabelWidth = 102;
  static const double lineLabelSize = 12;
  static final FontWeight lineLabelWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double lineValueSize = 13;
  static const double lineValueHeight = 1.45;
  static final FontWeight lineValueWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double lineGap = LayoutConfig.space_10;

  /// 底部“加载更多 / 没有更多”提示样式。
  static const double bottomActionVertical = 18;
  static const double bottomActionTopSpacing = LayoutConfig.space_8;
  static const double bottomActionTextSize = 12;
  static final FontWeight bottomActionTextWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static const double bottomActionDarkOpacity = 0.68;

  /// 处理中状态颜色。
  static const Color pendingStatusDarkColor = ColorConstants.pending_status_dark_color_ffffd166;
  static const Color pendingStatusLightColor = ColorConstants.pending_status_light_color_ffe2a400;
  static const Color failedStatusColor = ColorConstants.tag_color_list_ffe85d75;

  /// 默认未知状态在深色模式下的透明度。
  static const double defaultStatusDarkOpacity = 0.72;
}
