import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:get/get.dart';

import 'package:app/components/category_filter/index.dart';
import 'package:app/components/load_more_footer/index.dart';
import 'package:app/components/fixed_bottom_navigation/style.dart'
    as fixed_nav_style;
import 'package:app/components/floating_back_to_top/index.dart';
import 'package:app/components/floating_back_to_top/style.dart'
    as floating_back_to_top_style;
import 'package:app/components/login_required_dialog/index.dart';
import 'package:app/models/short_story_item.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/home_store.dart';
import 'package:app/pages/home/widgets/tab_contents/short_story_tab/logic.dart';
import 'package:app/pages/home/widgets/tab_contents/short_story_tab/style.dart';
import 'package:app/pages/home/widgets/tab_contents/short_story_tab/widgets/dislike_reason_sheet.dart';
import 'package:app/pages/home/widgets/tab_contents/short_story_tab/widgets/short_story_card.dart';
import 'package:app/pages/interest_preference/index.dart';
import 'package:app/util/router/router_util.dart';

/// 短篇 Tab 内容组件。
class ShortStoryTabContent extends StatefulWidget {
  const ShortStoryTabContent({super.key});

  @override
  State<ShortStoryTabContent> createState() => _ShortStoryTabContentState();
}

class _ShortStoryTabContentState extends State<ShortStoryTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final ScrollController _scroll_controller = ScrollController();
  final ScrollController _category_scroll_controller = ScrollController();

  bool _is_back_to_top_visible = false;
  late ShortStoryTabLogic _logic;
  bool _is_loading = false;
  bool _is_loading_more = false;
  bool _has_more = true;

  /// 本地列表数据，由 setState 驱动刷新。
  final List<ShortStoryItem> _display_list = [];

  /// 正在请求点赞的小说 id 集合，用于显示 loading 并阻止重复点击。
  final Set<int> _like_loading_ids = <int>{};

  /// 语种切换监听器，语种切换时清空本地短篇列表。
  late Worker _language_worker;

  static const double _load_more_trigger_distance = 300;
  static const int _skeleton_count = 5;

  @override
  void initState() {
    super.initState();
    _logic = ShortStoryTabLogic(context);
    _scroll_controller.addListener(_handle_scroll);

    /// 如果全局仓库已有数据，直接恢复，不重新请求。
    final HomeBannerStore home_store = Get.find<HomeBannerStore>();
    if (home_store.short_story_list.isNotEmpty) {
      _display_list.addAll(home_store.short_story_list);
    } else {
      _load_initial_data();
    }

    /// 监听全局加载状态，语种切换时 is_loading 变为 true，
    /// 此时清空本地列表，避免展示旧语种内容。
    _language_worker = ever(home_store.is_loading, (bool loading) {
      if (loading) {
        setState(() {
          _display_list.clear();
          _is_loading = true;
          _has_more = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _language_worker.dispose();
    _scroll_controller.removeListener(_handle_scroll);
    _scroll_controller.dispose();
    _category_scroll_controller.dispose();
    super.dispose();
  }

  /// 加载首屏数据。
  Future<void> _load_initial_data() async {
    if (_is_loading) return;

    setState(() {
      _is_loading = true;
      _display_list.clear();
      _has_more = true;
    });

    final List<ShortStoryItem> items = await _logic.fetch_short_story_list(
      category_id: _logic.selected_category_id.value,
    );

    if (!mounted) return;

    setState(() {
      _display_list.addAll(items);
      _has_more = items.isNotEmpty;
      _is_loading = false;
    });

    /// 同步到全局仓库。
    Get.find<HomeBannerStore>().short_story_list.assignAll(items);
  }

  /// 处理滚动事件。
  void _handle_scroll() {
    final bool should_show =
        _scroll_controller.hasClients &&
        _scroll_controller.offset >
            ShortStoryTabStyle.back_to_top_visible_offset;

    if (_is_back_to_top_visible != should_show) {
      setState(() {
        _is_back_to_top_visible = should_show;
      });
    }

    if (_scroll_controller.position.pixels >=
        _scroll_controller.position.maxScrollExtent -
            _load_more_trigger_distance) {
      _try_load_more();
    }
  }

  /// 加载更多。
  Future<void> _try_load_more() async {
    if (_is_loading_more || _is_loading || !_has_more) return;

    setState(() {
      _is_loading_more = true;
    });

    final List<int> no_ids = _display_list
        .map((ShortStoryItem item) => item.id)
        .toList();

    final List<ShortStoryItem> new_items = await _logic.fetch_short_story_list(
      no_ids: no_ids,
      category_id: _logic.selected_category_id.value,
    );

    if (!mounted) return;

    setState(() {
      _display_list.addAll(new_items);
      _has_more = new_items.isNotEmpty;
      _is_loading_more = false;
    });
  }

  /// 下拉刷新。
  ///
  /// 清空当前列表展示骨架屏，重新请求首屏数据。
  Future<void> _on_refresh() async {
    if (_is_loading) return;

    setState(() {
      _is_loading = true;
      _display_list.clear();
      _has_more = true;
    });

    final List<ShortStoryItem> items = await _logic.fetch_short_story_list(
      category_id: _logic.selected_category_id.value,
    );

    if (!mounted) return;

    setState(() {
      _display_list.addAll(items);
      _has_more = items.isNotEmpty;
      _is_loading = false;
    });
  }

  /// 分类切换回调。
  void _on_category_changed(int? category_id) {
    if (_is_loading) return;
    _logic.selected_category_id.value = category_id;
    _load_initial_data();
  }

  /// 点赞/取消点赞回调（乐观更新）。
  ///
  /// 立即切换本地 UI 状态，后台发请求，失败时回退。
  Future<void> _on_like_tap(int index) async {
    final bool is_logged_in = await showLoginRequiredDialog(
      title: easy.tr('short_story_read.login_required'),
    );
    if (!is_logged_in) return;

    final ShortStoryItem item = _display_list[index];

    /// 该条目正在请求中，忽略点击。
    if (_like_loading_ids.contains(item.id)) return;

    /// 乐观更新：立即切换点赞状态和数量。
    final bool new_liked = !item.is_liked;
    final int new_count = new_liked ? item.like_count + 1 : item.like_count - 1;
    setState(() {
      _display_list[index] = item.copyWith(
        is_liked: new_liked,
        like_count: new_count,
      );
      _like_loading_ids.add(item.id);
    });

    /// 发起网络请求。
    final bool? like = await _logic.click_novel_like(novel_id: item.id);

    if (!mounted) return;

    if (like == null) {
      /// 请求失败，回退乐观更新。
      setState(() {
        _display_list[index] = item;
        _like_loading_ids.remove(item.id);
      });
      return;
    }

    /// 请求成功，以服务端返回值为准更新状态，移除 loading。
    final int server_count = like ? item.like_count + 1 : item.like_count - 1;
    setState(() {
      _display_list[index] = _display_list[index].copyWith(
        is_liked: like,
        like_count: server_count,
      );
      _like_loading_ids.remove(item.id);
    });

    /// 同步到全局仓库。
    Get.find<HomeBannerStore>().short_story_list.assignAll(_display_list);
  }

  void _scroll_to_top() {
    if (!_scroll_controller.hasClients) return;
    _scroll_controller.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _show_dislike_reason_sheet() {
    final DeviceInfo device_info = Get.find<DeviceInfo>();
    final bool is_dark = device_info.theme.value == ThemeMode.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder:
          (
            BuildContext buildContext,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return DislikeReasonSheet(
              is_dark: is_dark,
              on_option_tap: (String reason) {
                debugPrint('用户选择的不喜欢理由: $reason');
              },
              on_close: () {
                Navigator.of(buildContext).pop();
              },
              on_navigate_to_interest: () async {
                final bool is_logged_in = await showLoginRequiredDialog(
                  title: easy.tr('dislike_sheet.login_required'),
                );
                if (!is_logged_in) return;
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext _) => const InterestPreferencePage(),
                  ),
                );
              },
            );
          },
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return child;
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 要求调用

    final DeviceInfo device_info = Get.find<DeviceInfo>();

    return Obx(() {
      final bool is_dark = device_info.theme.value == ThemeMode.dark;

      return Stack(
        children: <Widget>[
          Positioned.fill(
            child: Column(
              children: <Widget>[
                CategoryFilter(
                  on_category_changed: _on_category_changed,
                  category_scroll_controller: _category_scroll_controller,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _on_refresh,
                    child: _is_loading && _display_list.isEmpty
                        ? _build_skeleton_list(is_dark)
                        : ListView.builder(
                            controller: _scroll_controller,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(
                              top: ShortStoryTabStyle.list_top_spacing,
                              bottom: ShortStoryTabStyle.list_bottom_spacing,
                            ),
                            itemCount:
                                _display_list.length +
                                ((_is_loading_more || !_has_more) ? 1 : 0),
                            itemBuilder: (BuildContext context, int index) {
                              if (index == _display_list.length) {
                                return LoadMoreFooter(
                                  is_dark: is_dark,
                                  is_loading: _is_loading_more,
                                  has_more: _has_more,
                                  on_load_more: _try_load_more,
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: ShortStoryTabStyle.card_spacing,
                                ),
                                child: ShortStoryCard(
                                  story_item: _display_list[index],
                                  is_dark: is_dark,
                                  is_like_loading: _like_loading_ids.contains(
                                    _display_list[index].id,
                                  ),
                                  on_tap: () {
                                    routerUtil(
                                      path:
                                          '/short_story_read?id=${_display_list[index].id}',
                                      type: 'push',
                                    );
                                  },
                                  on_long_press: _show_dislike_reason_sheet,
                                  on_like_tap: () => _on_like_tap(index),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
          FloatingBackToTop(
            show: _is_back_to_top_visible,
            isDark: is_dark,
            onTap: _scroll_to_top,
            right: floating_back_to_top_style.FloatingBackToTopStyle.right,
            visibleBottom:
                fixed_nav_style.Style.bar_height +
                floating_back_to_top_style
                    .FloatingBackToTopStyle
                    .offset_from_bottom_nav +
                MediaQuery.paddingOf(context).bottom,
            hiddenBottom:
                fixed_nav_style.Style.bar_height +
                floating_back_to_top_style
                    .FloatingBackToTopStyle
                    .hidden_offset +
                MediaQuery.paddingOf(context).bottom,
          ),
        ],
      );
    });
  }

  /// 骨架屏列表。
  Widget _build_skeleton_list(bool is_dark) {
    final Color card_bg = is_dark
        ? ShortStoryTabStyle.card_dark_bg
        : ShortStoryTabStyle.card_light_bg;
    final Color shimmer_base = is_dark
        ? const Color(0xFF252836)
        : const Color(0xFFF0F1F5);
    final Color shimmer_highlight = is_dark
        ? const Color(0xFF2E3145)
        : const Color(0xFFF8F8FA);

    return ListView.builder(
      padding: const EdgeInsets.only(
        top: ShortStoryTabStyle.list_top_spacing,
        bottom: ShortStoryTabStyle.list_bottom_spacing,
      ),
      itemCount: _skeleton_count,
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: const EdgeInsets.only(
            bottom: ShortStoryTabStyle.card_spacing,
            left: ShortStoryTabStyle.list_horizontal_padding,
            right: ShortStoryTabStyle.list_horizontal_padding,
          ),
          child: _SkeletonCard(
            card_bg: card_bg,
            shimmer_base: shimmer_base,
            shimmer_highlight: shimmer_highlight,
          ),
        );
      },
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  final Color card_bg;
  final Color shimmer_base;
  final Color shimmer_highlight;

  const _SkeletonCard({
    required this.card_bg,
    required this.shimmer_base,
    required this.shimmer_highlight,
  });

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer_controller;

  @override
  void initState() {
    super.initState();
    _shimmer_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer_controller,
      builder: (BuildContext context, Widget? child) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.card_bg,
            borderRadius: BorderRadius.circular(
              ShortStoryTabStyle.card_border_radius,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _block(double.infinity, 16),
              const SizedBox(height: 4),
              _block(180, 16),
              const SizedBox(height: 6),
              _block(double.infinity, 14),
              const SizedBox(height: 4),
              _block(double.infinity, 14),
              const SizedBox(height: 4),
              _block(120, 14),
              const SizedBox(
                height: ShortStoryTabStyle.card_desc_bottom_gap_cjk,
              ),
              Row(
                children: <Widget>[
                  _block(52, 22),
                  const SizedBox(width: ShortStoryTabStyle.card_tag_spacing),
                  _block(64, 22),
                  const SizedBox(width: ShortStoryTabStyle.card_tag_spacing),
                  _block(44, 22),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _block(double width, double height) {
    final double p = _shimmer_controller.value;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: <double>[
            (p - 0.3).clamp(0.0, 1.0),
            p.clamp(0.0, 1.0),
            (p + 0.3).clamp(0.0, 1.0),
          ],
          colors: <Color>[
            widget.shimmer_base,
            widget.shimmer_highlight,
            widget.shimmer_base,
          ],
        ),
      ),
    );
  }
}
