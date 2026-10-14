// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/comics/style.dart';
import 'package:flutter/material.dart';

/// 漫画编辑器设计参数：分区卡片、表单控件、章节与图片列表集中在这里管理。
class ComicEditorStyle {
  /// 页面水平内边距。
  static const double page_padding = ComicsStyle.page_padding;

  /// 分区卡片间距。
  static const double section_spacing = ComicsStyle.large_gap;

  /// 卡片内边距（水平）。
  static const double card_padding_h = 16;

  /// 卡片内边距（垂直）。
  static const double card_padding_v = 18;

  /// 卡片圆角，与内容卡片同源。
  static const double card_radius = 24;

  /// 卡片内元素间距。
  static const double field_spacing = 14;

  /// 分区标题字号（CJK）。
  static const double section_title_font_size_cjk = 17;

  /// 分区标题字号（拉丁语系）。
  static const double section_title_font_size_alphabetic = 16;

  /// 分区副标题字号（CJK）。
  static const double section_subtitle_font_size_cjk = 12;

  /// 分区副标题字号（拉丁语系）。
  static const double section_subtitle_font_size_alphabetic = 11;

  /// 分区标题与副标题间距。
  static const double section_subtitle_top_spacing = 4;

  /// 分区标题与内容间距。
  static const double section_title_gap = 14;

  /// 输入框圆角。
  static const double input_radius = 14;

  /// 输入框水平内边距。
  static const double input_padding_h = 14;

  /// 输入框垂直内边距。
  static const double input_padding_v = 12;

  /// 输入框字号（CJK）。
  static const double input_font_size_cjk = 14;

  /// 输入框字号（拉丁语系）。
  static const double input_font_size_alphabetic = 13;

  /// 多行输入框最大行数（简介）。
  static const int description_max_lines = 6;

  /// 多行输入框最小行数（简介）。
  static const int description_min_lines = 3;

  /// 字段标签字号（CJK）。
  static const double label_font_size_cjk = 13;

  /// 字段标签字号（拉丁语系）。
  static const double label_font_size_alphabetic = 12;

  /// 字段标签与输入框间距。
  static const double label_bottom_spacing = 8;

  /// 封面预览宽度。
  static const double cover_width = 128;

  /// 封面预览高度（竖版漫画比例）。
  static const double cover_height = 182;

  /// 封面预览圆角。
  static const double cover_radius = 14;

  /// 封面占位图标尺寸。
  static const double cover_icon_size = 32;

  /// 封面与表单列的间距。
  static const double cover_gap = 16;

  /// 封面替换按钮字号。
  static const double cover_action_font_size = 12;

