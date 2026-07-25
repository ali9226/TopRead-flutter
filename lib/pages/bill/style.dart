import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';

/// 样式配置（类似 CSS）
class Style {
  /// 每页请求的数据条数。
  ///
  /// 用途：
  /// 1. 传给后端作为 `page_size`。
  /// 2. 前端根据返回条数是否小于这个值判断是否还有更多数据。
  static const int pageSize = 20;

  /// 返回顶部按钮出现的阈值比例。
  ///
  /// 用途：
  /// 当前滚动距离大于“屏幕高度 * 这个比例”时，显示返回顶部按钮。
  static const double backToTopThresholdRatio = 0.5;

  /// 页面内容区域左右基础边距。
  ///
  /// 用途：
  /// 真正渲染列表内容时，会在这个基础上叠加系统安全区边距。
  static const double pageHorizontalPadding = LayoutConfig.page_horizontal_padding;

  /// 页面内容区域顶部边距。
  ///
  /// 用途：
  /// 给固定头部预留空间，避免第一张卡片被头部遮住。
  static const double pageTopPadding = 118;

  /// 页面内容区域底部边距。
  ///
  /// 用途：
  /// 给底部内容和悬浮按钮预留呼吸空间。
  static const double pageBottomPadding = 28;

  /// 顶部 Hero 卡片和后续内容之间的垂直间距。
  static const double heroBottomSpacing = 18;

  /// 列表底部操作区上方的小间距。
  static const double listBottomSpacing = 8;

  /// 固定头部渐变层的不透明度起点。
  ///
  /// 用途：
  /// 让头部背后的背景更实一些，保证标题与语言切换区域可读。
  static const double headerGradientStartOpacity = 0.98;

  /// 固定头部渐变层的中间透明度。
  ///
  /// 用途：
  /// 让头部向内容区过渡得更柔和。
  static const double headerGradientMiddleOpacity = 0.82;

  /// 页面 loading 遮罩透明度。
  static const double loadingMaskOpacity = 0.12;

  /// loading 小卡片背景透明度。
  static const double loadingCardOpacity = 0.92;

  /// loading 小卡片内边距。
  static const double loadingCardPadding = 18;

  /// loading 小卡片圆角。
  static const double loadingCardRadius = 18;

  /// 返回顶部按钮距离屏幕右边的基础间距。
  static const double backToTopRight = 18;

  /// 返回顶部按钮相对底部导航顶部继续上移的距离。
  static const double backToTopOffsetFromBottomNav = 70;

  /// 返回顶部按钮滑入滑出的动画时长。
  static const int backToTopSlideDurationMs = 240;

  /// 返回顶部按钮淡入淡出的动画时长。
  static const int backToTopOpacityDurationMs = 180;

  /// 返回顶部按钮隐藏时的纵向位移。
  ///
  /// 用途：
  /// 按钮隐藏时稍微向下滑出，而不是生硬消失。
  static const double backToTopHiddenOffsetY = 1.6;

  /// 平滑返回顶部动画时长。
  static const int scrollToTopDurationMs = 420;

  /// 距离列表底部多远时，提前触发一次自动加载更多。
  ///
  /// 用途：
  /// 不必等用户真的滑到底部才请求下一页，而是在接近底部时预加载，
  /// 让长列表连续滑动时更顺畅。
  static const double autoLoadMoreTriggerDistance = 300;

  /// 顶部装饰圆一的尺寸。
  static const double decorCircleOneSize = 220;

  /// 顶部装饰圆一的顶部偏移。
  static const double decorCircleOneTop = -80;

  /// 顶部装饰圆一的右侧偏移。
  static const double decorCircleOneRight = -40;

  /// 顶部装饰圆一在夜间模式下的透明度。
  static const double decorCircleOneDarkOpacity = 0.10;

  /// 顶部装饰圆一在浅色模式下的透明度。
  static const double decorCircleOneLightOpacity = 0.18;

  /// 顶部装饰圆二的尺寸。
  static const double decorCircleTwoSize = 160;

  /// 顶部装饰圆二的顶部偏移。
  static const double decorCircleTwoTop = 60;

  /// 顶部装饰圆二的左侧偏移。
  static const double decorCircleTwoLeft = -50;

  /// 顶部装饰圆二透明度。
  static const double decorCircleTwoOpacity = 0.08;

  /// Hero 卡片内边距。
  static const EdgeInsets heroPadding = EdgeInsets.fromLTRB(20, 18, 20, 18);

  /// Hero 卡片圆角。
  static const double heroRadius = 28;

  /// Hero 卡片阴影模糊值。
  static const double heroShadowBlur = 24;

  /// Hero 卡片阴影 Y 方向偏移。
  static const double heroShadowOffsetY = 12;

