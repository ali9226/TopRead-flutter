// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/components/comment_list/widgets/comment_item.dart';
import 'package:app/components/comment_list/widgets/comment_skeleton.dart';
import 'package:app/pages/comics/widgets/comic_surface.dart';
import 'package:app/pages/comics/comments/logic.dart';
import 'package:app/pages/comics/detail/widgets/hot_comments/feedback.dart';
import 'package:app/pages/comics/detail/widgets/hot_comments/header.dart';
import 'package:app/pages/comics/detail/widgets/hot_comments/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 详情只请求服务端热度排序的第一页；完整列表、回复和编辑统一交给评论弹窗。
class ComicHotComments extends StatefulWidget {
  const ComicHotComments({
    super.key,
    required this.comic_id,
    required this.is_dark,
    required this.on_comments,
    this.controller,
    this.on_count_changed,
    this.refresh_revision = 0,
  });

  final int comic_id;
  final bool is_dark;
  final VoidCallback on_comments;

  /// 注入控制器供测试使用；外部控制器由其创建者释放。
  final ComicCommentsLogic? controller;
  final ValueChanged<int>? on_count_changed;

  /// 评论弹窗关闭时递增，重新读取热评排序、点赞状态及可见评论总数。
  final int refresh_revision;

  @override
  State<ComicHotComments> createState() => _ComicHotCommentsState();
}

class _ComicHotCommentsState extends State<ComicHotComments> {
  late ComicCommentsLogic _logic;
  int? _reported_count;
  int _reported_epoch = 0;

  @override
  void initState() {
    super.initState();
    _bind_logic();
  }

  /// 每个作品独立持有请求生命周期，账号切换由公共漫画评论控制器清理个人状态。
  void _bind_logic() {
    _logic =
        widget.controller ??
        ComicCommentsLogic(
          comic_id: widget.comic_id,
          sort: 'hot',
          page_size: ComicHotCommentsStyle.preview_count,
        );
    _reported_count = null;
    _reported_epoch = _logic.identity_epoch;
    _logic.addListener(_on_change);
    unawaited(_logic.load());
  }

  @override
  void didUpdateWidget(covariant ComicHotComments oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comic_id != widget.comic_id ||
        !identical(oldWidget.controller, widget.controller)) {
      _logic.removeListener(_on_change);
      if (oldWidget.controller == null) _logic.dispose();
      _bind_logic();
    } else if (oldWidget.refresh_revision != widget.refresh_revision) {
      unawaited(_logic.load());
    }
  }

  /// 总数回调延后到帧末，并确认仍属于同一作品与账号，避免旧请求影响父页面。
  void _on_change() {
    if (_reported_epoch != _logic.identity_epoch) {
      _reported_epoch = _logic.identity_epoch;
      _reported_count = null;
    }
    if (_logic.page == 0 || widget.on_count_changed == null) return;
    final logic = _logic;
    final epoch = logic.identity_epoch;
    final count = logic.comment_count;
    if (_reported_count == count) return;
    _reported_count = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          identical(logic, _logic) &&
          epoch == _logic.identity_epoch &&
          _reported_count == count) {
        widget.on_count_changed?.call(count);
      }
    });
  }

  @override
  void dispose() {
    _logic.removeListener(_on_change);
    if (widget.controller == null) _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _logic,
    builder: (context, _) => ComicSurface(
      key: const ValueKey<String>('comic_hot_comments'),
      is_dark: widget.is_dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ComicHotCommentsHeader(
            is_dark: widget.is_dark,
            on_comments: widget.on_comments,
            count: _logic.page > 0 ? _logic.comment_count : null,
          ),
          if (_logic.loading && _logic.items.isEmpty)
            CommentSkeleton(
              is_dark: widget.is_dark,
              count: ComicHotCommentsStyle.skeleton_count,
              shrink_wrap: true,
            ),
          for (final comment in _logic.items.take(
            ComicHotCommentsStyle.preview_count,
          ))
            CommentItem(
              key: ValueKey<String>('comic_hot_comment_${comment.id}'),
              comment: comment.copy_with(
                is_sending: _logic.busy_comments.contains(comment.id),
                replies: const [],
              ),
              is_dark: widget.is_dark,
              on_reply: (_, _) => widget.on_comments(),
              on_like: _logic.like,
            ),
          if (!_logic.loading && (_logic.items.isEmpty || _logic.error != null))
            ComicHotCommentsFeedback(
              is_dark: widget.is_dark,
              failed: _logic.error != null,
              on_retry: () => unawaited(_logic.load()),
            ),
          Padding(
            padding: const EdgeInsets.all(
              ComicHotCommentsStyle.horizontal_padding,
            ).copyWith(top: ComicHotCommentsStyle.footer_gap),
            child: OutlinedButton.icon(
              key: const ValueKey<String>('comic_hot_comments_write'),
              onPressed: widget.on_comments,
              icon: const Icon(
                Icons.edit_outlined,
                size: ComicHotCommentsStyle.action_icon,
              ),
              label: Text(
                tr('comics.write_comment'),
                style: TextStyle(
                  fontSize: ComicHotCommentsStyle.localized_size(
                    context,
                    ComicHotCommentsStyle.action_size_cjk,
                    ComicHotCommentsStyle.action_size_alphabetic,
                  ),
                  fontWeight: ComicHotCommentsStyle.medium,
                  height: ComicHotCommentsStyle.line_height(context),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ComicHotCommentsStyle.foreground(
                  widget.is_dark,
                ),
                backgroundColor: ComicHotCommentsStyle.foreground(
                  widget.is_dark,
                ).withValues(alpha: ComicHotCommentsStyle.control_tint),
                minimumSize: const Size(
                  0,
                  ComicHotCommentsStyle.control_min_height,
                ),
                side: BorderSide(
                  color: ComicHotCommentsStyle.foreground(
                    widget.is_dark,
                  ).withValues(alpha: ComicHotCommentsStyle.border_alpha),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ComicHotCommentsStyle.control_radius,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
