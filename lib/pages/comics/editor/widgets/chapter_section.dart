// ignore_for_file: non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/comics/editor/logic.dart';
import 'package:app/pages/comics/editor/models.dart';
import 'package:app/pages/comics/editor/style.dart';
import 'package:app/pages/comics/editor/widgets/image_list.dart';
import 'package:app/pages/comics/editor/widgets/basic_info_form.dart'
    show comic_editor_input_decoration;
import 'package:app/pages/comics/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 章节分区：当前语种下的章节列表，支持增删、拖动排序与图片管理。
class ChapterSection extends StatelessWidget {
  /// 编辑器逻辑层。
  final ComicEditorLogic logic;

  /// 是否允许编辑。
  final bool enabled;

  /// 为指定章节添加图片。
  final void Function(int chapter_index) on_add_images;

  /// 删除章节二次确认后回调。
  final void Function(int chapter_index) on_remove_chapter;

  const ChapterSection({
    super.key,
    required this.logic,
    required this.enabled,
    required this.on_add_images,
    required this.on_remove_chapter,
  });

  @override
  Widget build(BuildContext context) {
    final ComicEditorLanguage? language = logic.selected_language;
    if (language == null) return const SizedBox.shrink();
    final bool is_cjk = ComicsStyle.is_cjk(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 分区标题 + 添加章节。
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                tr('comics.chapters'),
                style: ComicEditorStyle.section_title(context),
              ),
            ),
            TextButton.icon(
              onPressed: enabled ? logic.add_chapter : null,
              icon: const Icon(Icons.add, size: 18),
              label: Text(tr('comics.add_chapter')),
              style: ComicsStyle.text_button(context),
            ),
          ],
        ),
        const SizedBox(height: LayoutConfig.space_4),
        Text(
          tr('comics.chapter_description'),
          style: ComicEditorStyle.section_subtitle(context),
        ),
        const SizedBox(height: ComicEditorStyle.section_title_gap),

        /// 空章节列表：引导创建。
        if (language.chapters.isEmpty)
          _EmptyChapters(enabled: enabled, on_add: logic.add_chapter)
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: enabled,
            onReorder: enabled ? logic.reorder_chapter : null,
            itemCount: language.chapters.length,
            itemBuilder: (BuildContext context, int index) {
              return _ChapterCard(
                key: ValueKey(
                  'comic_chapter_${language.chapters[index].id}_$index',
                ),
                logic: logic,
                chapter: language.chapters[index],
                index: index,
                enabled: enabled,
                is_cjk: is_cjk,
                on_add_images: () => on_add_images(index),
                on_remove: () => on_remove_chapter(index),
              );
            },
          ),
      ],
    );
  }
}

/// 空章节引导。
class _EmptyChapters extends StatelessWidget {
  final bool enabled;
  final VoidCallback on_add;

  const _EmptyChapters({required this.enabled, required this.on_add});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ComicEditorStyle.card_padding_v),
      decoration: BoxDecoration(
        color: ComicEditorStyle.input_fill(context),
        borderRadius: BorderRadius.circular(ComicEditorStyle.chapter_radius),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.menu_book_outlined,
            size: 36,
            color: ComicEditorStyle.input_hint(context),
          ),
          const SizedBox(height: LayoutConfig.space_12),
          Text(
            tr('comics.create_first_chapter'),
            textAlign: TextAlign.center,
            style: ComicsStyle.text(context, color: ComicsStyle.muted(context)),
          ),
          const SizedBox(height: LayoutConfig.space_14),
          ElevatedButton(
            onPressed: enabled ? on_add : null,
            style: ComicEditorStyle.primary_button(context),
            child: Text(tr('comics.add_chapter')),
          ),
        ],
      ),
    );
  }
}

/// 单章卡片：序号 + 标题输入 + 图片列表 + 删除。
class _ChapterCard extends StatelessWidget {
  final ComicEditorLogic logic;
  final ComicEditorChapter chapter;
  final int index;
  final bool enabled;
  final bool is_cjk;
  final VoidCallback on_add_images;
  final VoidCallback on_remove;

  const _ChapterCard({
    super.key,
    required this.logic,
    required this.chapter,
    required this.index,
    required this.enabled,
    required this.is_cjk,
    required this.on_add_images,
    required this.on_remove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: ComicEditorStyle.chapter_spacing),
      padding: ComicEditorStyle.chapter_padding,
      decoration: BoxDecoration(
        color: ComicEditorStyle.input_fill(context),
        borderRadius: BorderRadius.circular(ComicEditorStyle.chapter_radius),
        border: Border.all(
          color: ComicEditorStyle.input_border(context).withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// 头部：序号 + 标题 + 删除。
          Row(
            children: <Widget>[
              if (enabled)
                Icon(
                  Icons.drag_handle_rounded,
                  size: 20,
                  color: ComicEditorStyle.input_hint(context),
                ),
              Container(
                width: ComicEditorStyle.chapter_number_width,
                height: ComicEditorStyle.chapter_number_width,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ColorConstants.themeColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(LayoutConfig.radius_10),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: ComicEditorStyle.chapter_number_font_size,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                    color: ColorConstants.lightTextColor,
                  ),
                ),
              ),
              const SizedBox(width: ComicEditorStyle.chapter_title_gap),
              Expanded(
                child: TextFormField(
                  enabled: enabled,
                  initialValue: chapter.title,
                  onChanged: (String value) =>
                      logic.update_chapter_title(index, value),
                  decoration: comic_editor_input_decoration(
                    context,
                    tr('comics.chapter_title'),
                  ),
                  style: ComicEditorStyle.input_text(context),
                ),
              ),
              if (enabled)
                IconButton(
                  tooltip: tr('comics.remove_chapter'),
                  onPressed: on_remove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: ColorConstants.dangerColor,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: ComicEditorStyle.field_spacing),

          /// 图片列表。
          ChapterImageList(
            images: chapter.images,
            enabled: enabled,
            on_add: on_add_images,
            on_remove: (int image_index) =>
                logic.remove_chapter_image(index, image_index),
            on_reorder: (int old_index, int new_index) =>
                logic.reorder_chapter_image(index, old_index, new_index),
          ),
        ],
      ),
    );
  }
}
