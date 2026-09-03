// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';

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
  static const double pill_radius = 999;

  /// 区块纵向间距。
  static const double section_spacing = 22;

  // ==================== 可折叠头部 ====================

  /// CJK 语系的头部展开高度。
  static const double header_expanded_height_cjk = 354;

  /// 非 CJK 语系的头部展开高度。
  static const double header_expanded_height_alphabetic = 382;

  /// 折叠后的导航栏高度。
  static const double header_toolbar_height = 54;

  /// 状态筛选 Tab 区高度。
  static const double header_tab_bar_height = 54;

  /// 头部内容水平留白。
  static const double header_content_padding = 18;

  /// 头部展开导航区高度。
  static const double header_expanded_navigation_height = 48;

  /// 折叠导航两侧留白。
  static const double compact_navigation_padding = 16;

  /// 折叠导航图标按钮尺寸。
  static const double compact_action_size = 36;

  /// 折叠导航右侧图标之间的距离。
  static const double compact_action_spacing = 8;

  /// 共享头部返回点击区左侧偏移。
  static const double header_navigation_hit_inset = 14;

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

  /// 数据条高度。
  static const double metric_strip_height = 52;

  /// 头部操作按钮高度。
  static const double header_action_height = 42;

  /// 头部操作按钮圆角。
  static const double header_action_radius = 14;

  /// Tab 标签的垂直内边距。
  static const double tab_vertical_padding = 6;

  /// Tab 标签的水平内边距。
  static const double tab_horizontal_padding = 4;

  /// CJK Tab 字号。
  static const double tab_font_size_cjk = 15;

  /// 非 CJK Tab 字号。
  static const double tab_font_size_alphabetic = 13;

  /// CJK Tab 选中时的文字缩放比例。
  static const double tab_selected_scale_cjk = 1.3;

  /// 非 CJK Tab 选中时的文字缩放比例。
  static const double tab_selected_scale_alphabetic = 1.15;

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
  static const double list_header_top_spacing = 16;

  /// 作品列表头部的底部间距。
  static const double list_header_bottom_spacing = 12;

  /// 作品卡片之间的间距。
  static const double work_card_spacing = 12;

  /// 作品列表底部留白。
  static const double list_bottom_spacing = 110;

  /// CJK 主标题字号。
  static const double hero_title_size_cjk = 24;

  /// 非 CJK 主标题字号。
  static const double hero_title_size_alphabetic = 21;

  /// CJK 按钮字号。
  static const double button_font_size_cjk = 13;

  /// 非 CJK 按钮字号。
  static const double button_font_size_alphabetic = 11;

  /// CJK 状态标签字号。
  static const double status_font_size_cjk = 12;

  /// 非 CJK 状态标签字号。
  static const double status_font_size_alphabetic = 10.5;

  /// 标题字重。
  static final FontWeight title_weight = FontConfig.adjustedWeight(
    FontWeight.w600,
  );

  /// 强调字重。
  static final FontWeight emphasis_weight = FontConfig.adjustedWeight(
    FontWeight.w500,
  );

  /// 正文字重。
  static final FontWeight body_weight = FontConfig.adjustedWeight(
    FontWeight.w400,
  );

  /// 日间页面背景色。
  static const Color light_background = Color(0xFFF6F7FA);

  /// 夜间页面背景色。
  static const Color dark_background = Color(0xFF12121C);

  /// 夜间卡片颜色。
  static const Color dark_surface = Color(0xFF181A24);

  /// 夜间次级卡片颜色。
  static const Color dark_surface_secondary = Color(0xFF202330);

  /// 日间主文字颜色。
  static const Color light_primary_text = Color(0xFF17191F);

  /// 日间次级文字颜色。
  static const Color light_secondary_text = Color(0xFF777A84);

  /// 夜间次级文字颜色。
  static const Color dark_secondary_text = Color(0xFFA6A9B4);

  /// 创作者中心暖金强调色，与 ColorConstants.themeColor 一致。
  static const Color gold = Color(0xFFF8D02D);

  /// 深金色，保证日间背景上的文字对比度。
  static const Color deep_gold = Color(0xFF9A7300);

  /// 蓝色强调色。
  static const Color blue = Color(0xFF6596FF);

  /// 珊瑚强调色。
  static const Color coral = Color(0xFFFF8A72);

  /// 绿色成功色。
  static const Color green = Color(0xFF55B98A);

  /// 紫色定时状态色。
  static const Color purple = Color(0xFF9A86FF);

  /// 根据主题返回页面背景色。
  static Color background(bool is_dark) {
    return is_dark ? dark_background : light_background;
  }

  /// 根据主题返回卡片颜色。
  static Color surface(bool is_dark) {
    return is_dark ? dark_surface : Colors.white;
  }

  /// 根据主题返回次级卡片颜色。
  static Color secondary_surface(bool is_dark) {
    return is_dark ? dark_surface_secondary : const Color(0xFFF1F2F5);
  }

  /// 根据主题返回主文字颜色。
  static Color primary_text(bool is_dark) {
    return is_dark ? Colors.white : light_primary_text;
  }

  /// 根据主题返回次级文字颜色。
  static Color secondary_text(bool is_dark) {
    return is_dark ? dark_secondary_text : light_secondary_text;
  }

  /// 根据主题返回描边颜色。
  static Color border(bool is_dark) {
    return is_dark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE7E7E2);
  }

  /// 创作者头图渐变。
  static LinearGradient hero_gradient(bool is_dark) {
    if (is_dark) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFF2B2515), Color(0xFF1D1E29), dark_background],
        stops: <double>[0, 0.55, 1],
      );
    }

    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[Color(0xFFFFF0B8), Color(0xFFFFFBEC), light_background],
      stops: <double>[0, 0.54, 1],
    );
  }

  /// 头部内部半透明填充色。
  static Color header_glass(bool is_dark) {
    return is_dark
        ? Colors.white.withValues(alpha: 0.075)
        : Colors.white.withValues(alpha: 0.66);
  }

  /// Tab 选中背景色。
  static Color selected_tab_surface(bool is_dark) {
    return gold.withValues(alpha: is_dark ? 0.18 : 0.30);
  }

  /// Tab 选中文字颜色。
  static Color selected_tab_text(bool is_dark) {
    return is_dark ? gold : const Color(0xFF765600);
  }
}
