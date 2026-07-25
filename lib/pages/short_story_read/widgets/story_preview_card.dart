import 'package:easy_localization/easy_localization.dart';
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

import 'package:app/models/short_story_item.dart';
import 'package:app/pages/short_story_read/style.dart';

/// 小说预览提示组件。
///
/// 在正文底部展示"滑动查看下一篇"提示，
/// 或在正文顶部展示"松开查看上一篇"提示。
class StoryPreviewCard extends StatelessWidget {
  /// 小说数据。
  final ShortStoryItem item;

  /// 是否为夜间模式。
  final bool is_dark;

  /// 预览类型（next = 下一篇提示，previous = 上一篇提示）。
  final PreviewType type;

  const StoryPreviewCard({
    super.key,
    required this.item,
    required this.is_dark,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    /// 次要文字颜色。
    final Color secondary_color = is_dark
        ? ShortStoryReadStyle.secondary_dark_color
        : ShortStoryReadStyle.secondary_light_color;

    if (type == PreviewType.previous) {
      return _buildPreviousIndicator(secondary_color: secondary_color);
    }

    return _buildNextIndicator(secondary_color: secondary_color);
  }

  /// 构建上一篇提示（松开查看）。
  Widget _buildPreviousIndicator({required Color secondary_color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.keyboard_arrow_down,
              color: secondary_color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              tr('short_story_read.release_to_view'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                color: secondary_color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                color: secondary_color.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建下一篇提示（滑动查看下一篇）。
  Widget _buildNextIndicator({required Color secondary_color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.keyboard_arrow_up,
              color: secondary_color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              tr('short_story_read.scroll_to_view_next'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                color: secondary_color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                color: secondary_color.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// 预览类型枚举。
enum PreviewType {
  /// 下一篇提示（正文底部）。
  next,

  /// 上一篇提示（正文顶部）。
  previous,
}
