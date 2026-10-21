// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:app/pages/comics/detail/style.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
    padding: const EdgeInsets.all(_QuickActionsStyle.padding),
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
        const SizedBox(width: _QuickActionsStyle.gap),
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
    return Material(
      color: ComicDetailStyle.card_background(dark),
      borderRadius: BorderRadius.circular(_QuickActionsStyle.radius),
      child: InkWell(
        key: ValueKey(action_key),
        onTap: on_tap,
        borderRadius: BorderRadius.circular(_QuickActionsStyle.radius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: _QuickActionsStyle.height,
          ),
          child: Padding(
            padding: const EdgeInsets.all(_QuickActionsStyle.inner_padding),
            child: Row(
              children: [
                SvgIcon(
                  name: icon_name,
                  width: _QuickActionsStyle.icon_size,
                  height: _QuickActionsStyle.icon_size,
                  color: ComicDetailStyle.ink(context),
                  animateColor: false,
                ),
                const SizedBox(width: _QuickActionsStyle.gap),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: cjk
                          ? _QuickActionsStyle.font_size_cjk
                          : _QuickActionsStyle.font_size_alphabetic,
                      fontWeight: ComicDetailStyle.weight_medium,
                      color: ComicDetailStyle.ink(context),
                    ),
                  ),
                ),
                const SizedBox(width: _QuickActionsStyle.count_gap),
                Text(
                  ComicDetailStyle.format_count(count),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: _QuickActionsStyle.count_size,
                    color: ComicDetailStyle.muted(context),
                    fontWeight: ComicDetailStyle.weight_regular,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: _QuickActionsStyle.arrow_size,
                  color: ComicDetailStyle.muted(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionsStyle {
  static const double padding = 16;
  static const double inner_padding = 12;
  static const double gap = 8;
  static const double count_gap = 4;
  static const double radius = 14;
  static const double height = 56;
  static const double icon_size = 20;
  static const double arrow_size = 18;
  static const double count_size = 11;
  static const double font_size_cjk = 14;
  static const double font_size_alphabetic = 12;
}
