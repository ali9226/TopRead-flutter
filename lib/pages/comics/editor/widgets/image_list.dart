// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/pages/comics/editor/models.dart';
import 'package:app/pages/comics/editor/style.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/comics/widgets/comic_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 章节图片列表：缩略图列表 + 添加 / 删除 / 拖动排序。
///
/// 顺序即阅读顺序，保存时按当前列表顺序提交 images 数组。
class ChapterImageList extends StatelessWidget {
  /// 所属章节的图片列表。
  final List<ComicEditorImage> images;

  /// 是否允许编辑。
  final bool enabled;

  /// 添加图片回调（打开相册/拍照）。
  final VoidCallback on_add;

  /// 删除图片回调，参数为图片下标。
  final void Function(int image_index) on_remove;

  /// 拖动排序回调，参数为旧下标与新下标。
  final void Function(int old_index, int new_index) on_reorder;

  const ChapterImageList({
    super.key,
    required this.images,
    required this.enabled,
    required this.on_add,
    required this.on_remove,
    required this.on_reorder,
  });

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = ComicsStyle.is_cjk(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 标题行：上传入口 + 排序提示。
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                tr('comics.upload_pages'),
                style: ComicEditorStyle.label(context),
              ),
            ),
            Text(
              tr('comics.sort_hint'),
              style: ComicsStyle.text(
                context,
                size: is_cjk
                    ? ComicEditorStyle.section_subtitle_font_size_cjk
                    : ComicEditorStyle.section_subtitle_font_size_alphabetic,
                color: ComicsStyle.muted(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: ComicEditorStyle.label_bottom_spacing),

        /// 添加按钮始终可见。
        _AddImageButton(enabled: enabled, on_add: on_add),

        /// 已有图片：可拖动排序的紧凑行列表。
        if (images.isNotEmpty) ...<Widget>[
          const SizedBox(height: ComicEditorStyle.image_thumb_spacing),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: enabled,
            onReorder: enabled ? on_reorder : null,
            itemCount: images.length,
            itemBuilder: (BuildContext context, int index) {
              return _ImageRow(
                key: ValueKey('comic_image_${images[index].image_url}_$index'),
                image: images[index],
                index: index,
                enabled: enabled,
                on_remove: () => on_remove(index),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            tr('comics.image_count', namedArgs: <String, String>{
              'count': '${images.length}',
            }),
            style: ComicsStyle.text(
              context,
              size: is_cjk
                  ? ComicEditorStyle.section_subtitle_font_size_cjk
                  : ComicEditorStyle.section_subtitle_font_size_alphabetic,
              color: ComicsStyle.muted(context),
            ),
          ),
        ],
      ],
    );
  }
}

/// 单张图片行：缩略图 + 序号 + 删除。
class _ImageRow extends StatelessWidget {
  final ComicEditorImage image;
  final int index;
  final bool enabled;
  final VoidCallback on_remove;

  const _ImageRow({
    super.key,
    required this.image,
    required this.index,
    required this.enabled,
    required this.on_remove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: ComicEditorStyle.image_thumb_spacing),
      child: Row(
        children: <Widget>[
          /// 拖动手柄（仅可编辑时由 ReorderableListView 提供默认手势）。
          if (enabled)
            Icon(
              Icons.drag_handle_rounded,
              size: 20,
              color: ComicEditorStyle.input_hint(context),
            ),
          if (enabled) const SizedBox(width: 4),

          /// 缩略图。
          ClipRRect(
            borderRadius: BorderRadius.circular(ComicEditorStyle.image_thumb_radius),
            child: SizedBox(
              width: ComicEditorStyle.image_thumb_size,
              height: ComicEditorStyle.image_thumb_size,
              child: ComicImage(
                url: image.image_url,
                semantic_label: tr('comics.page_count', namedArgs: <String, String>{
                  'count': '${index + 1}',
                }),
              ),
            ),
          ),
          const SizedBox(width: 12),

          /// 页码 + 链接摘要。
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  tr('comics.page_count', namedArgs: <String, String>{
                    'count': '${index + 1}',
                  }),
                  style: ComicsStyle.text(context, strong: true),
                ),
                const SizedBox(height: 2),
                Text(
                  image.image_url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ComicsStyle.text(
                    context,
                    size: 11,
                    color: ComicsStyle.muted(context),
                  ),
                ),
              ],
            ),
          ),

          /// 删除按钮。
          if (enabled)
            IconButton(
              tooltip: tr('comics.remove_image'),
              onPressed: on_remove,
              icon: const Icon(Icons.delete_outline_rounded),
              color: ColorConstants.dangerColor,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

/// 添加图片按钮。
class _AddImageButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback on_add;

  const _AddImageButton({required this.enabled, required this.on_add});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tr('comics.upload_pages'),
      child: OutlinedButton.icon(
        onPressed: enabled ? on_add : null,
        style: ComicEditorStyle.secondary_button(context),
        icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
        label: Text(tr('comics.upload_pages')),
      ),
    );
  }
}
