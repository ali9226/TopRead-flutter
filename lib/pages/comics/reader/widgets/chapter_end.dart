// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app/config/color_config.dart';
import 'package:app/pages/comics/reader/style.dart';
import 'package:app/pages/comics/style.dart';

/// 章节收尾区：完成徽章 + 标题 + 主次操作按钮。
class ComicReaderChapterEnd extends StatelessWidget {
  /// 是否有下一章。
  final bool has_next_chapter;

  /// 下一章点击回调。
  final VoidCallback on_next_chapter;

  /// 评论点击回调。
  final VoidCallback on_comments;

  const ComicReaderChapterEnd({
    super.key,
    required this.has_next_chapter,
    required this.on_next_chapter,
    required this.on_comments,
  });

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = ComicsStyle.is_cjk(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ComicReaderStyle.end_section_padding_h,
        ComicReaderStyle.end_section_top_spacing,
        ComicReaderStyle.end_section_padding_h,
        ComicReaderStyle.end_section_bottom_spacing,
      ),
      child: Column(
        children: <Widget>[
          /// 完成徽章：主题色圆环 + 对勾。
          Container(
            width: ComicReaderStyle.end_icon_container,
            height: ComicReaderStyle.end_icon_container,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorConstants.themeColor.withValues(alpha: 0.16),
              border: Border.all(
                color: ColorConstants.themeColor.withValues(alpha: 0.40),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.check_rounded,
              size: ComicReaderStyle.end_icon_size,
              color: ColorConstants.themeColor,
            ),
          ),

          /// 标题。
          Padding(
            padding: const EdgeInsets.only(
              top: ComicReaderStyle.end_title_top_spacing,
            ),
            child: Text(
              tr('comics.chapter_finished'),
              style: TextStyle(
                color: Colors.white,
                fontSize: ComicReaderStyle.pick_font_size(
                  is_cjk: is_cjk,
                  cjk: ComicReaderStyle.end_title_font_size_cjk,
                  alphabetic: ComicReaderStyle.end_title_font_size_alphabetic,
                ),
                fontWeight: ComicReaderStyle.weight_medium,
              ),
            ),
          ),

          /// 副标题。
          Padding(
            padding: const EdgeInsets.only(
              top: ComicReaderStyle.end_subtitle_top_spacing,
            ),
            child: Text(
              has_next_chapter
                  ? tr('comics.next_chapter')
                  : tr('comics.end_list'),
              style: TextStyle(
                color: ComicReaderStyle.muted_text,
                fontSize: ComicReaderStyle.end_subtitle_font_size,
                fontWeight: ComicReaderStyle.weight_regular,
              ),
            ),
          ),

          /// 装饰分隔线。
          Padding(
            padding: const EdgeInsets.only(
              top: ComicReaderStyle.end_divider_top_spacing,
            ),
            child: Container(
              width: ComicReaderStyle.end_divider_width,
              height: ComicReaderStyle.end_divider_thickness,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          /// 操作按钮。
          Padding(
            padding: const EdgeInsets.only(
              top: ComicReaderStyle.end_actions_top_spacing,
            ),
            child: Column(
              children: <Widget>[
                if (has_next_chapter)
                  SizedBox(
                    height: ComicReaderStyle.end_button_height,
                    child: FilledButton(
                      onPressed: on_next_chapter,
                      style: FilledButton.styleFrom(
                        backgroundColor: ColorConstants.themeColor,
                        foregroundColor: ColorConstants.lightTextColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: ComicReaderStyle.end_button_padding_h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ComicReaderStyle.end_button_radius,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            tr('comics.next_chapter'),
                            style: TextStyle(
                              fontSize: ComicReaderStyle.pick_font_size(
                                is_cjk: is_cjk,
                                cjk: ComicReaderStyle.end_button_font_size_cjk,
                                alphabetic:
                                    ComicReaderStyle
                                        .end_button_font_size_alphabetic,
                              ),
                              fontWeight: ComicReaderStyle.weight_medium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: ComicReaderStyle.end_button_gap),
                SizedBox(
                  height: ComicReaderStyle.end_secondary_height,
                  child: TextButton(
                    onPressed: on_comments,
                    style: TextButton.styleFrom(
                      foregroundColor: ComicReaderStyle.muted_text,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ComicReaderStyle.end_button_radius,
                        ),
                      ),
                    ),
                    child: Text(
                      tr('comics.chapter_comments'),
                      style: TextStyle(
                        fontSize: ComicReaderStyle.pick_font_size(
                          is_cjk: is_cjk,
                          cjk: ComicReaderStyle.end_button_font_size_cjk,
                          alphabetic:
                              ComicReaderStyle
                                  .end_button_font_size_alphabetic,
                        ),
                        fontWeight: ComicReaderStyle.weight_regular,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
