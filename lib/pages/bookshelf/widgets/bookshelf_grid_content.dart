import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/bookshelf/logic.dart';
import 'package:app/pages/bookshelf/style.dart';
import 'package:app/pages/bookshelf/widgets/bookshelf_book_card.dart';
import 'package:app/util/dialog/show_message.dart';
import 'package:app/util/novel_navigation/index.dart';

/// 书架网格内容类型（历史/收藏）。
enum BookshelfContentType { history, favorite }

/// 书架网格内容公共组件。
///
/// 历史和收藏 Tab 共用此组件，通过 [type] 区分行为差异：
/// - 长按弹窗：历史→删除历史记录，收藏→取消收藏
/// - 数据由外部通过 [items] 传入，组件不负责请求
class BookshelfGridContent extends StatefulWidget {
  /// 内容类型。
  final BookshelfContentType type;

  /// 当前 Tab 的强调色。
  final Color accent_color;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 初始数据列表。
  final List<BookshelfBookItem> items;

  /// 是否还有更多数据。
  final bool has_more;

  /// 是否处于首屏加载。
  final bool is_initial_loading;

  /// 加载更多回调（滚动到底部时触发）。
  final Future<void> Function()? on_load_more;

  /// 下拉刷新回调。
  final Future<void> Function()? on_refresh;

  /// 删除/取消收藏成功后的回调（用于从列表中移除该项）。
  final void Function(String item_id)? on_item_removed;

  /// 删除/取消收藏的API调用函数（由外部传入）。
  final Future<bool> Function(String novel_id)? on_delete;

  const BookshelfGridContent({
    super.key,
    required this.type,
    required this.accent_color,
    required this.is_dark,
    required this.items,
    this.has_more = false,
    this.is_initial_loading = false,
    this.on_load_more,
    this.on_refresh,
    this.on_item_removed,
    this.on_delete,
  });

  @override
  State<BookshelfGridContent> createState() => _BookshelfGridContentState();
}

class _BookshelfGridContentState extends State<BookshelfGridContent> {
  /// 内容滚动控制器。
  final ScrollController _scroll_controller = ScrollController();

  /// 当前是否处于加载更多。
  bool _is_loading_more = false;

  @override
  void initState() {
    super.initState();
    _scroll_controller.addListener(_handle_scroll);
  }

