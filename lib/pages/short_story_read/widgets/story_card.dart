import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';

import 'package:app/pages/short_story_read/style.dart';
import 'package:app/pages/short_story_read/models/story_card_data.dart';
import 'package:app/pages/short_story_read/widgets/tag_list.dart';
import 'package:app/pages/short_story_read/widgets/collapse_button.dart';
import 'package:app/pages/short_story_read/widgets/inline_comment_bar.dart';
import 'package:app/util/language_util/index.dart';

/// 故事卡片组件。
///
/// 阅读页面的核心卡片，展示单篇短篇小说的内容。
/// 支持两种状态：
/// - **展开状态**：显示完整标题、标签、正文内容和评论栏。
/// - **收起状态**：固定高度 450px，底部显示渐变遮罩和展开按钮。
///
/// 点击卡片时触发 [on_card_tap] 回调，由父组件控制展开/收起切换。
class StoryCard extends StatelessWidget {
  /// 卡片数据。
  final StoryCardData data;

  /// 卡片在列表中的索引。
  final int index;

  /// 当前是否为展开状态。
  final bool is_expanded;

  /// 是否为夜间模式。
  final bool is_dark;

  /// 标题文字颜色。
  final Color title_color;

  /// 卡片点击回调（点击展开状态区域切换导航栏，点击收起状态展开卡片）。
  final VoidCallback on_card_tap;

  /// 展开/收起按钮点击回调。
  final VoidCallback on_toggle_expand;

  /// 评论输入框点击回调。
  final VoidCallback on_comment_tap;

  /// 点赞按钮点击回调。
  final VoidCallback on_like_tap;

  const StoryCard({
    super.key,
    required this.data,
    required this.index,
    required this.is_expanded,
    required this.is_dark,
    required this.title_color,
    required this.on_card_tap,
    required this.on_toggle_expand,
    required this.on_comment_tap,
    required this.on_like_tap,
  });

  @override
  Widget build(BuildContext context) {
    /// 卡片背景色。
    final Color card_bg = is_dark
        ? ShortStoryReadStyle.card_dark_bg
        : ShortStoryReadStyle.card_light_bg;

    /// 次要文字颜色。
    final Color secondary_color = is_dark
        ? ShortStoryReadStyle.secondary_dark_color
        : ShortStoryReadStyle.secondary_light_color;

    /// 正文文字颜色。
    final Color body_color = is_dark
        ? ShortStoryReadStyle.body_dark_color
        : ShortStoryReadStyle.body_light_color;

    /// 阴影颜色。
    final Color shadow_color = is_dark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.08);

    /// 正文内容（优先使用 content，如果没有则使用 description）。
    final String display_content =
        data.content.isNotEmpty ? data.content : data.description;

    /// 当前语种是否为 CJK。
    final bool is_cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );

    /// 标题字号（CJK 语系字号稍大）。
    final double title_font_size = is_cjk ? 20.0 : 18.0;

    /// 正文字号。
    final double body_font_size = is_cjk ? 17.0 : 15.5;

    return GestureDetector(
      onTap: on_card_tap,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: card_bg,
            boxShadow: [
              BoxShadow(
                color: shadow_color,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: is_expanded
              ? _buildExpandedContent(
                  display_content: display_content,
                  title_font_size: title_font_size,
                  body_font_size: body_font_size,
                  body_color: body_color,
                  secondary_color: secondary_color,
                  is_cjk: is_cjk,
                )
              : _buildCollapsedContent(
                  card_bg: card_bg,
                  display_content: display_content,
                  title_font_size: title_font_size,
                  body_font_size: body_font_size,
                  body_color: body_color,
                  secondary_color: secondary_color,
                  is_cjk: is_cjk,
                ),
        ),
      ),
    );
  }

  /// 构建展开状态的内容。
  ///
  /// 显示完整标题、标签、正文和评论栏。
  Widget _buildExpandedContent({
    required String display_content,
    required double title_font_size,
    required double body_font_size,
    required Color body_color,
    required Color secondary_color,
    required bool is_cjk,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// 标题。
          Text(
            data.title,
            style: TextStyle(
              fontSize: title_font_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
              color: title_color,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),

          /// 标签列表（最多显示 3 个）。
          if (data.tags.isNotEmpty)
            TagList(
              tags: data.tags.take(3).toList(),
              is_dark: is_dark,
              story_id: data.id,
              is_cjk: is_cjk,
            ),
          const SizedBox(height: 12),

          /// 正文内容。
          Flexible(
            child: Text(
              display_content,
              style: TextStyle(
                fontSize: body_font_size,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                color: body_color,
                height: is_cjk ? 1.7 : 1.6,
              ),
            ),
          ),
          const SizedBox(height: 16),

          /// 评论栏（展开状态下显示在正文下方）。
          InlineCommentBar(
            is_dark: is_dark,
            comment_count: data.comment_count,
            like_count: data.like_count,
            is_liked: data.is_liked,
            on_comment_tap: on_comment_tap,
            on_like_tap: on_like_tap,
          ),
        ],
      ),
    );
  }

  /// 构建收起状态的内容。
  ///
  /// 固定高度 450px，底部显示渐变遮罩和展开按钮。
  Widget _buildCollapsedContent({
    required Color card_bg,
    required String display_content,
    required double title_font_size,
    required double body_font_size,
    required Color body_color,
    required Color secondary_color,
    required bool is_cjk,
  }) {
    return SizedBox(
      height: 450,
      child: Stack(
        children: <Widget>[
          /// 内容区域（标题 + 标签 + 正文）。
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  /// 标题（最多 2 行，溢出省略）。
                  Text(
                    data.title,
                    style: TextStyle(
                      fontSize: title_font_size,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                      color: title_color,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  /// 标签列表（最多显示 3 个）。
                  if (data.tags.isNotEmpty)
                    TagList(
                      tags: data.tags.take(3).toList(),
                      is_dark: is_dark,
                      story_id: data.id,
                      is_cjk: is_cjk,
                    ),
                  const SizedBox(height: 12),

                  /// 正文内容（溢出部分被渐变遮罩覆盖）。
                  Expanded(
                    child: Text(
                      display_content,
                      style: TextStyle(
                        fontSize: body_font_size,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                        color: body_color,
                        height: is_cjk ? 1.7 : 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// 底部渐变遮罩（从透明过渡到卡片背景色，营造内容被截断的视觉效果）。
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.3, 1.0],
                  colors: [
                    card_bg.withValues(alpha: 0),
                    card_bg.withValues(alpha: 0.7),
                    card_bg,
                  ],
                ),
              ),
            ),
          ),

          /// 展开按钮（显示在卡片右下角）。
          Positioned(
            bottom: 12,
            right: 12,
            child: CollapseButton(
              is_dark: is_dark,
              is_expanded: false,
              on_tap: on_toggle_expand,
            ),
          ),
        ],
      ),
    );
  }
}
