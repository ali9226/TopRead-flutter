// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';

import 'api.dart';

/// 共用段评状态：请求锁、分页、鉴权和生命周期集中处理。
class ParagraphCommentSheetLogic extends ChangeNotifier {
  /// 当前弹窗对应的服务端段落 ID。
  final int paragraph_id;

  /// 可替换的数据网关，长短篇使用相同 API。
  final ParagraphCommentRepository repository;

  /// 操作前校验登录状态；返回 false 时保留当前界面与草稿。
  final Future<bool> Function() ensure_authenticated;

  /// 同步正文中的段评气泡总数。
  final ValueChanged<int>? on_comment_count_changed;

  /// 仅在弹窗仍活跃时展示网络或业务错误。
  final ValueChanged<Object>? on_error;

  /// 顶层评论列表，子回复保存在每个节点的 replies 内。
  List<ParagraphComment> comments = [];

  /// 服务端确认的段落总评论数，包含全部未删除回复。
  int comment_count;

  /// 首屏或主动刷新加载状态。
  bool is_loading = true;

  /// 顶层列表的下一页请求锁。
  bool is_loading_more = false;

  /// 创建和回复的提交锁，防止重复发布同一草稿。
  bool is_submitting = false;

  /// 顶层列表是否还存在下一页。
  bool has_more = true;

  /// 列表失败状态供 UI 展示重试入口。
  Object? load_error;

  /// 按评论 ID 独立锁定点赞、删除与展开回复。
  final Set<int> liking_ids = {};
  final Set<int> deleting_ids = {};
  final Set<int> loading_reply_ids = {};
  final Map<int, int> _reply_pages = {};
  final Map<int, bool> _reply_has_more = {};

  /// 记录本次弹窗内已成功的点赞响应，避免较早发出的分页覆盖新状态。
  final Map<int, ({int revision, bool liked, int count})> _confirmed_likes = {};
  int _like_revision = 0;
  int _page = 0;
  int _generation = 0;
  bool _active = true;
  Future<bool>? _authentication;

  ParagraphCommentSheetLogic({
    required this.paragraph_id,
    required int initial_comment_count,
    required this.ensure_authenticated,
    this.repository = const ParagraphCommentRepository(),
    this.on_comment_count_changed,
    this.on_error,
  }) : comment_count = initial_comment_count;

  bool get is_active => _active;
  bool get is_mutating => is_submitting || deleting_ids.isNotEmpty;

  void _notify() {
    if (_active) notifyListeners();
  }

  /// 关闭路由时就停止 UI 回调，覆盖退出动画尚未 dispose 的间隙。
  void deactivate() {
    _active = false;
    _generation++;
  }

  void _set_count(int? count) {
    if (!_active || count == null || count == comment_count) return;
    comment_count = count;
    on_comment_count_changed?.call(count);
  }

  void _report_error(Object error) {
    if (_active) on_error?.call(error);
  }

  /// 多个操作同时触发登录时只显示一个登录提示。
  Future<bool> _authenticate() async {
    final Future<bool> pending =
        _authentication ??= Future<bool>.sync(ensure_authenticated);
    try {
      return await pending && _active;
    } finally {
      if (identical(_authentication, pending)) _authentication = null;
    }
  }

  /// 刷新使旧列表及回复请求失效，分页成功后才推进页码。
  Future<void> load_comments({bool load_more = false}) async {
    if (!_active) return;
    if (load_more && (is_loading || is_loading_more || !has_more)) return;
    if (!load_more) {
      _generation++;
      is_loading = true;
      is_loading_more = false;
      loading_reply_ids.clear();
      _reply_pages.clear();
      _reply_has_more.clear();
    } else {
      is_loading_more = true;
    }
    final int generation = _generation;
    final int like_revision = _like_revision;
    final int page = load_more ? _page + 1 : 1;
    load_error = null;
    _notify();
    try {
      final response = await repository.inquire(
        paragraph_id: paragraph_id, page: page,
      );
      if (!_active || generation != _generation) return;
      comments = _merge_unique(
        load_more ? comments : [],
        _preserve_recent_likes(response.list, like_revision),
        preserve_loaded_replies: load_more,
      );
      _page = page;
      has_more = response.has_more;
      _set_count(response.comment_count);
    } catch (error) {
      if (!_active || generation != _generation) return;
      load_error = error;
      _report_error(error);
    } finally {
      if (_active && generation == _generation) {
        is_loading = false;
        is_loading_more = false;
        _notify();
      }
    }
  }

  /// 首次展开从第 1 页获取完整回复，不把 3 条预览误当作完整分页。
  Future<void> load_replies(ParagraphComment parent) async {
    if (!_active || is_loading || !can_load_replies(parent) ||
        !loading_reply_ids.add(parent.id)) {
      return;
    }
    final int generation = _generation;
    final int like_revision = _like_revision;
    final int page = (_reply_pages[parent.id] ?? 0) + 1;
    _notify();
    try {
      final response = await repository.inquire(
        paragraph_id: paragraph_id, parent_id: parent.id, page: page,
      );
      if (!_active || generation != _generation) return;
      _replace_comment(parent.id, (current) => current.copy_with(
        replies: _merge_unique(
          page == 1 ? [] : current.replies,
          _preserve_recent_likes(response.list, like_revision),
          preserve_loaded_replies: true,
        ),
        reply_count: response.total,
      ));
      _reply_pages[parent.id] = page;
      _reply_has_more[parent.id] = response.has_more;
      _set_count(response.comment_count);
    } catch (error) {
      if (_active && generation == _generation) _report_error(error);
    } finally {
      if (_active && generation == _generation) {
        loading_reply_ids.remove(parent.id);
        _notify();
      }
    }
  }

