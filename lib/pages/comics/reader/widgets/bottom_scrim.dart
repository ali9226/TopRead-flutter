// ignore_for_file: non_constant_identifier_names

import 'package:app/components/window_content_layout/index.dart';
import 'package:app/components/reader_bottom_action/style.dart';
import 'package:app/pages/comics/reader/style.dart';
import 'package:app/pages/comics/reader/widgets/control_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// TODO 与小说阅读底栏共用图标与触控规格，目录/进度/外观/评论均在当前阅读页操作。
class ComicReaderBottomScrim extends StatelessWidget {
  const ComicReaderBottomScrim({
    super.key,
    this.page_index = 0,
    this.page_count = 0,
    this.has_previous_chapter = false,
    this.has_next_chapter = false,
    this.on_previous_chapter,
    this.on_next_chapter,
    this.on_open_catalog,
    this.on_comments,
    this.on_progress,
    this.on_appearance,
    this.comment_count = 0,
  });
  final int page_index;
  final int page_count;
  final bool has_previous_chapter;
  final bool has_next_chapter;
  final VoidCallback? on_previous_chapter;
  final VoidCallback? on_next_chapter;
  final VoidCallback? on_open_catalog;
  final VoidCallback? on_comments;
  final VoidCallback? on_progress;
  final VoidCallback? on_appearance;
  final int comment_count;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ComicReaderStyle.panel_background(context),
        border: Border(
          top: BorderSide(
            color: ComicReaderStyle.border_color(context),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: ReaderBottomActionStyle.safe_bottom(context),
        ),
        child: WindowContentLayout(
          expand_height: false,
          child: SizedBox(
            height: ComicReaderStyle.bottom_bar_height(context),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ComicReaderControlButton(
                    icon: Icons.menu_book_outlined,
                    svg_name: 'qr_code',
                    label: tr('comics.reader_catalog'),
                    on_pressed: on_open_catalog,
                    vertical: true,
                  ),
                ),
                Expanded(
                  child: ComicReaderControlButton(
                    icon: Icons.timelapse_rounded,
                    svg_name: 'positioning',
                    label: tr('comics.reader_progress'),
                    on_pressed: on_progress,
                    vertical: true,
                  ),
                ),
                Expanded(
                  child: ComicReaderControlButton(
                    icon: dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    svg_name: dark ? 'sun_2' : 'night_mode',
                    label: tr(
                      dark ? 'comics.reader_day' : 'comics.reader_night',
                    ),
                    on_pressed: on_appearance,
                    vertical: true,
                  ),
                ),
                Expanded(
                  child: ComicReaderControlButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    svg_name: 'customer_service',
                    label: comment_count > 0
                        ? '${tr('comics.comments_tab')} ${comment_count > 999 ? '999+' : comment_count}'
                        : tr('comics.comments_tab'),
                    on_pressed: on_comments,
                    vertical: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
