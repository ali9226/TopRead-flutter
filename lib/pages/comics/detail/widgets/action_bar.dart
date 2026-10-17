// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:app/config/color_config.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:flutter/material.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/style.dart';

/// 行动栏保留明确主次层级；长章节名和辅助大字号自然换行，不用缩放文字牺牲可读性。
class ComicDetailActionBar extends StatelessWidget {
  final bool collected;
  final bool collecting;
  final bool can_read;
  final bool can_continue;
  final String? chapter_title;
  final VoidCallback on_collect;
  final VoidCallback on_read;
  const ComicDetailActionBar({
    super.key,
    required this.collected,
    required this.collecting,
    required this.can_read,
    required this.can_continue,
    this.chapter_title,
    required this.on_collect,
    required this.on_read,
  });

  @override
  Widget build(BuildContext context) {
    final is_dark = ComicDetailStyle.is_dark(context);
    final is_cjk = ComicsStyle.is_cjk(context);
    final label = can_continue && chapter_title?.trim().isNotEmpty == true
        ? tr(
            'comics.continue_chapter',
            namedArgs: <String, String>{'chapter': chapter_title!},
          )
        : tr(can_continue ? 'comics.continue_reading' : 'comics.start_reading');
    final button_text =
        (Theme.of(context).textTheme.labelLarge ?? const TextStyle()).copyWith(
          fontSize: ComicDetailStyle.pick_font_size(
            is_cjk: is_cjk,
            cjk: ComicDetailStyle.action_bar_primary_font_size,
            alphabetic: ComicDetailStyle.action_bar_secondary_font_size,
          ),
          height: ComicDetailStyle.pick_font_size(
            is_cjk: is_cjk,
            cjk: ComicDetailStyle.action_text_line_height_cjk,
            alphabetic: ComicDetailStyle.action_text_line_height_alphabetic,
          ),
          fontWeight: ComicDetailStyle.weight_medium,
        );
    final collect_foreground = collected && is_dark
        ? ColorConstants.themeColor
        : ComicDetailStyle.ink(context);
    final collect = Semantics(
      toggled: collected,
      enabled: !collecting,
      child: TextButton.icon(
        key: const ValueKey('comic_detail_collect'),
        onPressed: collecting ? null : on_collect,
        style: TextButton.styleFrom(
          foregroundColor: collect_foreground,
          minimumSize: const Size(0, ComicDetailStyle.action_bar_button_height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ComicDetailStyle.action_bar_button_radius,
            ),
          ),
          textStyle: button_text,
          padding: ComicDetailStyle.collect_padding,
        ),
        icon: collecting
            ? const SizedBox.square(
                dimension: ComicDetailStyle.collect_icon_size,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : SvgIcon(
                name: collected ? 'user_selected' : 'not_favorited',
                width: ComicDetailStyle.collect_icon_size,
                height: ComicDetailStyle.collect_icon_size,
                color: collect_foreground,
              ),
        label: Text(
          tr(collected ? 'comics.collected' : 'comics.collect'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
    final read = FilledButton(
      key: const ValueKey('comic_detail_read'),
      onPressed: can_read ? on_read : null,
      style: FilledButton.styleFrom(
        backgroundColor: ColorConstants.themeColor,
        foregroundColor: ColorConstants.lightTextColor,
        disabledBackgroundColor: ComicDetailStyle.outline(context),
        disabledForegroundColor: ComicDetailStyle.muted(context),
        minimumSize: const Size(0, ComicDetailStyle.action_bar_button_height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ComicDetailStyle.action_bar_button_radius,
          ),
        ),
        padding: ComicDetailStyle.read_padding,
        textStyle: button_text,
      ),
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );

    return ColoredBox(
      color: ComicDetailStyle.card_background(is_dark),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: ComicsStyle.content_width,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ComicDetailStyle.action_bar_padding_h,
                vertical: ComicDetailStyle.action_bar_padding_v,
              ),
              child: Row(
                children: <Widget>[
                  Flexible(flex: 2, child: collect),
                  const SizedBox(width: ComicDetailStyle.action_bar_spacing),
                  Expanded(flex: 5, child: read),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
