// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/author_center/logic.dart';
import 'package:app/pages/author_center/creator_tab_state.dart';
import 'package:app/pages/author_center/models/creator_backend_models.dart';
import 'package:app/pages/work_editor/backend_draft_loader.dart';
import 'package:app/pages/work_editor/draft_persistence.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/author_center/widgets/creator_header.dart';
import 'package:app/pages/author_center/widgets/creator_work_tab.dart';
import 'package:app/pages/author_center/widgets/nickname_badge.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/dialog/show_message.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/router/router_back.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 支持在首次创建 ScrollPosition 前更新初始偏移的控制器。
class _CreatorTabScrollController extends ScrollController {
  double _prepared_initial_scroll_offset = 0;
  bool _has_created_position = false;

  _CreatorTabScrollController({required super.debugLabel});

  /// 仅在目标 Tab 从未布局时设置首帧偏移。
  void prepare_initial_scroll_offset(double offset) {
    if (_has_created_position) return;
    _prepared_initial_scroll_offset = offset;
  }

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    final double initial_pixels = _has_created_position
        ? initialScrollOffset
        : _prepared_initial_scroll_offset;
    _has_created_position = true;
    return ScrollPositionWithSingleContext(
      physics: physics,
      context: context,
      initialPixels: initial_pixels,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

/// 已认证作者的创作工作台。
class AuthorView extends StatefulWidget {
  const AuthorView({super.key});

  @override
  State<AuthorView> createState() => _AuthorViewState();
}

class _AuthorViewState extends State<AuthorView> with TickerProviderStateMixin {
  final DeviceInfo _device_info = Get.find<DeviceInfo>();
  final UserInformation _user_information = Get.find<UserInformation>();

  late final List<CreatorTabState> _tabs;
  bool _opening_work = false;
  bool _loading_draft = false;
  late TabController _tab_controller;

  /// Dashboard统计数据
  int _total_works = 0;
  int _total_favorites = 0;
  int _total_comments = 0;

  /// 每个 Tab 独占的滚动控制器。
  late final List<_CreatorTabScrollController> _tab_scroll_controllers;

  /// 合并 Tab 切换动画与全部独立滚动位置，驱动共享头部绘制。
  late final Listenable _header_listenable;

  /// 横向切换 Tab 期间锁定的头部纵向距离。
  late final ValueNotifier<double?> _horizontal_header_offset_lock;

  /// 横向切换完成后用于平滑恢复目标 Tab 头部位置。
  late final AnimationController _header_transition_controller;

  /// 当前头部过渡的折叠距离动画。
  Animation<double>? _header_transition_animation;

  /// 用于忽略旧横向手势延迟触发的解锁回调。
  int _horizontal_scroll_generation = 0;

  /// 上一个已稳定记录的 Tab 索引。
  int _active_tab_index = 0;

  /// 目标 Tab 尚未完成布局时，临时保持共享头部吸顶。
  bool _preserve_pinned_header_on_tab_change = false;

  /// 头部从展开到吸顶需要的滚动距离。
  late double _header_collapse_range;

  /// 头部最大展开高度（含状态栏）。
  late double _header_max_extent;

  /// 头部最小高度（折叠态）。
  late double _header_min_extent;

  /// 创作中心固定状态 Tab 数量。
  static const int _tab_count = 3;

  /// 是否有服务器上可继续编辑的草稿。
  bool _has_draft = false;

  /// 随机头像索引（0-9）。
  late final int _random_avatar_index;

  @override
  void initState() {
    _random_avatar_index = NicknameBadge.generate_random_index();
    super.initState();
    _tabs = [
      CreatorTabState(
        loadPage: (page) =>
            CreatorLogic.getMyWorks(publicStatus: 2, page: page),
      ),
      CreatorTabState(
        loadPage: (page) =>
            CreatorLogic.getMyWorks(initialAuditStatus: 2, page: page),
      ),
      CreatorTabState(
        loadPage: (page) => CreatorLogic.getDraftList(page: page),
        isDraftList: true,
      ),
    ];
    for (final tab in _tabs) {
      tab.addListener(_on_data_changed);
    }
    _tab_controller = TabController(length: _tab_count, vsync: this);
    _tab_scroll_controllers = List<_CreatorTabScrollController>.generate(
      _tab_count,
      (int index) => _CreatorTabScrollController(
        debugLabel: 'creator_center_content_tab_$index',
      ),
      growable: false,
    );
    _horizontal_header_offset_lock = ValueNotifier<double?>(null);
    _header_transition_controller = AnimationController(
      vsync: this,
      duration: AuthorStyle.header_tab_transition_duration,
    );
    _header_listenable = Listenable.merge(<Listenable>[
      _tab_controller.animation!,
      _horizontal_header_offset_lock,
      _header_transition_controller,
      ..._tab_scroll_controllers,
    ]);
    _tab_controller.addListener(_on_tab_index_changed);

    // TODO 加载Dashboard统计数据
    _reload_all();
  }

  /// 加载Dashboard统计数据
  Future<void> _load_dashboard_data() async {
    try {
      final result = await CreatorLogic.getDashboard();
      if (result != null && mounted) {
        setState(() {
          _total_works = int.tryParse('${result['total_works']}') ?? 0;
          _total_favorites = int.tryParse('${result['total_favorites']}') ?? 0;
          _total_comments = int.tryParse('${result['total_comments']}') ?? 0;
        });
      }
    } catch (e) {
      debugPrint('加载Dashboard失败: $e');
    }
  }

  void _on_data_changed() {
    if (!mounted) return;
    setState(() {
      _has_draft = _tabs[2].works.isNotEmpty;
    });
  }

  Future<void> _reload_all() async {
    await Future.wait([
      ..._tabs.map((tab) => tab.refresh()),
      _load_dashboard_data(),
    ]);
  }

  Future<void> _refresh_tab(int index) async {
    await Future.wait([
      _tabs[index].refresh(),
      _load_dashboard_data(),
      if (index != 2) _tabs[2].refresh(),
    ]);
  }

  /// 测量文本在给定宽度下的实际行数。
  static int _measure_line_count(
    String text,
    TextStyle style,
    double maxWidth,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter.computeLineMetrics().length;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final double status_bar = MediaQuery.paddingOf(context).top;
    _header_min_extent =
        status_bar +
        AuthorStyle.header_toolbar_height +
        AuthorStyle.header_tab_bar_height;

    // 测量标题和副标题行数，动态计算高度。
    // 基础360 = 单行标题 + 2行副标题。
    // 标题每多一行 +30，副标题超过2行每多一行 +15。
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );
    final String title_text = easy.tr('creator_center.hero_title');
    final String subtitle_text = easy.tr('creator_center.hero_subtitle');
    final TextStyle title_style = TextStyle(
      fontSize: is_cjk
          ? AuthorStyle.hero_title_size_cjk
          : AuthorStyle.hero_title_size_alphabetic,
      height: is_cjk ? 1.24 : 1.28,
      fontWeight: AuthorStyle.title_weight,
      letterSpacing: is_cjk ? 0.2 : -0.2,
    );
    final TextStyle subtitle_style = TextStyle(
      fontSize: is_cjk ? 12.5 : 11.5,
      height: is_cjk ? 1.42 : 1.48,
      fontWeight: AuthorStyle.body_weight,
    );
    final double content_width =
        MediaQuery.sizeOf(context).width -
        AuthorStyle.header_content_padding * 2;
    final int title_lines = _measure_line_count(
      title_text,
      title_style,
      content_width,
    );
    final int subtitle_lines = _measure_line_count(
      subtitle_text,
      subtitle_style,
      content_width,
    );
    final int title_extra = title_lines - 1;
    final int subtitle_extra = subtitle_lines - 2;
    _header_max_extent =
        status_bar + 360 + title_extra * 30 + subtitle_extra * 15;
    _header_collapse_range = _header_max_extent - _header_min_extent;

    debugPrint(
      '[AuthorView] title_lines=$title_lines, title_extra=$title_extra, subtitle_lines=$subtitle_lines, subtitle_extra=$subtitle_extra, _header_max_extent=$_header_max_extent',
    );
  }

  @override
  void dispose() {
    for (final tab in _tabs) {
      tab.removeListener(_on_data_changed);
      tab.dispose();
    }
    _tab_controller.removeListener(_on_tab_index_changed);
    for (final ScrollController controller in _tab_scroll_controllers) {
      controller.dispose();
    }
    _header_transition_controller.dispose();
    _horizontal_header_offset_lock.dispose();
    _tab_controller.dispose();
    super.dispose();
  }

  Future<void> _create_work() async {
    if (_opening_work) return;
    _opening_work = true;
    try {
      final result = await context.push<CreatorWorkDraft>('/work_editor');
      if (!mounted) return;
      _select_result_tab(result);
      await _reload_all();
    } finally {
      _opening_work = false;
    }
  }

  void _select_result_tab(CreatorWorkDraft? result) {
    if (result == null) return;
    _tab_controller.animateTo(
      result.status == CreatorWorkStatus.reviewing ? 1 : 2,
    );
  }

  Future<void> _open_work(CreatorWorkModel work) async {
    if (work.is_draft || work.is_rejected) {
      await _open_draft(work.id);
    } else if (work.is_published) {
      final location = work.is_short_novel
          ? '/short_story_read?id=${work.id}'
          : '/read?id=${work.id}&title=${Uri.encodeComponent(work.title)}';
      await context.push<void>(location);
      if (mounted) await _reload_all();
    } else {
      await _show_review_status(work);
    }
  }

  Future<void> _open_draft(int novelId) async {
    if (_opening_work) return;
    _opening_work = true;
    setState(() => _loading_draft = true);
    try {
      // 列表只提供摘要；进入编辑器前必须从服务端取回完整正文和章节。
      final draft = await loadCreatorWorkDraft(novelId);
      if (!mounted) return;
      setState(() => _loading_draft = false);
      final result = await context.push<CreatorWorkDraft>(
        '/work_editor',
        extra: draft,
      );
      if (!mounted) return;
      _select_result_tab(result);
      await _reload_all();
    } catch (error) {
      _show_error(
        error is CreatorDraftException ? error.message : '草稿读取失败，请刷新后重试',
      );
      if (mounted) await _reload_all();
    } finally {
      _opening_work = false;
      if (mounted) setState(() => _loading_draft = false);
    }
  }

  Future<void> _continue_latest_draft() async {
    if (_opening_work) return;
    _opening_work = true;
    int? novelId;
    try {
      final result = await CreatorLogic.getDraftList(page: 1, pageSize: 1);
      if (!mounted) return;
      if (result == null) {
        _show_error('获取最近草稿失败，请稍后重试');
        return;
      }
      final list = result['list'] as List? ?? [];
      setState(() => _has_draft = list.isNotEmpty);
      if (list.isEmpty) {
        await _tabs[2].refresh();
        return;
      }
      novelId = int.tryParse('${list.first['novel_id']}');
      if (novelId == null) _show_error('草稿信息不完整，请刷新后重试');
    } finally {
      _opening_work = false;
    }
    if (mounted && novelId != null) await _open_draft(novelId);
  }

  void _show_error(String message) {
    if (!mounted) return;
    showBottomTip(message);
  }

  Future<bool> _delete_work(CreatorWorkModel work) async {
    bool confirmed = false;
    await showMessage(
      message: easy.tr('creator_center.delete_confirm_message'),
      iconData: Icons.delete_outline_rounded,
      iconColor: ColorConstants.dangerColor,
      leftButtonText: easy.tr('common.cancel'),
      rightButtonText: easy.tr('creator_center.delete_work'),
      rightButtonColor: ColorConstants.dangerColor,
      onRightPressed: () async => confirmed = true,
    );
    if (!confirmed || !mounted) return false;

    // 乐观删除：立即返回 true 让列表播放移除动画，后台调 API
    CreatorLogic.deleteWork(work.id).then((success) {
      if (!mounted) return;
      if (!success) {
        _show_error(easy.tr('creator_center.delete_failed'));
      }
      _reload_all();
    });

    return true;
  }

  Future<bool> _withdraw_work(CreatorWorkModel work) async {
    bool confirmed = false;
    await showMessage(
      message: easy.tr('creator_center.withdraw_confirm_message'),
      iconData: Icons.undo_rounded,
      iconColor: ColorConstants.dangerColor,
      leftButtonText: easy.tr('common.cancel'),
      rightButtonText: easy.tr('creator_center.withdraw_work'),
      rightButtonColor: ColorConstants.dangerColor,
      onRightPressed: () async => confirmed = true,
    );
    if (!confirmed || !mounted) return false;

    CreatorLogic.withdrawByNovel(work.id).then((success) {
      if (!mounted) return;
      if (!success) {
        _show_error(easy.tr('creator_center.withdraw_failed'));
      }
      _reload_all();
    });

    return true;
  }

  Future<void> _show_review_status(CreatorWorkModel work) async {
    if (_opening_work) return;
    _opening_work = true;
    try {
      final info = await CreatorLogic.getWorkInfo(work.id);
      if (!mounted) return;
      if (info == null) {
        _show_error('审核信息加载失败，请稍后重试');
        return;
      }
      final submissions = info['recent_submissions'] as List? ?? [];
      final latest = submissions.isEmpty ? null : submissions.first as Map;
      final status = int.tryParse('${latest?['status']}');
      final statusText = switch (status) {
        3 => '审核已通过',
        4 => '审核未通过',
        5 => '审核已撤回',
        _ => '作品待审核',
      };
      final isDark = _device_info.dark.value;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AuthorStyle.surface(isDark),
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.fact_check_outlined,
                  size: 36,
                  color: isDark ? AuthorStyle.gold : AuthorStyle.deep_gold,
                ),
                const SizedBox(height: 16),
                Text(
                  work.title.isEmpty ? '未命名作品' : work.title,
                  style: TextStyle(
                    fontSize: 20,
                    color: AuthorStyle.primary_text(isDark),
                    fontWeight: AuthorStyle.title_weight,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    color: AuthorStyle.primary_text(isDark),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  latest?['review_note']?.toString().trim().isNotEmpty == true
                      ? latest!['review_note'].toString()
                      : '提交的内容已保存。审核通过并发布后，读者即可浏览这部作品。',
                  style: TextStyle(
                    height: 1.6,
                    color: AuthorStyle.secondary_text(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (mounted) await _reload_all();
    } finally {
      _opening_work = false;
    }
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );

    return Obx(() {
      final bool is_dark = _device_info.dark.value;
      final Color background = AuthorStyle.background(is_dark);
      final String author_name =
          _user_information.userInfo.value?.name.trim().isNotEmpty == true
          ? _user_information.userInfo.value!.name.trim()
          : easy.tr('creator_center.author_fallback_name');

      return Scaffold(
        backgroundColor: background,
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: NotificationListener<ScrollNotification>(
                onNotification: _on_tab_view_scroll_notification,
                child: TabBarView(
                  controller: _tab_controller,
                  physics: const BouncingScrollPhysics(),
                  children: List<Widget>.generate(
                    _tab_count,
                    (int tab_index) => CreatorWorkTab(
                      key: ValueKey<String>('creator_work_tab_$tab_index'),
                      tab_index: tab_index,
                      works: _tabs[tab_index].works,
                      is_loading: _tabs[tab_index].isLoading,
                      is_loading_more: _tabs[tab_index].isLoadingMore,
                      error_message: _tabs[tab_index].error,
                      load_more_error: _tabs[tab_index].loadMoreError,
                      has_more: _tabs[tab_index].hasMore,
                      total_count: _tabs[tab_index].total,
                      on_refresh: () => _refresh_tab(tab_index),
                      on_load_more: _tabs[tab_index].loadMore,
                      is_dark: is_dark,
                      is_cjk: is_cjk,
                      scroll_controller: _tab_scroll_controllers[tab_index],
                      header_spacer_height: _header_max_extent,
                      minimum_header_height: _header_min_extent,
                      minimum_scroll_extent:
                          _header_max_extent - _header_min_extent,
                      on_create_work: _create_work,
                      on_edit_work: (work) =>
                          (work.is_reviewing || work.pending_submission != null)
                          ? _show_review_status(work)
                          : _open_draft(work.id),
                      on_primary_action: _open_work,
                      on_delete_work: _delete_work,
                      on_withdraw_work: _withdraw_work,
                    ),
                    growable: false,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _header_listenable,
                builder: (BuildContext context, Widget? child) {
                  final double current_height = _current_header_height(
                    maximum_extent: _header_max_extent,
                    minimum_extent: _header_min_extent,
                  );

                  return CreatorHeaderOverlay(
                    tab_controller: _tab_controller,
                    current_height: current_height,
                    is_dark: is_dark,
                    is_cjk: is_cjk,
                    author_name: author_name,
                    works_count: _total_works,
                    favorites_count: _total_favorites.toString(),
                    comments_count: _total_comments.toString(),
                    on_back: () => routerBack(context),
                    on_create_work: _create_work,
                    on_continue_writing: _continue_latest_draft,
                    on_open_guide: () => _show_creator_guide(is_dark),
                    has_draft: _has_draft,
                    avatar_url: _user_information.userInfo.value?.avatarUrl,
                    random_avatar_index: _random_avatar_index,
                  );
                },
              ),
            ),
            if (_loading_draft)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: .18),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 22,
                      ),
                      decoration: BoxDecoration(
                        color: AuthorStyle.surface(is_dark),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              color: AuthorStyle.gold,
                              strokeWidth: 2.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '正在加载作品与章节…',
                            style: TextStyle(
                              color: AuthorStyle.primary_text(is_dark),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  /// 读取当前头部应该展示的纵向折叠距离。
  ///
  /// 横向手势期间始终使用手势开始时的固定值，不再在两个
  /// Tab 的不同滚动位置之间插值，避免横滑带动头部纵向位移。
  double _effective_header_scroll_offset() {
    final double? locked_offset = _horizontal_header_offset_lock.value;
    if (locked_offset != null) return locked_offset;
    if (_header_transition_controller.isAnimating &&
        _header_transition_animation != null) {
      return _header_transition_animation!.value;
    }
    if (_preserve_pinned_header_on_tab_change) {
      return _header_collapse_range;
    }
    return _tab_scroll_offset(_active_tab_index);
  }

  /// 监听 TabBarView 的横向滚动，切换期间锁定头部高度。
  bool _on_tab_view_scroll_notification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.horizontal) return false;

    if (notification is ScrollStartNotification) {
      _horizontal_scroll_generation += 1;
      _lock_horizontal_header_offset();
    } else if (notification is ScrollEndNotification) {
      final int completed_generation = _horizontal_scroll_generation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || completed_generation != _horizontal_scroll_generation) {
          return;
        }
        _release_horizontal_header_offset_with_transition();
      });
    }
    return false;
  }

  /// 保存横向切换开始时的头部折叠位置。
  void _lock_horizontal_header_offset() {
    if (_horizontal_header_offset_lock.value != null) return;

    final double current_offset =
        _header_transition_controller.isAnimating &&
            _header_transition_animation != null
        ? _header_transition_animation!.value
        : _preserve_pinned_header_on_tab_change
        ? _header_collapse_range
        : _tab_scroll_offset(_active_tab_index);
    _header_transition_controller.stop();
    _horizontal_header_offset_lock.value = current_offset.clamp(
      0.0,
      _header_collapse_range,
    );
    if (current_offset >=
        _header_collapse_range - AuthorStyle.scroll_extent_tolerance) {
      _prepare_tabs_for_pinned_header();
    }
  }

  /// 在吸顶状态的横向手势开始时预先对齐其他 Tab。
  ///
  /// 未创建的 Tab 直接使用吸顶偏移创建 ScrollPosition；
  /// 已布局的 Tab 在进入屏幕前即完成对齐，避免首帧空白。
  void _prepare_tabs_for_pinned_header() {
    for (int index = 0; index < _tab_count; index++) {
      if (index == _active_tab_index) continue;

      final _CreatorTabScrollController controller =
          _tab_scroll_controllers[index];
      controller.prepare_initial_scroll_offset(_header_collapse_range);
      if (!controller.hasClients ||
          !controller.position.hasContentDimensions ||
          controller.position.maxScrollExtent +
                  AuthorStyle.scroll_extent_tolerance <
              _header_collapse_range ||
          controller.offset + AuthorStyle.scroll_extent_tolerance >=
              _header_collapse_range) {
        continue;
      }
      controller.jumpTo(_header_collapse_range);
    }
  }

  /// 从横向手势的锁定位置平滑过渡到目标 Tab 的保存位置。
  void _release_horizontal_header_offset_with_transition() {
    final double? begin_offset = _horizontal_header_offset_lock.value;
    if (begin_offset == null) return;

    final double target_offset =
        (_preserve_pinned_header_on_tab_change
                ? _header_collapse_range
                : _tab_scroll_offset(_active_tab_index))
            .clamp(0.0, _header_collapse_range);
    if ((target_offset - begin_offset).abs() <=
        AuthorStyle.scroll_extent_tolerance) {
      _horizontal_header_offset_lock.value = null;
      return;
    }

    _header_transition_animation =
        Tween<double>(begin: begin_offset, end: target_offset).animate(
          CurvedAnimation(
            parent: _header_transition_controller,
            curve: Curves.easeOutCubic,
          ),
        );
    _header_transition_controller.forward(from: 0);
    _horizontal_header_offset_lock.value = null;
  }

  /// 读取指定 Tab 的滚动距离；尚未挂载的 Tab 从顶部开始。
  double _tab_scroll_offset(int tab_index) {
    final ScrollController controller = _tab_scroll_controllers[tab_index];
    if (!controller.hasClients) return 0;
    return controller.offset;
  }

  /// 在已吸顶状态下切换 Tab 时，让目标 Tab 继续保持吸顶。
  ///
  /// 只补齐头部折叠所需的距离，目标 Tab 原有的内容滚动距离
  /// 若更大则完全保留，不会被覆盖。
  void _on_tab_index_changed() {
    final int next_index = _tab_controller.index;
    if (next_index == _active_tab_index) return;

    if (_tab_controller.indexIsChanging) {
      _lock_horizontal_header_offset();
    }

    final bool keep_header_pinned =
        _tab_scroll_offset(_active_tab_index) >=
        _header_collapse_range - AuthorStyle.scroll_extent_tolerance;
    _active_tab_index = next_index;
    _preserve_pinned_header_on_tab_change = keep_header_pinned;

    if (keep_header_pinned) {
      _tab_scroll_controllers[next_index].prepare_initial_scroll_offset(
        _header_collapse_range,
      );
    }
    if (keep_header_pinned && !_try_pin_tab_header(next_index)) {
      _restore_pinned_header(next_index, attempt: 0);
    }
  }

  /// 在目标 Tab 已完成布局时立即对齐吸顶距离。
  bool _try_pin_tab_header(int tab_index) {
    final ScrollController controller = _tab_scroll_controllers[tab_index];
    if (!controller.hasClients) return false;

    final double maximum_offset = controller.position.maxScrollExtent;
    if (maximum_offset + AuthorStyle.scroll_extent_tolerance <
        _header_collapse_range) {
      return false;
    }

    if (controller.offset + AuthorStyle.scroll_extent_tolerance <
        _header_collapse_range) {
      controller.jumpTo(_header_collapse_range);
    }
    _preserve_pinned_header_on_tab_change = false;
    return true;
  }

  /// 在目标 Tab 完成布局后恢复吸顶距离。
  void _restore_pinned_header(int tab_index, {required int attempt}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _tab_controller.index != tab_index) return;

      final ScrollController controller = _tab_scroll_controllers[tab_index];
      if (!controller.hasClients) {
        if (attempt < AuthorStyle.pin_restore_max_attempts) {
          _restore_pinned_header(tab_index, attempt: attempt + 1);
        }
        return;
      }

      if (_try_pin_tab_header(tab_index)) return;

      if (attempt < AuthorStyle.pin_restore_max_attempts) {
        _restore_pinned_header(tab_index, attempt: attempt + 1);
        return;
      }

      final double maximum_offset = controller.position.maxScrollExtent;
      final double target_offset = _header_collapse_range.clamp(
        controller.position.minScrollExtent,
        maximum_offset,
      );
      if (controller.offset + AuthorStyle.scroll_extent_tolerance <
          target_offset) {
        controller.jumpTo(target_offset);
      }
      _preserve_pinned_header_on_tab_change = false;
    });
  }

