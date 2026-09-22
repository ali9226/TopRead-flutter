// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'style.dart';

/// 由不可选 WidgetSpan 承载的段评气泡，与正文共同行内排版但不参与选区。
class ParagraphCommentBadge extends StatelessWidget {
  const ParagraphCommentBadge({
    super.key,
    required this.comment_count,
    required this.is_dark,
    required this.is_cjk,
    this.on_tap,
  });

  final int comment_count;
  final bool is_dark;
  final bool is_cjk;
  final VoidCallback? on_tap;

  /// 布局与实际 Text 共用测量参数，支持系统放大字体及多位数字。
  static Size measure({
    required int comment_count,
    required TextStyle style,
    required TextScaler text_scaler,
    required TextDirection text_direction,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: comment_count.toString(), style: style),
      textScaler: text_scaler,
      textDirection: text_direction,
    )..layout();
    final Size size = Size(
      math.max(
        ParagraphSelectionStyle.badge_min_width,
        painter.width + ParagraphSelectionStyle.badge_horizontal_padding * 2,
      ),
      math.max(
        ParagraphSelectionStyle.badge_height,
        painter.height + ParagraphSelectionStyle.badge_tail_size * 2,
      ),
    );
    painter.dispose();
    return size;
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'paragraph_comment.count_label'.tr(
      namedArgs: <String, String>{'count': comment_count.toString()},
    ),
    button: on_tap != null,
    onTap: on_tap,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: on_tap,
      child: CustomPaint(
        painter: _CommentBubblePainter(
          color: ParagraphSelectionStyle.badge_color(is_dark),
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            bottom: ParagraphSelectionStyle.badge_tail_size,
          ),
          child: Center(
            child: Text(
              comment_count.toString(),
              style: ParagraphSelectionStyle.badge_text_style(
                is_dark: is_dark,
                is_cjk: is_cjk,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// 描边聊天气泡；下侧折角与圆角矩形一次描边，没有重叠接缝。
class _CommentBubblePainter extends CustomPainter {
  const _CommentBubblePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = ParagraphSelectionStyle.badge_border_width;
    const double radius = ParagraphSelectionStyle.badge_radius;
    const double tail = ParagraphSelectionStyle.badge_tail_size;
    const double inset = stroke / 2;
    final double right = size.width - inset;
    final double bottom = size.height - tail - inset;
    final Path path = Path()
      ..moveTo(radius, inset)
      ..lineTo(right - radius, inset)
      ..quadraticBezierTo(right, inset, right, radius)
      ..lineTo(right, bottom - radius)
      ..quadraticBezierTo(right, bottom, right - radius, bottom)
      ..lineTo(radius + tail, bottom)
      ..lineTo(radius, size.height - inset)
      ..lineTo(radius, bottom)
      ..quadraticBezierTo(inset, bottom, inset, bottom - radius)
      ..lineTo(inset, radius)
      ..quadraticBezierTo(inset, inset, radius, inset)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_CommentBubblePainter old_delegate) =>
      old_delegate.color != color;
}
