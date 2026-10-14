import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/api/bookshelf.dart';
import 'package:app/api/comics.dart';
import 'package:app/pages/bookshelf/widgets/bookshelf_grid_content.dart';
import 'package:app/stores/bookshelf_store.dart';

/// 历史 Tab 内容。
///
/// 使用公共 [BookshelfGridContent] 组件展示阅读历史列表。
/// 数据由 [BookshelfStore] 统一管理，切换 Tab 时不会丢失。
class HistoryTabContent extends StatefulWidget {
  /// 当前 Tab 的强调色。
  final Color accent_color;

  /// 当前是否为夜间模式。
  final bool is_dark;

  const HistoryTabContent({
    super.key,
    required this.accent_color,
    required this.is_dark,
  });

  @override
  State<HistoryTabContent> createState() => _HistoryTabContentState();
}

class _HistoryTabContentState extends State<HistoryTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// 书架数据仓库。
  final BookshelfStore _store = Get.find<BookshelfStore>();

  @override
  void initState() {
    super.initState();
    _store.load_history_if_needed();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(() {
      return BookshelfGridContent(
        type: BookshelfContentType.history,
        accent_color: widget.accent_color,
        is_dark: widget.is_dark,
        items: _store.history_list.toList(),
        has_more: _store.history_has_more.value,
        is_initial_loading: _store.history_is_loading.value,
        is_loading_more: _store.history_is_loading_more.value,
        on_load_more: _store.load_more_history,
        on_refresh: _store.refresh_history,
        on_item_removed: _store.remove_history_item,
        on_delete: _handle_delete,
      );
    });
  }

  /// 调用删除历史记录API。
  /// 删除阅读记录：漫画走 comics/remove_history，小说走 novel_read_record/remove。
  Future<bool> _handle_delete(BookshelfBookItem book_item) async {
    if (book_item.content_type == 'comic') {
      final result = await comics_request('remove_history', <String, dynamic>{
        'comic_id': int.tryParse(book_item.novel_id) ?? 0,
      });
      return result['comic_id'] != null;
    }
    return remove_read_record(novel_id: int.tryParse(book_item.novel_id) ?? 0);
  }
}
