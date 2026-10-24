import 'package:app/config/font_config.dart';
import 'package:app/pages/read/utils/read_models.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import 'style.dart';

/// 按真实字体、语种、宽度和系统字号测量长评，只有确实超过四行才提供展开。
class ReadReviewContent extends StatefulWidget {
  const ReadReviewContent({
    super.key,
    required this.comment,
    required this.is_dark,
  });
  final ReadComment comment;
  final bool is_dark;

  @override
  State<ReadReviewContent> createState() => _ReadReviewContentState();
}

class _ReadReviewContentState extends State<ReadReviewContent> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final style = DefaultTextStyle.of(context).style.merge(
      TextStyle(
        color: CommentItemStyle.text_color(widget.is_dark),
        fontSize: cjk
            ? CommentItemStyle.text_font_size_cjk
            : CommentItemStyle.text_font_size_alphabetic,
        height: cjk
            ? CommentItemStyle.text_line_height_cjk
            : CommentItemStyle.text_line_height_alphabetic,
        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.comment.content, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.localeOf(context),
          maxLines: CommentItemStyle.collapsed_lines,
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();
        final label = easy.tr(
          _expanded ? 'comics.show_less' : 'comics.show_more',
        );
        return AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : CommentItemStyle.toggle_duration,
          alignment: AlignmentDirectional.topStart,
          curve: Curves.easeInOutCubic,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.comment.content,
                key: ValueKey('read_comment_content_${widget.comment.user_id}'),
                maxLines: _expanded ? null : CommentItemStyle.collapsed_lines,
                overflow: _expanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: style,
              ),
              if (overflows)
                Semantics(
                  expanded: _expanded,
                  child: TextButton(
                    key: ValueKey(
                      'read_comment_toggle_${widget.comment.user_id}',
                    ),
                    onPressed: () => setState(() => _expanded = !_expanded),
                    style: TextButton.styleFrom(
                      foregroundColor: CommentItemStyle.name_color(
                        widget.is_dark,
                      ),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(
                        0,
                        CommentItemStyle.toggle_extent,
                      ),
                      alignment: AlignmentDirectional.centerStart,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          CommentItemStyle.toggle_radius,
                        ),
                      ),
                      textStyle: Theme.of(context).textTheme.labelLarge!
                          .copyWith(
                            fontSize: cjk
                                ? CommentItemStyle.toggle_size_cjk
                                : CommentItemStyle.toggle_size_alphabetic,
                            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                          ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: Text(label)),
                        const SizedBox(width: CommentItemStyle.toggle_icon_gap),
                        Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          size: CommentItemStyle.toggle_icon_size,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