  @override
  void dispose() {
    _scroll_controller.removeListener(_handle_scroll);
    _scroll_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int grid_count = BookshelfLogic.resolve_grid_count(
          constraints.maxWidth,
        );

        final double item_width =
            (constraints.maxWidth -
                (grid_count - 1) * Style.grid_cross_spacing) /
            grid_count;

        final double item_height =
            item_width / Style.cover_aspect_ratio +
            Style.book_title_top_spacing +
            Style.book_title_min_height +
            Style.book_meta_top_spacing +
            18;

        return RefreshIndicator(
          onRefresh: _handle_refresh,
          child: CustomScrollView(
            controller: _scroll_controller,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: <Widget>[
              if (widget.is_initial_loading)
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return _BookCardSkeleton(is_dark: widget.is_dark);
                    },
                    childCount: Style.page_size,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: grid_count,
                    crossAxisSpacing: Style.grid_cross_spacing,
                    mainAxisSpacing: Style.grid_main_spacing,
                    mainAxisExtent: item_height,
                  ),
                )
              else if (widget.items.isEmpty)
                SliverToBoxAdapter(
                  child: _build_empty_state(),
                )
              else ...<Widget>[
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      final BookshelfBookItem book_item = widget.items[index];

                      return BookshelfBookCard(
                        book_item: book_item,
                        is_dark: widget.is_dark,
                        on_tap: () => _navigate_to_read(book_item),
                        on_long_press: () => _show_action_dialog(book_item),
                      );
                    },
                    childCount: widget.items.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: grid_count,
                    crossAxisSpacing: Style.grid_cross_spacing,
                    mainAxisSpacing: Style.grid_main_spacing,
                    mainAxisExtent: item_height,
                  ),
                ),
                SliverToBoxAdapter(child: _build_load_more_section()),
              ],
            ],
          ),
        );
      },
    );
  }

  /// 处理滚动事件，触发加载更多。
  void _handle_scroll() {
    if (_is_loading_more || !widget.has_more) return;

    if (_scroll_controller.position.pixels >=
        _scroll_controller.position.maxScrollExtent -
            Style.load_more_auto_trigger_distance) {
      _load_more_data();
    }
  }

  /// 加载更多数据。
  Future<void> _load_more_data() async {
    if (_is_loading_more || !widget.has_more) return;

    setState(() {
      _is_loading_more = true;
    });

    await widget.on_load_more?.call();

    if (mounted) {
      setState(() {
        _is_loading_more = false;
      });
    }
  }

  /// 下拉刷新数据。
  Future<void> _handle_refresh() async {
    await widget.on_refresh?.call();
  }

  /// 跳转到阅读页面。
  void _navigate_to_read(BookshelfBookItem book_item) {
    navigate_to_novel(
      id: int.tryParse(book_item.novel_id) ?? 0,
      title: book_item.title,
      publish_status: book_item.publish_status,
    );
  }

  /// 展示操作弹窗（历史→删除，收藏→取消收藏）。
  void _show_action_dialog(BookshelfBookItem book_item) {
    final String message = widget.type == BookshelfContentType.history
        ? easy.tr(
            'bookshelf.delete_dialog.message',
            namedArgs: <String, String>{'title': book_item.title},
          )
        : easy.tr(
            'bookshelf.unfavorite_dialog.message',
            namedArgs: <String, String>{'title': book_item.title},
          );
    final String rightButtonText = widget.type == BookshelfContentType.history
        ? easy.tr('bookshelf.delete_dialog.confirm')
        : easy.tr('bookshelf.unfavorite_dialog.confirm');

    showMessage(
      message: message,
      showHelperText: false,
      iconData: widget.type == BookshelfContentType.history
          ? Icons.delete_outline_rounded
          : Icons.bookmark_remove_outlined,
      iconColor: ColorConstants.dangerColor,
      leftButtonText: easy.tr('bookshelf.delete_dialog.cancel'),
      rightButtonText: rightButtonText,
      rightButtonColor: ColorConstants.dangerColor,
      onRightPressed: () async {
        final bool success =
            await widget.on_delete?.call(book_item.novel_id) ?? false;
        if (success && mounted) {
          widget.on_item_removed?.call(book_item.id);
        }
      },
    );
  }

  /// 构建空状态。
  Widget _build_empty_state() {
    final Color text_color = widget.is_dark
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF9BA3B1);

    final String empty_key = widget.type == BookshelfContentType.history
        ? 'bookshelf.empty.history'
        : 'bookshelf.empty.favorite';

    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              widget.type == BookshelfContentType.history
                  ? Icons.history_rounded
                  : Icons.bookmark_outline_rounded,
              size: 64,
              color: text_color,
            ),
            const SizedBox(height: 16),
            Text(
              easy.tr(empty_key),
              style: TextStyle(
                color: text_color,
                fontSize: 16,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建加载更多区域。
  Widget _build_load_more_section() {
    final Color text_color = widget.is_dark
        ? Colors.white.withValues(alpha: 0.8)
        : const Color(0xFF616775);

    final String text_key = _is_loading_more
        ? 'bookshelf.load_more.loading'
        : (widget.has_more
            ? 'bookshelf.load_more.button'
            : 'bookshelf.load_more.no_more');

    return Padding(
      padding: const EdgeInsets.only(top: Style.load_more_top_spacing),
      child: Center(
        child: Text(
          easy.tr(text_key),
          style: TextStyle(
            color: text_color,
            fontSize: Style.load_more_font_size,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
          ),
        ),
      ),
    );
  }
}

/// 书籍卡片骨架屏。
class _BookCardSkeleton extends StatelessWidget {
  final bool is_dark;

  const _BookCardSkeleton({required this.is_dark});

  @override
  Widget build(BuildContext context) {
    final Color block_color = is_dark
        ? const Color(0xFF1A2130)
        : const Color(0xFFEDEFF4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: block_color,
              borderRadius: BorderRadius.circular(Style.cover_radius),
            ),
          ),
        ),
        const SizedBox(height: Style.book_title_top_spacing),
        Container(
          height: 13,
          width: double.infinity,
          decoration: BoxDecoration(
            color: block_color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 13,
          width: 72,
          decoration: BoxDecoration(
            color: block_color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: Style.book_meta_top_spacing),
        Container(
          height: Style.book_meta_skeleton_height,
          width: 88,
          decoration: BoxDecoration(
            color: block_color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}
