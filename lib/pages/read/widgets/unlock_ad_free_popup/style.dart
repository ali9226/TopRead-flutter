import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';

/// 解锁免广告弹窗样式常量。
///
/// 所有颜色统一从 [ColorConstants] 取值，保证与 App 主题一致。
/// 字重统一使用 [FontConfig.adjustedWeight] 适配 Android/iOS 跨平台差异。
class UnlockAdFreePopupStyle {
  UnlockAdFreePopupStyle._();

  // ========== 布局尺寸 ==========

  /// 弹窗顶部圆角半径，与底部弹窗风格统一。
  static const double border_radius = 20;

  /// 顶部拖拽指示条宽度。
  static const double drag_handle_width = 40;

  /// 顶部拖拽指示条高度。
  static const double drag_handle_height = 4;

  /// 拖拽指示条圆角半径。
  static const double drag_handle_radius = 2;

  /// 弹窗顶部内边距（拖拽条与内容之间）。
  static const double top_padding = 16;

  /// 弹窗底部内边距（按钮下方留白）。
  static const double bottom_padding = 32;

  /// 弹窗内容区域水平内边距。
  static const double content_horizontal_padding = 24;

  /// 数字与下方副标题的间距。
  static const double number_subtitle_spacing = 4;

  /// 副标题与描述文字的间距。
  static const double subtitle_desc_spacing = 12;

  /// 描述文字与按钮的间距。
  static const double desc_button_spacing = 24;

  /// 按钮高度。
  static const double button_height = 48;

  /// 按钮圆角半径（胶囊形状）。
  static const double button_radius = 24;

  // ========== 字号 ==========

  /// 倒计时数字字号（视觉主体，最大最醒目）。
  static const double number_font_size = 72;

  /// 副标题字号（"免广告阅读"，数字下方说明文字）。
  static const double subtitle_font_size = 15;

  /// 描述文字字号（"观看短视频即可解锁"，引导操作）。
  static const double desc_font_size = 13;

  /// 按钮文字字号。
  static const double button_font_size = 16;

  // ========== 字重 ==========

  /// 数字字重（加粗突出）。
  static final FontWeight number_font_weight =
      FontConfig.adjustedWeight(FontWeight.w700);

  /// 副标题字重。
  static final FontWeight subtitle_font_weight =
      FontConfig.adjustedWeight(FontWeight.w500);

  /// 描述字重（常规，弱化视觉层级）。
  static final FontWeight desc_font_weight =
      FontConfig.adjustedWeight(FontWeight.w400);

  /// 按钮字重。
  static final FontWeight button_font_weight =
      FontConfig.adjustedWeight(FontWeight.w600);

  // ========== 动画 ==========

  /// 倒计时动画总时长，数字从 24 滚动到目标值的耗时。
  static const Duration countdown_duration = Duration(milliseconds: 1800);

  // ========== 颜色（统一使用 ColorConstants） ==========

  /// 日间模式弹窗背景色。
  static final Color background_color_light = ColorConstants.whiteColor;

  /// 夜间模式弹窗背景色。
  static final Color background_color_dark = ColorConstants.backgroundColor;

  /// 数字颜色（主题色 #F8D02D，最醒目的视觉焦点）。
  static final Color number_color = ColorConstants.themeColor;

  /// 日间模式副标题颜色。
  static final Color subtitle_color_light = ColorConstants.lightTextColor;

  /// 夜间模式副标题颜色。
  static final Color subtitle_color_dark = ColorConstants.whiteColor;

  /// 日间模式描述文字颜色（浅灰，弱化层级）。
  static final Color desc_color_light = ColorConstants.hintColor;

  /// 夜间模式描述文字颜色。
  static final Color desc_color_dark = ColorConstants.nightTextColor;

  /// 按钮背景色（主题色）。
  static final Color button_color = ColorConstants.themeColor;

  /// 按钮文字颜色（深色，与黄色背景形成高对比度）。
  static final Color button_text_color = ColorConstants.lightTextColor;

  /// 日间模式拖拽指示条颜色（半透明灰）。
  static Color get drag_handle_color_light =>
      ColorConstants.hintColor.withValues(alpha: 0.3);

  /// 夜间模式拖拽指示条颜色。
  static Color get drag_handle_color_dark =>
      ColorConstants.nightTextColor.withValues(alpha: 0.3);

  /// 遮罩层颜色（半透明黑，点击可关闭弹窗）。
  static const Color barrier_color = Colors.black54;
}
