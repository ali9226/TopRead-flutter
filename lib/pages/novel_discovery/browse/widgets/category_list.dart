// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/components/load_more_footer/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/novel_discovery.dart';
import 'package:app/pages/novel_discovery/browse/logic.dart';
import 'package:app/pages/novel_discovery/browse/style.dart';
import 'package:app/pages/novel_discovery/browse/widgets/inline_error.dart';
import 'package:app/pages/novel_discovery/widgets/discovery_grid/index.dart';
import 'package:app/pages/novel_discovery/widgets/discovery_grid/skeleton.dart';
import 'package:app/pages/novel_discovery/widgets/empty_state.dart';
import 'package:app/util/router/router_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 每个分类持有独立滚动位置，保活切换后可继续原来的位置和分页。
class NovelBrowseCategoryList extends StatefulWidget {
  const NovelBrowseCategoryList({
    super.key,
    required this.category_id,
    required this.logic,
    required this.is_dark,
    this.on_open,
  });
  final int category_id;
  final NovelBrowseLogic logic;
  final bool is_dark;
  final ValueChanged<NovelDiscoveryItem>? on_open;

  @override
  State<NovelBrowseCategoryList> createState() =>
      _NovelBrowseCategoryListState();
}

class _NovelBrowseCategoryListState extends State<NovelBrowseCategoryList>
    with AutomaticKeepAliveClientMixin {
  late final int _context_revision = widget.logic.context_revision;
  late int _snapshot_revision = widget.logic
      .state_for(widget.category_id)
      .snapshot_revision;
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: widget.logic
        .state_for(widget.category_id)
        .scroll_offset,
  )..addListener(_on_scroll);
  bool _pagination_scheduled = false;

  @override
  bool get wantKeepAlive => true;

  void _on_scroll() {
    if (!_scroll.hasClients ||
        _context_revision != widget.logic.context_revision) {
      return;
    }
    widget.logic.state_for(widget.category_id).scroll_offset = _scroll.offset;
    _maybe_load_more();
  }

  void _maybe_load_more() {
    final state = widget.logic.state_for(widget.category_id);
    if (!mounted ||
        _context_revision != widget.logic.context_revision ||
        widget.logic.selected_category_id != widget.category_id ||
        !_scroll.hasClients ||
        !_scroll.position.hasContentDimensions ||
        state.error != null ||
        state.busy ||
        !state.has_more) {
      return;
    }
    if (_scroll.position.extentAfter < NovelBrowseStyle.pagination_threshold) {
      unawaited(widget.logic.load_more(widget.category_id));
    }
  }

  /// 首屏不足一屏时补齐内容；所有入口都走同一个在途请求保护。
  void _schedule_pagination() {
    if (_pagination_scheduled) return;
    _pagination_scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pagination_scheduled = false;
      if (mounted) _maybe_load_more();
    });
  }

  void _open(NovelDiscoveryItem item) {
    if (widget.on_open != null) {
      widget.on_open!(item);
    } else {
      routerUtil(
        path: Uri(
          path: '/read',
          queryParameters: {'id': '${item.id}', 'title': item.title},
        ).toString(),
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = widget.logic.state_for(widget.category_id);
    if (_snapshot_revision != state.snapshot_revision) {
      _snapshot_revision = state.snapshot_revision;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _context_revision == widget.logic.context_revision &&
            _scroll.hasClients) {
          _scroll.jumpTo(0);
        }
      });
    }
    _schedule_pagination();
    return RefreshIndicator(
      key: ValueKey('novel_browse_refresh_${widget.category_id}'),
      color: ColorConstants.themeColor,
      onRefresh: () => widget.logic.refresh(widget.category_id),
      child: CustomScrollView(
        key: PageStorageKey(
          'novel_browse_scroll_${widget.category_id}_${widget.logic.context_revision}',
        ),
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // TODO 相邻Tab在滑动中会先被构建，此时还未发请求，也应显示骨架而非无数据。
          if (state.items.isEmpty &&
              (state.loading || (!state.loaded && state.error == null)))
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                NovelBrowseStyle.horizontal_padding,
                NovelBrowseStyle.content_top_gap,
                NovelBrowseStyle.horizontal_padding,
                MediaQuery.paddingOf(context).bottom +
                    NovelBrowseStyle.content_bottom_gap,
              ),
              sliver: NovelDiscoverySliverSkeleton(
                key: ValueKey('novel_browse_skeleton_${widget.category_id}'),
                is_dark: widget.is_dark,
              ),
            )
          else if (state.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: NovelDiscoveryEmptyState(
                error: state.error == null
                    ? null
                    : tr('novel_discovery.discovery_load_failed'),
                message: tr('novel_discovery.empty'),
                on_retry: () =>
                    unawaited(widget.logic.retry(widget.category_id)),
              ),
            )
          else ...[
            if (state.error != null && !state.failed_more)
              SliverToBoxAdapter(
                child: NovelBrowseInlineError(
                  key: ValueKey(
                    'novel_browse_refresh_error_${widget.category_id}',
                  ),
                  is_dark: widget.is_dark,
                  message: tr('novel_discovery.discovery_load_failed'),
                  on_retry: () =>
                      unawaited(widget.logic.retry(widget.category_id)),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                NovelBrowseStyle.horizontal_padding,
                NovelBrowseStyle.content_top_gap,
                NovelBrowseStyle.horizontal_padding,
                0,
              ),
              sliver: NovelDiscoverySliverGrid(
                items: state.items,
                on_open: _open,
              ),
            ),
            if (state.loading_more)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  NovelBrowseStyle.horizontal_padding,
                  NovelBrowseStyle.footer_gap,
                  NovelBrowseStyle.horizontal_padding,
                  0,
                ),
                sliver: NovelDiscoverySliverSkeleton(
                  key: ValueKey(
                    'novel_browse_more_skeleton_${widget.category_id}',
                  ),
                  is_dark: widget.is_dark,
                  item_count: NovelDiscoveryGridStyle.wide_columns,
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.paddingOf(context).bottom +
                    NovelBrowseStyle.content_bottom_gap,
              ),
              sliver: SliverToBoxAdapter(
                child: state.error != null && state.failed_more
                    ? NovelBrowseInlineError(
                        key: ValueKey(
                          'novel_browse_more_error_${widget.category_id}',
                        ),
                        is_dark: widget.is_dark,
                        message: tr('novel_discovery.discovery_load_failed'),
                        on_retry: () =>
                            unawaited(widget.logic.retry(widget.category_id)),
                      )
                    : state.loading_more
                    ? const SizedBox.shrink()
                    : LoadMoreFooter(
                        is_dark: widget.is_dark,
                        is_loading: state.loading_more,
                        has_more: state.has_more,
                        on_load_more: () => unawaited(
                          widget.logic.load_more(widget.category_id),
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
