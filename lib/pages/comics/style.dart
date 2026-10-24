// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 漫画整体设计参数：留白、节奏、阅读宽度及日夜色彩集中在这里管理。
class ComicsStyle {
  static const double page_padding = LayoutConfig.space_20;
  static const double small_gap = LayoutConfig.space_8;
  static const double gap = LayoutConfig.space_16;
  static const double large_gap = LayoutConfig.space_24;
  static const double radius = LayoutConfig.radius_20;
  static const double cover_radius = LayoutConfig.radius_14;
  static const double cover_ratio = 0.70;
  static const double grid_card_width = 158;
  static const double content_width = 1080;
  static const double reader_width = 920;
  static const double touch_target = LayoutConfig.touch_target_size;
  static const double actions_width_cjk = 280;
  static const double actions_width_alphabetic = 330;
  static const double title_font_size_cjk = 28;
  static const double title_font_size_alphabetic = 26;
  static const double body_font_size_cjk = 14;
  static const double body_font_size_alphabetic = 13;
  static const double line_height_cjk = 1.55;
  static const double line_height_alphabetic = 1.65;
  static const int page_size = 24;
  static const int comment_page_size = 20;
  static const int search_delay_ms = 350;
  static const int progress_delay_ms = 850;
  static const int max_images = 500;
  static const int max_image_bytes = 30 * 1024 * 1024;
  static const int thumbnail_max_pixels = 1024 * 1024;
  static const Color reader_background =
      ColorConstants.reader_background_ff0c0d10;

  static bool is_dark(BuildContext context) {
    // 显式订阅 Theme，切换日夜主题时所有依赖此样式的页面会即时重建。
    final inherited_dark = Theme.of(context).brightness == Brightness.dark;
    return Get.isRegistered<DeviceInfo>()
        ? Get.find<DeviceInfo>().dark.value
        : inherited_dark;
  }

  static Color background(BuildContext context) => is_dark(context)
      ? ColorConstants.nightBackgroundColor
      : ColorConstants.lightBackgroundColor;
  static Color surface(BuildContext context) => is_dark(context)
      ? ColorConstants.nightHighlightColor
      : ColorConstants.whiteColor;
  static Color ink(BuildContext context) => is_dark(context)
      ? ColorConstants.whiteColor
      : ColorConstants.lightTextColor;
  static Color muted(BuildContext context) =>
      ink(context).withValues(alpha: is_dark(context) ? 0.62 : 0.58);
  static Color outline(BuildContext context) =>
      ink(context).withValues(alpha: 0.09);
  static bool is_cjk(BuildContext context) =>
      LanguageUtil.is_cjk_language(context.locale.languageCode);

  /// 所有漫画文本使用平台适配字重和语种适配行高。
  static TextStyle text(
    BuildContext context, {
    double? size,
    bool strong = false,
    Color? color,
  }) => TextStyle(
    fontSize:
        size ??
        (is_cjk(context) ? body_font_size_cjk : body_font_size_alphabetic),
    height: is_cjk(context) ? line_height_cjk : line_height_alphabetic,
    color: color ?? ink(context),
    fontWeight: FontConfig.adjustedWeight(
      strong
          ? FontConfig.adjustedWeight(FontWeight.w500)
          : FontConfig.adjustedWeight(FontWeight.w400),
    ),
  );

