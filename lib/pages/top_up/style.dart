import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/config/font_config.dart';

/// 样式配置（类似 CSS）
class Style {
  /// 页面左右基础边距
  static const double pageHorizontalPadding = LayoutConfig.page_horizontal_padding;

  /// 页面顶部边距，给自定义头部预留空间
  static const double pageTopPadding = 118;

  /// 页面底部边距
  static const double pageBottomPadding = 28;

  /// 给底部固定提交按钮预留的滚动内容底部空间
  static const double bottomActionReserveHeight = 144;

  /// 横屏时底部操作区和上方内容之间的间距
  static const double bottomActionTopSpacing = 14;

  /// 顶部主卡片与下方内容间距
  static const double heroBottomSpacing = 18;

  /// 页面卡片圆角
  static const double cardRadius = 26;

  /// 页面卡片阴影模糊值
  static const double cardShadowBlur = 22;

  /// 页面卡片阴影下移距离
  static const double cardShadowOffsetY = 10;

  /// 页面卡片阴影浅色透明度
  static const double cardShadowLightOpacity = 0.06;

  /// 页面卡片阴影深色透明度
  static const double cardShadowDarkOpacity = 0.20;

  /// 页面区块内边距
  static const EdgeInsets cardPadding = EdgeInsets.fromLTRB(18, 18, 18, 18);

  /// 金额区卡片单独使用的内边距，顶部更小，避免副标题和金额列表显得太空
  static const EdgeInsets amountSectionPadding = EdgeInsets.fromLTRB(
    18,
    14,
    18,
    0,
  );

  /// Web 端金额区卡片底部内边距，避免金额网格紧贴模块底边（移动端保持 0）。
  static const double amountSectionWebBottomPadding = 20;

  /// 顶部 Hero 卡片内边距
  static const EdgeInsets heroPadding = EdgeInsets.fromLTRB(20, 20, 20, 18);

  /// Hero 卡片圆角
  static const double heroRadius = 28;

  /// Hero 标题字号
  static const double heroTitleSize = 24;

  /// Hero 标题字重
  static final FontWeight heroTitleWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// Hero 副标题字号
  static const double heroSubtitleSize = 13;

  /// Hero 副标题字重
  static final FontWeight heroSubtitleWeight = FontConfig.adjustedWeight(FontWeight.w600);

  /// 区块标题字号
  static const double sectionTitleSize = 15;

  /// 区块标题字重
  static final FontWeight sectionTitleWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 区块副文案字号
  static const double sectionHintSize = 12;

  /// 区块副文案字重
  static final FontWeight sectionHintWeight = FontConfig.adjustedWeight(FontWeight.w600);

  /// 区块之间的间距
  static const double sectionSpacing = 14;

  /// 金额区标题和金额网格之间的紧凑间距
  static const double amountSectionContentTopSpacing = 0;

  /// 金额区标题和副标题之间的间距
  static const double amountSectionTitleSpacing = 4;

  /// 金额区副标题和金额网格之间的间距
  static const double amountSectionHintSpacing = 0;

  /// 金额网格整体向上微调的像素值，用于进一步压缩视觉空白
  static const double amountGridTranslateY = -20;

  /// 单个充值类型按钮高度
  static const double typeTileHeight = 62;

  /// 充值类型下拉框圆角
  static const double typeTileRadius = 20;