  /// Hero 卡片在夜间模式下的阴影透明度。
  static const double heroShadowDarkOpacity = 0.28;

  /// Hero 卡片在浅色模式下的阴影透明度。
  static const double heroShadowLightOpacity = 0.08;

  /// Hero 标题字号。
  static const double heroTitleSize = 24;

  /// Hero 标题字重。
  static final FontWeight heroTitleWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// Hero 标题字距。
  static const double heroTitleLetterSpacing = 0.2;

  /// Hero 副标题字号。
  static const double heroSubtitleSize = 13;

  /// Hero 副标题字重。
  static final FontWeight heroSubtitleWeight = FontConfig.adjustedWeight(FontWeight.w400);

  /// Hero 标题和副标题之间的垂直间距。
  static const double heroTitleBottomSpacing = 8;

  /// Hero 副标题在夜间模式下透明度。
  static const double heroSubtitleDarkOpacity = 0.68;

  /// 空状态卡片内边距。
  static const EdgeInsets emptyCardPadding = EdgeInsets.fromLTRB(
    24,
    36,
    24,
    28,
  );

  /// 空状态卡片圆角。
  static const double emptyCardRadius = 26;

  /// 空状态卡片边框透明度。
  static const double emptyCardBorderDarkOpacity = 0.06;
  static const double emptyCardBorderLightOpacity = 0.05;

  /// 空状态卡片阴影透明度。
  static const double emptyCardShadowDarkOpacity = 0.20;
  static const double emptyCardShadowLightOpacity = 0.05;

  /// 空状态卡片阴影模糊值。
  static const double emptyCardShadowBlur = 24;

  /// 空状态卡片阴影 Y 方向偏移。
  static const double emptyCardShadowOffsetY = 10;

  /// 空状态圆形占位图标尺寸。
  static const double emptyCircleSize = 72;

  /// 空状态圆形背景透明度。
  static const double emptyCircleDarkOpacity = 0.14;
  static const double emptyCircleLightOpacity = 0.20;

  /// 空状态数字字号。
  static const double emptyNumberSize = 28;

  /// 空状态数字字重。
  static final FontWeight emptyNumberWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 空状态主文案字号。
  static const double emptyTitleSize = 18;

  /// 空状态主文案字重。
  static final FontWeight emptyTitleWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 空状态区域垂直间距。
  static const double emptyCircleBottomSpacing = 18;
  static const double emptyActionTopSpacing = 16;

  /// 单条账单卡片底部外边距。
  static const double billCardBottomMargin = 14;

  /// 单条账单卡片内边距。
  static const EdgeInsets billCardPadding = EdgeInsets.fromLTRB(18, 18, 18, 16);

  /// 单条账单卡片圆角。
  static const double billCardRadius = 24;

  /// 单条账单卡片外层描边厚度。
  static const double billCardOuterBorderWidth = 1.2;

  /// 单条账单卡片内层圆角。
  static const double billCardInnerRadius = 22;

  /// 单条账单卡片内层边框透明度。
  static const double billCardInnerBorderDarkOpacity = 0.05;
  static const double billCardInnerBorderLightOpacity = 0.04;

  /// 卡片内层装饰圆一尺寸。
  static const double billCardGlowOneSize = 120;

  /// 卡片内层装饰圆一顶部偏移。
  static const double billCardGlowOneTop = -36;

  /// 卡片内层装饰圆一右侧偏移。
  static const double billCardGlowOneRight = -24;

  /// 卡片内层装饰圆二尺寸。
  static const double billCardGlowTwoSize = 84;

  /// 卡片内层装饰圆二底部偏移。
  static const double billCardGlowTwoBottom = -24;

  /// 卡片内层装饰圆二左侧偏移。
  static const double billCardGlowTwoLeft = -12;

  /// 卡片内层装饰圆透明度。
  static const double billCardGlowDarkOpacity = 0.08;
  static const double billCardGlowLightOpacity = 0.10;

  /// 单条账单卡片边框透明度。
  static const double billCardBorderDarkOpacity = 0.05;
  static const double billCardBorderLightOpacity = 0.05;

  /// 单条账单卡片阴影透明度。
  static const double billCardShadowDarkOpacity = 0.20;
  static const double billCardShadowLightOpacity = 0.05;

  /// 单条账单卡片阴影模糊值。
  static const double billCardShadowBlur = 22;

  /// 单条账单卡片阴影 Y 方向偏移。
  static const double billCardShadowOffsetY = 10;

  /// 卡片标题字号与字重。
  static const double billCardTitleSize = 17;
  static final FontWeight billCardTitleWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 账单头部图标圆块尺寸。
  static const double billTypeOrbSize = 42;

