// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../api.dart';
import '../style.dart';

/// 评论正文独立展示图片；段评针对整个段落，不展示选区引用。
class ParagraphCommentBody extends StatelessWidget {
  final ParagraphComment comment;
  final bool is_dark;
  final bool is_cjk;

  const ParagraphCommentBody({
    super.key,
    required this.comment,
    required this.is_dark,
    required this.is_cjk,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (comment.content.isNotEmpty)
        Text(
          comment.content,
          style: ParagraphCommentSheetStyle.text(
            is_dark: is_dark, is_cjk: is_cjk,
          ),
        ),
      if (comment.images.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(
            top: ParagraphCommentSheetStyle.small_spacing,
          ),
          child: Wrap(
            spacing: ParagraphCommentSheetStyle.image_spacing,
            runSpacing: ParagraphCommentSheetStyle.image_spacing,
            children: [
              for (final url in comment.images)
                InkWell(
                  onTap: () => _show_image(context, url),
                  borderRadius: BorderRadius.circular(
                    ParagraphCommentSheetStyle.image_radius,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      ParagraphCommentSheetStyle.image_radius,
                    ),
                    child: Image.network(
                      url,
                      width: ParagraphCommentSheetStyle.image_size,
                      height: ParagraphCommentSheetStyle.image_size,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => SizedBox.square(
                        dimension: ParagraphCommentSheetStyle.image_size,
                        child: Icon(Icons.broken_image_outlined,
                          color: ParagraphCommentSheetStyle.secondary(is_dark)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
    ],
  );

  void _show_image(BuildContext context, String url) => showDialog<void>(
    context: context,
    builder: (dialog_context) => Dialog(
      backgroundColor: ParagraphCommentSheetStyle.surface(is_dark),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: InteractiveViewer(child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
          ))),
          TextButton(
            onPressed: () => Navigator.of(dialog_context).pop(),
            style: ParagraphCommentSheetStyle.button(
              is_dark: is_dark, is_cjk: is_cjk,
            ),
            child: Text(tr('common.cancel')),
          ),
        ],
      ),
    ),
  );
}
