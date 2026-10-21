// ignore_for_file: non_constant_identifier_names

import 'package:app/components/svg_icon/index.dart';
import 'package:app/pages/comics/widgets/comment_sheet/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// TODO 区分空评论与加载失败；空状态直接唤起共用输入框，不跳转新页面。
class ComicCommentSheetFeedback extends StatelessWidget {
  const ComicCommentSheetFeedback({
    super.key,
    required this.is_dark,
    required this.on_write,
    required this.on_retry,
    this.error,
  });
  final bool is_dark;
  final String? error;
  final VoidCallback on_write;
  final VoidCallback on_retry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      ComicCommentSheetStyle.horizontal_padding,
      ComicCommentSheetStyle.feedback_top,
      ComicCommentSheetStyle.horizontal_padding,
      ComicCommentSheetStyle.feedback_bottom,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ComicCommentSheetStyle.feedback_max_width,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: ComicCommentSheetStyle.feedback_icon_surface,
              height: ComicCommentSheetStyle.feedback_icon_surface,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ComicCommentSheetStyle.icon_tint(is_dark),
              ),
              child: Center(
                child: error == null
                    ? SvgIcon(
                        name: 'customer_service',
                        width: ComicCommentSheetStyle.feedback_icon,
                        height: ComicCommentSheetStyle.feedback_icon,
                        color: ComicCommentSheetStyle.foreground(is_dark),
                        animateColor: false,
                      )
                    : Icon(
                        Icons.cloud_off_outlined,
                        size: ComicCommentSheetStyle.feedback_icon,
                        color: ComicCommentSheetStyle.secondary(is_dark),
                      ),
              ),
            ),
            const SizedBox(height: ComicCommentSheetStyle.feedback_gap),
            Text(
              error ?? tr('comics.empty_comments'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ComicCommentSheetStyle.secondary(is_dark),
                fontSize: ComicCommentSheetStyle.localized_size(
                  context,
                  ComicCommentSheetStyle.feedback_font_cjk,
                  ComicCommentSheetStyle.feedback_font_alphabetic,
                ),
                fontWeight: ComicCommentSheetStyle.regular,
                height: ComicCommentSheetStyle.feedback_line_height,
              ),
            ),
            const SizedBox(height: ComicCommentSheetStyle.header_gap),
            TextButton(
              onPressed: error == null ? on_write : on_retry,
              style: TextButton.styleFrom(
                foregroundColor: ComicCommentSheetStyle.foreground(is_dark),
                backgroundColor: ComicCommentSheetStyle.soft_surface(is_dark),
                minimumSize: const Size(0, ComicCommentSheetStyle.close_target),
              ),
              child: Text(
                tr(error == null ? 'comment.input_hint' : 'comics.retry'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
