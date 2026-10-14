// ignore_for_file: non_constant_identifier_names

import 'package:app/api/comics.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/logic.dart';
import 'package:app/pages/comics/style.dart';

/// 「我的漫画」分页列表逻辑：只查询当前登录作者的作品，含草稿与审核中。
class ComicsMineLogic extends ComicsController {
  /// 当前页作品列表。
  final List<ComicItem> items = <ComicItem>[];

  /// 是否正在加载首页。
  bool loading = false;

  /// 是否正在加载更多。
  bool loading_more = false;

  /// 当前过滤条件下的总条数。
  int total = 0;

  /// 当前已加载到的页码。
  int page = 0;

  /// 请求序号，丢弃过期响应。
  int _request_id = 0;

  /// 是否还有下一页。
  bool get has_more => items.length < total;

  /// 拉取一页作品。
  ///
  /// [more] 为 true 时追加下一页；为 false 时刷新首页。
  Future<void> load({bool more = false}) async {
    if (disposed || (more && (loading || loading_more || !has_more))) return;
    final int request_id = ++_request_id;
    final int next_page = more ? page + 1 : 1;
    if (more) {
      loading_more = true;
    } else {
      loading = true;
      loading_more = false;
    }
    error = null;
    emit();
    try {
      final Map<String, dynamic> data = await comics_request(
        'my_comics',
        <String, dynamic>{
          'page': next_page,
          'page_size': ComicsStyle.page_size,
        },
      );
      if (disposed || request_id != _request_id) return;
      final Iterable<ComicItem> next_items = comics_list(
        data['list'],
      ).map(ComicItem.from_json);
      if (!more) items.clear();
      final Set<int> known_ids = items.map((ComicItem item) => item.id).toSet();
      items.addAll(
        next_items.where((ComicItem item) => !known_ids.contains(item.id)),
      );
      total = comics_int(data['total']);
      page = next_page;
    } catch (failure) {
      if (disposed || request_id != _request_id) return;
      error = failure.toString();
    } finally {
      if (!disposed && request_id == _request_id) {
        loading = false;
        loading_more = false;
        emit();
      }
    }
  }

  /// 下拉刷新。
  Future<void> refresh() => load();

  /// 滚动到底部加载更多。
  Future<void> load_more() => load(more: true);

  /// 本地移除某部作品（下架成功后同步列表，无需再请求）。
  void remove_local(int comic_id) {
    items.removeWhere((ComicItem item) => item.id == comic_id);
    if (total > 0) total -= 1;
    emit();
  }

  /// 本地更新状态（保存/提交后返回列表时同步角标）。
  void update_status(int comic_id, String status, {int? chapter_count}) {
    final int index = items.indexWhere((ComicItem item) => item.id == comic_id);
    if (index < 0) return;
    final ComicItem current = items[index];
    items[index] = ComicItem(
      id: current.id,
      title: current.title,
      cover_url: current.cover_url,
      author_id: current.author_id,
      author_name: current.author_name,
      description: current.description,
      categories: current.categories,
      chapter_count: chapter_count ?? current.chapter_count,
      language_count: current.language_count,
      status: status,
      completion_status: current.completion_status,
      review_reason: current.review_reason,
      lock_version: current.lock_version,
    );
    emit();
  }
}
