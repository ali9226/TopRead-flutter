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

/// 根据评论 ID 获取定位锚点的回调。
typedef CommentTargetKeyBuilder = GlobalKey Function(int comment_id);

/// 留白式评论项。
///
/// 主评论使用“头像 + 昵称/正文/元数据”的纵向信息层级；子回复在正文列下方
/// 以独立头像和内容行展示。点赞入口统一放在元数据行最右侧，避免挤压正文。
class CommentItem extends StatelessWidget {
  /// 当前顶层评论。
  final CommentData comment;

  /// 是否使用夜间主题。
  final bool is_dark;

  /// 点击评论或回复时触发。
  final CommentReplyCallback on_reply;

  /// 点击点赞按钮时触发。
  final ValueChanged<CommentData> on_like;

  /// 当前需要高亮的评论 ID，0 表示不高亮。
  final int highlighted_comment_id;

  /// 评论定位锚点构建器。
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
    final Color content_color = is_dark
        ? CommentListStyle.content_dark_color
        : CommentListStyle.content_light_color;
    final Color metadata_color = is_dark
        ? CommentListStyle.metadata_dark_color
        : CommentListStyle.metadata_light_color;
    final Color action_color = is_dark
        ? CommentListStyle.action_dark_color
        : CommentListStyle.action_light_color;
    final Color nickname_color = is_dark
        ? CommentListStyle.nickname_dark_color
        : CommentListStyle.nickname_light_color;
    final Color divider_color = is_dark
        ? CommentListStyle.divider_dark_color
        : CommentListStyle.divider_light_color;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CommentListStyle.list_horizontal_padding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _build_main_comment(
              is_cjk: is_cjk,
              content_color: content_color,
              metadata_color: metadata_color,
              action_color: action_color,
              nickname_color: nickname_color,
            ),
            if (comment.replies.isNotEmpty)
              _build_reply_section(
                is_cjk: is_cjk,
                content_color: content_color,
                metadata_color: metadata_color,
                action_color: action_color,
                nickname_color: nickname_color,
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

  /// 构建顶层评论。
  Widget _build_main_comment({
    required bool is_cjk,
    required Color content_color,
    required Color metadata_color,
    required Color action_color,
    required Color nickname_color,
  }) {
    final bool is_highlighted = highlighted_comment_id == comment.id;

    return _HighlightWrapper(
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
                  const SizedBox(width: CommentListStyle.avatar_content_gap),
                  Expanded(
                    child: _build_comment_content(
                      target: comment,
                      is_cjk: is_cjk,
                      content_color: content_color,
                      metadata_color: metadata_color,
                      action_color: action_color,
                      nickname_color: nickname_color,
                      is_reply: false,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建缩进的子回复列表。
  Widget _build_reply_section({
    required bool is_cjk,
    required Color content_color,
    required Color metadata_color,
    required Color action_color,
    required Color nickname_color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        left: CommentListStyle.reply_indent,
        bottom: CommentListStyle.reply_section_bottom_padding,
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
              content_color: content_color,
              metadata_color: metadata_color,
              action_color: action_color,
              nickname_color: nickname_color,
            ),
          ],
        ],
      ),
    );
  }

  /// 构建一条带头像的子回复。
  Widget _build_reply_item({
    required CommentData reply,
    required bool is_cjk,
    required Color content_color,
    required Color metadata_color,
    required Color action_color,
    required Color nickname_color,
  }) {
    final bool is_highlighted = highlighted_comment_id == reply.id;

    return _HighlightWrapper(
      highlighted: is_highlighted,
      is_dark: is_dark,
      child: Builder(
        key: target_key_builder?.call(reply.id),
        builder: (BuildContext target_context) {
          return GestureDetector(
            key: ValueKey<String>('comment_reply_tap_${reply.id}'),
            onTap: () => on_reply(reply, target_context),
            behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CommentAvatar(
                  avatar_url: reply.avatar,
                  user_id: reply.user_id,
                  size: CommentListStyle.reply_avatar_size,
                  is_dark: is_dark,
                ),
                const SizedBox(width: CommentListStyle.reply_avatar_gap),
                Expanded(
                  child: _build_comment_content(
                    target: reply,
                    is_cjk: is_cjk,
                    content_color: content_color,
                    metadata_color: metadata_color,
                    action_color: action_color,
                    nickname_color: nickname_color,
                    is_reply: true,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建评论的昵称、正文与元数据。
  Widget _build_comment_content({
    required CommentData target,
    required bool is_cjk,
    required Color content_color,
    required Color metadata_color,
    required Color action_color,
    required Color nickname_color,
    required bool is_reply,
  }) {
    final double nickname_font_size;
    final double content_font_size;
    final double content_line_height;

    if (is_reply) {
      nickname_font_size = is_cjk
          ? CommentListStyle.reply_nickname_font_size_cjk
          : CommentListStyle.reply_nickname_font_size_alphabetic;
      content_font_size = is_cjk
          ? CommentListStyle.reply_text_font_size_cjk
          : CommentListStyle.reply_text_font_size_alphabetic;
      content_line_height = is_cjk
          ? CommentListStyle.reply_line_height_cjk
          : CommentListStyle.reply_line_height_alphabetic;
    } else {
      nickname_font_size = is_cjk
          ? CommentListStyle.nickname_font_size_cjk
          : CommentListStyle.nickname_font_size_alphabetic;
      content_font_size = is_cjk
          ? CommentListStyle.content_font_size_cjk
          : CommentListStyle.content_font_size_alphabetic;
      content_line_height = is_cjk
          ? CommentListStyle.content_line_height_cjk
          : CommentListStyle.content_line_height_alphabetic;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          target.nickname,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: nickname_font_size,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            color: nickname_color,
          ),
        ),
        SizedBox(
          height: is_reply
              ? CommentListStyle.reply_content_top_spacing
              : CommentListStyle.content_top_spacing,
        ),
        _build_content_text(
          target: target,
          is_reply: is_reply,
          font_size: content_font_size,
          line_height: content_line_height,
          content_color: content_color,
          nickname_color: nickname_color,
        ),
        SizedBox(
          height: is_reply
              ? CommentListStyle.reply_metadata_top_spacing
              : CommentListStyle.metadata_top_spacing,
        ),
        _build_metadata_row(
          target: target,
          is_cjk: is_cjk,
          metadata_color: metadata_color,
          action_color: action_color,
          is_reply: is_reply,
        ),
      ],
    );
  }

  /// 构建正文；回复其他用户时保留明确的回复关系。
  Widget _build_content_text({
    required CommentData target,
    required bool is_reply,
    required double font_size,
    required double line_height,
    required Color content_color,
    required Color nickname_color,
  }) {
    final TextStyle content_style = TextStyle(
      fontSize: font_size,
      height: line_height,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
      color: content_color,
    );
    final String? reply_to_nickname = target.reply_to_nickname;

    if (!is_reply || reply_to_nickname?.isNotEmpty != true) {
      return Text(target.content, style: content_style);
    }

    return RichText(
      text: TextSpan(
        style: content_style,
        children: <InlineSpan>[
          TextSpan(text: '${tr('comment.reply')} '),
          TextSpan(
            text: reply_to_nickname,
            style: TextStyle(
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              color: nickname_color,
            ),
          ),
          TextSpan(text: '：${target.content}'),
        ],
      ),
    );
  }

  /// 构建时间、回复入口与右侧点赞按钮。
  Widget _build_metadata_row({
    required CommentData target,
    required bool is_cjk,
    required Color metadata_color,
    required Color action_color,
    required bool is_reply,
  }) {
    final String formatted_time = _format_time(target.time);

    return Row(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              if (formatted_time.isNotEmpty) ...<Widget>[
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
              Flexible(
                child: Text(
                  tr('comment.reply'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: is_cjk
                        ? CommentListStyle.action_font_size_cjk
                        : CommentListStyle.action_font_size_alphabetic,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                    color: action_color,
                  ),
                ),
              ),
            ],
          ),
        ),
        _CommentLikeButton(
          key: ValueKey<String>('comment_like_${target.id}'),
          is_dark: is_dark,
          is_liked: target.is_liked,
          like_count: target.like_count,
          compact: is_reply,
          on_tap: () => on_like(target),
        ),
      ],
    );
  }

  /// 将接口时间格式化为紧凑的相对时间。
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

/// 元数据行右侧的单一点赞按钮。
class _CommentLikeButton extends StatefulWidget {
  /// 是否使用夜间主题。
  final bool is_dark;

  /// 当前用户是否已点赞。
  final bool is_liked;

  /// 当前点赞数量。
  final int like_count;

  /// 是否使用子回复的小尺寸图标。
  final bool compact;

  /// 点赞回调。
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
  State<_CommentLikeButton> createState() => _CommentLikeButtonState();
}

class _CommentLikeButtonState extends State<_CommentLikeButton>
    with SingleTickerProviderStateMixin {
  /// 点赞与取消点赞共用的缩放动画控制器。
  late final AnimationController _scale_controller;

  /// 爱心图标缩小、放大并回到原始尺寸的动画。
  late final Animation<double> _scale_animation;

  @override
  void initState() {
    super.initState();
    _scale_controller = AnimationController(
      duration: const Duration(
        milliseconds: CommentListStyle.like_animation_duration_ms,
      ),
      vsync: this,
    );
    _scale_animation = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1,
          end: CommentListStyle.like_scale_shrink,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: CommentListStyle.like_scale_shrink_weight,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: CommentListStyle.like_scale_shrink,
          end: CommentListStyle.like_scale_overshoot,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: CommentListStyle.like_scale_overshoot_weight,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: CommentListStyle.like_scale_overshoot,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: CommentListStyle.like_scale_settle_weight,
      ),
    ]).animate(_scale_controller);
  }

