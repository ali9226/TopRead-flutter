import 'package:flutter/material.dart';

/// 首页 Tab 栏样式常量。
class HomeTabBarStyle {
  /// Tab 标题字号（CJK 语系）。
  ///
  /// 中文字符方正紧凑，15px 可读性最佳。
  static const double tab_title_font_size_cjk = 15.0;

  /// Tab 标题字号（非 CJK 语系，如英语等拉丁字母语种）。
  ///
  /// 拉丁字母单词宽度更大，缩小 2px 避免 Tab 栏溢出。
  static const double tab_title_font_size_alphabetic = 13.0;

  /// Tab 选中状态缩放比例（CJK 语系）。
  ///
  /// 使用缩放而非字号变化，避免切换时文字抖动。
  /// 中文字符紧凑，1.3 倍缩放视觉上突出但不夸张。
  static const double tab_selected_scale_cjk = 1.3;

  /// Tab 选中状态缩放比例（非 CJK 语系）。
  ///
  /// 英文单词本身更宽，缩放过大会挤压相邻 Tab 空间，
  /// 降至 1.15 倍保持视觉平衡。
  static const double tab_selected_scale_alphabetic = 1.15;

  /// Tab 标签左侧内边距（CJK 语系）。
  ///
  /// 中文字符窄，16px 间距视觉舒适。
  static const double tab_label_padding_left_cjk = 16.0;

  /// Tab 标签左侧内边距（非 CJK 语系）。
  ///
  /// 英文单词更宽，缩减间距避免总宽溢出。
  static const double tab_label_padding_left_alphabetic = 10.0;

  /// Tab 列表右侧预留宽度（CJK 语系）。
  static const double tab_padding_right_cjk = 30.0;

  /// Tab 列表右侧预留宽度（非 CJK 语系）。
  ///
  /// 英文 Tab 更宽，增大右侧预留避免最后一个 Tab 被截断。
  static const double tab_padding_right_alphabetic = 40.0;

  /// 未选中文字颜色（日间模式）。
  static const Color unselected_light_color = Color(0xFF999999);

  /// 未选中文字颜色（夜间模式）。
  static const Color unselected_dark_color = Color(0xFF666666);

  /// 渐变遮罩宽度。
  static const double gradient_width = 20.0;
}
