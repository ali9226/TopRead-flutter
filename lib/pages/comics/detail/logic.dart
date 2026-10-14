// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'package:app/api/comics.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/logic.dart';
import 'package:app/pages/comics/reader/logic.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/services/bookshelf_sync_service.dart';
import 'package:app/util/router/router_util.dart';

/// 详情页只读取选定语种的章节；切换语种时保留主作品和收藏归属。
class ComicDetailLogic extends ComicsController {
  final int comic_id;
  ComicDetailLogic(this.comic_id);
  ComicDetail? detail;
  bool loading = true;
  bool collecting = false;
  bool collected = false;
  int _request_id = 0;
  String? selected_code;
  Map<String, dynamic> local_record = <String, dynamic>{};
  Map<String, dynamic> get read_record => local_record.isNotEmpty
      ? local_record
      : detail?.read_record ?? <String, dynamic>{};

  Future<void> load({String? language}) async {
    final request_id = ++_request_id;
    selected_code = language ?? selected_code;
    loading = true;
    error = null;
    emit();
    try {
      final value = await comics_detail(comic_id, language: selected_code);
      if (disposed || request_id != _request_id) return;
      local_record = <String, dynamic>{};
      final cached = await StorageUtil.getData(comic_progress_key(comic_id));
      if (disposed || request_id != _request_id) return;
      if (cached != null) {
        try {
          final record = comics_map(jsonDecode(cached));
          if (record['language'] == value.selected_language?.language &&
              value.chapters.any(
                (chapter) => chapter.id == comics_int(record['chapter_id']),
              )) {
            local_record = record;
          }
        } catch (_) {
          /* 旧缓存格式异常时使用服务器进度。 */
        }
      }
      detail = value;
      collected = value.is_collected;
    } catch (failure) {
      if (!disposed && request_id == _request_id) error = failure.toString();
    } finally {
      if (!disposed && request_id == _request_id) {
        loading = false;
        emit();
      }
    }
  }

  Future<void> collect() async {
    if (collecting || !comics_require_login()) return;
    collecting = true;
    emit();
    try {
      await comics_request('collect', <String, dynamic>{
        'comic_id': comic_id,
        'collected': !collected,
      });
      if (!disposed) collected = !collected;
      // 收藏关系变化后刷新书架收藏列表。
      unawaited(BookshelfSyncService.favorite_changed());
    } catch (failure) {
      if (!disposed) showBottomTip(failure.toString());
    } finally {
      collecting = false;
      emit();
    }
  }

  /// 续读只使用当前语种的有效章节，切换语种之后不会跳入另一个翻译。
  int get start_chapter_id {
    final value = detail;
    if (value == null || value.chapters.isEmpty) return 0;
    final saved_id = comics_int(read_record['chapter_id']);
    return value.chapters.any((chapter) => chapter.id == saved_id)
        ? saved_id
        : value.chapters.first.id;
  }

  bool get can_continue =>
      detail != null &&
      start_chapter_id == comics_int(read_record['chapter_id']);
  void open_chapter(int chapter_id, {bool resume = false}) {
    final saved_page = resume && detail != null
        ? comics_int(read_record['page_index'])
        : 0;
    routerUtil(path: '/comics/read?chapter_id=$chapter_id&page=$saved_page');
  }
}
