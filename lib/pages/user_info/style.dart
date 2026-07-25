import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/config/font_config.dart';

/// 样式配置（类似 CSS）
class Style {
  /// 用户中心内容区与客服区之间的垂直间距。
  static const double support_spacing = 40;

  /// 用户中心页面底部基础留白。
  static const double page_bottom_spacing = 24;

  /// 用户中心顶部背景图在夜间模式下的遮罩透明度。
  ///
  /// 这里只做轻微压暗，避免背景图在夜间模式下过亮。
  static const double top_background_dark_overlay_opacity = 0.09;

  /// 顶部区域默认横向内边距
  static const double horizontalPadding = 16;

  /// 头像尺寸
  static const double avatarSize = 70;

  /// 未登录时logo在头像内的显示尺寸
  static const double logoSize = 45;

  /// 福袋的尺寸
  static const double luckyBagSize = 34;

  /// 福袋入口动画基础下移距离
  static const double luckyBagOffsetY = 10;

  /// 语言切换区域距离状态栏下方的间距
  static const double languageTopSpacing = 0;

  /// 顶部区域基础上内边距
  static const double topPadding = 20;

  /// 顶部区域基础下内边距
  static const double bottomPadding = 20;

  /// 头像距离语种切换区域的间距
  static const double avatarSpacingFromLanguage = -10;

  /// 未登录时，头像距离登录注册按钮的间距
  static const double loginButtonSpacingFromAvatar = 20;

  /// 未登录时，福袋距离登录注册按钮的间距
  static const double guestLuckyBagSpacingFromLoginButton = 30;

  /// 已登录时，头像距离昵称的间距
  static const double nicknameSpacingFromAvatar = 10;

  /// 已登录时，昵称距离余额区块的间距
  static const double balanceSectionSpacingFromNickname = 20;

  /// 福袋右边距
  static const double luckyBagRight = 10;

  /// 右下角操作按钮区域距离右侧的间距
  static const double actionButtonRight = 12;

  /// 中日韩这类短文案语言使用的按钮最小宽度
  static const double actionButtonCompactMinWidth = 84;

  /// 英文等长文案语言使用的按钮最小宽度
  static const double actionButtonExpandedMinWidth = 110;

  /// 操作按钮最大宽度，避免长文案把按钮撑得过宽
  static const double actionButtonMaxWidth = 154;

  /// 单个操作按钮高度
  static const double actionButtonHeight = 42;

  /// 上下两个操作按钮之间的垂直间距
  static const double actionButtonSpacing = 8;

  /// 操作按钮左右内容留白
  static const EdgeInsets actionButtonPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 8,
  );

  /// 操作按钮圆角
  static const double actionButtonRadius = LayoutConfig.section_radius;

  /// 操作按钮图标尺寸
  static const double actionButtonIconSize = 20;

  /// 操作按钮图标与文案之间的间距
  static const double actionButtonIconGap = 4;

  /// 操作按钮左侧图标区域固定宽度
  static const double actionButtonIconAreaWidth = 24;

  /// 操作按钮图标承载块尺寸
  static const double actionButtonIconWrapSize = 24;

  /// 操作按钮图标承载块圆角
  static const double actionButtonIconWrapRadius = 8;

  /// 充值按钮图标承载块透明度
  static const double rechargeIconWrapOpacity = 0.16;

  /// 提现按钮图标承载块透明度
  static const double withdrawIconWrapOpacity = 0.14;

  /// 操作按钮文案字号
  static const double actionButtonTextSize = 12;

  /// 操作按钮文案字重
  static final FontWeight actionButtonFontWeight = FontConfig.adjustedWeight(FontWeight.w700);

  /// 操作按钮阴影透明度
  static const double actionButtonShadowOpacity = 0.18;

  /// 操作按钮阴影模糊值
  static const double actionButtonShadowBlur = 16;

  /// 操作按钮阴影向下偏移
  static const Offset actionButtonShadowOffset = Offset(0, 8);

  /// 提现按钮描边透明度，避免纯黑背景与背景图完全粘连
  static const double withdrawBorderOpacity = 0.18;

  /// 充值按钮的文字和图标颜色
  static const Color rechargeForegroundColor = Colors.black;

  /// 提现按钮的背景色
  static const Color withdrawBackgroundColor = Colors.black;

  /// 提现按钮的文字和图标颜色
  static final Color withdrawForegroundColor = ColorConstants.themeColor;

  /// 用户中心顶部背景图在夜间模式下的遮罩颜色。
  static final Color top_background_dark_overlay_color =
      ColorConstants.nightBackgroundColor;

  /// 刷新遮罩层透明度。
  static const double refresh_mask_opacity = 0.12;

  /// 内容装饰层高度。
  static const double content_decor_height = 320;

  /// 内容装饰：右上大光晕。
  static const double decor_glow_one_top = -16;
  static const double decor_glow_one_right = -18;
  static const double decor_glow_one_size = 180;
  static const Color decor_glow_one_dark_color = Color(0xFF8DB7FF);
  static const Color decor_glow_one_light_color = Color(0xFFFFD45A);
  static const double decor_glow_one_dark_opacity = 0.08;
  static const double decor_glow_one_light_opacity = 0.12;

  /// 内容装饰：左侧辅助光晕。
  static const double decor_glow_two_top = 92;
  static const double decor_glow_two_left = -34;
  static const double decor_glow_two_size = 140;
  static const Color decor_glow_two_dark_color = Color(0xFFFF9E80);
  static const Color decor_glow_two_light_color = Color(0xFF8DB7FF);
  static const double decor_glow_two_dark_opacity = 0.06;
  static const double decor_glow_two_light_opacity = 0.10;

  /// 内容装饰：旋转描边方块。
  static const double decor_outline_one_top = 20;
  static const double decor_outline_one_right = 42;
  static const double decor_outline_one_angle = -0.22;
  static const double decor_outline_one_size = 72;
  static const double decor_outline_one_radius = 22;
  static const double decor_outline_one_dark_opacity = 0.05;
  static const double decor_outline_one_light_opacity = 0.07;

  /// 内容装饰：右侧渐变块。
  static const double decor_block_top = 150;
  static const double decor_block_right = -12;
  static const double decor_block_angle = 0.38;
  static const double decor_block_size = 110;
  static const double decor_block_radius = 30;
  static const Color decor_block_dark_color = Color(0xFFFFD45A);
  static const Color decor_block_light_color = Color(0xFFFF9E80);
  static const double decor_block_dark_opacity = 0.04;
  static const double decor_block_light_opacity = 0.06;

  /// 内容装饰：横向渐变线。
  static const double decor_line_one_top = 62;
  static const double decor_line_one_side = 18;
  static const double decor_line_two_top = 118;
  static const double decor_line_two_side = 56;
  static const double decor_line_height = 1;
  static const double decor_line_one_dark_opacity = 0.04;
  static const double decor_line_one_light_opacity = 0.07;
  static const Color decor_line_two_dark_color = Color(0xFFFFD45A);
  static const Color decor_line_two_light_color = Color(0xFF8DB7FF);
  static const double decor_line_two_dark_opacity = 0.05;
  static const double decor_line_two_light_opacity = 0.07;
}
