// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/pages/comics/reader/style.dart';
import 'package:app/pages/comics/reader/widgets/control_button.dart';
import 'package:app/pages/comics/style.dart';

/// TODO 对齐小说ReadTopBar：纯色紧凑导航、原有right图标返回，不另造圆角卡片按钮。
class ComicReaderTopScrim extends StatelessWidget {
  final String title;
  final String comic_title;
  final VoidCallback on_back;
  final VoidCallback on_open_catalog;
  final VoidCallback on_comments;
  const ComicReaderTopScrim({
    super.key,
    required this.title,
    this.comic_title = '',
    required this.on_back,
    required this.on_open_catalog,
    required this.on_comments,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: ComicReaderStyle.panel_background(context),
    ),
    child: SafeArea(
      bottom: false,
      child: WindowReservedRegionPadding(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ComicReaderStyle.toolbar_padding,
          ),
          child: Row(
            children: <Widget>[
              ComicReaderControlButton(
                icon: Icons.arrow_back_rounded,
                svg_name: 'right',
                reverse_icon: true,
                label: easy.tr('comics.reader_back'),
                on_pressed: on_back,
                icon_only: true,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: ComicReaderStyle.top_title_padding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        comic_title.isEmpty ? title : comic_title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ComicReaderStyle.foreground(context),
                          fontSize: ComicReaderStyle.pick_font_size(
                            is_cjk: ComicsStyle.is_cjk(context),
                            cjk: ComicReaderStyle.title_font_size_cjk,
                            alphabetic:
                                ComicReaderStyle.title_font_size_alphabetic,
                          ),
                          fontWeight: ComicReaderStyle.weight_medium,
                        ),
                      ),
                      if (comic_title.isNotEmpty)
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ComicReaderStyle.secondary_foreground(
                              context,
                            ),
                            fontSize: ComicReaderStyle.subtitle_size,
                            fontWeight: ComicReaderStyle.weight_regular,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              ComicReaderControlButton(
                icon: Icons.chat_bubble_outline_rounded,
                svg_name: 'message',
                label: easy.tr('comics.chapter_comments'),
                on_pressed: on_comments,
                icon_only: true,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