  /// 分类可能同时包含 en/zh-CN 等翻译，按当前 UI 语种选择可读名称。
  static String category_name(
    BuildContext context,
    Map<String, dynamic> category,
  ) {
    final translations = category['translations'];
    if (translations is Map) {
      final locale = context.locale.toLanguageTag();
      final code = context.locale.languageCode;
      final value =
          translations[locale] ??
          translations[code] ??
          (code == 'zh' ? translations['zh-CN'] : null) ??
          translations['en'];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return category['name']?.toString() ?? category['title']?.toString() ?? '';
  }

  static TextStyle button_text(BuildContext context) =>
      (Theme.of(context).textTheme.labelLarge ?? const TextStyle()).merge(
        text(context, strong: true),
      );

  static ButtonStyle outlined_button(BuildContext context) =>
      OutlinedButton.styleFrom(
        foregroundColor: ink(context),
        side: BorderSide(color: outline(context)),
        minimumSize: const Size(0, touch_target),
        textStyle: button_text(context),
      );

  static ButtonStyle text_button(BuildContext context) => TextButton.styleFrom(
    foregroundColor: ink(context),
    minimumSize: const Size(0, touch_target),
    textStyle: button_text(context),
  );

  static TextStyle heading(BuildContext context) => text(
    context,
    strong: true,
    size: is_cjk(context) ? title_font_size_cjk : title_font_size_alphabetic,
  );
}

/// 瀑布流漫画卡片的设计参数：圆角、字阶、标签与封面信息条集中在这里管理。
class ComicCardStyle {
  /// 卡片圆角，与首页推荐卡片共用同一设计令牌。
  static const double card_radius = LayoutConfig.card_radius;

  /// 卡片内容水平内边距。
  static const double content_padding_h = LayoutConfig.space_10;

  /// 卡片内容顶部内边距。
  static const double content_padding_top = LayoutConfig.space_10;

  /// 卡片内容底部内边距。
  static const double content_padding_bottom = LayoutConfig.space_12;

  /// 标题字号（CJK）。
  static const double title_font_size_cjk = 15;

  /// 标题字号（拉丁语系，单词更宽需略缩）。
  static const double title_font_size_alphabetic = 14;

  /// 标题行高（CJK）。
  static const double title_height_cjk = 1.45;

  /// 标题行高（拉丁语系，升部降部需要更大行高）。
  static const double title_height_alphabetic = 1.5;

  /// 标题最大行数。
  static const int title_max_lines = 2;

  /// 标题字距（拉丁语系）。
  static const double title_letter_spacing_alphabetic = 0.2;

  /// 简介与标题的间距（CJK）。
  static const double description_top_spacing_cjk = LayoutConfig.space_6;

  /// 简介与标题的间距（拉丁语系）。
  static const double description_top_spacing_alphabetic = 5;

  /// 简介字号（CJK）。
  static const double description_font_size_cjk = 12;

  /// 简介字号（拉丁语系）。
  static const double description_font_size_alphabetic = 11.5;

  /// 简介行高（CJK）。
  static const double description_height_cjk = 1.5;

  /// 简介行高（拉丁语系，升部降部需要更大行高）。
  static const double description_height_alphabetic = 1.6;

  /// 简介最大行数。
  static const int description_max_lines = 2;

  /// 简介字距（拉丁语系）。
  static const double description_letter_spacing_alphabetic = 0.15;

  /// 标签最大展示数量，与首页推荐卡片一致，超出部分截断。
  static const int max_tag_count = 2;

  /// 标签区与简介的间距。
  static const double tag_top_spacing = LayoutConfig.space_8;

  /// 标签水平间距。
  static const double tag_spacing = LayoutConfig.space_6;

  /// 标签换行间距。
  static const double tag_run_spacing = LayoutConfig.space_6;

  /// 标签垂直内边距。
  static const double tag_padding_v = LayoutConfig.space_4;

  /// 标签圆角。
  static const double tag_radius = LayoutConfig.radius_pill;

  /// 标签字号（CJK）。
  static const double tag_font_size_cjk = 11;

  /// 标签字号（拉丁语系）。
  static const double tag_font_size_alphabetic = 10;

  /// 标签水平内边距（CJK）。
  static const double tag_padding_h_cjk = LayoutConfig.space_8;

  /// 标签水平内边距（拉丁语系，单词更宽需更大留白）。
  static const double tag_padding_h_alphabetic = 10;

  /// 封面角标字号。
  static const double cover_badge_font_size = 10;

  /// 封面角标内边距。
  static const EdgeInsets cover_badge_padding = EdgeInsets.fromLTRB(
    LayoutConfig.space_8,
    LayoutConfig.space_4,
    LayoutConfig.space_8,
    LayoutConfig.space_4,
  );

