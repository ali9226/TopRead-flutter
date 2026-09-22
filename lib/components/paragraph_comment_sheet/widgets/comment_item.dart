// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/components/comment_list/style.dart';
import 'package:app/components/comment_list/widgets/comment_avatar.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';

import '../api.dart';
import '../logic.dart';

/// 段落评论项，视觉风格与小说主评论完全一致。
///
/// 主评论：头像 + 昵称/正文/元数据行（时间 + 回复 + 点赞）
/// 子回复：缩进 + 小头像 + 昵称/正文/元数据行
/// 长按时显示淡淡阴影，提示用户可操作的区域。
class ParagraphCommentItem extends StatefulWidget {
  final ParagraphComment comment;
  final ParagraphCommentSheetLogic logic;
  final bool is_dark;
  final bool is_cjk;
  final bool is_reply;
  final ValueChanged<ParagraphComment> on_reply;
  final ValueChanged<ParagraphComment> on_actions;

  const ParagraphCommentItem({
    super.key,
    required this.comment,
    required this.logic,
    required this.is_dark,
    required this.is_cjk,
    required this.on_reply,
    required this.on_actions,
    this.is_reply = false,
  });

  @override
  State<ParagraphCommentItem> createState() => _ParagraphCommentItemState();
}

class _ParagraphCommentItemState extends State<ParagraphCommentItem> {
  bool _is_pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color content_color = widget.is_dark
        ? CommentListStyle.content_dark_color
        : CommentListStyle.content_light_color;
    final Color metadata_color = widget.is_dark
        ? CommentListStyle.metadata_dark_color
        : CommentListStyle.metadata_light_color;
    final Color nickname_color = widget.is_dark
        ? CommentListStyle.nickname_dark_color
        : CommentListStyle.nickname_light_color;

    // 已删除评论禁用所有交互
    final bool is_disabled = widget.comment.is_deleted;

