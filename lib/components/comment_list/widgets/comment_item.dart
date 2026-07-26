import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app/components/comment_list/models/comment_data.dart';
import 'package:app/components/comment_list/style.dart';
import 'package:app/components/comment_list/widgets/comment_avatar.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';

/// 评论回复点击回调，同时返回被点击区域的真实布局上下文。
typedef CommentReplyCallback =
    void Function(CommentData comment, BuildContext target_context);

typedef CommentTargetKeyBuilder = GlobalKey Function(int comment_id);

/// 微信视频号式评论项。
///
/// 主评论使用“头像 + 内容 + 右侧点赞”的清晰结构；回复收进轻量灰色区域，
/// 不再重复渲染多层头像和分割卡片，降低长回复列表的布局与图片解码开销。
class CommentItem extends StatelessWidget {
  final CommentData comment;
  final bool is_dark;
  final CommentReplyCallback on_reply;
  final ValueChanged<CommentData> on_like;
  final int highlighted_comment_id;
  final CommentTargetKeyBuilder? target_key_builder;

  const CommentItem({
    super.key,
    required this.comment,
    required this.is_dark,
    required this.on_reply,
    required this.on_like,
    this.highlighted_comment_id = 0,
    this.target_key_builder,
  });

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );
    final Color text_color = is_dark
        ? CommentListStyle.title_dark_color
        : CommentListStyle.title_light_color;
    final Color secondary_color = is_dark
        ? CommentListStyle.secondary_dark_color
        : CommentListStyle.secondary_light_color;
    final Color name_color = is_dark
        ? CommentListStyle.nickname_dark_color
        : CommentListStyle.nickname_light_color;
    final Color divider_color = is_dark
        ? CommentListStyle.divider_dark_color
        : CommentListStyle.divider_light_color;

    final bool is_highlighted = highlighted_comment_id == comment.id;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CommentListStyle.list_horizontal_padding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _HighlightWrapper(
              highlighted: is_highlighted,
              is_dark: is_dark,
              child: Builder(
                key: target_key_builder?.call(comment.id),
                builder: (BuildContext target_context) {
                  return GestureDetector(
                    key: ValueKey<String>('comment_item_tap_${comment.id}'),
                    onTap: () => on_reply(comment, target_context),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: CommentListStyle.item_top_padding,
                        bottom: CommentListStyle.item_bottom_padding,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          CommentAvatar(
                            avatar_url: comment.avatar,
                            user_id: comment.user_id,
                            size: CommentListStyle.avatar_size,
                            is_dark: is_dark,
                          ),
                          const SizedBox(
                            width: CommentListStyle.avatar_content_gap,
                          ),
                          Expanded(
                            child: _build_main_content(
                              is_cjk: is_cjk,
                              text_color: text_color,
                              secondary_color: secondary_color,
                              name_color: name_color,
                            ),
                          ),
                          _CommentLikeButton(
                            key: ValueKey<String>('comment_like_${comment.id}'),
                            is_dark: is_dark,
                            is_liked: comment.is_liked,
                            like_count: comment.like_count,
                            on_tap: () => on_like(comment),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (comment.replies.isNotEmpty)
              _build_reply_section(
                is_cjk: is_cjk,
                text_color: text_color,
                secondary_color: secondary_color,
                name_color: name_color,
              ),
            Padding(
              padding: const EdgeInsets.only(
                left: CommentListStyle.divider_indent,
              ),
              child: Divider(
                height: CommentListStyle.divider_thickness,
                thickness: CommentListStyle.divider_thickness,
                color: divider_color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build_main_content({
    required bool is_cjk,
    required Color text_color,
    required Color secondary_color,
    required Color name_color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          comment.nickname,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: is_cjk
                ? CommentListStyle.nickname_font_size_cjk
                : CommentListStyle.nickname_font_size_alphabetic,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
            color: name_color,
          ),
        ),
        const SizedBox(height: CommentListStyle.content_top_spacing),
        Text(
          comment.content,
          style: TextStyle(
            fontSize: is_cjk
                ? CommentListStyle.content_font_size_cjk
                : CommentListStyle.content_font_size_alphabetic,
            height: is_cjk
                ? CommentListStyle.content_line_height_cjk
                : CommentListStyle.content_line_height_alphabetic,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            color: text_color,
          ),
        ),
        const SizedBox(height: CommentListStyle.metadata_top_spacing),
        Row(
          children: <Widget>[
            Text(
              _format_time(comment.time),
              style: TextStyle(
                fontSize: CommentListStyle.time_font_size,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                color: secondary_color,
              ),
            ),
            const SizedBox(width: CommentListStyle.action_spacing),
            Text(
              tr('comment.reply'),
              style: TextStyle(
                fontSize: is_cjk
                    ? CommentListStyle.action_font_size_cjk
                    : CommentListStyle.action_font_size_alphabetic,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                color: secondary_color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _build_reply_section({
    required bool is_cjk,
    required Color text_color,
    required Color secondary_color,
    required Color name_color,
  }) {
    final Color reply_background = is_dark
        ? CommentListStyle.reply_area_dark_bg
        : CommentListStyle.reply_area_light_bg;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        left: CommentListStyle.reply_indent,
        bottom: CommentListStyle.item_bottom_padding,
      ),
      padding: const EdgeInsets.all(CommentListStyle.reply_area_padding),
      decoration: BoxDecoration(
        color: reply_background,
        borderRadius: BorderRadius.circular(CommentListStyle.reply_area_radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int index = 0; index < comment.replies.length; index++) ...[
            if (index > 0)
              const SizedBox(height: CommentListStyle.reply_item_spacing),
            _build_reply_item(
              reply: comment.replies[index],
              is_cjk: is_cjk,
              text_color: text_color,
              secondary_color: secondary_color,
              name_color: name_color,
            ),
          ],
        ],
      ),
    );
  }

  Widget _build_reply_item({
    required CommentData reply,
    required bool is_cjk,
    required Color text_color,
    required Color secondary_color,
    required Color name_color,
  }) {
    final double reply_font_size = is_cjk
        ? CommentListStyle.reply_text_font_size_cjk
        : CommentListStyle.reply_text_font_size_alphabetic;
    final double reply_line_height = is_cjk
        ? CommentListStyle.reply_line_height_cjk
        : CommentListStyle.reply_line_height_alphabetic;

    final bool is_reply_highlighted = highlighted_comment_id == reply.id;

    return _HighlightWrapper(
      highlighted: is_reply_highlighted,
      is_dark: is_dark,
      child: Builder(
        key: target_key_builder?.call(reply.id),
        builder: (BuildContext target_context) {
          return GestureDetector(
            key: ValueKey<String>('comment_reply_tap_${reply.id}'),
            onTap: () => on_reply(reply, target_context),
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: reply_font_size,
                      height: reply_line_height,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                      color: text_color,
                    ),
                    children: <InlineSpan>[
                      TextSpan(
                        text: reply.nickname,
                        style: TextStyle(
                          fontWeight: FontConfig.adjustedWeight(
                            FontWeight.w500,
                          ),
                          color: name_color,
                        ),
                      ),
                      if (reply.reply_to_nickname?.isNotEmpty ==
                          true) ...<InlineSpan>[
                        TextSpan(
                          text: ' ${tr('comment.reply')} ',
                          style: TextStyle(color: secondary_color),
                        ),
                        TextSpan(
                          text: reply.reply_to_nickname,
                          style: TextStyle(
                            fontWeight: FontConfig.adjustedWeight(
                              FontWeight.w500,
                            ),
                            color: name_color,
                          ),
                        ),
                      ],
                      TextSpan(text: '：${reply.content}'),
                    ],
                  ),
                ),
                const SizedBox(
                  height: CommentListStyle.reply_metadata_top_spacing,
                ),
                Row(
                  children: <Widget>[
                    Text(
                      _format_time(reply.time),
                      style: TextStyle(
                        fontSize: CommentListStyle.time_font_size,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                        color: secondary_color,
                      ),
                    ),
                    const SizedBox(width: CommentListStyle.action_spacing),
                    Text(
                      tr('comment.reply'),
                      style: TextStyle(
                        fontSize: is_cjk
                            ? CommentListStyle.action_font_size_cjk
                            : CommentListStyle.action_font_size_alphabetic,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                        color: secondary_color,
                      ),
                    ),
                    const Spacer(),
                    _CommentLikeButton(
                      key: ValueKey<String>('comment_like_${reply.id}'),
                      is_dark: is_dark,
                      is_liked: reply.is_liked,
                      like_count: reply.like_count,
                      compact: true,
                      on_tap: () => on_like(reply),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _format_time(String time_str) {
    if (time_str.isEmpty) return '';
    try {
      final bool has_timezone = RegExp(
        r'(Z|[+-]\d{2}:?\d{2})$',
        caseSensitive: false,
      ).hasMatch(time_str);
      final DateTime comment_time = DateTime.parse(
        has_timezone ? time_str : '${time_str}Z',
      ).toLocal();
      final Duration difference = DateTime.now().difference(comment_time);

      if (difference.inMinutes < 1) {
        return tr('comment.time.just_now');
      }
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}${tr('comment.time.minutes_ago')}';
      }
      if (difference.inHours < 24) {
        return '${difference.inHours}${tr('comment.time.hours_ago')}';
      }
      if (difference.inDays < 7) {
        return '${difference.inDays}${tr('comment.time.days_ago')}';
      }
      if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()}${tr('comment.time.weeks_ago')}';
      }
      return '${comment_time.month}/${comment_time.day}';
    } catch (_) {
      return time_str;
    }
  }
}

/// 点赞按钮，主评论使用纵向布局，回复使用紧凑横向布局。
class _CommentLikeButton extends StatelessWidget {
  final bool is_dark;
  final bool is_liked;
  final int like_count;
  final bool compact;
  final VoidCallback on_tap;

  const _CommentLikeButton({
    super.key,
    required this.is_dark,
    required this.is_liked,
    required this.like_count,
    required this.on_tap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = is_liked
        ? CommentListStyle.like_active_color
        : is_dark
        ? CommentListStyle.like_dark_color
        : CommentListStyle.like_light_color;
    final String count_text = like_count > 0
        ? _format_like_count(like_count)
        : tr('comment.like');

    return GestureDetector(
      onTap: on_tap,
      behavior: HitTestBehavior.opaque,
      child: compact
          ? ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: CommentListStyle.like_compact_touch_width,
                minHeight: CommentListStyle.like_compact_touch_height,
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: CommentListStyle.like_compact_left_padding,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    SvgIcon(
                      name: is_liked ? 'love_02' : 'love',
                      width: CommentListStyle.like_compact_icon_size,
                      height: CommentListStyle.like_compact_icon_size,
                      color: color,
                      animateColor: false,
                    ),
                    if (like_count > 0) ...<Widget>[
                      const SizedBox(
                        width: CommentListStyle.like_icon_count_spacing,
                      ),
                      Text(
                        count_text,
                        style: TextStyle(
                          fontSize: CommentListStyle.like_count_font_size,
                          fontWeight: FontConfig.adjustedWeight(
                            FontWeight.w400,
                          ),
                          color: color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : SizedBox(
              width: CommentListStyle.like_touch_width,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: CommentListStyle.like_main_top_padding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SvgIcon(
                      name: is_liked ? 'love_02' : 'love',
                      width: CommentListStyle.like_icon_size,
                      height: CommentListStyle.like_icon_size,
                      color: color,
                      animateColor: false,
                    ),
                    const SizedBox(
                      height: CommentListStyle.like_icon_count_spacing,
                    ),
                    Text(
                      count_text,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: CommentListStyle.like_count_font_size,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _format_like_count(int count) {
    if (count < 1000) return '$count';
    if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}

/// 评论高亮闪烁包装器。
///
/// 当 [highlighted] 为 true 时，子组件会有一个从高亮色渐变到透明的动画，
/// 持续约 1.5 秒，用于引导用户注意刚从推送定位到的评论。
class _HighlightWrapper extends StatefulWidget {
  final bool highlighted;
  final bool is_dark;
  final Widget child;

  const _HighlightWrapper({
    required this.highlighted,
    required this.is_dark,
    required this.child,
  });

  @override
  State<_HighlightWrapper> createState() => _HighlightWrapperState();
}

class _HighlightWrapperState extends State<_HighlightWrapper>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<Color?>? _color_animation;

  @override
  void initState() {
    super.initState();
    if (widget.highlighted) {
      _start_animation();
    }
  }

  @override
  void didUpdateWidget(_HighlightWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlighted && !oldWidget.highlighted) {
      _start_animation();
    }
  }

  void _start_animation() {
    _controller?.dispose();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    final Color highlight_color = widget.is_dark
        ? const Color(0x33FFFFFF)
        : const Color(0x33FF9800);
    _color_animation = ColorTween(
      begin: highlight_color,
      end: Colors.transparent,
    ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeOut));
    _controller!.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_color_animation == null || _controller == null) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, child) {
        return Container(color: _color_animation!.value, child: child);
      },
      child: widget.child,
    );
  }
}
