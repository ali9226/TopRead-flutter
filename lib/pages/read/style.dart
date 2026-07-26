import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 阅读页占位页面级样式常量。
///
/// 存放页面全局、多个子组件共用或由主页面逻辑直接引用的样式配置。
class Style {
  /// 滚动交互相关配置。
  static const int page_scroll_animation_duration_ms = 320;
  static const double page_scroll_step_offset = 100;
  static const double scroll_offset_epsilon = 1;
  static const double progress_update_epsilon = 0.01;

  /// 正文三段式点击区域配置。
  static const double reading_tap_block_count = 3;
  static const double reading_tap_middle_block_factor = 2;
  static const double reading_tap_bottom_reserved_height = 96;

  /// 第一章简介区域内判定“尚未开始阅读”的顶部距离。
  static const double reading_start_near_top_threshold = 300;

  /// 章节标题越过该阅读基准线后，才将其识别为当前章节。
  static const double current_chapter_detection_top_offset = 24;

  /// 导航栏显隐的同方向累计滚动距离。
  static const double navigation_visibility_scroll_threshold = 8;

  /// 小说介绍顶部范围内强制隐藏阅读导航栏。
  static const double navigation_force_hidden_top_threshold = 300;

  /// 第一章标题距离可视区域底部达到该距离时，隐藏"上滑开始阅读"胶囊。
  static const double first_chapter_title_bottom_trigger_distance = 20;

  /// 点击"上滑开始阅读"后，第一章标题距离可视区域顶部的目标距离。
  static const double chapter_title_top_target_offset = 20;

  /// 按章节内进度恢复阅读时，章节标题与可视区域顶部保留的距离。
  static const double chapter_progress_restore_top_offset = 18;

  /// 等待阅读内容完成布局的最大尝试次数。
  static const int restore_layout_max_attempts = 100;

  /// 下拉刷新指示器最终停留位置。
  static const double refresh_indicator_displacement = 54;

  /// 提前预取/拼接下一章的触发阈值（距离底部距离）。
  ///
  /// 注意：实际是否把章节 append 到正文列表，由页面的滚动空闲状态决定。
  /// 这里故意设置得较大，保证章节正文至少提前约 2 屏进入内存/磁盘缓存，
  /// 避免用户滑到边界时才开始网络请求。
  static const double load_next_chapter_threshold = 2400;

  /// 提前预取/拼接上一章的触发阈值（距离正文顶部距离）。
  ///
  /// 由于上一章是 prepend 到列表头部，插入后还需要修正 scroll offset，
  /// 所以滚动活动期间只允许提前请求并缓存，等滚动完全 idle 后再真正插入。
  static const double load_prev_chapter_threshold = 2400;

  /// 预取触发距离至少按视口高度的倍数计算。
  ///
  /// 最终触发距离 = max(上面的固定阈值, viewportDimension * 该倍数)。
  static const double chapter_prefetch_viewport_multiplier = 2.2;

  /// 正文区块"已到达顶部"的容差阈值（像素）。
  /// 正文区块顶部距离状态栏在此范围内即视为已到达顶部，允许点击翻页和导航。
  static const double reading_section_at_top_threshold = 50;

  /// 动画时长配置。
  static const int progress_mask_animation_duration_ms = 220;
  static const int scroll_to_reading_section_duration_ms = 420;

  /// --- 颜色配置 ---

  /// 阅读页背景颜色（日间模式）。
  static const Color light_background_color = Colors.white;

  /// 阅读页背景颜色（夜间模式）。
  static final Color dark_background_color =
      ColorConstants.nightBackgroundColor;

  /// 上下导航栏背景颜色（日间模式）。
  static const Color light_navigation_bar_color = Colors.white;

  /// 上下导航栏背景颜色（夜间模式）。
  static const Color dark_navigation_bar_color = Color(0xFF1B2231);

  /// 底部进度条激活颜色。
  static final Color progress_bar_active_color = ColorConstants.themeColor;

  /// 底部进度条渐变结束颜色（如果需要渐变效果）。
  static const Color progress_bar_gradient_end_color = Color(0xFFFF9E80);
}
