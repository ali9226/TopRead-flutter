// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 创作者中心统一样式。
///
/// 页面尺寸与 [LayoutConfig] 对齐，头部额外使用独立的流体尺寸，
/// 以支持展开态到紧凑态的连续过渡。
class AuthorStyle {
  const AuthorStyle._();

  /// 页面内容最大宽度，兼容平板和桌面端。
  static const double content_max_width = 760;

  /// 页面水平留白，与全局 LayoutConfig 保持一致。
  static const double page_padding = LayoutConfig.page_horizontal_padding;

  /// 区块圆角，与全局 LayoutConfig 保持一致。
  static const double section_radius = LayoutConfig.section_radius;

  /// 小型卡片圆角，与全局 LayoutConfig 保持一致。
  static const double card_radius = LayoutConfig.card_radius;

  /// 胶囊圆角。
  static const double pill_radius = LayoutConfig.radius_pill;

  /// 区块纵向间距。
  static const double section_spacing = LayoutConfig.space_22;

  // ==================== 可折叠头部 ====================

  /// 头部展开高度初始预估值（含状态栏）。
  /// 内容高度约410px，加上状态栏约47px，总计约457px。
  static const double header_expanded_height_initial = 360;

  /// 折叠后的导航栏高度。
  static const double header_toolbar_height = 54;

  /// 状态筛选 Tab 区高度。
  static const double header_tab_bar_height = 54;

  /// 头部内容水平留白，与页面内容 page_padding 保持一致。
  static const double header_content_padding = LayoutConfig.space_12;

  /// 头部展开导航区高度。
  static const double header_expanded_navigation_height =
      LayoutConfig.button_height;

  /// 折叠导航两侧留白。
  static const double compact_navigation_padding = LayoutConfig.space_16;

  /// 折叠导航图标按钮尺寸。
  static const double compact_action_size = 36;

  /// 折叠导航右侧图标之间的距离。
  static const double compact_action_spacing = LayoutConfig.space_8;

  /// 共享头部返回点击区左侧偏移。
  static const double header_navigation_hit_inset = LayoutConfig.space_14;

  /// 共享头部返回点击区顶部偏移。
  static const double header_navigation_hit_top = 3;

  /// 展开态导航操作的顶部偏移。
  static const double header_expanded_action_top = 6;

  /// 紧凑态导航操作的顶部偏移。
  static const double header_compact_action_top = 9;

  /// 导航元素允许交互的最小透明度。
  static const double header_action_interaction_opacity = 0.55;

  /// 头部装饰圆尺寸。
  static const double header_glow_size = 180;

  /// 头部装饰圆的模糊强度。
  static const double header_glow_blur = 42;

  /// 展开内容完全淡出前的折叠进度。
  static const double expanded_content_fade_end = 0.82;

  /// 紧凑导航开始淡入的折叠进度。
  static const double compact_navigation_fade_start = 0.48;

  /// 头部展开内容上移距离。
  static const double expanded_content_translate_y = 18;

  /// 数据卡片高度。
  static const double metric_strip_height = 84;

  /// 数据卡片圆角。
  static const double metric_card_radius = LayoutConfig.radius_16;

  /// 数据卡片内边距。
  static const EdgeInsets metric_card_padding = EdgeInsets.symmetric(
    horizontal: LayoutConfig.space_14,
    vertical: LayoutConfig.space_12,
  );

  /// 数据卡片之间的间距。
  static const double metric_card_spacing = LayoutConfig.space_8;

  /// 头部操作按钮高度，与作品卡片的"写新章节"按钮风格一致。
  static const double header_action_height =
      LayoutConfig.compact_control_height;

  /// 头部操作按钮圆角。
  static const double header_action_radius = LayoutConfig.radius_14;

  /// Tab 标签的垂直内边距。
  static const double tab_vertical_padding = LayoutConfig.space_6;

  /// Tab 标签的水平内边距。
  static const double tab_horizontal_padding = LayoutConfig.space_4;

  /// Tab 下划线厚度；绘制区域必须位于滚动视口内，避免标签溢出时被裁剪。
  static const double tab_indicator_width = 3;

  /// Tab 下划线距标签底部的统一偏移量。
  ///
  /// 所有页面的 TabBar 下划线应使用此常量，保证全局视觉一致。
  static const double tab_indicator_bottom_offset = 4;

  /// CJK Tab 字号。
  static const double tab_font_size_cjk = 15;

  /// 非 CJK Tab 字号。
  static const double tab_font_size_alphabetic = 13;

  /// CJK Tab 选中时的文字缩放比例。
  static const double tab_selected_scale_cjk = 1.3;

  /// 非 CJK Tab 选中时的文字缩放比例。
  static const double tab_selected_scale_alphabetic = 1.3;

  /// 滚动距离比较容差。
  static const double scroll_extent_tolerance = 0.5;

  /// 切换 Tab 时恢复吸顶状态的最大布局重试次数。
  static const int pin_restore_max_attempts = 4;

  /// 头部在展开态和吸顶态之间的自动吸附时长。
  static const Duration header_snap_duration = Duration(milliseconds: 260);

  /// 横向切换完成后，恢复目标 Tab 头部位置的过渡时长。
  static const Duration header_tab_transition_duration = Duration(
    milliseconds: 220,
  );

  /// 单个 Tab 内容返回顶部的滚动时长。
  static const Duration back_to_top_scroll_duration = Duration(
    milliseconds: 360,
  );

  /// 手指移动超过该距离后才锁定横纵手势方向。
  static const double pointer_axis_lock_distance = 6;