  bool can_load_replies(ParagraphComment parent) =>
      _reply_has_more[parent.id] ?? parent.reply_count > parent.replies.length;

  /// 提交成功先同步事务计数，即使随后刷新失败也不会重复发送已成功的草稿。
  Future<bool> submit({
    required String content,
    List<String> images = const [],
    int? parent_id,
  }) async {
    if (!_active || is_mutating ||
        (content.trim().isEmpty && images.isEmpty)) {
      return false;
    }
    is_submitting = true;
    _notify();
    try {
      if (!await _authenticate()) return false;
      final result = await repository.submit(
        paragraph_id: paragraph_id,
        parent_id: parent_id,
        content: content.trim(),
        images: images,
      );
      if (!_active) return false;
      _set_count(result.comment_count);
      await load_comments();
      return true;
    } catch (error) {
      _report_error(error);
      return false;
    } finally {
      if (_active) {
        is_submitting = false;
        _notify();
      }
    }
  }

  Future<void> delete_comment(int comment_id) async {
    if (!_active || is_mutating || !deleting_ids.add(comment_id)) return;
    _notify();
    try {
      if (!await _authenticate()) return;
      final result = await repository.delete(comment_id);
      if (!_active) return;
      _set_count(result.comment_count);
      await load_comments();
    } catch (error) {
      _report_error(error);
    } finally {
      if (_active) {
        deleting_ids.remove(comment_id);
        _notify();
      }
    }
  }

  /// 指定点赞目标状态并锁定该评论，连续点击不会反复切换或重复计数。
  Future<void> toggle_like(ParagraphComment comment) async {
    if (!_active || !liking_ids.add(comment.id)) return;
    _notify();
    try {
      if (!await _authenticate()) return;
      // 登录期间列表可能刷新，使用当前节点而非点击时捕获的旧对象。
      final current = _find_comment(comments, comment.id);
      if (current == null) return;
      final result = await repository.like(comment.id, !current.is_liked);
      if (!_active) return;
      final bool liked = parse_paragraph_bool(result['liked']);
      final int count = parse_paragraph_int(result['like_count']);
      _confirmed_likes[comment.id] = (
        revision: ++_like_revision,
        liked: liked,
        count: count,
      );
      _replace_comment(comment.id, (current) => current.copy_with(
        is_liked: liked,
        like_count: count,
      ));
    } catch (error) {
      _report_error(error);
    } finally {
      if (_active) {
        liking_ids.remove(comment.id);
        _notify();
      }
    }
  }

  List<ParagraphComment> _merge_unique(
    List<ParagraphComment> old_comments,
    List<ParagraphComment> incoming, {
    bool preserve_loaded_replies = false,
  }) {
    final by_id = {for (final comment in old_comments) comment.id: comment};
    for (final comment in incoming) {
      final previous = by_id[comment.id];
      // 翻页遇到重复父评论时，不能用三条预览折叠用户已经展开的回复。
      by_id[comment.id] = preserve_loaded_replies &&
              previous != null && _reply_pages.containsKey(comment.id)
          ? comment.copy_with(replies: previous.replies)
          : comment;
    }
    return by_id.values.toList();
  }

  /// 仅保留请求发出之后确认的点赞；更晚发起的刷新仍以服务端为准。
  List<ParagraphComment> _preserve_recent_likes(
    List<ParagraphComment> incoming,
    int request_revision,
  ) => incoming.map((comment) {
    final confirmed = _confirmed_likes[comment.id];
    final bool keep_like = confirmed != null &&
        confirmed.revision > request_revision;
    return comment.copy_with(
      replies: _preserve_recent_likes(comment.replies, request_revision),
      is_liked: keep_like ? confirmed!.liked : null,
      like_count: keep_like ? confirmed!.count : null,
    );
  }).toList();

  /// 按稳定 ID 递归定位当前评论，回复与顶层评论执行相同的点赞规则。
  ParagraphComment? _find_comment(List<ParagraphComment> source, int id) {
    for (final comment in source) {
      if (comment.id == id) return comment;
      final reply = _find_comment(comment.replies, id);
      if (reply != null) return reply;
    }
    return null;
  }

  /// 回复可继续被回复，所有节点共用一套递归更新逻辑。
  void _replace_comment(
    int comment_id, ParagraphComment Function(ParagraphComment) update,
  ) {
    List<ParagraphComment> replace(List<ParagraphComment> source) => source.map(
      (comment) => comment.id == comment_id
          ? update(comment)
          : comment.copy_with(replies: replace(comment.replies)),
    ).toList();
    comments = replace(comments);
  }

  @override
  void dispose() {
    deactivate();
    super.dispose();
  }
}
