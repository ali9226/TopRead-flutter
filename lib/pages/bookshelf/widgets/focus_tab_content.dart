import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/api/bookshelf.dart';
import 'package:app/components/fixed_bottom_navigation/style.dart'
    as fixed_nav_style;
import 'package:app/components/floating_back_to_top/index.dart';
import 'package:app/components/floating_back_to_top/style.dart'
    as floating_back_to_top_style;
import 'package:app/components/load_more_footer/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/bookshelf/style.dart';
import 'package:app/stores/bookshelf_store.dart';
import 'package:app/util/dialog/show_message.dart';

/// 关注 Tab 内容。
///
/// 展示用户关注的作者列表，采用卡片网格布局展示作者信息。
/// 数据由 [BookshelfStore] 统一管理，切换 Tab 时不会丢失。
class FocusTabContent extends StatefulWidget {
  /// 当前 Tab 的强调色。
  final Color accent_color;

  /// 当前是否为夜间模式。
  final bool is_dark;

  const FocusTabContent({
    super.key,
    required this.accent_color,
    required this.is_dark,
  });

  @override
  State<FocusTabContent> createState() => _FocusTabContentState();
}

class _FocusTabContentState extends State<FocusTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// 内容滚动控制器。
  final ScrollController _scroll_controller = ScrollController();

  /// 书架数据仓库。
  final BookshelfStore _store = Get.find<BookshelfStore>();

  /// 当前是否处于加载更多。
  bool _is_loading_more = false;

  /// 返回顶部按钮是否可见。
  bool _is_back_to_top_visible = false;

  @override
  void initState() {
    super.initState();
    _scroll_controller.addListener(_handle_scroll);
    _store.load_focus_if_needed();
  }

  @override
  void dispose() {
    _scroll_controller.removeListener(_handle_scroll);
    _scroll_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(() {
      final bool is_initial_loading = _store.focus_is_loading.value;
      final List<FocusAuthorItem> visible_list = _store.focus_list.toList();
      final bool has_more = _store.focus_has_more.value;

      return Stack(
        children: <Widget>[
          RefreshIndicator(
            onRefresh: _handle_refresh,
            child: CustomScrollView(
              controller: _scroll_controller,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: <Widget>[
                if (is_initial_loading)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((
                        BuildContext context,
                        int index,
                      ) {
                        return _AuthorCardSkeleton(is_dark: widget.is_dark);
                      }, childCount: 6),
                    ),
                  )
                else if (visible_list.isEmpty)
                  SliverToBoxAdapter(child: _build_empty_state())
                else ...<Widget>[
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((
                        BuildContext context,
                        int index,
                      ) {
                        final FocusAuthorItem author_item = visible_list[index];
                        return _FocusAuthorCard(
                          author_item: author_item,
                          is_dark: widget.is_dark,
                          on_unfollow: () => _show_unfollow_dialog(author_item),
                        );
                      }, childCount: visible_list.length),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _build_load_more_section(has_more: has_more),
                  ),
                ],
              ],
            ),
          ),
          // 返回顶部按钮
          FloatingBackToTop(
            show: _is_back_to_top_visible,
            isDark: widget.is_dark,
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

  /// 下拉刷新数据。
  Future<void> _handle_refresh() async {
    await _store.refresh_focus();
    if (mounted) {
      setState(() {
        _is_loading_more = false;
      });
    }
  }

  /// 处理滚动事件：控制返回顶部按钮显隐、触发加载更多。
  void _handle_scroll() {
    // 返回顶部按钮显隐。
    final bool should_show_back_to_top =
        _scroll_controller.hasClients &&
        _scroll_controller.offset > Style.back_to_top_visible_offset;

    if (_is_back_to_top_visible != should_show_back_to_top) {
      setState(() {
        _is_back_to_top_visible = should_show_back_to_top;
      });
    }

    // 加载更多。
    if (_store.focus_is_loading.value ||
        _is_loading_more ||
        !_store.focus_has_more.value) {
      return;
    }

    if (_scroll_controller.position.pixels >=
        _scroll_controller.position.maxScrollExtent -
            Style.load_more_auto_trigger_distance) {
      _load_more_data();
    }
  }

  /// 平滑滚动到顶部。
  void _scroll_to_top() {
    if (!_scroll_controller.hasClients) return;

    _scroll_controller.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  /// 加载更多数据。
  Future<void> _load_more_data() async {
    if (_is_loading_more || !_store.focus_has_more.value) return;

    setState(() {
      _is_loading_more = true;
    });

    await _store.load_more_focus();

    if (mounted) {
      setState(() {
        _is_loading_more = false;
      });
    }
  }

  /// 构建空状态。
  Widget _build_empty_state() {
    final Color text_color = widget.is_dark
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF9BA3B1);

    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: widget.accent_color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 36,
                color: widget.accent_color,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              easy.tr('bookshelf.empty.focus'),
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
  Widget _build_load_more_section({required bool has_more}) {
    return LoadMoreFooter(
      is_dark: widget.is_dark,
      is_loading: _is_loading_more,
      has_more: has_more,
      on_load_more: _load_more_data,
    );
  }

  /// 展示取消关注确认弹窗。
  Future<void> _show_unfollow_dialog(FocusAuthorItem author_item) async {
    await showMessage(
      message: easy.tr(
        'bookshelf.unfollow_dialog.message',
        namedArgs: <String, String>{'name': author_item.author_name},
      ),
      showHelperText: false,
      iconData: Icons.person_remove_outlined,
      iconColor: ColorConstants.dangerColor,
      leftButtonText: easy.tr('bookshelf.unfollow_dialog.cancel'),
      rightButtonText: easy.tr('bookshelf.unfollow_dialog.confirm'),
      rightButtonColor: ColorConstants.dangerColor,
      onRightPressed: () async {
        if (!mounted) return;
        _store.remove_focus_item(author_item.id);
      },
    );
  }
}

/// 关注作者卡片组件。
class _FocusAuthorCard extends StatelessWidget {
  /// 作者数据。
  final FocusAuthorItem author_item;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 取消关注回调。
  final VoidCallback on_unfollow;

  const _FocusAuthorCard({
    required this.author_item,
    required this.is_dark,
    required this.on_unfollow,
  });

  @override
  Widget build(BuildContext context) {
    /// 标题文字颜色。
    final Color title_color = is_dark ? Colors.white : const Color(0xFF1A1D26);

    /// 副标题文字颜色。
    final Color subtitle_color = is_dark
        ? Colors.white.withValues(alpha: 0.55)
        : const Color(0xFF8E95A2);

    /// 卡片背景颜色。
    final Color card_background = is_dark
        ? const Color(0xFF1C2030)
        : Colors.white;

    /// 关注时间背景色。
    final Color time_badge_background = is_dark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF2F4F8);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onLongPress: on_unfollow,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: card_background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: is_dark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFE8ECF2),
              width: 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              _build_avatar(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      author_item.author_name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: title_color,
                        fontSize: 15,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.menu_book_rounded,
                          size: 13,
                          color: subtitle_color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          easy.tr(
                            'bookshelf.focus.novel_count',
                            namedArgs: <String, String>{
                              'count': author_item.novel_count.toString(),
                            },
                          ),
                          style: TextStyle(
                            color: subtitle_color,
                            fontSize: 13,
                            fontWeight: FontConfig.adjustedWeight(
                              FontWeight.w400,
                            ),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: time_badge_background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _format_time(author_item.creation_time),
                  style: TextStyle(
                    color: subtitle_color,
                    fontSize: 11,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建作者头像。
  Widget _build_avatar() {
    const double avatar_size = 48;

    if (author_item.author_avatar.isNotEmpty) {
      return Container(
        width: avatar_size,
        height: avatar_size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: is_dark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE8ECF2),
            width: 1.5,
          ),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: author_item.author_avatar,
            width: avatar_size,
            height: avatar_size,
            fit: BoxFit.cover,
            placeholder: (context, url) => _build_avatar_placeholder(),
            errorWidget: (context, url, error) =>
                _build_avatar_fallback(avatar_size),
          ),
        ),
      );
    }

    return _build_avatar_fallback(avatar_size);
  }

  /// 构建头像占位符。
  Widget _build_avatar_placeholder() {
    final Color placeholder_color = is_dark
        ? const Color(0xFF252B3B)
        : const Color(0xFFEFF1F5);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: placeholder_color,
      ),
    );
  }

  /// 构建头像加载失败时的兜底内容。
  Widget _build_avatar_fallback(double size) {
    final List<Color> gradient_colors = _get_avatar_gradient();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient_colors,
        ),
      ),
      child: Center(
        child: Text(
          author_item.author_name.isNotEmpty
              ? author_item.author_name[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
          ),
        ),
      ),
    );
  }

  /// 根据作者名称生成稳定的渐变色。
  List<Color> _get_avatar_gradient() {
    final List<List<Color>> palettes = <List<Color>>[
      [const Color(0xFF6B8CFF), const Color(0xFF9B6BFF)],
      [const Color(0xFFFF6B8C), const Color(0xFFFF9B6B)],
      [const Color(0xFF6BCCAA), const Color(0xFF6BAAEE)],
      [const Color(0xCC8B6B), const Color(0xCC6B8B)],
      [const Color(0xFF8B6BCC), const Color(0xFF6BCCCB)],
      [const Color(0xFFEE8B6B), const Color(0xFFEECB6B)],
    ];

    int hash = 0;
    for (final int code_unit in author_item.author_name.codeUnits) {
      hash = 0x1fffffff & (hash * 31 + code_unit);
    }
    return palettes[hash.abs() % palettes.length];
  }

  /// 格式化时间显示。
  String _format_time(String time_str) {
    if (time_str.isEmpty) return '';

    try {
      final DateTime time = DateTime.parse(time_str);
      final DateTime now = DateTime.now();
      final Duration diff = now.difference(time);

      if (diff.inDays > 365) {
        return '${(diff.inDays / 365).floor()}${easy.tr('bookshelf.time.year_ago')}';
      } else if (diff.inDays > 30) {
        return '${(diff.inDays / 30).floor()}${easy.tr('bookshelf.time.month_ago')}';
      } else if (diff.inDays > 0) {
        return '${diff.inDays}${easy.tr('bookshelf.time.day_ago')}';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}${easy.tr('bookshelf.time.hour_ago')}';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}${easy.tr('bookshelf.time.minute_ago')}';
      } else {
        return easy.tr('bookshelf.time.just_now');
      }
    } catch (e) {
      return '';
    }
  }
}

/// 作者卡片骨架屏。
class _AuthorCardSkeleton extends StatelessWidget {
  final bool is_dark;

  const _AuthorCardSkeleton({required this.is_dark});

  @override
  Widget build(BuildContext context) {
    final Color block_color = is_dark
        ? const Color(0xFF252B3B)
        : const Color(0xFFEFF1F5);

    final Color card_background = is_dark
        ? const Color(0xFF1C2030)
        : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: card_background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: is_dark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE8ECF2),
            width: 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: block_color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: 15,
                    width: 100,
                    decoration: BoxDecoration(
                      color: block_color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 13,
                    width: 72,
                    decoration: BoxDecoration(
                      color: block_color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 22,
              width: 56,
              decoration: BoxDecoration(
                color: block_color,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
