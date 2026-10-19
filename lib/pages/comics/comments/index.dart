// ignore_for_file: non_constant_identifier_names

import 'package:app/components/window_content_layout/index.dart';
import 'package:app/components/comment_list/widgets/comment_input.dart';
import 'package:app/components/comment_list/widgets/comment_skeleton.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/comics/comments/comment_item.dart';
import 'package:app/pages/comics/comments/logic.dart';
import 'package:app/pages/comics/comments/style.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/comics/widgets/empty_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// TODO 普通漫画评论与章评论共用小说列表项及输入栏，章 ID 只决定独立的数据范围。
class ComicCommentsPage extends StatefulWidget {
  const ComicCommentsPage({
    super.key,
    required this.comic_id,
    this.chapter_id,
    this.controller,
  });
  final int comic_id;
  final int? chapter_id;
  final ComicCommentsLogic? controller;
  @override
  State<ComicCommentsPage> createState() => _ComicCommentsPageState();
}

class _ComicCommentsPageState extends State<ComicCommentsPage> {
  late ComicCommentsLogic _logic;
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();
  int _identity_epoch = 0;

  @override
  void initState() {
    super.initState();
    _bind_logic();
    _scroll.addListener(_on_scroll);
  }

  /// TODO 测试可注入同一生产控制器，真实页面仍通过统一加密接口加载。
  void _bind_logic() {
    _logic =
        widget.controller ??
        ComicCommentsLogic(
          comic_id: widget.comic_id,
          chapter_id: widget.chapter_id,
        );
    _identity_epoch = _logic.identity_epoch;
    _logic.addListener(_on_change);
    _logic.load();
  }

  @override
  void didUpdateWidget(covariant ComicCommentsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comic_id == widget.comic_id &&
        oldWidget.chapter_id == widget.chapter_id &&
        identical(oldWidget.controller, widget.controller)) {
      return;
    }
    _logic.removeListener(_on_change);
    if (oldWidget.controller == null) _logic.dispose();
    _focus.unfocus();
    _bind_logic();
  }

  void _on_scroll() {
    if (_scroll.hasClients &&
        _scroll.position.extentAfter < ComicCommentsStyle.load_more_distance) {
      _logic.load(more: true);
    }
  }

  /// TODO 切换账号重建公共输入栏，清理旧草稿和焦点；选择回复时只聚焦一次。
  void _on_change() {
    if (_identity_epoch != _logic.identity_epoch) {
      _identity_epoch = _logic.identity_epoch;
      _focus.unfocus();
    } else if (_logic.replying != null && !_focus.hasFocus) {
      _focus.requestFocus();
    }
  }

  @override
  void dispose() {
    _logic.removeListener(_on_change);
    if (widget.controller == null) _logic.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _logic,
    builder: (context, _) {
      final dark = ComicsStyle.is_dark(context);
      final scaler = MediaQuery.textScalerOf(context);
      final title_size = ComicsStyle.is_cjk(context)
          ? ComicCommentsStyle.title_size_cjk
          : ComicCommentsStyle.title_size_alphabetic;
      final toolbar_height =
          (scaler.scale(title_size) * ComicsStyle.line_height_alphabetic +
                  (_logic.total > 0
                      ? scaler.scale(ComicCommentsStyle.count_size) *
                            ComicsStyle.line_height_alphabetic
                      : 0) +
                  ComicCommentsStyle.toolbar_vertical_padding)
              .clamp(ComicCommentsStyle.toolbar_height, double.infinity)
              .toDouble();
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: ComicsStyle.surface(context),
        appBar: WindowAppBar(
          child: AppBar(
            toolbarHeight: toolbar_height,
            backgroundColor: ComicsStyle.surface(context),
            surfaceTintColor: Colors.transparent,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  tr(
                    widget.chapter_id == null
                        ? 'comics.comments'
                        : 'comics.chapter_comments',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ComicsStyle.ink(context),
                    fontSize: ComicsStyle.is_cjk(context)
                        ? ComicCommentsStyle.title_size_cjk
                        : ComicCommentsStyle.title_size_alphabetic,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                  ),
                ),
                if (_logic.total > 0)
                  Text(
                    tr(
                      'comment.count_label',
                      namedArgs: <String, String>{'count': '${_logic.total}'},
                    ),
                    style: ComicsStyle.text(
                      context,
                      size: ComicCommentsStyle.count_size,
                      color: ComicsStyle.muted(context),
                    ),
                  ),
              ],
            ),
          ),
        ),
        body: WindowContentLayout(
          child: Column(
            children: <Widget>[
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _logic.load,
                  child: ListView(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: <Widget>[
                      if (_logic.loading && _logic.items.isEmpty)
                        CommentSkeleton(is_dark: dark),
                      if (!_logic.loading && _logic.items.isEmpty)
                        ComicsEmptyState(
                          error: _logic.error,
                          message: tr('comics.empty_comments'),
                          on_retry: _logic.load,
                        ),
                      for (final comment in _logic.items)
                        ComicCommentItem(
                          key: ValueKey<int>(comment.id),
                          comment: comment,
                          logic: _logic,
                        ),
                      if (_logic.error != null && _logic.items.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(
                            ComicCommentsStyle.footer_padding,
                          ),
                          child: Column(
                            children: <Widget>[
                              Text(
                                _logic.error!,
                                textAlign: TextAlign.center,
                                style: ComicsStyle.text(
                                  context,
                                  color: ComicsStyle.muted(context),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _logic.load(more: _logic.has_more),
                                child: Text(tr('comics.retry')),
                              ),
                            ],
                          ),
                        ),
                      if (_logic.loading_more)
                        const Padding(
                          padding: EdgeInsets.all(
                            ComicCommentsStyle.footer_padding,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      if (!_logic.loading_more &&
                          _logic.has_more &&
                          _logic.error == null)
                        Center(
                          child: TextButton(
                            onPressed: () => _logic.load(more: true),
                            child: Text(tr('comics.load_more')),
                          ),
                        ),
                      const SizedBox(height: ComicCommentsStyle.footer_padding),
                    ],
                  ),
                ),
              ),
              CommentInput(
                key: ValueKey<int>(_logic.identity_epoch),
                is_dark: dark,
                on_send: _logic.send,
                focus_node: _focus,
                reply_target: _logic.replying,
                on_cancel_reply: _logic.cancel_reply,
              ),
            ],
          ),
        ),
      );
    },
  );
}