  /// 将当前 Tab 的滚动距离转换为共享头部可见高度。
  double _current_header_height({
    required double maximum_extent,
    required double minimum_extent,
  }) {
    final double collapse_range = maximum_extent - minimum_extent;
    if (collapse_range <= 0) return minimum_extent;
    final double collapsed_distance = _effective_header_scroll_offset().clamp(
      0.0,
      collapse_range,
    );
    return maximum_extent - collapsed_distance;
  }

  // ───────────────────── guide sheet ─────────────────────

  Future<void> _show_creator_guide(bool is_dark) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            decoration: BoxDecoration(
              color: AuthorStyle.surface(is_dark),
              borderRadius: BorderRadius.circular(AuthorStyle.section_radius),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AuthorStyle.border(is_dark),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  easy.tr('creator_center.creator_guide'),
                  style: TextStyle(
                    color: AuthorStyle.primary_text(is_dark),
                    fontSize: 19,
                    fontWeight: AuthorStyle.title_weight,
                  ),
                ),
                const SizedBox(height: 16),
                _guide_item(
                  is_dark,
                  Icons.cloud_done_outlined,
                  easy.tr('creator_center.guide_draft_title'),
                  easy.tr('creator_center.guide_draft_desc'),
                ),
                _guide_item(
                  is_dark,
                  Icons.fact_check_outlined,
                  easy.tr('creator_center.guide_review_title'),
                  easy.tr('creator_center.guide_review_desc'),
                ),
                _guide_item(
                  is_dark,
                  Icons.schedule_rounded,
                  easy.tr('creator_center.guide_schedule_title'),
                  easy.tr('creator_center.guide_schedule_desc'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _guide_item(
    bool is_dark,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AuthorStyle.gold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: AuthorStyle.primary_text(is_dark),
                    fontSize: 14,
                    fontWeight: AuthorStyle.emphasis_weight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AuthorStyle.secondary_text(is_dark),
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: AuthorStyle.body_weight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
