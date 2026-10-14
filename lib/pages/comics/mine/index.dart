// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/comics/mine/logic.dart';
import 'package:app/pages/comics/mine/style.dart';
import 'package:app/pages/comics/mine/widgets/mine_comics_grid.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/comics/widgets/empty_state.dart';
import 'package:app/components/load_more_footer/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 「我的漫画」页面：展示当前作者的全部作品，点击进入编辑器，右下角新建。
class ComicsMinePage extends StatefulWidget {
  const ComicsMinePage({super.key});

  @override
  State<ComicsMinePage> createState() => _ComicsMinePageState();
}

class _ComicsMinePageState extends State<ComicsMinePage> {
  /// 列表分页逻辑。
  final ComicsMineLogic _logic = ComicsMineLogic();

  /// 滚动控制器，用于触底加载更多。
  final ScrollController _scroll_controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll_controller.addListener(_on_scroll);
    _logic.load();
  }

  @override
  void dispose() {
    _scroll_controller.removeListener(_on_scroll);
    _scroll_controller.dispose();
    _logic.dispose();
    super.dispose();
  }

  /// 滚动接近底部时自动加载下一页。
  void _on_scroll() {
    if (!_scroll_controller.hasClients) return;
    final ScrollPosition position = _scroll_controller.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _logic.load_more();
    }
  }

  /// 打开编辑器；返回后刷新列表以同步状态。
  Future<void> _open_editor({int comic_id = 0}) async {
    final String query = comic_id > 0 ? '?id=$comic_id' : '';
    await context.push('/comics/editor$query');
    if (!mounted) return;
    await _logic.refresh();
  }

  @override
  Widget build(BuildContext context) {
    /// 夜间主题与 CJK 标记，决定背景、字阶与按钮文案宽度。
    final bool is_dark = ComicsStyle.is_dark(context);
    final bool is_cjk = ComicsStyle.is_cjk(context);
    final Color background = ComicsStyle.background(context);

    return Scaffold(
      backgroundColor: background,
      /// 悬浮新建按钮：主题金底 + 深色文字，与全局主行动按钮一致。
      floatingActionButton: _build_fab(context, is_cjk),
      body: AnimatedBuilder(
        animation: _logic,
        builder: (context, child) {
          return SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: ColorConstants.themeColor,
              backgroundColor: ComicsStyle.surface(context),
              onRefresh: _logic.refresh,
              child: CustomScrollView(
                controller: _scroll_controller,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  /// 顶部标题区。
                  SliverToBoxAdapter(child: _build_header(context, is_cjk)),

                  /// 列表主体：加载中 / 失败 / 空 / 网格。
                  ..._build_content(context, is_dark),

                  /// 底部加载更多。
                  if (_logic.items.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: ComicsMineStyle.load_more_top_spacing,
                          bottom: ComicsStyle.large_gap,
                        ),
                        child: LoadMoreFooter(
                          is_dark: is_dark,
                          is_loading: _logic.loading_more,
                          has_more: _logic.has_more,
                          on_load_more: _logic.load_more,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 顶部标题 + 副标题。
  Widget _build_header(BuildContext context, bool is_cjk) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ComicsStyle.page_padding,
        ComicsStyle.gap,
        ComicsStyle.page_padding,
        ComicsMineStyle.header_bottom_spacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            tr('comics.my_comics'),
            style: TextStyle(
              fontSize: is_cjk
                  ? ComicsMineStyle.title_font_size_cjk
                  : ComicsMineStyle.title_font_size_alphabetic,
              height: is_cjk
                  ? ComicsStyle.line_height_cjk
                  : ComicsStyle.line_height_alphabetic,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
              color: ComicsStyle.ink(context),
            ),
          ),
          const SizedBox(height: ComicsMineStyle.subtitle_top_spacing),
          Text(
            tr('comics.editor_description'),
            style: TextStyle(
              fontSize: is_cjk
                  ? ComicsMineStyle.subtitle_font_size_cjk
                  : ComicsMineStyle.subtitle_font_size_alphabetic,
              height: is_cjk
                  ? ComicsStyle.line_height_cjk
                  : ComicsStyle.line_height_alphabetic,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              color: ComicsStyle.muted(context),
            ),
          ),
        ],
      ),
    );
  }

  /// 列表主体：按加载状态返回不同 Sliver。
  List<Widget> _build_content(BuildContext context, bool is_dark) {
    /// 首屏加载：居中转圈。
    if (_logic.loading && _logic.items.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: ComicsEmptyState(
            loading: true,
            message: tr('comics.loading'),
          ),
        ),
      ];
    }

    /// 首屏失败：错误文案 + 重试。
    if (_logic.error != null && _logic.items.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: ComicsEmptyState(
            error: _logic.error,
            message: tr('comics.empty_mine'),
            on_retry: _logic.load,
          ),
        ),
      ];
    }

    /// 空列表：引导去新建。
    if (_logic.items.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: ComicsEmptyState(message: tr('comics.empty_mine')),
        ),
      ];
    }

    /// 正常网格。
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.symmetric(
          horizontal: ComicsStyle.page_padding,
        ),
        sliver: MineComicsGrid(
          items: _logic.items,
          on_item_tap: (int comic_id) => _open_editor(comic_id: comic_id),
        ),
      ),
    ];
  }

  /// 右下角「新建漫画」主按钮。
  Widget _build_fab(BuildContext context, bool is_cjk) {
    return Material(
      color: ComicsMineStyle.primary_background(context),
      borderRadius: BorderRadius.circular(ComicsMineStyle.fab_radius),
      elevation: 0,
      child: InkWell(
        onTap: () => _open_editor(),
        borderRadius: BorderRadius.circular(ComicsMineStyle.fab_radius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ComicsMineStyle.fab_padding_h,
            vertical: ComicsMineStyle.fab_padding_v,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ComicsMineStyle.fab_radius),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: ColorConstants.themeColor.withValues(
                  alpha: ComicsMineStyle.fab_shadow_opacity,
                ),
                blurRadius: ComicsMineStyle.fab_shadow_blur,
                offset: ComicsMineStyle.fab_shadow_offset,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.add_photo_alternate_outlined,
                size: ComicsMineStyle.fab_icon_size,
                color: ComicsMineStyle.primary_foreground(context),
              ),
              const SizedBox(width: ComicsMineStyle.fab_icon_spacing),
              Text(
                tr('comics.new_comic'),
                style: ComicsMineStyle.primary_text(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
