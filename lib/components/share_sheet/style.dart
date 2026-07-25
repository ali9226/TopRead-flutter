import 'package:flutter/material.dart';
import 'package:app/util/color_util.dart';
import 'package:app/config/font_config.dart';

/// 分享组件的样式常量。
///
/// 统一管理分享弹窗和卡片预览弹窗中的所有尺寸、颜色、间距等样式值，
/// 方便后续维护和主题适配。
class ShareSheetStyle {
  ShareSheetStyle._();

  // ==================== 分享弹窗 ====================

  /// 弹窗顶部拖拽指示条的宽度。
  static const double drag_bar_width = 40;

  /// 弹窗顶部拖拽指示条的高度。
  static const double drag_bar_height = 4;

  /// 弹窗顶部拖拽指示条的圆角。
  static const double drag_bar_radius = 2;

  /// 弹窗顶部拖拽指示条的颜色（日间模式）。
  static final Color drag_bar_color_light = hexToColor("#E0E0E0");

  /// 弹窗顶部拖拽指示条的颜色（夜间模式）。
  static final Color drag_bar_color_dark = hexToColor("#3A3A4A");

  /// 弹窗标题字号。
  static const double title_font_size = 18;

  /// 弹窗标题字重。
  static final FontWeight title_font_weight = FontConfig.adjustedWeight(
    FontWeight.w600,
  );

  /// 标题文字颜色（日间模式）。
  static final Color title_color_light = hexToColor("#222222");

  /// 标题文字颜色（夜间模式）。
  static final Color title_color_dark = hexToColor("#EEEEEE");

  /// 弹窗背景色（日间模式）。
  static final Color background_color_light = hexToColor("#FFFFFF");

  /// 弹窗背景色（夜间模式）。
  static final Color background_color_dark = hexToColor("#1C1C2E");

  /// 弹窗顶部圆角半径。
  static const double border_radius_top = 20;

  /// 标题区域的内边距。
  static const EdgeInsets title_padding = EdgeInsets.only(top: 12, bottom: 20);

  /// 分享图标行的水平内边距。
  static const EdgeInsets icon_row_padding = EdgeInsets.symmetric(
    horizontal: 20,
  );

  /// 分享图标行底部的内边距。
  static const EdgeInsets icon_row_bottom_padding = EdgeInsets.only(bottom: 30);

  /// 分享图标之间的间距。
  static const double icon_spacing = 16;

  /// 分享图标的大小（点击区域）。
  static const double icon_size = 58;

  /// 分享图标内部图标的大小。
  static const double icon_inner_size = 30;

  /// 分享图标下方文字的字号。
  static const double icon_label_font_size = 11;

  /// 分享图标下方文字的颜色（日间模式）。
  static final Color icon_label_color_light = hexToColor("#666666");

  /// 分享图标下方文字的颜色（夜间模式）。
  static final Color icon_label_color_dark = hexToColor("#999999");

  /// 分享图标容器的背景色（日间模式）。
  static final Color icon_bg_color_light = hexToColor("#F5F5F5");

  /// 分享图标容器的背景色（夜间模式）。
  static final Color icon_bg_color_dark = hexToColor("#2A2A3C");

  // ==================== 卡片预览 ====================

  /// 卡片预览弹窗标题字号。
  static const double preview_title_font_size = 18;

  /// 卡片预览弹窗标题字重。
  static final FontWeight preview_title_font_weight = FontConfig.adjustedWeight(
    FontWeight.w600,
  );

  /// 卡片预览区域的水平内边距。
  static const double preview_card_horizontal_padding = 24;

  /// 卡片预览卡片的圆角半径。
  static const double preview_card_radius = 22;

  /// 海报设计稿宽度；预览时只缩放显示，导出时始终使用这个逻辑尺寸。
  static const double poster_design_width = 342;

  /// 海报设计稿高度。
  static const double poster_design_height = 438;

  /// 海报预览允许占用的最大高度。
  static const double poster_preview_max_height = 438;

  /// 海报彩色外框宽度。
  static const double poster_frame_width = 7;

  /// 海报白色内容区圆角。
  static const double poster_content_radius = 16;

  /// 海报纸张背景色。
  static const Color poster_paper_color = Color(0xFFFFFEFC);

  /// 墨黑海报纸张背景色，避免使用绝对纯黑造成文字边缘过于生硬。
  static const Color poster_paper_color_dark = Color(0xFF111214);

  /// 海报主文字颜色。
  static const Color poster_primary_text_color = Color(0xFF171717);

  /// 墨黑海报主文字颜色，使用柔和米白降低黑底眩光。
  static const Color poster_primary_text_color_dark = Color(0xFFF3F0E9);

  /// 海报次要文字颜色。
  static const Color poster_secondary_text_color = Color(0xFF8A8985);

  /// 墨黑海报次要文字颜色。
  static const Color poster_secondary_text_color_dark = Color(0xFFA9A7A1);

  /// 墨黑海报 Logo 的浅色承载面，保证原始黑黄 Logo 清晰可见。
  static const Color poster_brand_surface_color_dark = Color(0xFFF4F0E7);

  /// 海报二维码颜色。
  static const Color poster_qr_color = Color(0xFF232323);

  /// 摘录区内边距。
  static const EdgeInsets poster_excerpt_padding = EdgeInsets.fromLTRB(
    22,
    17,
    22,
    16,
  );

