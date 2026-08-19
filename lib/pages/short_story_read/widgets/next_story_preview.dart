import 'package:flutter/material.dart';

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/components/novel_cover/index.dart';
import 'package:app/models/short_story_item.dart';
import 'package:app/pages/short_story_read/style.dart';

/// 下一篇小说预览区域。
///
/// 展示下一篇小说的标题、标签和简介预览，
/// 包含与当前篇之间的衔接装饰（分割线 + 胶囊标题）。
class NextStoryPreview extends StatelessWidget {
  /// 下一篇小说数据。
  final ShortStoryItem next_story;

  /// 正文字号。
  final double body_font_size;

  /// 是否为夜间模式。
  final bool is_dark;

  /// 是否为 CJK 语种。
  final bool is_cjk;

  /// 标题字号。
  final double title_font_size;

  /// 标题颜色。
  final Color title_color;

  /// 正文颜色。
  final Color body_color;

  /// 次要文字颜色。
  final Color secondary_color;

  /// 预览区域高度。
  final double preview_body_height;

  /// 预览最大行数。
  final int preview_max_lines;

  /// 预览行高。
  final double preview_line_height;

  /// 预览内容文本。
  final String preview_content;

  /// 标题定位 key（用于判断是否进入可视区域）。
  final GlobalKey? title_key;

  /// 本地化文本获取函数。
  final String Function(String key) reader_text;

  const NextStoryPreview({
    super.key,
    required this.next_story,
    required this.body_font_size,
    required this.is_dark,
    required this.is_cjk,
    required this.title_font_size,
    required this.title_color,
    required this.body_color,
    required this.secondary_color,
    required this.preview_body_height,
    required this.preview_max_lines,
    required this.preview_line_height,
    required this.preview_content,
    this.title_key,
    required this.reader_text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 42),
          _buildBridgeDivider(),
          const SizedBox(height: 30),
          _buildTitle(),
          if (next_story.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildTags(),
          ],
          const SizedBox(height: 18),
          _buildPreviewText(),
        ],
      ),
    );
  }

  /// 构建标题（有封面时左侧显示封面缩略图）。
  Widget _buildTitle() {
    final Widget titleText = Text(
      next_story.title,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: title_font_size,
        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
        color: title_color,
        height: 1.4,
      ),
    );

    if (next_story.cover_url.isNotEmpty) {
      return Row(
        key: title_key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          NovelCover(
            image_url: next_story.cover_url,
            width: 48,
            height: 64,
            border_radius: 6,
            is_dark: is_dark,
          ),
          const SizedBox(width: 12),
          Expanded(child: titleText),
        ],
      );
    }

    return Text(
      next_story.title,
      key: title_key,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: title_font_size,
        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
        color: title_color,
        height: 1.4,
      ),
    );
  }

  /// 构建标签列表。
  Widget _buildTags() {
    return Wrap(
      spacing: ShortStoryReadStyle.tag_spacing,
      runSpacing: ShortStoryReadStyle.tag_spacing,
      children: List<Widget>.generate(next_story.tags.length, (int index) {
        final Color tag_color = ColorConstants
                .tagColorList[(next_story.id * 7 + index * 3) %
            ColorConstants.tagColorList.length];
        final Color tag_bg = tag_color.withValues(alpha: 0.12);

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: is_cjk ? 6 : 8,
            vertical: ShortStoryReadStyle.tag_vertical_padding,
          ),
          decoration: BoxDecoration(
            color: tag_bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            next_story.tags[index],
            style: TextStyle(
              fontSize: ShortStoryReadStyle.tag_font_size,
              color: tag_color,
            ),
          ),
        );
      }),
    );
  }

  /// 构建简介预览文本。
  Widget _buildPreviewText() {
    return SizedBox(
      width: double.infinity,
      height: preview_body_height,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            preview_content,
            softWrap: true,
            maxLines: preview_max_lines,
            overflow: TextOverflow.fade,
            style: TextStyle(
              fontSize: body_font_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              color: body_color,
              height: preview_line_height,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建当前篇和下一篇之间的衔接装饰。
  Widget _buildBridgeDivider() {
    final Color line_color = is_dark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);
    final Color dot_color = is_dark
        ? Colors.white.withValues(alpha: 0.28)
        : Colors.black.withValues(alpha: 0.18);
    final Color pill_bg = is_dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.035);

    Widget line() {
      return Expanded(
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                line_color.withValues(alpha: 0.0),
                line_color,
                line_color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      );
    }

    Widget dot(double size, double opacity) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dot_color.withValues(alpha: opacity),
        ),
      );
    }

    return Row(
      children: <Widget>[
        line(),
        const SizedBox(width: 12),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: is_cjk ? 14 : 16,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: pill_bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: line_color),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              dot(4, 0.55),
              const SizedBox(width: 7),
              Text(
                reader_text('next_story'),
                style: TextStyle(
                  fontSize: is_cjk ? 12 : 11,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                  letterSpacing: is_cjk ? 0.2 : 0.8,
                  color: secondary_color,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 7),
              dot(4, 0.55),
            ],
          ),
        ),
        const SizedBox(width: 12),
        line(),
      ],
    );
  }
}
