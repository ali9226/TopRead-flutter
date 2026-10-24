// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:app/api/comics_comments.dart';
import 'package:app/components/comment_list/models/comment_data.dart';
import 'package:app/config/constant.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/comments/style.dart';
import 'package:app/pages/comics/logic.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get/get.dart';

typedef ComicCommentRequester =
    Future<Map<String, dynamic>> Function(
      String action,
      Map<String, dynamic> parameter, {
      String? authorization_token,
    });

/// TODO 主评论与回复线程各自分页，展开回复不会重置主列表。
class ComicReplyThread {
  final List<CommentData> items = <CommentData>[];
  int page = 0;
  int total = 0;
  int request_id = 0;
  bool loading = false;
  bool expanded = false;
  bool has_more = false;
  String? error;
}

/// TODO 漫画独立接口转换为公共 CommentData，小说评论组件保持原有行为。
class ComicCommentsLogic extends ComicsController {
  ComicCommentsLogic({
    required this.comic_id,
    this.chapter_id,
    this.sort,
    this.page_size = ComicCommentsStyle.page_size,
    ComicCommentRequester? requester,
    Future<String?> Function()? token_reader,
    bool Function()? require_login,
    void Function(String)? feedback,
  }) : assert(page_size > 0),
       _requester = requester ?? comics_comments_request,
       _token_reader =
           token_reader ?? (() => StorageUtil.getData(Constant.tokenKey)),
       _require_login = require_login ?? comics_require_login,
       _feedback =
           feedback ??
           ((message) {
             unawaited(showBottomTip(message));
           }) {
    _identity_revision = _user?.auth_revision ?? 0;
    _identity_user_id = user_id;
    final user = _user;
    if (user != null) {
      _identity_worker = everAll(<RxInterface>[
        user.userInfo,
        user.isLoggedIn,
      ], (_) => _identity_changed());
    }
  }

  final int comic_id;
  final int? chapter_id;

  /// 详情预览由服务端按热度排序；普通评论页省略参数，保留原来的时间顺序。
  final String? sort;

  /// 主评论可按预览数量请求，回复线程继续使用完整评论页的分页大小。
  final int page_size;
  final ComicCommentRequester _requester;
  final Future<String?> Function() _token_reader;
  final bool Function() _require_login;
  final void Function(String) _feedback;
  final List<CommentData> items = <CommentData>[];
  final Map<int, ComicReplyThread> threads = <int, ComicReplyThread>{};
  final Map<int, int> reply_counts = <int, int>{};
  final Set<int> busy_comments = <int>{};
  CommentData? replying;
  int? replying_root_id;
  int page = 0;
  int total = 0;

  /// TODO 可见正文条数包含回复，用于与作品详情展示同一口径。
  int comment_count = 0;
  int identity_epoch = 0;
  bool loading = true;
  bool loading_more = false;
  bool sending = false;
  bool has_more = false;
  int _request_id = 0;
  int _identity_revision = 0;
  int _identity_user_id = 0;
  Worker? _identity_worker;
  UserInformation? get _user =>
      Get.isRegistered<UserInformation>() ? Get.find<UserInformation>() : null;
  int get user_id =>
      _user?.isLoggedIn.value == true ? _user?.userInfo.value?.id ?? 0 : 0;

  /// TODO 作品评论省略 chapter_id，章评论仅携带所属章节，不复用小说段评参数。
  Map<String, dynamic> _scope() => <String, dynamic>{
    'comic_id': comic_id,
    if (chapter_id != null && chapter_id! > 0) 'chapter_id': chapter_id,
  };

  /// TODO 身份变化立即清空个人点赞、回复草稿和缓存，使旧请求响应全部失效。
  void _identity_changed() {
    final revision = _user?.auth_revision ?? 0;
    if (revision == _identity_revision && user_id == _identity_user_id) return;
    _identity_revision = revision;
    _identity_user_id = user_id;
    identity_epoch++;
    _request_id++;
    items.clear();
    threads.clear();
    reply_counts.clear();
    busy_comments.clear();
    replying = null;
    replying_root_id = null;
    sending = false;
    page = 0;
    total = 0;
    comment_count = 0;
    has_more = false;
    loading_more = false;
    unawaited(load());
  }

