// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/pages/comics/reader/style.dart';
import 'package:app/pages/comics/reader/widgets/control_button.dart';

/// TODO 与小说ReadBottomBar保持同一布局：轻量前后章和进度区、下方图标文字操作，无卡片边框。
class ComicReaderBottomScrim extends StatelessWidget {
  final int page_index;
  final int page_count;
  final bool has_previous_chapter;
  final bool has_next_chapter;
  final VoidCallback on_previous_chapter;
  final VoidCallback on_next_chapter;
  final VoidCallback? on_open_catalog;
  final VoidCallback? on_comments;
  const ComicReaderBottomScrim({
    super.key,
    required this.page_index,
    required this.page_count,
    required this.has_previous_chapter,
    required this.has_next_chapter,
    required this.on_previous_chapter,
    required this.on_next_chapter,
    this.on_open_catalog,
    this.on_comments,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: ComicReaderStyle.panel_background(context),
      border: Border(
        top: BorderSide(
          color: ComicReaderStyle.border_color(context),
          width: ComicReaderStyle.divider_width,
        ),
      ),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ComicReaderStyle.toolbar_padding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: ComicReaderControlButton(
                      icon: Icons.arrow_back_rounded,
                      show_icon: false,
                      label: tr('comics.previous_chapter'),
                      on_pressed: has_previous_chapter
                          ? on_previous_chapter
                          : null,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal:
                            ComicReaderStyle.progress_horizontal_padding,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            tr(
                              'comics.reader_page_progress',
                              namedArgs: <String, String>{
                                'page':
                                    '${page_count > 0 ? page_index + 1 : 0}',
                                'total': '$page_count',
                              },
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: TextStyle(
                              color: ComicReaderStyle.secondary_foreground(
                                context,
                              ),
                              fontSize: ComicReaderStyle.page_font_size,
                              fontWeight: ComicReaderStyle.weight_regular,
                            ),
                          ),
                          const SizedBox(
                            height: ComicReaderStyle.progress_label_gap,
                          ),
                          LinearProgressIndicator(
                            value: page_count > 0
                                ? ((page_index + 1) / page_count).clamp(0, 1)
                                : 0,
                            minHeight: ComicReaderStyle.progress_track_height,
                            borderRadius: BorderRadius.circular(
                              ComicReaderStyle.progress_radius,
                            ),
                            color: ComicReaderStyle.secondary_foreground(
                              context,
                            ),
                            backgroundColor: ComicReaderStyle.track_background(
                              context,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ComicReaderControlButton(
                      icon: Icons.arrow_forward_rounded,
                      show_icon: false,
                      label: tr('comics.next_chapter'),
                      on_pressed: has_next_chapter ? on_next_chapter : null,
                    ),
                  ),
                ],
              ),
            ),
            if (on_open_catalog != null || on_comments != null)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: ComicReaderControlButton(
                        icon: Icons.format_list_numbered_rounded,
                        svg_name: 'menu',
                        vertical: true,
                        label: tr('comics.chapters'),
                        on_pressed: on_open_catalog,
                      ),
                    ),
                    Expanded(
                      child: ComicReaderControlButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        svg_name: 'message',
                        vertical: true,
                        label: tr('comics.chapter_comments'),
                        on_pressed: on_comments,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
