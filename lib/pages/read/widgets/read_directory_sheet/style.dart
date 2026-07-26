import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/layout_config.dart';

/// 阅读页目录底部弹窗样式配置。
class ReadDirectorySheetStyle {
  /// 弹窗圆角。
  static const double sheet_border_radius = 32.0;

  /// 弹窗背景高度比例（相对于屏幕高度）。
  static const double sheet_height_ratio = 0.88;

  /// 顶部书籍信息区内边距。
  static const EdgeInsets header_padding = EdgeInsets.fromLTRB(
    LayoutConfig.page_horizontal_padding,
    20.0,
    LayoutConfig.page_horizontal_padding,
    18.0,
  );

  /// 顶部书籍信息区底部间距。
  static const double header_bottom_spacing = 4.0;

  /// 封面宽度。
  static const double cover_width = 58.0;

  /// 封面高度。
  static const double cover_height = 78.0;

  /// 封面圆角。
  static const double cover_border_radius = 8.0;

  /// 封面阴影模糊半径。
  static const double cover_shadow_blur_radius = 18.0;

  /// 封面阴影垂直偏移。
  static const double cover_shadow_offset_y = 8.0;

  /// 封面和书籍信息的横向间距。
  static const double header_content_spacing = 18.0;

  /// 标题和作者行的垂直间距。
  static const double title_author_spacing = 12.0;

  /// 书名文字大小。
  static const double book_title_font_size_cjk = 22.0;

  /// 非 CJK 语种书名文字大小。
  static const double book_title_font_size_alphabetic = 19.0;

  /// 作者头像半径。
  static const double author_avatar_radius = 11.0;

  /// 作者名称文字大小。
  static const double author_name_font_size_cjk = 14.0;

  /// 非 CJK 语种作者名称文字大小。
  static const double author_name_font_size_alphabetic = 12.0;

  /// 关注按钮内边距。
  static const EdgeInsets follow_button_padding = EdgeInsets.symmetric(
    horizontal: 11.0,
    vertical: 4.0,
  );

  /// 关注按钮圆角。
  static const double follow_button_radius = 18.0;

  /// 关注按钮文字大小。
  static const double follow_button_font_size_cjk = 13.0;

  /// 非 CJK 语种关注按钮文字大小。
  static const double follow_button_font_size_alphabetic = 11.0;

  /// Tab 栏高度。
  static const double tab_bar_height = 58.0;

  /// Tab 栏水平内边距。
  static const double tab_bar_horizontal_padding =
      LayoutConfig.page_horizontal_padding;

  /// Tab 文字大小（CJK）。
  static const double tab_font_size_cjk = 18.0;

  /// Tab 文字大小（非 CJK）。
  static const double tab_font_size_alphabetic = 15.0;

  /// Tab 之间的横向间距（CJK）。
  static const double tab_label_padding_cjk = 24.0;

  /// Tab 之间的横向间距（非 CJK）。
  static const double tab_label_padding_alphabetic = 15.0;

  /// Tab 指示器顶部内边距。
  static const EdgeInsets tab_indicator_padding = EdgeInsets.only(
    top: 46.0,
    left: 4.0,
    right: 4.0,
  );

  /// 目录列表内边距。
  static const EdgeInsets catalog_list_padding = EdgeInsets.fromLTRB(
    0.0,
    8.0,
    0.0,
    0.0,
  );

  /// 目录列表底部额外留白，避免最后几项被定位按钮遮住。
  static const double catalog_bottom_extra_padding = 72.0;

  /// 章节列表项垂直内边距。
  static const double chapter_item_vertical_padding = 12.0;

  /// 章节列表项最小高度（单行文字时）。
  static const double chapter_item_min_height = 44.0;

  /// 章节列表项分割线高度。
  static const double chapter_separator_height = 0.5;

  /// 目录定位首次粗略跳转使用的章节外部估算高度。
  ///
  /// 标题允许多行后，真实定位以 RenderBox 为准；该值只在目标章节尚未构建时用于先滚动到附近。
  static const double chapter_item_estimated_height = 56.0;

  /// 当前章节滚动到可视区域时在视口中的相对位置。
  static const double current_chapter_reveal_alignment = 0.18;

  /// 判断章节已舒适落入视口时保留的上下边距。
  static const double chapter_visibility_margin = 12.0;