  /// 充值类型按钮左右内边距
  static const EdgeInsets typeTilePadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );

  /// 类型选择器闭合态的内边距，单独压缩纵向空间避免两行文字溢出
  static const EdgeInsets typeSelectorPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  );

  /// 自定义类型选择器高度
  static const double typeSelectorHeight = 62;

  /// 类型选择器外层圆角
  static const double typeSelectorRadius = 22;

  /// 类型选择器内层圆角
  static const double typeSelectorInnerRadius = 20;

  /// 类型选择器背景渐变透明度起点
  static const double typeSelectorGradientStartOpacity = 0.14;

  /// 类型选择器背景渐变透明度终点
  static const double typeSelectorGradientEndOpacity = 0.03;

  /// 类型选择器高光描边透明度
  static const double typeSelectorHighlightOpacity = 0.18;

  /// 类型选择器箭头区宽度
  static const double typeSelectorTrailingWidth = 42;

  /// 类型选择器副标题字号
  static const double typeSelectorCaptionSize = 10;

  /// 类型选择器值字号
  static const double typeSelectorValueSize = 14;

  /// 类型选择器上下两行文字之间的间距
  static const double typeSelectorTextSpacing = 2;

  /// 类型图标圆块尺寸
  static const double typeIconWrapSize = 38;

  /// 类型图标尺寸
  static const double typeIconSize = 18;

  /// 类型按钮选中态描边宽度
  static const double typeTileBorderWidth = 1.3;

  /// 下拉菜单最大高度
  static const double typeDropdownMenuMaxHeight = 320;

  /// 金额区域网格间距
  static const double amountGridSpacing = 10;

  /// 金额按钮高度
  static const double amountTileHeight = 56;

  /// 横屏时金额按钮高度
  static const double amountTileLandscapeHeight = 42;

  /// 金额按钮圆角
  static const double amountTileRadius = 18;

  /// 横屏时金额按钮圆角
  static const double amountTileLandscapeRadius = 15;

  /// 金额按钮最小宽度，用来推导横屏时的列数
  static const double amountTileMinWidth = 108;

  /// 横屏时金额按钮最小宽度，用来让同屏出现更多列
  static const double amountTileLandscapeMinWidth = 88;

  /// 金额按钮选中态切换动画时长
  static const int amountTileAnimationMs = 300;

  /// 金额字号
  static const double amountTileTextSize = 16;

  /// 横屏时金额字号
  static const double amountTileLandscapeTextSize = 13;

  /// 横屏时金额区域网格间距
  static const double amountGridLandscapeSpacing = 8;

  /// 金额字重
  static final FontWeight amountTileTextWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 提交按钮高度
  static const double submitButtonHeight = 56;

  /// 底部固定提交区域的左右边距
  static const double bottomActionHorizontal = 18;

  /// 底部固定提交区域距离底部的间距
  static const double bottomActionBottom = 16;

  /// 底部固定提交区域内边距
  static const EdgeInsets bottomActionPadding = EdgeInsets.fromLTRB(
    16,
    14,
    16,
    16,
  );

  /// 底部固定提交区域圆角
  static const double bottomActionRadius = 24;

  /// 底部固定区内摘要胶囊之间的间距
  static const double bottomActionChipSpacing = 8;

  /// 底部固定区摘要胶囊内边距
  static const EdgeInsets bottomActionChipPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );

  /// 底部固定区摘要胶囊圆角
  static const double bottomActionChipRadius = 999;

  /// 底部固定区摘要标题字号
  static const double bottomActionChipLabelSize = 10;

  /// 底部固定区摘要值字号
  static const double bottomActionChipValueSize = 13;

  /// 提交按钮圆角
  static const double submitButtonRadius = 20;

  /// 提交按钮字号
  static const double submitButtonTextSize = 16;

  /// 提交按钮字重
  static final FontWeight submitButtonTextWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// loading 遮罩透明度
  static const double loadingMaskOpacity = 0.12;

  /// loading 小卡片内边距
  static const double loadingCardPadding = 18;

  /// loading 小卡片圆角
  static const double loadingCardRadius = 18;

  /// 装饰光斑尺寸一
  static const double decorCircleOneSize = 220;

  /// 装饰光斑尺寸二
  static const double decorCircleTwoSize = 150;

  /// 装饰光斑透明度
  static const double decorCircleOpacity = 0.10;

  /// 区块内部装饰圆一的尺寸
  static const double sectionDecorPrimarySize = 120;

  /// 区块内部装饰圆二的尺寸
  static const double sectionDecorSecondarySize = 72;

  /// 浅色模式下区块装饰透明度
  static const double sectionDecorLightOpacity = 0.08;

  /// 夜间模式下区块装饰透明度
  static const double sectionDecorDarkOpacity = 0.12;

  /// 已选金额摘要圆角
  static const double summaryRadius = 22;

  /// 已选金额摘要内边距
  static const EdgeInsets summaryPadding = EdgeInsets.fromLTRB(16, 14, 16, 14);

  /// 已选金额摘要标题字号
  static const double summaryLabelSize = 11;

  /// 已选金额摘要值字号
  static const double summaryValueSize = 22;

  /// 已选金额摘要值字重
  static final FontWeight summaryValueWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 默认高亮色
  static final Color accentColor = ColorConstants.themeColor;
}