  /// 封面角标外边距。
  static const EdgeInsets cover_badge_margin = EdgeInsets.fromLTRB(
    LayoutConfig.space_8,
    LayoutConfig.space_8,
    0,
    0,
  );

  /// 封面角标圆角。
  static const double cover_badge_radius = LayoutConfig.radius_pill;

  /// 封面角标背景不透明度。
  static const double cover_badge_background_opacity = 0.56;

  /// 封面底部信息条字号。
  static const double cover_meta_font_size = 11;

  /// 封面底部信息条水平内边距。
  static const double cover_meta_padding_h = LayoutConfig.space_12;

  /// 封面底部信息条顶部渐变预留高度。
  static const double cover_meta_padding_top = LayoutConfig.space_32;

  /// 封面底部信息条文字阴影不透明度。
  static const double cover_meta_shadow_opacity = 0.30;

  /// 封面渐变遮罩顶部起始透明度。
  static const double cover_gradient_top_opacity = 0.0;

  /// 封面渐变遮罩底部结束透明度。
  static const double cover_gradient_bottom_opacity = 0.82;

  /// 网格列间水平间距，与首页小说瀑布流保持一致。
  static const double grid_column_spacing = LayoutConfig.space_8;

  /// 网格行间垂直间距，与首页小说瀑布流保持一致。
  static const double grid_item_spacing = LayoutConfig.space_10;

  /// 网格最小列数，与首页小说瀑布流保持一致。
  static const int grid_min_column_count = 2;

  /// 网格最大列数，与首页小说瀑布流保持一致。
  static const int grid_max_column_count = 4;

  /// 点击波纹不透明度，与首页推荐卡片保持一致。
  static const double ripple_opacity = 0.14;

  /// 点击高亮不透明度，与首页推荐卡片保持一致。
  static const double highlight_opacity = 0.08;

  /// 标签背景不透明度，与首页推荐卡片保持一致。
  static const double tag_background_opacity = 0.16;

  /// 标签文字不透明度，与首页推荐卡片保持一致。
  static const double tag_text_opacity = 0.96;

  /// 标签取色：漫画 id 权重，保证同一漫画标签颜色稳定。
  static const int tag_color_id_factor = 7;

  /// 标签取色：标签序号权重。
  static const int tag_color_index_factor = 3;

  /// 按压时文字区域缩放比例，与首页推荐卡片一致。
  static const double press_text_scale = 0.96;

  /// 按压缩放动画时长（毫秒）。
  static const int press_scale_duration_ms = 150;

  /// 按压后指针移动超过该距离则取消缩放，避免列表滚动时误触。
  static const double press_move_cancel_threshold = 10.0;

  /// 骨架屏每列卡片数，决定首屏填充高度。
  static const int skeleton_row_count = 3;

  /// 字形条位于真实文字行盒内，不使用整块行高填充。
  static const double skeleton_ink_ratio = 0.68;
  static const double skeleton_text_radius = LayoutConfig.radius_3;
  static const double skeleton_title_trailing_ratio = 0.62;
  static const double skeleton_description_trailing_ratio = 0.78;

  /// 分类占位只决定未知标签的典型宽度；高度沿用真实标签字阶。
  static const double skeleton_tag_width = 44;

  /// 卡片深色背景。
  static const Color card_dark_bg =
      ColorConstants.pages_home_widgets_tab_contents_recommend_tab_index_tone;

  /// 卡片浅色背景。
  static const Color card_light_bg = ColorConstants.whiteColor;

  /// 深色模式标题色。
  static const Color title_dark = ColorConstants.whiteColor;

  /// 浅色模式标题色。
  static const Color title_light =
      ColorConstants.components_recommend_book_card_index_tone;

  /// 深色模式简介色。
  static final Color description_dark =
      ColorConstants.components_recommend_book_card_index_tone_9effffff;

  /// 浅色模式简介色。
  static const Color description_light =
      ColorConstants.components_recommend_book_card_index_tone_ff8b93a2;
}
