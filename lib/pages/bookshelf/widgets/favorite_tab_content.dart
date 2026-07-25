import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/api/bookshelf.dart';
import 'package:app/pages/bookshelf/logic.dart';
import 'package:app/pages/bookshelf/widgets/bookshelf_grid_content.dart';
import 'package:app/stores/bookshelf_store.dart';

/// 收藏 Tab 内容。
///
/// 使用公共 [BookshelfGridContent] 组件展示收藏小说列表。
/// 数据由 [BookshelfStore] 统一管理，切换 Tab 时不会丢失。
class FavoriteTabContent extends StatefulWidget {
  /// 当前 Tab 的强调色。
  final Color accent_color;

  /// 当前是否为夜间模式。
  final bool is_dark;

  const FavoriteTabContent({
    super.key,
    required this.accent_color,
    required this.is_dark,
  });

  @override
  State<FavoriteTabContent> createState() => _FavoriteTabContentState();
}

class _FavoriteTabContentState extends State<FavoriteTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// 书架数据仓库。
  final BookshelfStore _store = Get.find<BookshelfStore>();

  @override
  void initState() {
    super.initState();
    _store.load_favorite_if_needed();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(() {
      return BookshelfGridContent(
        type: BookshelfContentType.favorite,
        accent_color: widget.accent_color,
        is_dark: widget.is_dark,
        items: _store.favorite_list.toList(),
        has_more: _store.favorite_has_more.value,
        is_initial_loading: _store.favorite_is_loading.value,
        on_load_more: _store.load_more_favorite,
        on_refresh: _store.refresh_favorite,
        on_item_removed: _store.remove_favorite_item,
        on_delete: _handle_delete,
      );
    });
  }

  /// 调用取消收藏API。
  Future<bool> _handle_delete(String novel_id) async {
    final result = await toggle_favorite(novel_id: int.tryParse(novel_id) ?? 0);
    return result != null && !result.favorite;
  }
}
