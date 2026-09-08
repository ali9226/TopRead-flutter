// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/models/novel_info.dart';
import 'package:app/permission_request/notification_permission_request.dart';
import 'package:app/services/bookshelf_sync_service.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:get/get.dart';

/// 阅读页互动操作 Mixin。
///
/// 负责点赞、收藏、关注、评论数更新等用户互动操作。
/// 所有操作采用乐观更新策略：先更新本地状态，再发起请求。
mixin ReadInteractionMixin {
  /// 小说阅读仓库。
  NovelReadingStore get store;

  /// 路由传入的书籍 id。
  int get story_id;

  /// 是否已点赞。
  RxBool get is_liked;

  /// 点赞数。
  RxInt get like_count;

  /// 是否正在点赞请求中。
  RxBool get is_like_loading;

  /// 是否正在收藏请求中。
  RxBool get is_favorite_loading;

  /// 是否已收藏。
  RxBool get is_favorited;

  /// 同步点赞状态到底层数据。
  void sync_like_state(bool new_status, int new_count);

  /// 切换点赞状态（乐观更新）。
  ///
  /// 立即切换本地状态，然后发起请求。
  /// 请求失败时回退状态，请求成功时保持不变。
  /// 请求期间通过 [is_like_loading] 防止重复点击。
  Future<void> toggle_like() async {
    if (is_like_loading.value) return;

    is_like_loading.value = true;

    // 乐观更新：立即切换状态。
    final bool previous_status = is_liked.value;
    final int previous_count = like_count.value;
    final bool optimistic_status = !previous_status;
    final int optimistic_count = (previous_count + (optimistic_status ? 1 : -1)).clamp(0, 999999);
    sync_like_state(optimistic_status, optimistic_count);

    try {
      final ResultsType<Map<String, dynamic>> results =
          await postRequest<Map<String, dynamic>>(
            path: 'novel_like/click',
            parameter: <String, dynamic>{'novel_id': story_id},
            fromJson: (Map<String, dynamic> json) => json,
          );

      if (!results.status || results.content == null) {
        // 请求失败，回退状态。
        sync_like_state(previous_status, previous_count);
        return;
      }

      final bool server_status = results.content!['like'] == true;
      // 服务端状态与乐观更新不一致时，以服务端为准。
      if (server_status != optimistic_status) {
        final int server_count = (previous_count + (server_status ? 1 : -1)).clamp(0, 999999);
        sync_like_state(server_status, server_count);
      }
    } catch (_) {
      // 异常时回退状态。
      sync_like_state(previous_status, previous_count);
    } finally {
      is_like_loading.value = false;
    }
  }

  /// 切换收藏状态（乐观更新）。
  ///
  /// 立即切换本地状态，然后发起请求。
  /// 请求失败时回退状态，请求成功时保持不变。
  /// 请求期间通过 [is_favorite_loading] 防止重复点击。
  ///
  /// 返回服务端确认的收藏状态，失败时返回 null。
  Future<bool?> toggle_favorite() async {
    if (is_favorite_loading.value) return null;

    is_favorite_loading.value = true;

    // 乐观更新：立即切换状态。
    final bool previous_status = is_favorited.value;
    final bool optimistic_status = !previous_status;
    is_favorited.value = optimistic_status;

    // 同步到 store 中的 novel_info。
    final info = store.novel_info.value;
    NovelInfo? previous_info;
    if (info != null) {
      previous_info = info;
      final int delta = optimistic_status ? 1 : -1;
      final int new_count = (int.tryParse(info.favorite_count) ?? 0) + delta;
      final updated = NovelInfo(
        id: info.id,
        title: info.title,
        subtitle: info.subtitle,
        score: info.score,
        focus_on: info.focus_on,
        is_liked: info.is_liked,
        is_favorited: optimistic_status,
        author_id: info.author_id,
        source_type: info.source_type,
        publish_status: info.publish_status,
        recommend_status: info.recommend_status,
        sorting: info.sorting,
        read_count: info.read_count,
        comment_count: info.comment_count,
        like_count: info.like_count,
        favorite_count: new_count.toString(),
        latest_chapter_no: info.latest_chapter_no,
        latest_update_time: info.latest_update_time,
        remark: info.remark,
        create_time: info.create_time,
        update_time: info.update_time,
        remove_status: info.remove_status,
        remove_time: info.remove_time,
        author_name: info.author_name,
        author_avatar: info.author_avatar,
        language_info: info.language_info,
        category_list: info.category_list,
        comment_list: info.comment_list,
        chapter_info: info.chapter_info,
      );
      store.set_novel_info(updated);
    }

    try {
      final ResultsType<Map<String, dynamic>> results =
          await postRequest<Map<String, dynamic>>(
            path: 'novel_favorite/click',
            parameter: <String, dynamic>{'novel_id': story_id},
            fromJson: (Map<String, dynamic> json) => json,
          );

      if (!results.status || results.content == null) {
        // 请求失败，回退状态。
        _revert_favorite(previous_status, previous_info);
        return null;
      }

      final dynamic raw_server_status = results.content!['favorite'];
      final bool server_status = raw_server_status == true || raw_server_status == 1;
      // 服务端状态与乐观更新不一致时，以服务端为准。
      if (server_status != optimistic_status) {
        is_favorited.value = server_status;
        if (previous_info != null) {
          final int server_delta = server_status ? 1 : -1;
          final int server_count = (int.tryParse(previous_info.favorite_count) ?? 0) + server_delta;
          store.set_novel_info(NovelInfo(
            id: previous_info.id,
            title: previous_info.title,
            subtitle: previous_info.subtitle,
            score: previous_info.score,
            focus_on: previous_info.focus_on,
            is_liked: previous_info.is_liked,
            is_favorited: server_status,
            author_id: previous_info.author_id,
            source_type: previous_info.source_type,
            publish_status: previous_info.publish_status,
            recommend_status: previous_info.recommend_status,
            sorting: previous_info.sorting,
            read_count: previous_info.read_count,
            comment_count: previous_info.comment_count,
            like_count: previous_info.like_count,
            favorite_count: server_count.toString(),
            latest_chapter_no: previous_info.latest_chapter_no,
            latest_update_time: previous_info.latest_update_time,
            remark: previous_info.remark,
            create_time: previous_info.create_time,
            update_time: previous_info.update_time,
            remove_status: previous_info.remove_status,
            remove_time: previous_info.remove_time,
            author_name: previous_info.author_name,
            author_avatar: previous_info.author_avatar,
            language_info: previous_info.language_info,
            category_list: previous_info.category_list,
            comment_list: previous_info.comment_list,
            chapter_info: previous_info.chapter_info,
          ));
        }
      }

      unawaited(BookshelfSyncService.favorite_changed());

      // 只在服务端确认小说已加入收藏后申请系统通知权限。
      if (server_status) {
        unawaited(NotificationPermissionRequest.request_after_novel_favorite());
      }
      return server_status;
    } catch (_) {
      // 异常时回退状态。
      _revert_favorite(previous_status, previous_info);
      return null;
    } finally {
      is_favorite_loading.value = false;
    }
  }

  /// 回退收藏状态。
  void _revert_favorite(bool previous_status, NovelInfo? previous_info) {
    is_favorited.value = previous_status;
    if (previous_info != null) {
      store.set_novel_info(previous_info);
    }
  }

  /// 同步关注状态到底层数据（关注/取消关注后调用）。
  void update_focus_on(bool new_status) {
    final info = store.novel_info.value;
    if (info == null) return;

    final updated = NovelInfo(
      id: info.id,
      title: info.title,
      subtitle: info.subtitle,
      score: info.score,
      focus_on: new_status,
      is_liked: info.is_liked,
      is_favorited: info.is_favorited,
      author_id: info.author_id,
      source_type: info.source_type,
      publish_status: info.publish_status,
      recommend_status: info.recommend_status,
      sorting: info.sorting,
      read_count: info.read_count,
      comment_count: info.comment_count,
      like_count: info.like_count,
      favorite_count: info.favorite_count,
      latest_chapter_no: info.latest_chapter_no,
      latest_update_time: info.latest_update_time,
      remark: info.remark,
      create_time: info.create_time,
      update_time: info.update_time,
      remove_status: info.remove_status,
      remove_time: info.remove_time,
      author_name: info.author_name,
      author_avatar: info.author_avatar,
      language_info: info.language_info,
      category_list: info.category_list,
      comment_list: info.comment_list,
      chapter_info: info.chapter_info,
    );
    store.set_novel_info(updated);
  }

  /// 评论数（从 novel_info 读取）。
  int get comment_count {
    final info = store.novel_info.value;
    if (info == null) return 0;
    return int.tryParse(info.comment_count) ?? 0;
  }

  /// 更新评论数（评论弹窗关闭后同步最新数量）。
  void update_comment_count(int new_count) {
    final info = store.novel_info.value;
    if (info == null) return;
    final updated = NovelInfo(
      id: info.id,
      title: info.title,
      subtitle: info.subtitle,
      score: info.score,
      focus_on: info.focus_on,
      is_liked: info.is_liked,
      is_favorited: info.is_favorited,
      author_id: info.author_id,
      source_type: info.source_type,
      publish_status: info.publish_status,
      recommend_status: info.recommend_status,
      sorting: info.sorting,
      read_count: info.read_count,
      comment_count: new_count.toString(),
      like_count: info.like_count,
      favorite_count: info.favorite_count,
      latest_chapter_no: info.latest_chapter_no,
      latest_update_time: info.latest_update_time,
      remark: info.remark,
      create_time: info.create_time,
      update_time: info.update_time,
      remove_status: info.remove_status,
      remove_time: info.remove_time,
      author_name: info.author_name,
      author_avatar: info.author_avatar,
      language_info: info.language_info,
      category_list: info.category_list,
      comment_list: info.comment_list,
      chapter_info: info.chapter_info,
    );
    store.set_novel_info(updated);
  }
}