  /// 分类标签内边距。
  static const EdgeInsets tag_padding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 7,
  );

  /// 分类标签圆角。
  static const double tag_radius = 999;

  /// 分类标签字号（CJK）。
  static const double tag_font_size_cjk = 12;

  /// 分类标签字号（拉丁语系）。
  static const double tag_font_size_alphabetic = 11;

  /// 分类标签间距。
  static const double tag_spacing = 8;

  /// 分类标签换行间距。
  static const double tag_run_spacing = 8;

  /// 语种芯片内边距。
  static const EdgeInsets chip_padding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 8,
  );

  /// 语种芯片圆角。
  static const double chip_radius = 999;

  /// 语种芯片字号。
  static const double chip_font_size = 13;

  /// 语种芯片间距。
  static const double chip_spacing = 8;

  /// 章节卡片内边距。
  static const EdgeInsets chapter_padding = EdgeInsets.all(14);

  /// 章节卡片圆角。
  static const double chapter_radius = 16;

  /// 章节卡片间距。
  static const double chapter_spacing = 10;

  /// 章节序号胶囊宽度。
  static const double chapter_number_width = 36;

  /// 章节序号字号。
  static const double chapter_number_font_size = 13;

  /// 章节标题输入框与序号间距。
  static const double chapter_title_gap = 10;

  /// 图片缩略图尺寸。
  static const double image_thumb_size = 88;

  /// 图片缩略图圆角。
  static const double image_thumb_radius = 10;

  /// 图片缩略图间距。
  static const double image_thumb_spacing = 8;

  /// 图片删除按钮尺寸。
  static const double image_delete_size = 22;

  /// 图片删除按钮图标尺寸。
  static const double image_delete_icon_size = 14;

  /// 添加图片占位块边长。
  static const double image_add_size = 88;

  /// 底部操作栏水平内边距。
  static const double action_bar_padding_h = 20;

  /// 底部操作栏垂直内边距。
  static const double action_bar_padding_v = 12;

  /// 底部操作栏按钮间距。
  static const double action_bar_spacing = 10;

  /// 主按钮圆角。
  static const double button_radius = 999;

  /// 按钮最小高度。
  static const double button_height = 48;

  /// 按钮水平内边距（CJK）。
  static const double button_padding_h_cjk = 20;

  /// 按钮水平内边距（拉丁语系，按钮更宽）。
  static const double button_padding_h_alphabetic = 24;

  /// 按钮文字字号（CJK）。
  static const double button_font_size_cjk = 14;

  /// 按钮文字字号（拉丁语系）。
  static const double button_font_size_alphabetic = 13;

  /// 提示横幅内边距。
  static const EdgeInsets banner_padding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );

  /// 提示横幅圆角。
  static const double banner_radius = 14;

  /// 提示横幅与下方内容间距。
  static const double banner_bottom_spacing = 12;

  /// 封面上传中遮罩不透明度。
  static const double upload_mask_opacity = 0.45;

  /// 主行动按钮背景：主题金。
  static Color primary_background(BuildContext context) =>
      ColorConstants.themeColor;

  /// 主行动按钮文字：深色保证金底对比度。
  static Color primary_foreground(BuildContext context) =>
      ColorConstants.lightTextColor;

  /// 危险按钮背景。
  static Color danger_background(BuildContext context) =>
      ColorConstants.dangerColor;

  /// 危险按钮文字。
  static Color danger_foreground(BuildContext context) =>
      ColorConstants.whiteColor;

  /// 卡片背景。
  static Color card_background(BuildContext context) =>
      ComicsStyle.surface(context);

  /// 输入框填充色。
  static Color input_fill(BuildContext context) =>
      ComicsStyle.is_dark(context)
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFFF5F6F8);

  /// 输入框边框色。
  static Color input_border(BuildContext context) => ComicsStyle.outline(context);

  /// 输入框文字色。
  static Color input_ink(BuildContext context) => ComicsStyle.ink(context);

  /// 输入框提示文字色。
  static Color input_hint(BuildContext context) => ComicsStyle.muted(context);

  /// 标签选中背景。
  static Color tag_selected(BuildContext context) =>
      ColorConstants.themeColor.withValues(alpha: 0.22);

  /// 标签未选中背景。
  static Color tag_unselected(BuildContext context) =>
      ComicsStyle.is_dark(context)
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFFF0F1F4);

  /// 标签选中文字色。
  static Color tag_selected_ink(BuildContext context) =>
      ColorConstants.lightTextColor;

  /// 标签未选中文字色。
  static Color tag_unselected_ink(BuildContext context) =>
      ComicsStyle.muted(context);

  /// 分区标题样式。
  static TextStyle section_title(BuildContext context) => ComicsStyle.text(
    context,
    strong: true,
    size: ComicsStyle.is_cjk(context)
        ? section_title_font_size_cjk
        : section_title_font_size_alphabetic,
  );

  /// 分区副标题样式。
  static TextStyle section_subtitle(BuildContext context) => ComicsStyle.text(
    context,
    color: ComicsStyle.muted(context),
    size: ComicsStyle.is_cjk(context)
        ? section_subtitle_font_size_cjk
        : section_subtitle_font_size_alphabetic,
  );

  /// 字段标签样式。
  static TextStyle label(BuildContext context) => ComicsStyle.text(
    context,
    strong: true,
    size: ComicsStyle.is_cjk(context)
        ? label_font_size_cjk
        : label_font_size_alphabetic,
  );

  /// 输入框文字样式。
  static TextStyle input_text(BuildContext context) => ComicsStyle.text(
    context,
    size: ComicsStyle.is_cjk(context)
        ? input_font_size_cjk
        : input_font_size_alphabetic,
  );

  /// 按钮文字样式。
  static TextStyle button_text(BuildContext context) => TextStyle(
    fontSize: ComicsStyle.is_cjk(context)
        ? button_font_size_cjk
        : button_font_size_alphabetic,
    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
    color: primary_foreground(context),
  );

  /// 主按钮样式（金底黑字）。
  static ButtonStyle primary_button(BuildContext context) =>
      ElevatedButton.styleFrom(
        backgroundColor: primary_background(context),
        foregroundColor: primary_foreground(context),
        elevation: 0,
        minimumSize: const Size(0, button_height),
        padding: EdgeInsets.symmetric(
          horizontal: ComicsStyle.is_cjk(context)
              ? button_padding_h_cjk
              : button_padding_h_alphabetic,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(button_radius),
        ),
        textStyle: button_text(context),
      );

  /// 次按钮样式（描边）。
  static ButtonStyle secondary_button(BuildContext context) =>
      OutlinedButton.styleFrom(
        foregroundColor: ComicsStyle.ink(context),
        minimumSize: const Size(0, button_height),
        side: BorderSide(color: ComicsStyle.outline(context)),
        padding: EdgeInsets.symmetric(
          horizontal: ComicsStyle.is_cjk(context)
              ? button_padding_h_cjk
              : button_padding_h_alphabetic,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(button_radius),
        ),
        textStyle: button_text(context).copyWith(
          color: ComicsStyle.ink(context),
        ),
      );

  /// 危险按钮样式。
  static ButtonStyle danger_button(BuildContext context) =>
      ElevatedButton.styleFrom(
        backgroundColor: danger_background(context),
        foregroundColor: danger_foreground(context),
        elevation: 0,
        minimumSize: const Size(0, button_height),
        padding: EdgeInsets.symmetric(
          horizontal: ComicsStyle.is_cjk(context)
              ? button_padding_h_cjk
              : button_padding_h_alphabetic,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(button_radius),
        ),
        textStyle: button_text(context).copyWith(
          color: danger_foreground(context),
        ),
      );
}