  /// TODO 凭证读取完成后复核身份；访客显式使用空凭证，拒绝残留账号 token。
  Future<_CommentSession> _capture_session() async {
    final revision = _user?.auth_revision ?? 0;
    final id = user_id;
    final profile = _user?.userInfo.value;
    final token = id > 0 ? await _token_reader() ?? '' : '';
    final session = _CommentSession(
      revision,
      id,
      token,
      profile?.name ?? '',
      profile?.avatarUrl ?? '',
    );
    if (!_current(session)) throw const _CommentSessionChanged();
    return session;
  }

  /// TODO 只接受请求所属会话，旧账号的成功数据与错误提示均不能影响新账号。
  bool _current(_CommentSession session) =>
      !disposed &&
      session.revision == (_user?.auth_revision ?? 0) &&
      session.user_id == user_id;

  /// TODO 主列表分页按评论 ID 去重，刷新清理旧线程；临时失败保留现有评论并可重试。
  Future<void> load({bool more = false, bool preserve_threads = false}) async {
    if (disposed || (more && (loading || loading_more || !has_more))) return;
    final request_id = ++_request_id;
    final next_page = more ? page + 1 : 1;
    if (!more && !preserve_threads) threads.clear();
    if (more) {
      loading_more = true;
    } else {
      loading = true;
      loading_more = false;
    }
    error = null;
    emit();
    _CommentSession? session;
    try {
      session = await _capture_session();
      final data = await _requester('inquire', <String, dynamic>{
        ..._scope(),
        'page': next_page,
        'page_size': page_size,
        if (sort != null) 'sort': sort,
      }, authorization_token: session.token);
      if (!_current(session) || request_id != _request_id) return;
      if (data['list'] is! List) {
        throw FormatException(tr('comics.operation_failed'));
      }
      final rows = comics_list(data['list']);
      final merged = _merge(
        more ? items : const <CommentData>[],
        rows.map(CommentData.from_json),
      );
      items
        ..clear()
        ..addAll(merged);
      if (!more) reply_counts.clear();
      for (final row in rows) {
        reply_counts[comics_int(row['id'])] = comics_int(row['reply_count']);
      }
      threads.removeWhere((id, _) => !items.any((item) => item.id == id));
      total = comics_int(data['total']);
      comment_count = comics_int(data['comment_count'] ?? data['total']);
      page = next_page;
      has_more = rows.length >= page_size && page * page_size < total;
    } on _CommentSessionChanged {
      return;
    } catch (failure) {
      if (!disposed &&
          request_id == _request_id &&
          (session == null || _current(session))) {
        error = failure.toString();
      }
    } finally {
      if (!disposed && request_id == _request_id) {
        loading = false;
        loading_more = false;
        emit();
      }
    }
  }

