// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/read/widgets/paragraph_comment/paragraph_comment_api.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

/// 段落评论面板。
///
/// 从底部弹出，显示段落的评论列表，支持发表评论和回复。
class ParagraphCommentSheet extends StatefulWidget {
  /// 段落ID。
  final int paragraph_id;

  /// 段落序号（用于显示）。
  final int paragraph_no;

  /// 初始评论数量。
  final int initial_comment_count;

  /// 当前是否夜间主题。
  final bool is_dark;

  const ParagraphCommentSheet({
    super.key,
    required this.paragraph_id,
    required this.paragraph_no,
    required this.initial_comment_count,
    required this.is_dark,
  });

  /// 显示评论面板。
  static Future<int?> show({
    required BuildContext context,
    required int paragraph_id,
    required int paragraph_no,
    required int initial_comment_count,
    required bool is_dark,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ParagraphCommentSheet(
        paragraph_id: paragraph_id,
        paragraph_no: paragraph_no,
        initial_comment_count: initial_comment_count,
        is_dark: is_dark,
      ),
    );
  }

  @override
  State<ParagraphCommentSheet> createState() => _ParagraphCommentSheetState();
}

class _ParagraphCommentSheetState extends State<ParagraphCommentSheet> {
  final TextEditingController _input_controller = TextEditingController();
  final ScrollController _scroll_controller = ScrollController();

  List<ParagraphComment> _comments = [];
  bool _is_loading = true;
  bool _is_submitting = false;
  int _total = 0;
  int _page = 1;
  bool _has_more = true;
  int? _reply_to_id;
  String? _reply_to_name;

  @override
  void initState() {
    super.initState();
    _total = widget.initial_comment_count;
    _load_comments();
  }

  @override
  void dispose() {
    _input_controller.dispose();
    _scroll_controller.dispose();
    super.dispose();
  }

  Future<void> _load_comments({bool load_more = false}) async {
    if (load_more && !_has_more) return;

    try {
      final response = await ParagraphCommentApi.inquire(
        paragraph_id: widget.paragraph_id,
        page: load_more ? _page + 1 : 1,
      );

      if (mounted) {
        setState(() {
          if (load_more) {
            _comments.addAll(response.list);
            _page++;
          } else {
            _comments = response.list;
            _page = 1;
          }
          _total = response.total;
          _has_more = response.has_more;
          _is_loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _is_loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载评论失败: $e')),
        );
      }
    }
  }

  Future<void> _submit_comment() async {
    final content = _input_controller.text.trim();
    if (content.isEmpty || _is_submitting) return;

    setState(() => _is_submitting = true);

    try {
      if (_reply_to_id != null) {
        await ParagraphCommentApi.reply(
          paragraph_id: widget.paragraph_id,
          parent_id: _reply_to_id!,
          content: content,
        );
      } else {
        await ParagraphCommentApi.create(
          paragraph_id: widget.paragraph_id,
          content: content,
        );
      }

      _input_controller.clear();
      _cancel_reply();
      await _load_comments();

      // 返回更新后的评论数量
      if (mounted) {
        Navigator.pop(context, _total);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发表评论失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _is_submitting = false);
      }
    }
  }

  void _start_reply(int comment_id, String user_name) {
    setState(() {
      _reply_to_id = comment_id;
      _reply_to_name = user_name;
    });
    _input_controller.text = '';
    FocusScope.of(context).requestFocus();
  }

  void _cancel_reply() {
    setState(() {
      _reply_to_id = null;
      _reply_to_name = null;
    });
  }

  Future<void> _delete_comment(int comment_id) async {
    try {
      await ParagraphCommentApi.delete(comment_id: comment_id);
      await _load_comments();

      if (mounted) {
        Navigator.pop(context, _total);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除评论失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottom_safe = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AuthorStyle.surface(widget.is_dark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 标题栏
          _build_header(),

          // 评论列表
          Expanded(
            child: _is_loading
                ? const Center(child: CircularProgressIndicator())
                : _build_comment_list(),
          ),

          // 输入框
          _build_input_bar(bottom_safe),
        ],
      ),
    );
  }

