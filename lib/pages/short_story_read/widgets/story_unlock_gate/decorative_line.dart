import 'package:app/pages/short_story_read/style.dart';
import 'package:flutter/material.dart';

/// 解锁文案两侧的水平渐变细线。
class DecorativeLine extends StatelessWidget {
  const DecorativeLine({
    required this.color,
    required this.fade_towards_end,
    super.key,
  });

  /// 细线中心颜色。
  final Color color;

  /// 是否向右侧渐隐。
  final bool fade_towards_end;

  @override
  Widget build(BuildContext context) {
    final Color transparent_color = color.withValues(alpha: 0);
    return Expanded(
      child: Container(
        height: ShortStoryReadStyle.unlock_line_height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: fade_towards_end
                ? <Color>[color, transparent_color]
                : <Color>[transparent_color, color],
          ),
        ),
      ),
    );
  }
}
