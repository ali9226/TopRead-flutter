// ignore_for_file: non_constant_identifier_names

import 'package:app/api/comics.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/logic.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 每个评论线程拥有自己的页码和加载状态，展开回复不会重置主列表。
class ComicReplyThread {
  final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
  int page = 0;
  int total = 0;
  bool loading = false;
  bool expanded = false;
  String? error;
}

/// 漫画评论与小说评论接口独立，作品评论和章评论由 chapter_id 精确隔离。
class ComicCommentsLogic extends ComicsController {
  final int comic_id;
  final int? chapter_id;
  ComicCommentsLogic({required this.comic_id, this.chapter_id});
  final TextEditingController input = TextEditingController();
  final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
  final Map<int, ComicReplyThread> threads = <int, ComicReplyThread>{};
  final Set<int> busy_comments = <int>{};
  Map<String, dynamic>? replying;
  int? replying_root_id;
  int page = 0;
  int total = 0;
  bool loading = true;
  bool loading_more = false;
  bool sending = false;
  int _request_id = 0;
  bool get has_more => items.length < total;
  int get user_id => Get.isRegistered<UserInformation>()
      ? Get.find<UserInformation>().userInfo.value?.id ?? 0
      : 0;

  Map<String, dynamic> _scope() => <String, dynamic>{
    'comic_id': comic_id,
    if (chapter_id != null && chapter_id! > 0) 'chapter_id': chapter_id,
  };

  Future<void> load({bool more = false}) async {
    if (more && (loading || loading_more || !has_more)) return;
    final request_id = ++_request_id;
    if (more) {
      loading_more = true;
    } else {
      loading = true;
    }
    error = null;
    emit();
    try {
      final data =
          await comics_request('comics_comment/inquire', <String, dynamic>{
            ..._scope(),
            'page': more ? page + 1 : 1,
            'page_size': ComicsStyle.comment_page_size,
          });
      if (disposed || request_id != _request_id) return;
      if (!more) items.clear();
      items.addAll(comics_list(data['list']));
      total = comics_int(data['total']);
      page = more ? page + 1 : 1;
    } catch (failure) {
      if (!disposed && request_id == _request_id) error = failure.toString();
    } finally {
      if (!disposed && request_id == _request_id) {
        loading = false;
        loading_more = false;
        emit();
      }
    }
  }

  Future<void> replies(
    int root_id, {
    bool more = false,
    bool refresh = false,
  }) async {
    final thread = threads.putIfAbsent(root_id, ComicReplyThread.new);
    if (thread.loading) return;
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
    thread.loading = true;
    thread.error = null;
    emit();
    try {
      final data =
          await comics_request('comics_comment/inquire', <String, dynamic>{
            ..._scope(),
            'parent_id': root_id,
            'page': more ? thread.page + 1 : 1,
            'page_size': ComicsStyle.comment_page_size,
          });
      if (disposed) return;
      if (!more) thread.items.clear();
      thread.items.addAll(comics_list(data['list']));
      thread.total = comics_int(data['total']);
      thread.page = more ? thread.page + 1 : 1;
    } catch (failure) {
      if (!disposed) thread.error = failure.toString();
    } finally {
      thread.loading = false;
      emit();
    }
  }

  void reply_to(Map<String, dynamic> comment, int root_id) {
    if (!comics_require_login()) return;
    replying = comment;
    replying_root_id = root_id;
    emit();
  }

  void cancel_reply() {
    replying = null;
    replying_root_id = null;
    emit();
  }

  Future<void> send() async {
    if (sending || input.text.trim().isEmpty || !comics_require_login()) return;
    sending = true;
    emit();
    final target = replying;
    final root_id = replying_root_id;
    try {
      await comics_request('comics_comment/add', <String, dynamic>{
        ..._scope(),
        'comment_content': input.text.trim(),
        if (target != null) 'parent_id': comics_int(target['id']),
      });
      if (disposed) return;
      input.clear();
      cancel_reply();
      if (root_id != null) {
        await replies(root_id, refresh: true);
        for (final root in items) {
          if (comics_int(root['id']) == root_id) {
            root['reply_count'] = comics_int(root['reply_count']) + 1;
          }
        }
      } else {
        await load();
      }
    } catch (failure) {
      if (!disposed) showBottomTip(failure.toString());
    } finally {
      sending = false;
      emit();
    }
  }

  Future<void> like(Map<String, dynamic> comment) async {
    final id = comics_int(comment['id']);
    if (busy_comments.contains(id) || !comics_require_login()) return;
    busy_comments.add(id);
    emit();
    try {
      final data = await comics_request(
        'comics_comment/like',
        <String, dynamic>{
          'comment_id': id,
          'liked': !comics_bool(comment['is_liked']),
        },
      );
      if (disposed) return;
      comment['is_liked'] = data['liked'];
      comment['like_count'] = data['like_count'];
    } catch (failure) {
      if (!disposed) showBottomTip(failure.toString());
    } finally {
      busy_comments.remove(id);
      emit();
    }
  }

  Future<void> delete(Map<String, dynamic> comment, int root_id) async {
    final id = comics_int(comment['id']);
    if (busy_comments.contains(id)) return;
    busy_comments.add(id);
    emit();
    try {
      await comics_request('comics_comment/delete', <String, dynamic>{
        'comment_id': id,
      });
      if (disposed) return;
      await load();
      if (id != root_id) await replies(root_id, refresh: true);
    } catch (failure) {
      if (!disposed) showBottomTip(failure.toString());
    } finally {
      busy_comments.remove(id);
      emit();
    }
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }
}
