// ignore_for_file: non_constant_identifier_names

import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';

import 'comment_badge.dart';
import 'style.dart';

/// 独立更新不可选气泡的布局，外层 WidgetSpan 始终保持同一实例。
class InlineParagraphCommentBadge extends StatelessWidget {
  const InlineParagraphCommentBadge({
    super.key,
    required this.comment_count,
    required this.is_dark,
    required this.on_tap,
  });

  /// 当前段落的实时评论数量；零评论不占用行内空间。
  final int comment_count;

  /// 阅读主题决定文字与气泡描边颜色。
  final bool is_dark;

  /// 使用父组件当前段落信息打开段评列表。
  final VoidCallback on_tap;

  @override
  Widget build(BuildContext context) {
    if (comment_count <= 0) return const SizedBox.shrink();
    final is_cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final badge_size = ParagraphCommentBadge.measure(
      comment_count: comment_count,
      style: ParagraphSelectionStyle.badge_text_style(
        is_dark: is_dark,
        is_cjk: is_cjk,
      ),
      text_scaler: MediaQuery.textScalerOf(context),
      text_direction: Directionality.of(context),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: ParagraphSelectionStyle.badge_gap,
      ),
      child: SizedBox(
        width: badge_size.width,
        height: badge_size.height,
        child: ParagraphCommentBadge(
          comment_count: comment_count,
          is_dark: is_dark,
          is_cjk: is_cjk,
          on_tap: on_tap,
        ),
      ),
    );
  }
}
