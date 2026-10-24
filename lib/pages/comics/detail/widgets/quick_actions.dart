// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:app/pages/comics/detail/style.dart';
import 'package:app/components/reader_action_icon/index.dart';
import 'package:app/components/work_section_card/index.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// TODO 单页详情的目录与评论入口，两个弹窗不挤占作品简介的阅读空间。
class ComicDetailQuickActions extends StatelessWidget {
  const ComicDetailQuickActions({
    super.key,
    required this.chapter_count,
    required this.comment_count,
    required this.on_chapters,
    required this.on_comments,
  });
  final int chapter_count;
  final int comment_count;
  final VoidCallback on_chapters;
  final VoidCallback on_comments;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: LayoutConfig.page_horizontal_padding,
      vertical: ComicDetailStyle.quick_action_padding,
    ),
    child: Row(
      children: [
        Expanded(
          child: _action(
            context,
            icon_name: 'qr_code',
            text: tr('comics.chapters'),
            count: chapter_count,
            on_tap: on_chapters,
            action_key: 'comic_detail_chapters',
          ),
        ),
        const SizedBox(width: ComicDetailStyle.quick_action_gap),
        Expanded(
          child: _action(
            context,
            icon_name: 'customer_service',
            text: tr('comics.comments_tab'),
            count: comment_count,
            on_tap: on_comments,
            action_key: 'comic_detail_comments',
          ),
        ),
      ],
    ),
  );

  Widget _action(
    BuildContext context, {
    required String icon_name,
    required String text,
    required int count,
    required VoidCallback on_tap,
    required String action_key,
  }) {
    final dark = ComicDetailStyle.is_dark(context);
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    return WorkSectionCard(
      is_dark: dark,
      padding: EdgeInsets.zero,
      child: Material(
        color: ColorConstants.transparent,
        borderRadius: BorderRadius.circular(LayoutConfig.card_radius),
        child: InkWell(
          key: ValueKey(action_key),
          onTap: on_tap,
          borderRadius: BorderRadius.circular(LayoutConfig.card_radius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: ComicDetailStyle.quick_action_height,
            ),
            child: Padding(
              padding: const EdgeInsets.all(
                ComicDetailStyle.quick_action_inner_padding,
              ),
              child: Row(
                children: [
                  ReaderActionIcon(
                    name: icon_name,
                    size: ComicDetailStyle.quick_action_icon_size,
                    color: ComicDetailStyle.ink(context),
                  ),
                  const SizedBox(width: ComicDetailStyle.quick_action_gap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          text,
                          style: TextStyle(
                            fontSize: cjk
                                ? ComicDetailStyle.quick_action_font_cjk
                                : ComicDetailStyle.quick_action_font_alphabetic,
                            height: ComicDetailStyle.quick_action_line_height,
                            fontWeight: ComicDetailStyle.weight_medium,
                            color: ComicDetailStyle.ink(context),
                          ),
                        ),
                        const SizedBox(
                          height: ComicDetailStyle.quick_action_count_gap,
                        ),
                        Text(
                          ComicDetailStyle.format_count(count),
                          style: TextStyle(
                            fontSize: cjk
                                ? ComicDetailStyle.quick_action_count_cjk
                                : ComicDetailStyle
                                      .quick_action_count_alphabetic,
                            height: ComicDetailStyle.quick_action_line_height,
                            color: ComicDetailStyle.muted(context),
                            fontWeight: ComicDetailStyle.weight_regular,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: ComicDetailStyle.quick_action_arrow_size,
                    color: ComicDetailStyle.muted(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