  @override
  void didUpdateWidget(_CommentLikeButton old_widget) {
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

    return Semantics(
      button: true,
      label: tr('comment.like'),
      child: GestureDetector(
        onTap: widget.on_tap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: CommentListStyle.like_touch_width,
            minHeight: CommentListStyle.like_touch_height,
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              left: CommentListStyle.like_left_padding,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
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
                if (widget.like_count > 0) ...<Widget>[
                  const SizedBox(
                    width: CommentListStyle.like_icon_count_spacing,
                  ),
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
      ),
    );
  }

  /// 将较大的点赞数量格式化为紧凑形式。
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
/// 当 [highlighted] 为 true 时，子组件会从高亮色渐变到透明，用于定位评论。
class _HighlightWrapper extends StatefulWidget {
  /// 是否播放高亮动画。
  final bool highlighted;

  /// 是否使用夜间主题。
  final bool is_dark;

  /// 被高亮的评论内容。
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
  /// 高亮动画控制器。
  AnimationController? _controller;

  /// 高亮背景色动画。
  Animation<Color?>? _color_animation;

  @override
  void initState() {
    super.initState();
    if (widget.highlighted) {
      _start_animation();
    }
  }

  @override
  void didUpdateWidget(_HighlightWrapper old_widget) {
    super.didUpdateWidget(old_widget);
    if (widget.highlighted && !old_widget.highlighted) {
      _start_animation();
    }
  }

  /// 从当前主题对应的高亮色开始淡出。
  void _start_animation() {
    _controller?.dispose();
    _controller = AnimationController(
      duration: const Duration(
        milliseconds: CommentListStyle.highlight_animation_duration_ms,
      ),
      vsync: this,
    );
    final Color highlight_color = widget.is_dark
        ? CommentListStyle.highlight_dark_color
        : CommentListStyle.highlight_light_color;
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
      builder: (BuildContext context, Widget? child) {
        return ColoredBox(
          color: _color_animation!.value ?? Colors.transparent,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
