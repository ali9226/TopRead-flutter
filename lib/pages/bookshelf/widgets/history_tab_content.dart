import 'package:flutter/material.dart';
import 'package:app/api/bookshelf.dart';
import 'package:app/pages/bookshelf/logic.dart';
import 'package:app/pages/bookshelf/widgets/bookshelf_grid_content.dart';

/// 历史 Tab 内容。
///
/// 使用公共 [BookshelfGridContent] 组件展示阅读历史列表。
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

class _HistoryTabContentState extends State<HistoryTabContent> {
  /// 当前可见数据列表。
  List<BookshelfBookItem> _visible_list = <BookshelfBookItem>[];

  /// 当前是否处于首屏加载。
  bool _is_initial_loading = true;

  /// 当前页码。
  int _current_page = 1;

  /// 是否还有更多数据。
  bool _has_more = true;

  /// 每页数量。
  static const int _page_size = 20;

  @override
  void initState() {
    super.initState();
    _load_initial_data();
  }

  @override
  Widget build(BuildContext context) {
    return BookshelfGridContent(
      type: BookshelfContentType.history,
      accent_color: widget.accent_color,
      is_dark: widget.is_dark,
      items: _visible_list,
      has_more: _has_more,
      is_initial_loading: _is_initial_loading,
      on_load_more: _load_more_data,
      on_refresh: _handle_refresh,
      on_item_removed: _handle_item_removed,
      on_delete: _handle_delete,
    );
  }

  /// 首屏加载数据。
  Future<void> _load_initial_data() async {
    setState(() {
      _is_initial_loading = true;
      _current_page = 1;
    });

    final result = await inquire_read_record_list(
      page: 1,
      page_size: _page_size,
    );

    if (!mounted) return;

    setState(() {
      if (result != null) {
        _visible_list = result.list
            .asMap()
            .map((index, item) =>
                MapEntry(index, _convert_to_book_item(item, index)))
            .values
            .toList();
        _has_more = result.list.length >= _page_size;
      } else {
        _visible_list = [];
        _has_more = false;
      }
      _is_initial_loading = false;
    });
  }

  /// 下拉刷新数据。
  Future<void> _handle_refresh() async {
    _current_page = 1;

    final result = await inquire_read_record_list(
      page: 1,
      page_size: _page_size,
    );

    if (!mounted) return;

    setState(() {
      if (result != null) {
        _visible_list = result.list
            .asMap()
            .map((index, item) =>
                MapEntry(index, _convert_to_book_item(item, index)))
            .values
            .toList();
        _has_more = result.list.length >= _page_size;
      }
    });
  }

  /// 加载更多数据。
  Future<void> _load_more_data() async {
    if (!_has_more) return;

    _current_page++;
    final result = await inquire_read_record_list(
      page: _current_page,
      page_size: _page_size,
    );

    if (!mounted) return;

    setState(() {
      if (result != null && result.list.isNotEmpty) {
        final new_items = result.list
            .asMap()
            .map((index, item) => MapEntry(
                index,
                _convert_to_book_item(
                    item, _visible_list.length + index)))
            .values
            .toList();
        _visible_list.addAll(new_items);
        _has_more = result.list.length >= _page_size;
      } else {
        _has_more = false;
      }
    });
  }

  /// 删除历史记录成功后移除该项。
  void _handle_item_removed(String item_id) {
    setState(() {
      _visible_list =
          _visible_list.where((item) => item.id != item_id).toList();
    });
  }

  /// 调用删除历史记录API。
  Future<bool> _handle_delete(String novel_id) async {
    // TODO 调用后端删除阅读记录接口，当前先返回 true
    return true;
  }

  /// 将阅读记录转换为书架书籍项。
  BookshelfBookItem _convert_to_book_item(ReadRecordItem item, int index) {
    final colors = cover_gradient_colors[index % cover_gradient_colors.length];
    final bool is_short_story = item.publish_status == 4;
    final bool has_progress = item.read_progress > 0;
    final bool has_categories = item.category_names.isNotEmpty;

    // 短篇无进度时显示分类列表，有进度显示百分比
    // 长篇有进度显示百分比，无进度显示"未读"
    String progress_key;
    Map<String, String> progress_args;
    if (has_progress) {
      progress_key = 'bookshelf.progress.read_progress';
      progress_args = <String, String>{
        'progress': item.read_progress.toStringAsFixed(0)
      };
    } else if (is_short_story && has_categories) {
      progress_key = 'bookshelf.progress.categories';
      progress_args = <String, String>{
        'names': item.category_names.split(',').take(2).join(' · ')
      };
    } else {
      progress_key = 'bookshelf.progress.unread';
      progress_args = <String, String>{};
    }

    return BookshelfBookItem(
      id: item.id,
      novel_id: item.novel_id,
      title: item.novel_title,
      publish_status: item.publish_status,
      introduction: item.introduction,
      progress_key: progress_key,
      progress_args: progress_args,
      cover_image_url: item.cover_url.isNotEmpty ? item.cover_url : null,
      cover_start_color: colors[0],
      cover_end_color: colors[1],
    );
  }
}