  /// TODO 后端 parent_id 查询根线程，扁平回复保留被回复者昵称供共享组件呈现。
  Future<void> replies(
    int root_id, {
    bool more = false,
    bool refresh = false,
  }) async {
    if (disposed) return;
    final thread = threads.putIfAbsent(root_id, ComicReplyThread.new);
    if (thread.loading || (more && !thread.has_more)) return;
    if (thread.expanded && !more && !refresh) {
      thread.expanded = false;
      emit();
      return;
    }
    thread.expanded = true;
    if (thread.page > 0 && !more && !refresh) {
      emit();
      return;
    }
    final request_id = ++thread.request_id;
    final next_page = more ? thread.page + 1 : 1;
    thread.loading = true;
    thread.error = null;
    emit();
    _CommentSession? session;
    try {
      session = await _capture_session();
      final data = await _requester('inquire', <String, dynamic>{
        ..._scope(),
        'parent_id': root_id,
        'page': next_page,
        'page_size': ComicCommentsStyle.page_size,
      }, authorization_token: session.token);
      if (!_current(session) ||
          !identical(threads[root_id], thread) ||
          request_id != thread.request_id) {
        return;
      }
      if (data['list'] is! List) {
        throw FormatException(tr('comics.operation_failed'));
      }
      final rows = comics_list(data['list']);
      final merged = _merge(
        more ? thread.items : const <CommentData>[],
        rows.map(CommentData.from_json),
      )..sort((left, right) => left.id.compareTo(right.id));
      thread.items
        ..clear()
        ..addAll(merged);
      thread.total = comics_int(data['total']);
      thread.page = next_page;
      thread.has_more =
          rows.length >= ComicCommentsStyle.page_size &&
          next_page * ComicCommentsStyle.page_size < thread.total;
      reply_counts[root_id] = thread.total;
    } on _CommentSessionChanged {
      return;
    } catch (failure) {
      if (!disposed &&
          identical(threads[root_id], thread) &&
          (session == null || _current(session))) {
        thread.error = failure.toString();
      }
    } finally {
      if (!disposed &&
          identical(threads[root_id], thread) &&
          request_id == thread.request_id) {
        thread.loading = false;
        emit();
      }
    }
  }

  /// TODO 选择回复前要求登录，已删除评论不能作为交互目标。
  void reply_to(CommentData comment, int root_id) {
    if (comment.is_deleted || !_require_login()) return;
    replying = comment;
    replying_root_id = root_id;
    emit();
  }

  void cancel_reply() {
    replying = null;
    replying_root_id = null;
    emit();
  }

  /// TODO 发送绑定原会话与作品/章节范围；失败返回 false，使公共输入框保留草稿。
  Future<bool> send(String content) async {
    final text = content.trim();
    if (disposed || sending || text.isEmpty || !_require_login()) return false;
    if (text.length > ComicCommentsStyle.max_comment_length) {
      _feedback(tr('comics.comment_too_long'));
      return false;
    }
    final target = replying;
    final root_id = replying_root_id;
    sending = true;
    emit();
    _CommentSession? session;
    try {
      session = await _capture_session();
      final data = await _requester('add', <String, dynamic>{
        ..._scope(),
        'comment_content': text,
        if (target != null) 'parent_id': target.id,
      }, authorization_token: session.token);
      if (!_current(session)) return false;
      final id = comics_int(data['id']);
      if (id <= 0) throw FormatException(tr('comics.operation_failed'));
      final added = CommentData(
        id: id,
        user_id: session.user_id,
        avatar: session.avatar,
        nickname: session.nickname,
        content: text,
        time: DateTime.now().toUtc().toIso8601String(),
        parent_id: target?.id ?? 0,
        reply_to_nickname: target?.nickname,
      );
      cancel_reply();
      comment_count++;
      if (root_id == null) {
        items.insert(0, added);
        total++;
        reply_counts[id] = 0;
      } else {
        final thread = threads.putIfAbsent(root_id, ComicReplyThread.new);
        if (thread.page == 0) await replies(root_id, refresh: true);
        if (!_current(session)) return true;
        final existed = thread.items.any((item) => item.id == id);
        final merged = _merge(thread.items, <CommentData>[added])
          ..sort((left, right) => left.id.compareTo(right.id));
        thread.items
          ..clear()
          ..addAll(merged);
        thread.expanded = true;
        if (!existed) thread.total++;
        reply_counts[root_id] = thread.total;
      }
      emit();
      await load(preserve_threads: true);
      return true;
    } on _CommentSessionChanged {
      return false;
    } catch (failure) {
      if (!disposed && (session == null || _current(session))) {
        _feedback(failure.toString());
      }
      return false;
    } finally {
      if (!disposed && (session == null || _current(session))) {
        sending = false;
        emit();
      }
    }
  }