  /// 引号占用的垂直高度。
  static const double poster_quote_mark_height = 42;

  /// 引号字号。
  static const double poster_quote_mark_font_size = 62;

  /// 中日韩文字摘录字号。
  static const double poster_excerpt_font_size_cjk = 17;

  /// 字母文字摘录字号。
  static const double poster_excerpt_font_size_alphabetic = 15;

  /// 摘录最大行数。
  static const int poster_excerpt_max_lines = 7;

  /// 摘录与用户信息之间的间距。
  static const double poster_excerpt_user_spacing = 10;

  /// 用户头像大小。
  static const double poster_avatar_size = 34;

  /// 头像与文字间距。
  static const double poster_avatar_text_spacing = 9;

  /// 用户昵称字号。
  static const double poster_nickname_font_size = 12;

  /// 日期字号。
  static const double poster_date_font_size = 10;

  /// 品牌标识大小。
  static const double poster_brand_mark_size = 34;

  /// 底部书籍信息区高度。
  static const double poster_footer_height = 108;

  /// 底部书籍信息区内边距。
  static const EdgeInsets poster_footer_padding = EdgeInsets.fromLTRB(
    16,
    14,
    14,
    14,
  );

  /// 书籍封面宽度。
  static const double poster_cover_width = 50;

  /// 书籍封面高度。
  static const double poster_cover_height = 70;

  /// 书籍封面圆角。
  static const double poster_cover_radius = 6;

  /// 封面与文字间距。
  static const double poster_cover_text_spacing = 11;

  /// 小说标题字号。
  static const double poster_title_font_size = 13;

  /// 小说作者字号。
  static const double poster_author_font_size = 10;

  /// 共读提示字号。
  static const double poster_cta_font_size = 9;

  /// 二维码与文字间距。
  static const double poster_qr_spacing = 9;

  /// 二维码尺寸。
  static const double poster_qr_size = 58;

  /// 摘录纸张的小尾巴尺寸。
  static const double poster_notch_size = 12;

  /// 摘录纸张的小尾巴距左侧位置。
  static const double poster_notch_left = 30;

  /// 墨黑海报在色板列表中的位置。
  static const int card_dark_style_index = 1;

  /// 海报外框配色，使用低饱和纸张色，避免抢夺正文视觉焦点。
  static const List<List<Color>> card_gradient_colors = [
    [Color(0xFFE7E2D8), Color(0xFFD8D1C4)],
    [Color(0xFF050506), Color(0xFF292A2E)],
    [Color(0xFFDCE6F1), Color(0xFFC8D7E8)],
    [Color(0xFFF0DDD7), Color(0xFFE8C9C0)],
    [Color(0xFFDCE9DE), Color(0xFFC9DDCD)],
    [Color(0xFFE6DEF0), Color(0xFFD7CBE8)],
  ];

  /// 每套海报配色的强调色。
  static const List<Color> card_accent_colors = <Color>[
    Color(0xFF8A755D),
    Color(0xFFC8A96B),
    Color(0xFF557AA0),
    Color(0xFFA86758),
    Color(0xFF557D60),
    Color(0xFF765D91),
  ];

  /// 每套海报配色的书籍信息区底色。
  static const List<Color> card_footer_colors = <Color>[
    Color(0xFFF3F0EA),
    Color(0xFF1D1E21),
    Color(0xFFF0F4F8),
    Color(0xFFF8F0ED),
    Color(0xFFF0F5F1),
    Color(0xFFF4F0F8),
  ];

  /// 卡片指示器（小圆点）的大小。
  static const double indicator_size = 14;

  /// 卡片指示器选中时的宽度。
  static const double indicator_active_width = 22;

  /// 每个色板指示器固定占用的槽位尺寸，防止选中动画改变整行高度。
  static const double indicator_slot_size = 30;

  /// 卡片指示器的间距。
  static const double indicator_spacing = 8;

  /// 色板指示器顶部留白。
  static const double indicator_top_padding = 12;

  /// 色板指示器与下方分享列表之间的留白。
  static const double indicator_bottom_padding = 20;

  /// 卡片指示器的圆角。
  static const double indicator_radius = 3;

  /// 卡片指示器外圈颜色。
  static const Color indicator_ring_color = Color(0xFF242424);

  /// 底部操作栏的图标大小。
  static const double action_icon_size = 52;

  /// 底部操作栏内部图标大小。
  static const double action_icon_inner_size = 22;

  /// 底部操作栏的间距。
  static const double action_icon_spacing = 16;

  /// 保存按钮的背景色。
  static final Color save_button_bg_color = hexToColor("#F8D02D");

  /// 保存按钮的文字颜色。
  static final Color save_button_text_color = hexToColor("#222222");

  /// 保存按钮的字号。
  static const double save_button_font_size = 13;

  /// 保存按钮的字重。
  static final FontWeight save_button_font_weight = FontConfig.adjustedWeight(
    FontWeight.w600,
  );

  /// 保存按钮的高度。
  static const double save_button_height = 44;

  /// 保存按钮的圆角。
  static const double save_button_radius = 22;

  /// 保存按钮的水平内边距。
  static const double save_button_horizontal_padding = 24;

  /// 分隔线颜色（日间模式）。
  static final Color divider_color_light = hexToColor("#F0F0F0");

  /// 分隔线颜色（夜间模式）。
  static final Color divider_color_dark = hexToColor("#2A2A3C");
}