  Widget _build_header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AuthorStyle.border(widget.is_dark),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '段落评论',
            style: TextStyle(
              fontSize: 17,
              fontWeight: AuthorStyle.title_weight,
              color: AuthorStyle.primary_text(widget.is_dark),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($_total)',
            style: TextStyle(
              fontSize: 14,
              color: AuthorStyle.secondary_text(widget.is_dark),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context, _total),
            icon: Icon(
              Icons.close_rounded,
              color: AuthorStyle.secondary_text(widget.is_dark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build_comment_list() {
    if (_comments.isEmpty) {
      return Center(
        child: Text(
          '暂无评论',
          style: TextStyle(
            color: AuthorStyle.secondary_text(widget.is_dark),
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scroll_controller,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _comments.length + (_has_more ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _comments.length) {
          return _build_load_more_button();
        }
        return _build_comment_item(_comments[index]);
      },
    );
  }

  Widget _build_load_more_button() {
    return Center(
      child: TextButton(
        onPressed: () => _load_comments(load_more: true),
        child: Text(
          '加载更多',
          style: TextStyle(
            color: AuthorStyle.gold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _build_comment_item(ParagraphComment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 评论头部
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AuthorStyle.secondary_surface(widget.is_dark),
                child: comment.user_avatar.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          comment.user_avatar,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person,
                            size: 20,
                            color: AuthorStyle.secondary_text(widget.is_dark),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 20,
                        color: AuthorStyle.secondary_text(widget.is_dark),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.user_name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: AuthorStyle.emphasis_weight,
                        color: AuthorStyle.primary_text(widget.is_dark),
                      ),
                    ),
                    Text(
                      _format_time(comment.create_time),
                      style: TextStyle(
                        fontSize: 12,
                        color: AuthorStyle.secondary_text(widget.is_dark),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz,
                  color: AuthorStyle.secondary_text(widget.is_dark),
                ),
                onSelected: (value) {
                  if (value == 'reply') {
                    _start_reply(comment.id, comment.user_name);
                  } else if (value == 'delete') {
                    _delete_comment(comment.id);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'reply',
                    child: Text('回复'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('删除'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 评论内容
          Text(
            comment.content,
            style: TextStyle(
              fontSize: 15,
              color: AuthorStyle.primary_text(widget.is_dark),
              height: 1.5,
            ),
          ),

          // 回复列表
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AuthorStyle.secondary_surface(widget.is_dark),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final reply in comment.replies.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _build_reply_item(reply),
                    ),
                  if (comment.reply_count > 3)
                    TextButton(
                      onPressed: () {
                        // TODO: 查看更多回复
                      },
                      child: Text(
                        '查看全部${comment.reply_count}条回复',
                        style: TextStyle(
                          color: AuthorStyle.gold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _build_reply_item(ParagraphComment reply) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              reply.user_name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: AuthorStyle.emphasis_weight,
                color: AuthorStyle.primary_text(widget.is_dark),
              ),
            ),
            const Spacer(),
            Text(
              _format_time(reply.create_time),
              style: TextStyle(
                fontSize: 11,
                color: AuthorStyle.secondary_text(widget.is_dark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          reply.content,
          style: TextStyle(
            fontSize: 14,
            color: AuthorStyle.primary_text(widget.is_dark),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _build_input_bar(double bottom_safe) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottom_safe),
      decoration: BoxDecoration(
        color: AuthorStyle.surface(widget.is_dark),
        border: Border(
          top: BorderSide(color: AuthorStyle.border(widget.is_dark)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 回复提示
          if (_reply_to_id != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    '回复 $_reply_to_name',
                    style: TextStyle(
                      fontSize: 13,
                      color: AuthorStyle.secondary_text(widget.is_dark),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cancel_reply,
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: AuthorStyle.secondary_text(widget.is_dark),
                    ),
                  ),
                ],
              ),
            ),

          // 输入框
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input_controller,
                  style: TextStyle(
                    fontSize: 15,
                    color: AuthorStyle.primary_text(widget.is_dark),
                  ),
                  decoration: InputDecoration(
                    hintText: _reply_to_id != null ? '写回复...' : '写评论...',
                    hintStyle: TextStyle(
                      color: AuthorStyle.secondary_text(widget.is_dark),
                    ),
                    filled: true,
                    fillColor: AuthorStyle.secondary_surface(widget.is_dark),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _is_submitting ? null : _submit_comment,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _is_submitting
                        ? AuthorStyle.secondary_surface(widget.is_dark)
                        : AuthorStyle.gold,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send,
                    size: 20,
                    color: _is_submitting
                        ? AuthorStyle.secondary_text(widget.is_dark)
                        : const Color(0xFF1A1A18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _format_time(String time_str) {
    if (time_str.isEmpty) return '';
    try {
      final DateTime time = DateTime.parse(time_str);
      final Duration diff = DateTime.now().difference(time);

      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
      if (diff.inDays < 1) return '${diff.inHours}小时前';
      if (diff.inDays < 30) return '${diff.inDays}天前';
      return '${time.month}-${time.day}';
    } catch (_) {
      return time_str;
    }
  }
}