  /// TODO 点赞仅根据后端最新值更新，失败不反转状态，快速重复点击只产生一个请求。
  Future<void> like(CommentData comment) async {
    if (disposed ||
        comment.is_deleted ||
        busy_comments.contains(comment.id) ||
        !_require_login()) {
      return;
    }
    busy_comments.add(comment.id);
    emit();
    _CommentSession? session;
    try {
      session = await _capture_session();
      final data = await _requester('like', <String, dynamic>{
        'comment_id': comment.id,
        'liked': !comment.is_liked,
      }, authorization_token: session.token);
      if (!_current(session)) return;
      if (!data.containsKey('liked') || !data.containsKey('like_count')) {
        throw FormatException(tr('comics.operation_failed'));
      }
      _replace(
        comment.id,
        (item) => item.copy_with(
          is_liked: comics_bool(data['liked']),
          like_count: comics_int(data['like_count']),
        ),
      );
    } on _CommentSessionChanged {
      return;
    } catch (failure) {
      if (!disposed && (session == null || _current(session))) {
        _feedback(failure.toString());
      }
    } finally {
      if (!disposed && (session == null || _current(session))) {
        busy_comments.remove(comment.id);
        emit();
      }
    }
  }

  /// TODO 只能删除当前账号自己的评论，软删除保留根线程与其现有回复关系。
  Future<void> delete(CommentData comment, int root_id) async {
    if (disposed ||
        comment.is_deleted ||
        comment.user_id != user_id ||
        busy_comments.contains(comment.id) ||
        !_require_login()) {
      return;
    }
    busy_comments.add(comment.id);
    emit();
    _CommentSession? session;
    try {
      session = await _capture_session();
      await _requester('delete', <String, dynamic>{
        'comment_id': comment.id,
      }, authorization_token: session.token);
      if (!_current(session)) return;
      _replace(comment.id, (item) => item.copy_with(is_deleted: true));
      if (replying?.id == comment.id) cancel_reply();
      await load(preserve_threads: true);
      if (_current(session) && threads[root_id]?.expanded == true) {
        await replies(root_id, refresh: true);
      }
    } on _CommentSessionChanged {
      return;
    } catch (failure) {
      if (!disposed && (session == null || _current(session))) {
        _feedback(failure.toString());
      }
    } finally {
      if (!disposed && (session == null || _current(session))) {
        busy_comments.remove(comment.id);
        emit();
      }
    }
  }

  /// TODO 重复分页更新已有评论正文与点赞状态，稳定保留已经显示的顺序。
  List<CommentData> _merge(
    Iterable<CommentData> current,
    Iterable<CommentData> incoming,
  ) => <int, CommentData>{
    for (final item in current)
      if (item.id > 0) item.id: item,
    for (final item in incoming)
      if (item.id > 0) item.id: item,
  }.values.toList();

  /// TODO 更新主列表或已加载线程中的相同评论，公共展示模型保持不可变。
  void _replace(int id, CommentData Function(CommentData) update) {
    for (var index = 0; index < items.length; index++) {
      if (items[index].id == id) items[index] = update(items[index]);
    }
    for (final thread in threads.values) {
      for (var index = 0; index < thread.items.length; index++) {
        if (thread.items[index].id == id) {
          thread.items[index] = update(thread.items[index]);
        }
      }
    }
  }

  @override
  void dispose() {
    _identity_worker?.dispose();
    super.dispose();
  }
}

/// TODO 请求身份快照；凭证只进入网络请求，不进入界面或日志。
class _CommentSession {
  const _CommentSession(
    this.revision,
    this.user_id,
    this.token,
    this.nickname,
    this.avatar,
  );
  final int revision;
  final int user_id;
  final String token;
  final String nickname;
  final String avatar;
}

class _CommentSessionChanged implements Exception {
  const _CommentSessionChanged();
}