    return GestureDetector(
      onTap: is_disabled ? null : () => widget.on_reply(widget.comment),
      onLongPressStart: is_disabled ? null : (_) => setState(() => _is_pressed = true),
      onLongPressEnd: is_disabled ? null : (_) {
        setState(() => _is_pressed = false);
        widget.on_actions(widget.comment);
      },
      onLongPressCancel: is_disabled ? null : () => setState(() => _is_pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _is_pressed
              ? (widget.is_dark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主评论行：头像 + 内容区
            Padding(
              padding: EdgeInsets.only(
                top: widget.is_reply ? 0 : CommentListStyle.item_top_padding,
                bottom: widget.is_reply ? 0 : CommentListStyle.item_bottom_padding,
                left: 4,
                right: 4,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommentAvatar(
                    avatar_url: widget.comment.user_avatar,
                    user_id: widget.comment.user_id,
                    size: widget.is_reply
                        ? CommentListStyle.reply_avatar_size
                        : CommentListStyle.avatar_size,
                    is_dark: widget.is_dark,
                  ),
                  SizedBox(width: widget.is_reply
                      ? CommentListStyle.reply_avatar_gap
                      : CommentListStyle.avatar_content_gap),
                  Expanded(
                    child: _build_comment_content(
                      content_color: content_color,
                      metadata_color: metadata_color,
                      nickname_color: nickname_color,
                    ),
                  ),
                ],
              ),
            ),
            // 子回复列表
            if (widget.comment.replies.isNotEmpty ||
                widget.logic.can_load_replies(widget.comment))
              _build_reply_section(
                content_color: content_color,
                metadata_color: metadata_color,
                nickname_color: nickname_color,
              ),
          ],
        ),
      ),
    );
  }

  /// 构建评论内容区：昵称 + 正文 + 元数据行。
  Widget _build_comment_content({
    required Color content_color,
    required Color metadata_color,
    required Color nickname_color,
  }) {
    final double nickname_font_size = widget.is_reply
        ? (widget.is_cjk
            ? CommentListStyle.reply_nickname_font_size_cjk
            : CommentListStyle.reply_nickname_font_size_alphabetic)
        : (widget.is_cjk
            ? CommentListStyle.nickname_font_size_cjk
            : CommentListStyle.nickname_font_size_alphabetic);
    final double content_font_size = widget.is_reply
        ? (widget.is_cjk
            ? CommentListStyle.reply_text_font_size_cjk
            : CommentListStyle.reply_text_font_size_alphabetic)
        : (widget.is_cjk
            ? CommentListStyle.content_font_size_cjk
            : CommentListStyle.content_font_size_alphabetic);
    final double content_line_height = widget.is_reply
        ? (widget.is_cjk
            ? CommentListStyle.reply_line_height_cjk
            : CommentListStyle.reply_line_height_alphabetic)
        : (widget.is_cjk
            ? CommentListStyle.content_line_height_cjk
            : CommentListStyle.content_line_height_alphabetic);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 昵称（回复时显示"回复 XXX"）
        _build_nickname(nickname_font_size, nickname_color),
        SizedBox(height: widget.is_reply
            ? CommentListStyle.reply_content_top_spacing
            : CommentListStyle.content_top_spacing),
        // 正文内容
        _build_content_text(
          font_size: content_font_size,
          line_height: content_line_height,
          content_color: content_color,
          nickname_color: nickname_color,
        ),
        SizedBox(height: widget.is_reply
            ? CommentListStyle.reply_metadata_top_spacing
            : CommentListStyle.metadata_top_spacing),
        // 元数据行：时间 + 回复 + 点赞
        _build_metadata_row(
          metadata_color: metadata_color,
          nickname_color: nickname_color,
        ),
      ],
    );
  }

  /// 构建昵称，回复时显示"回复 XXX"格式。
  Widget _build_nickname(double font_size, Color nickname_color) {
    final String display_name = widget.comment.reply_to_name.isEmpty
        ? widget.comment.user_name
        : '${widget.comment.user_name} ${tr('comment.reply_to')} ${widget.comment.reply_to_name}';

    return Text(
      display_name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: font_size,
        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
        color: nickname_color,
      ),
    );
  }

  /// 构建正文内容。
  Widget _build_content_text({
    required double font_size,
    required double line_height,
    required Color content_color,
    required Color nickname_color,
  }) {
    // 已删除的评论显示删除提示
    if (widget.comment.is_deleted) {
      return Text(
        tr('comment.deleted'),
        style: TextStyle(
          fontSize: font_size,
          height: line_height,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
          color: content_color.withValues(alpha: 0.4),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    if (widget.comment.content.isEmpty) return const SizedBox.shrink();

    return Text(
      widget.comment.content,
      style: TextStyle(
        fontSize: font_size,
        height: line_height,
        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
        color: content_color,
      ),
    );
  }

  /// 构建元数据行：时间 + 回复按钮 + 点赞按钮（与小说主评论一致）。
  Widget _build_metadata_row({
    required Color metadata_color,
    required Color nickname_color,
  }) {
    final String formatted_time = _format_time(widget.comment.create_time);
    // 已删除评论禁用交互
    final bool is_disabled = widget.comment.is_deleted;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              if (formatted_time.isNotEmpty) ...[
                Flexible(
                  child: Text(
                    formatted_time,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: CommentListStyle.time_font_size,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                      color: metadata_color,
                    ),
                  ),
                ),
                const SizedBox(width: CommentListStyle.action_spacing),
              ],
              // 已删除评论不显示回复按钮
              if (!is_disabled)
                Flexible(
                  child: GestureDetector(
                    onTap: () => widget.on_reply(widget.comment),
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      tr('comment.reply'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.is_cjk
                            ? CommentListStyle.action_font_size_cjk
                            : CommentListStyle.action_font_size_alphabetic,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                        color: metadata_color,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // 已删除评论显示置灰点赞按钮
        is_disabled
            ? _DisabledParagraphLikeButton(
                is_dark: widget.is_dark,
                like_count: widget.comment.like_count,
                compact: widget.is_reply,
              )
            : _ParagraphLikeButton(
                key: ValueKey('paragraph_like_${widget.comment.id}'),
                is_dark: widget.is_dark,
                is_liked: widget.comment.is_liked,
                like_count: widget.comment.like_count,
                compact: widget.is_reply,
                on_tap: () => widget.logic.toggle_like(widget.comment),
              ),
      ],
    );
  }

  /// 构建子回复列表区域。
  Widget _build_reply_section({
    required Color content_color,
    required Color metadata_color,
    required Color nickname_color,
  }) {
    if (widget.comment.replies.isEmpty &&
        !widget.logic.can_load_replies(widget.comment)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: CommentListStyle.reply_indent,
        bottom: CommentListStyle.reply_section_bottom_padding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int index = 0;
              index < widget.comment.replies.length;
              index++) ...[
            if (index > 0)
              const SizedBox(height: CommentListStyle.reply_item_spacing),
            ParagraphCommentItem(
              key: ValueKey(
                  'paragraph_reply_${widget.comment.replies[index].id}'),
              comment: widget.comment.replies[index],
              logic: widget.logic,
              is_dark: widget.is_dark,
              is_cjk: widget.is_cjk,
              is_reply: true,
              on_reply: widget.on_reply,
              on_actions: widget.on_actions,
            ),
          ],
          if (widget.logic.can_load_replies(widget.comment))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: widget.logic.loading_reply_ids
                        .contains(widget.comment.id)
                    ? null
                    : () => widget.logic.load_replies(widget.comment),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    widget.logic.loading_reply_ids
                            .contains(widget.comment.id)
                        ? tr('common.loading')
                        : tr('paragraph_comment.more_replies', namedArgs: {
                            'count': '${widget.comment.reply_count}',
                          }),
                    style: TextStyle(
                      fontSize: widget.is_cjk
                          ? CommentListStyle.action_font_size_cjk
                          : CommentListStyle.action_font_size_alphabetic,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                      color: widget.is_dark
                          ? CommentListStyle.action_dark_color
                          : CommentListStyle.action_light_color,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 格式化时间，与小说主评论使用相同的逻辑。
  String _format_time(String value) {
    final DateTime? time = DateTime.tryParse(value);
    if (time == null) return value;
    final Duration difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) return tr('comment.time.just_now');
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
    return '${time.month}/${time.day}';
  }
}

/// 段评点赞按钮，与小说主评论使用相同的 SVG 图标和缩放动画。
class _ParagraphLikeButton extends StatefulWidget {
  final bool is_dark;
  final bool is_liked;
  final int like_count;
  final bool compact;
  final VoidCallback on_tap;

  const _ParagraphLikeButton({
    super.key,
    required this.is_dark,
    required this.is_liked,
    required this.like_count,
    required this.on_tap,
    this.compact = false,
  });

  @override
  State<_ParagraphLikeButton> createState() => _ParagraphLikeButtonState();
}

class _ParagraphLikeButtonState extends State<_ParagraphLikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale_controller;
  late final Animation<double> _scale_animation;

  @override
  void initState() {
    super.initState();
    _scale_controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scale_animation = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0.82)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 28,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.82, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.12, end: 1)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 32,
      ),
    ]).animate(_scale_controller);
  }

  @override
  void didUpdateWidget(_ParagraphLikeButton old_widget) {
    super.didUpdateWidget(old_widget);
    if (old_widget.is_liked != widget.is_liked) {
      _scale_controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _scale_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.is_liked
        ? CommentListStyle.like_active_color
        : widget.is_dark
            ? CommentListStyle.like_dark_color
            : CommentListStyle.like_light_color;
    final double icon_size = widget.compact
        ? CommentListStyle.like_compact_icon_size
        : CommentListStyle.like_icon_size;

    return GestureDetector(
      onTap: widget.on_tap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: CommentListStyle.like_touch_width,
          minHeight: CommentListStyle.like_touch_height,
        ),
        child: Padding(
          padding:
              const EdgeInsets.only(left: CommentListStyle.like_left_padding),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ScaleTransition(
                scale: _scale_animation,
                child: SvgIcon(
                  name: widget.is_liked ? 'love_02' : 'love',
                  width: icon_size,
                  height: icon_size,
                  color: color,
                  animateColor: false,
                ),
              ),
              if (widget.like_count > 0) ...[
                const SizedBox(
                    width: CommentListStyle.like_icon_count_spacing),
                Text(
                  _format_like_count(widget.like_count),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: CommentListStyle.like_count_font_size,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 将较大的点赞数量格式化为紧凑形式。
  String _format_like_count(int count) {
    if (count < 1000) return '$count';
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}

/// 置灰点赞按钮，用于已删除的段评。
class _DisabledParagraphLikeButton extends StatelessWidget {
  final bool is_dark;
  final int like_count;
  final bool compact;

  const _DisabledParagraphLikeButton({
    required this.is_dark,
    required this.like_count,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = is_dark
        ? CommentListStyle.like_disabled_color_dark
        : CommentListStyle.like_disabled_color_light;
    final double icon_size = compact
        ? CommentListStyle.like_compact_icon_size
        : CommentListStyle.like_icon_size;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: CommentListStyle.like_touch_width,
        minHeight: CommentListStyle.like_touch_height,
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: CommentListStyle.like_left_padding),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SvgIcon(
              name: 'love',
              width: icon_size,
              height: icon_size,
              color: color,
              animateColor: false,
            ),
            if (like_count > 0) ...[
              const SizedBox(width: CommentListStyle.like_icon_count_spacing),
              Text(
                _format_like_count(like_count),
                maxLines: 1,
                style: TextStyle(
                  fontSize: CommentListStyle.like_count_font_size,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _format_like_count(int count) {
    if (count < 1000) return '$count';
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}