  /// 账单头部图标尺寸。
  static const double billTypeOrbIconSize = 24;

  /// 图标区和右侧信息区之间的横向间距。
  static const double billHeaderSpacing = 14;

  /// 账单类型值和方向标签之间的垂直间距。
  static const double billTypeValueBottomSpacing = 8;

  /// 金额方向标签与标题之间的垂直间距。
  static const double billDirectionTopSpacing = 8;

  /// 金额方向标签左右内边距。
  static const EdgeInsets billDirectionBadgePadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 5,
  );

  /// 金额方向标签圆角。
  static const double billDirectionBadgeRadius = 999;

  /// 金额方向标签字号。
  static const double billDirectionBadgeTextSize = 12;

  /// 金额方向标签字重。
  static final FontWeight billDirectionBadgeTextWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 金额方向标签浅色模式背景透明度。
  static const double billDirectionBadgeLightOpacity = 0.14;

  /// 金额方向标签深色模式背景透明度。
  static const double billDirectionBadgeDarkOpacity = 0.22;

  /// 卡片分隔线和上下内容的垂直间距。
  static const double billDividerSpacing = 14;

  /// 卡片分隔线透明度。
  static const double billDividerDarkOpacity = 0.08;
  static const double billDividerLightOpacity = 0.06;

  /// 明细信息行之间的间距。
  static const double infoRowSpacing = 10;

  /// 副文案在夜间模式下的透明度。
  static const double billCardSubTextDarkOpacity = 0.58;

  /// 金额标签内边距与圆角。
  static const EdgeInsets amountBadgePadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );
  static const double amountBadgeRadius = 16;

  /// 金额标签背景透明度。
  static const double amountBadgeDarkOpacity = 0.12;
  static const double amountBadgeLightOpacity = 0.10;

  /// 金额字号与字重。
  static const double amountTextSize = 18;
  static final FontWeight amountTextWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 金额区域最小宽度。
  static const double amountBadgeMinWidth = 108;

  /// 金额区域顶部说明字号与字重。
  static const double amountBadgeLabelSize = 10;
  static final FontWeight amountBadgeLabelWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 金额区域顶部说明透明度。
  static const double amountBadgeLabelDarkOpacity = 0.58;
  static const double amountBadgeLabelLightOpacity = 0.70;

  /// 金额区域主次文案间距。
  static const double amountBadgeInnerSpacing = 6;

  /// 左侧账单 id 复制图标与文字之间的间距。
  static const double billIdCopySpacing = 6;

  /// 左侧账单 id 复制图标尺寸。
  static const double billIdCopyIconSize = 14;

  /// 明细行左侧标签区域宽度。
  static const double infoLabelWidth = 84;

  /// 明细行左侧标签字号与字重。
  static const double infoLabelSize = 12;
  static final FontWeight infoLabelWeight = FontConfig.adjustedWeight(FontWeight.w600);

  /// 明细行左侧标签在夜间模式下的透明度。
  static const double infoLabelDarkOpacity = 0.48;

  /// 明细行右侧内容字号与字重。
  static const double infoValueSize = 13;
  static final FontWeight infoValueWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 明细行右侧内容在夜间模式下的透明度。
  static const double infoValueDarkOpacity = 0.92;

  /// 明细行复制图标与文本间距。
  static const double infoCopySpacing = 8;

  /// 明细行复制图标顶部微调。
  static const double infoCopyTopPadding = 1;

  /// 明细行复制图标尺寸。
  static const double infoCopyIconSize = 16;

  /// 明细行复制图标在夜间模式下的透明度。
  static const double infoCopyDarkOpacity = 0.72;

  /// 底部“没有更多数据”区域的上下边距。
  static const double noMoreTopPadding = 4;
  static const double noMoreBottomPadding = 12;

  /// “没有更多数据”文案字号与字重。
  static const double noMoreTextSize = 13;
  static final FontWeight noMoreTextWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// “没有更多数据”文案在夜间模式下的透明度。
  static const double noMoreDarkOpacity = 0.54;

  /// 通用按钮高度与圆角。
  static const double actionButtonHeight = 52;
  static const double actionButtonRadius = 18;

  /// 通用按钮字号与字重。
  static const double actionButtonTextSize = 15;
  static final FontWeight actionButtonTextWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 通用次级按钮边框透明度。
  static const double actionButtonBorderDarkOpacity = 0.08;
  static const double actionButtonBorderLightOpacity = 0.06;

  /// loading 状态下按钮背景透明度。
  static const double actionButtonDisabledBackgroundOpacity = 0.6;

  /// loading 状态下按钮文字透明度。
  static const double actionButtonDisabledForegroundOpacity = 0.75;
}
