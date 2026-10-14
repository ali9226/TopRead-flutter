// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/comments/comment_item.dart';
import 'package:app/pages/comics/comments/logic.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/comics/widgets/empty_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 普通评论和章节评论共享界面，底部输入框随键盘和安全区调整。
class ComicCommentsPage extends StatefulWidget {
  final int comic_id;
  final int? chapter_id;
  const ComicCommentsPage({super.key, required this.comic_id, this.chapter_id});
  @override
  State<ComicCommentsPage> createState() => _ComicCommentsPageState();
}

class _ComicCommentsPageState extends State<ComicCommentsPage> {
  late final ComicCommentsLogic _logic = ComicCommentsLogic(
    comic_id: widget.comic_id,
    chapter_id: widget.chapter_id,
  );
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();
  @override
  void initState() {
    super.initState();
    _logic.load();
    _scroll.addListener(_on_scroll);
    _logic.addListener(_on_change);
  }

  void _on_scroll() {
    if (_scroll.position.extentAfter < 400) _logic.load(more: true);
  }

  void _on_change() {
    if (_logic.replying != null && !_focus.hasFocus) _focus.requestFocus();
  }

  @override
  void dispose() {
    _logic.removeListener(_on_change);
    _logic.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _logic,
    builder: (context, child) => Scaffold(
      backgroundColor: ComicsStyle.background(context),
      appBar: AppBar(
        backgroundColor: ComicsStyle.background(context),
        surfaceTintColor: Colors.transparent,
        title: Text(
          tr(
            widget.chapter_id == null
                ? 'comics.comments'
                : 'comics.chapter_comments',
          ),
          style: ComicsStyle.text(context, size: 18, strong: true),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: ComicsStyle.content_width,
          ),
          child: Column(
            children: <Widget>[
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _logic.load,
                  child: ListView(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: ComicsStyle.page_padding,
                    ),
                    children: <Widget>[
                      if (_logic.loading || _logic.items.isEmpty)
                        ComicsEmptyState(
                          loading: _logic.loading,
                          error: _logic.error,
                          message: tr('comics.empty_comments'),
                          on_retry: _logic.load,
                        ),
                      for (final comment in _logic.items)
                        _thread(context, comment),
                      if (!_logic.loading && _logic.has_more)
                        Center(
                          child: _logic.loading_more
                              ? const CircularProgressIndicator()
                              : TextButton(
                                  style: ComicsStyle.text_button(context),
                                  onPressed: () => _logic.load(more: true),
                                  child: Text(
                                    tr(
                                      _logic.error == null
                                          ? 'comics.load_more'
                                          : 'comics.retry',
                                    ),
                                  ),
                                ),
                        ),
                      const SizedBox(height: ComicsStyle.large_gap),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(ComicsStyle.gap),
                  decoration: BoxDecoration(
                    color: ComicsStyle.surface(context),
                    border: Border(
                      top: BorderSide(color: ComicsStyle.outline(context)),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (_logic.replying != null)
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                tr(
                                  'comics.replying_to',
                                  namedArgs: <String, String>{
                                    'name':
                                        '${_logic.replying!['nickname'] ?? ''}',
                                  },
                                ),
                                style: ComicsStyle.text(
                                  context,
                                  size: 12,
                                  color: ComicsStyle.muted(context),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: tr('comics.cancel_reply'),
                              onPressed: _logic.cancel_reply,
                              icon: const Icon(Icons.close, size: 18),
                            ),
                          ],
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: _logic.input,
                              focusNode: _focus,
                              minLines: 1,
                              maxLines: 4,
                              maxLength: 2000,
                              style: ComicsStyle.text(context),
                              decoration: InputDecoration(
                                hintText: tr('comics.comment_hint'),
                                counterText: '',
                                filled: true,
                                fillColor: ComicsStyle.background(context),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    ComicsStyle.cover_radius,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: ComicsStyle.small_gap),
                          FilledButton(
                            onPressed: _logic.sending ? null : _logic.send,
                            style: FilledButton.styleFrom(
                              backgroundColor: ColorConstants.themeColor,
                              foregroundColor: ColorConstants.lightTextColor,
                              minimumSize: const Size(48, 48),
                            ),
                            child: _logic.sending
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.arrow_upward_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _thread(BuildContext context, Map<String, dynamic> comment) {
    final root_id = comics_int(comment['id']);
    final thread = _logic.threads[root_id];
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ComicsStyle.outline(context))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ComicCommentItem(comment: comment, logic: _logic, root_id: root_id),
          if (comics_int(comment['reply_count']) > 0 || thread != null)
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: TextButton(
                style: ComicsStyle.text_button(context),
                onPressed: () => _logic.replies(root_id),
                child: Text(
                  thread?.expanded == true
                      ? tr('comics.hide_replies')
                      : tr(
                          'comics.show_replies',
                          namedArgs: <String, String>{
                            'count': '${comics_int(comment['reply_count'])}',
                          },
                        ),
                  style: ComicsStyle.text(context, size: 12, strong: true),
                ),
              ),
            ),
          if (thread?.expanded == true)
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                children: <Widget>[
                  for (final reply in thread!.items)
                    ComicCommentItem(
                      comment: reply,
                      logic: _logic,
                      root_id: root_id,
                      reply: true,
                    ),
                  if (thread.loading)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (thread.error != null)
                    TextButton(
                      style: ComicsStyle.text_button(context),
                      onPressed: () => _logic.replies(root_id, refresh: true),
                      child: Text(tr('comics.retry')),
                    ),
                  if (!thread.loading && thread.items.length < thread.total)
                    TextButton(
                      style: ComicsStyle.text_button(context),
                      onPressed: () => _logic.replies(root_id, more: true),
                      child: Text(tr('comics.load_more')),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