  /// 作品列表头部的顶部间距。
  static const double list_header_top_spacing = LayoutConfig.space_16;

  /// 作品列表头部的底部间距。
  static const double list_header_bottom_spacing = LayoutConfig.space_12;

  /// 作品卡片之间的间距。
  static const double work_card_spacing = LayoutConfig.space_12;

  /// 作品列表底部留白。
  static const double list_bottom_spacing = 110;

  /// CJK 主标题字号。
  static const double hero_title_size_cjk = 24;

  /// 非 CJK 主标题字号。
  static const double hero_title_size_alphabetic = 21;

  /// CJK 主标题2行高度（字号24 × 行高1.24 × 2行）。
  static const double hero_title_height_cjk = 60;

  /// 非 CJK 主标题2行高度（字号21 × 行高1.28 × 2行）。
  static const double hero_title_height_alphabetic = 54;

  /// CJK 副标题2行高度（字号12.5 × 行高1.42 × 2行）。
  static const double hero_subtitle_height_cjk = 36;

  /// 非 CJK 副标题2行高度（字号11.5 × 行高1.48 × 2行）。
  static const double hero_subtitle_height_alphabetic = 34;

  /// CJK 按钮字号。
  static const double button_font_size_cjk = 15;

  /// 非 CJK 按钮字号。
  static const double button_font_size_alphabetic = 13;

  /// CJK 状态标签字号。
  static const double status_font_size_cjk = 12;

  /// 非 CJK 状态标签字号。
  static const double status_font_size_alphabetic = 10.5;

  /// 标题字重。
  static final FontWeight title_weight = FontConfig.adjustedWeight(FontWeight.w600);

  /// 强调字重。
  static final FontWeight emphasis_weight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 正文字重。
  static final FontWeight body_weight = FontConfig.adjustedWeight(FontWeight.w400);

  /// 日间页面背景色。
  static const Color light_background = ColorConstants.light_background_fff6f7fa;

  /// 夜间页面背景色。
  static const Color dark_background = ColorConstants.nightBackgroundColor;

  /// 夜间卡片颜色。
  static const Color dark_surface = ColorConstants.dark_surface_ff181a24;

  /// 夜间次级卡片颜色。
  static const Color dark_surface_secondary = ColorConstants.dark_surface_secondary_ff202330;

  /// 日间主文字颜色。
  static const Color light_primary_text = ColorConstants.light_primary_text_ff17191f;

  /// 日间次级文字颜色。
  static const Color light_secondary_text = ColorConstants.light_secondary_text_ff777a84;

  /// 夜间次级文字颜色。
  static const Color dark_secondary_text = ColorConstants.dark_secondary_text_ffa6a9b4;

  /// 创作者中心暖金强调色，与 ColorConstants.themeColor 一致。
  static const Color gold = ColorConstants.themeColor;

  /// 深金色，保证日间背景上的文字对比度。
  static const Color deep_gold = ColorConstants.deep_gold_ff9a7300;

  /// 蓝色强调色。
  static const Color blue = ColorConstants.accent_sky_blue;

  /// 珊瑚强调色。
  static const Color coral = ColorConstants.coral_ffff8a72;

  /// 绿色成功色。
  static const Color green = ColorConstants.green_ff55b98a;

  /// 紫色定时状态色。
  static const Color purple = ColorConstants.purple_ff9a86ff;

  /// 根据主题返回页面背景色。
  static Color background(bool is_dark) {
    return is_dark ? dark_background : light_background;
  }

  /// 根据主题返回卡片颜色。
  static Color surface(bool is_dark) {
    return is_dark ? dark_surface : ColorConstants.whiteColor;
  }

  /// 根据主题返回次级卡片颜色。
  static Color secondary_surface(bool is_dark) {
    return is_dark ? dark_surface_secondary : ColorConstants.pages_author_center_author_style_tone;
  }

  /// 根据主题返回主文字颜色。
  static Color primary_text(bool is_dark) {
    return is_dark ? ColorConstants.whiteColor : light_primary_text;
  }

  /// 根据主题返回次级文字颜色。
  static Color secondary_text(bool is_dark) {
    return is_dark ? dark_secondary_text : light_secondary_text;
  }

  /// 根据主题返回描边颜色。
  static Color border(bool is_dark) {
    return is_dark
        ? ColorConstants.util_dialog_show_upgrade_dialog_tone_14ffffff
        : ColorConstants.pages_author_center_author_style_tone_ffe7e7e2;
  }

  /// 创作者头图渐变。
  static LinearGradient hero_gradient(bool is_dark) {
    if (is_dark) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[ColorConstants.purple_ff2b2515, ColorConstants.purple_ff1d1e29, dark_background],
        stops: <double>[0, 0.55, 1],
      );
    }

    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[ColorConstants.purple_fffff0b8, ColorConstants.purple_fffffbec, light_background],
      stops: <double>[0, 0.54, 1],
    );
  }

  /// 头部内部半透明填充色。
  static Color header_glass(bool is_dark) {
    return is_dark
        ? ColorConstants.pages_author_center_author_style_tone_13ffffff
        : ColorConstants.pages_author_center_author_style_tone_a8ffffff;
  }

  /// Tab 选中背景色。
  static Color selected_tab_surface(bool is_dark) {
    return gold.withValues(alpha: is_dark ? 0.18 : 0.30);
  }

  /// Tab 选中文字颜色。
  static Color selected_tab_text(bool is_dark) {
    return is_dark ? gold : ColorConstants.pages_author_center_author_style_tone_ff765600;
  }
}
