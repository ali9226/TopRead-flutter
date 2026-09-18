// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app/components/paragraph_comment_composer/logic.dart';
import 'package:app/components/paragraph_comment_composer/style.dart';
import 'package:app/config/color_config.dart';

/// 本地预览避免等待网络缩略图，上传失败的图片可保留并重试。
class ParagraphCommentImageStrip extends StatelessWidget {
  final ParagraphCommentComposerLogic logic;
  final bool is_dark;

  const ParagraphCommentImageStrip({
    super.key,
    required this.logic,
    required this.is_dark,
  });

  @override
  Widget build(BuildContext context) {
    return TextFieldTapRegion(
      child: GestureDetector(
        key: const ValueKey<String>('paragraph_comment_image_strip'),
        // 整行空白也属于图片操作区，消耗轻触但不改变输入焦点。
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: () {},
        child: SizedBox(
          height: ParagraphCommentComposerStyle.image_size,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: logic.images.length,
            separatorBuilder: (_, _) => const SizedBox(
              width: ParagraphCommentComposerStyle.image_spacing,
            ),
            itemBuilder: (BuildContext context, int index) {
              final ParagraphCommentImage image = logic.images[index];
              return SizedBox.square(
                dimension: ParagraphCommentComposerStyle.image_size,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        ParagraphCommentComposerStyle.image_radius,
                      ),
                      child: Image.memory(
                        image.bytes,
                        fit: BoxFit.cover,
                        cacheWidth:
                            (ParagraphCommentComposerStyle.image_size *
                                    MediaQuery.devicePixelRatioOf(context))
                                .round(),
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: ParagraphCommentComposerStyle.quote_background(
                            is_dark,
                          ),
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: ParagraphCommentComposerStyle.secondary_text(
                              is_dark,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (image.url == null && logic.is_uploading)
                      Center(
                        child: SizedBox.square(
                          dimension:
                              ParagraphCommentComposerStyle.progress_size,
                          child: CircularProgressIndicator(
                            color: ColorConstants.themeColor,
                            strokeWidth:
                                ParagraphCommentComposerStyle.progress_stroke,
                          ),
                        ),
                      ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: ExcludeFocus(
                        child: SizedBox.square(
                          dimension: ParagraphCommentComposerStyle.remove_size,
                          child: IconButton.filled(
                            padding: EdgeInsets.zero,
                            tooltip: tr('paragraph_comment.remove_image'),
                            onPressed: logic.is_busy
                                ? null
                                : () => logic.remove_image(image),
                            icon: const Icon(
                              Icons.close_rounded,
                              size: ParagraphCommentComposerStyle
                                  .remove_icon_size,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  ParagraphCommentComposerStyle.surface(
                                    is_dark,
                                  ),
                              foregroundColor:
                                  ParagraphCommentComposerStyle.text(is_dark),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