  /// 远距离定位时按比例与实测高度迭代逼近的最大次数。
  static const int position_max_refine_attempts = 4;

  /// 章节列表项水平内边距。
  static const double chapter_item_horizontal_padding = 20.0;

  /// 当前章节左侧高亮竖条宽度。
  static const double current_chapter_bar_width = 3.0;

  /// 当前章节左侧高亮竖条圆角。
  static const double current_chapter_bar_radius = 2.0;

  /// 章节序号宽度。
  static const double chapter_number_width = 36.0;

  /// 章节序号和标题之间的间距。
  static const double chapter_number_title_spacing = 12.0;

  /// 章节标题字体大小。
  static const double chapter_title_font_size_cjk = 15.0;

  /// 非 CJK 语种章节标题字体大小。
  static const double chapter_title_font_size_alphabetic = 15.0;

  /// 章节元信息字体大小。
  static const double chapter_meta_font_size_cjk = 13.0;

  /// 非 CJK 语种章节元信息字体大小。
  static const double chapter_meta_font_size_alphabetic = 11.5;

  /// 当前章节进度条宽度。
  static const double progress_bar_width = 120.0;

  /// 当前章节进度条高度。
  static const double progress_bar_height = 3.0;

  /// 当前章节进度条圆角。
  static const double progress_bar_radius = 99.0;

  /// 定位图标容器大小。
  static const double position_icon_container_size = 48.0;

  /// 定位图标大小。
  static const double position_icon_size = 22.0;

  /// 定位按钮距离右侧的距离。
  static const double position_button_right = 18.0;

  /// 定位按钮距离底部安全区的距离。
  static const double position_button_bottom_spacing = 24.0;

  /// 滚动到当前章节的动画时长。
  static const int scroll_animation_duration_ms = 400;

  /// 定位按钮更新延迟，需略大于滚动动画时长。
  static const int position_button_update_delay_ms = 450;

  /// 获取弹窗背景色。
  static Color getSheetColor(bool is_dark) {
    return is_dark ? const Color(0xFF171B25) : const Color(0xFFFFFEFB);
  }

  /// 获取主要文字颜色。
  static Color getPrimaryTextColor(bool is_dark) {
    return is_dark ? Colors.white : const Color(0xFF111111);
  }

  /// 获取次要文字颜色。
  static Color getSubTextColor(bool is_dark) {
    return is_dark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF9A9A9A);
  }

  /// 获取分割线颜色。
  static Color getDividerColor(bool is_dark) {
    return is_dark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF1EEE8);
  }

  /// 获取普通章节卡片背景色。
  static Color getCardColor(bool is_dark) {
    return is_dark ? const Color(0xFF202633) : Colors.white;
  }

  /// 获取普通章节卡片边框色。
  static Color getCardBorderColor(bool is_dark) {
    return is_dark
        ? Colors.white.withValues(alpha: 0.055)
        : const Color(0xFFF5F2EC);
  }

  /// 获取当前章节卡片背景色。
  static Color getCurrentCardColor(bool is_dark) {
    return is_dark ? const Color(0xFF252216) : const Color(0xFFFFFCF1);
  }

  /// 获取章节序号背景色。
  static Color getChapterNumberColor(bool is_dark) {
    return is_dark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF4F4F4);
  }

  /// 获取当前章节序号背景色。
  static Color getCurrentChapterNumberColor(bool is_dark) {
    return is_dark ? const Color(0xFF3A2F12) : Colors.white;
  }

  /// 获取当前章节进度条底色。
  static Color getProgressTrackColor(bool is_dark) {
    return is_dark
        ? Colors.white.withValues(alpha: 0.12)
        : ColorConstants.dangerColor.withValues(alpha: 0.16);
  }

  /// 获取主题色衍生的文字色，避免散落硬编码金色。
  static Color getAccentTextColor(bool is_dark) {
    return is_dark
        ? ColorConstants.themeColor
        : Color.lerp(ColorConstants.themeColor, Colors.black, 0.14)!;
  }

  /// 获取主题色衍生的浅背景色。
  static Color getAccentSoftColor(bool is_dark, {double light_alpha = 0.18}) {
    return ColorConstants.themeColor.withValues(
      alpha: is_dark ? 0.14 : light_alpha,
    );
  }
}
