// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/pages/comics/detail/widgets/detail_sheets.dart';
import 'package:app/pages/comics/reader/auto_read.dart';
import 'package:app/pages/comics/reader/image_page.dart';
import 'package:app/pages/comics/reader/logic.dart';
import 'package:app/pages/comics/reader/style.dart';
import 'package:app/pages/comics/reader/widgets/bottom_scrim.dart';
import 'package:app/pages/comics/reader/widgets/chapter_end.dart';
import 'package:app/pages/comics/reader/widgets/top_scrim.dart';
import 'package:app/pages/comics/reader/widgets/reading_panels/index.dart';
import 'package:app/pages/comics/widgets/chapter_sheet/index.dart';
import 'package:app/pages/comics/widgets/comment_sheet/index.dart';
import 'package:app/pages/comics/widgets/empty_state.dart';
import 'package:app/pages/read/widgets/auto_read_settings_button/index.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/device/save_body_font_size.dart';
import 'package:app/util/router/router_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// TODO 原比例漫画阅读：三段触控、共用目录与评论弹窗，进度与自动阅读保持当前章的阅读锚点。
class ComicReaderPage extends StatefulWidget {
  const ComicReaderPage({
    super.key,
    required this.chapter_id,
    this.initial_page,
    this.controller,
    this.detail_controller,
  });
  final int chapter_id;
  final int? initial_page;
  final ComicReaderLogic? controller;
  final ComicDetailLogic? detail_controller;
  @override
  State<ComicReaderPage> createState() => _ComicReaderPageState();
}

class _ComicReaderPageState extends State<ComicReaderPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final ComicReaderLogic _logic;
  late final ComicAutoRead _auto;
  final RxDouble _auto_speed = 0.2.obs;
  final ComicReaderBrightnessSession _brightness =
      ComicReaderBrightnessSession();
  ComicDetailLogic? _detail;
  DeviceInfo? _device;
  bool _page_scrolling = false;
  bool _sheet_open = false;
  // 只跟踪手动拖动及其惯性，恢复进度、滑块定位和自动阅读不改变导航栏。
  bool _user_scrolling = false;
  bool? _scrolling_down;
  double _last_user_offset = 0;
  double _scroll_direction_anchor = 0;
  int? _comment_count;
  int _collection_comic = 0;

  @override
  void initState() {
    super.initState();
    _logic = widget.controller ?? ComicReaderLogic();
    _device = Get.isRegistered<DeviceInfo>() ? Get.find<DeviceInfo>() : null;
    if (widget.controller == null) {
      _auto_speed.value = (load_auto_read_speed() ?? 0.2).clamp(0, 1);
    }
    _auto = ComicAutoRead(
      vsync: this,
      logic: _logic,
      speed: () => _auto_speed.value,
      on_next: _auto_next,
    );
    _logic.addListener(_on_reading_changed);
    WidgetsBinding.instance.addObserver(this);
    // 系统安全区保持稳定；工具栏显隐只调整画布可读高度，不重排图片宽度。
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      ),
    );
    unawaited(_brightness.initialize());
    unawaited(
      _logic.load(widget.chapter_id, initial_page: widget.initial_page),
    );
  }

  /// TODO 收藏状态由已有会话安全的详情控制器处理，章节切换不重复加载作品状态。
  void _on_reading_changed() {
    final reading = _logic.reading;
    if (reading != null && _collection_comic != reading.comic.id) {
      _collection_comic = reading.comic.id;
      _comment_count = null;
      _detail?.removeListener(_on_detail_changed);
      if (_detail != widget.detail_controller) _detail?.dispose();
      _detail = widget.detail_controller ?? ComicDetailLogic(reading.comic.id);
      _detail!.addListener(_on_detail_changed);
      unawaited(_detail!.load(language: reading.language.language));
    }
  }

  void _on_detail_changed() {
    if (mounted) setState(() {});
  }

  void _set_controls(bool visible) {
    if (_logic.controls_visible == visible) return;
    _reset_scroll_direction();
    _logic.toggle_controls();
  }

  /// 手动切换或开始新手势时重置基准，防止上一段滚动让工具栏立即反向切换。
  void _reset_scroll_direction() {
    final position = _logic.scroll.hasClients ? _logic.scroll.position : null;
    _last_user_offset = position == null
        ? 0
        : position.pixels.clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          );
    _scroll_direction_anchor = _last_user_offset;
    _scrolling_down = null;
  }

  /// 与小说阅读一致：同方向累计超过阈值才显隐，轻微手抖和回弹不触发。
  bool _on_scroll_notification(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification) {
      _user_scrolling = notification.dragDetails != null;
      _reset_scroll_direction();
      if (_user_scrolling) _auto.stop();
    } else if (notification is ScrollEndNotification) {
      _user_scrolling = false;
      _reset_scroll_direction();
    } else if (notification is ScrollUpdateNotification &&
        _user_scrolling &&
        !_sheet_open &&
        !_page_scrolling &&
        !_auto.running &&
        !_logic.is_reflowing) {
      final offset = notification.metrics.pixels.clamp(
        notification.metrics.minScrollExtent,
        notification.metrics.maxScrollExtent,
      );
      if (offset == _last_user_offset) return false;
      final down = offset > _last_user_offset;
      if (_scrolling_down != down) {
        _scroll_direction_anchor = _last_user_offset;
        _scrolling_down = down;
      }
      _last_user_offset = offset;
      if ((offset - _scroll_direction_anchor).abs() >
          ComicReaderStyle.navigation_scroll_threshold) {
        _set_controls(!down);
      }
    }
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _auto.stop();
      unawaited(_logic.flush());
    } else {
      // 从控制中心返回时同步系统新亮度，已打开的面板也能立即更新滑块。
      unawaited(_brightness.refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auto.dispose();
    _brightness.dispose();
    _logic.removeListener(_on_reading_changed);
    _detail?.removeListener(_on_detail_changed);
    if (_detail != widget.detail_controller) _detail?.dispose();
    if (widget.controller == null) {
      _logic.dispose();
    } else {
      unawaited(_logic.flush());
    }
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      ),
    );
    super.dispose();
  }

  void _on_back() {
    _auto.stop();
    unawaited(_logic.flush());
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      routerUtil(path: '/', type: 'replace');
    }
  }

  /// TODO 弹窗期间停止自动阅读，遮罩下的正文不会继续移动；同一时刻只打开一个面板。
  Future<void> _open_sheet(Future<void> Function() open) async {
    if (_sheet_open || _logic.reading == null) return;
    _sheet_open = true;
    _auto.stop();
    _set_controls(false);
    try {
      await open();
    } finally {
      _sheet_open = false;
    }
  }

  void _on_catalog() => unawaited(
    _open_sheet(() async {
      final reading = _logic.reading!;
      await show_comic_chapter_sheet(
        context,
        comic_id: reading.comic.id,
        language: reading.language.language,
        current_chapter_id: reading.chapter.id,
        on_open: (chapter) {
          if (mounted) {
            unawaited(
              _logic.load(
                chapter.id,
                initial_page: chapter.id == reading.chapter.id ? null : 0,
              ),
            );
          }
        },
      );
    }),
  );

  void _on_comments() => unawaited(
    _open_sheet(() async {
      await show_comic_comment_sheet(
        context,
        comic_id: _logic.reading!.comic.id,
        on_count_changed: (count) {
          if (mounted) setState(() => _comment_count = count);
        },
      );
    }),
  );

  void _on_progress() => unawaited(
    _open_sheet(
      () => show_comic_progress_sheet(
        context,
        logic: _logic,
        on_start_auto_read: () {
          if (mounted && !_logic.loading) {
            _set_controls(false);
            _auto.start();
          }
        },
      ),
    ),
  );

  void _on_appearance() => unawaited(
    _open_sheet(
      () => show_comic_appearance_sheet(context, brightness: _brightness),
    ),
  );

  /// TODO 调整速度时暂停Tick而保留自动阅读状态，关闭设置继续，明确退出才终止。
  Future<void> _on_auto_settings() async {
    if (_sheet_open) return;
    _sheet_open = true;
    _auto.pause();
    try {
      await show_comic_auto_read_settings(
        context,
        speed: _auto_speed,
        on_stop: _auto.stop,
      );
    } finally {
      _sheet_open = false;
      if (mounted) _auto.resume();
    }
  }

  void _on_share() => unawaited(
    _open_sheet(() async {
      final reading = _logic.reading!;
      final detail =
          _detail?.detail ??
          ComicDetail(
            comic: reading.comic,
            languages: [reading.language],
            selected_language_id: reading.language.id,
            chapters: [reading.chapter],
            is_collected: _detail?.collected ?? false,
            read_record: reading.read_record,
          );
      await show_comic_share_sheet(context, detail);
    }),
  );

  Future<bool> _auto_next() async {
    final next = _logic.reading?.next_chapter_id ?? 0;
    if (!mounted || next <= 0) return false;
    await _logic.load(next, initial_page: 0);
    await WidgetsBinding.instance.endOfFrame;
    return mounted &&
        _logic.error == null &&
        _logic.reading?.chapter.id == next;
  }

  /// TODO 全屏按当前画布等分三段：上翻一屏、中段显隐工具栏、下翻一屏。
  void _on_canvas_tap(TapUpDetails details, double height) {
    _auto.stop();
    if (_sheet_open) return;
    if (_logic.controls_visible) {
      _set_controls(false);
      return;
    }
    final third = height / 3;
    if (details.localPosition.dy < third) {
      unawaited(_scroll_page(-1));
    } else if (details.localPosition.dy > third * 2) {
      unawaited(_scroll_page(1));
    } else {
      _set_controls(true);
    }
  }

  Future<void> _scroll_page(int direction) async {
    if (_page_scrolling || _logic.loading || !_logic.scroll.hasClients) return;
    final position = _logic.scroll.position;
    final target = (position.pixels + direction * position.viewportDimension)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (ComicReaderStyle.controls_duration(context) == Duration.zero) {
      _logic.scroll.jumpTo(target);
      return;
    }
    _page_scrolling = true;
    try {
      await _logic.scroll.animateTo(
        target,
        duration: ComicReaderStyle.controls_duration(context) == Duration.zero
            ? Duration.zero
            : const Duration(milliseconds: ComicReaderStyle.page_scroll_ms),
        curve: Curves.easeOutCubic,
      );
    } finally {
      _page_scrolling = false;
    }
  }

  Widget _controls(
    BuildContext context, {
    required Widget child,
    required Offset hidden_offset,
  }) => IgnorePointer(
    ignoring: !_logic.controls_visible,
    child: ExcludeSemantics(
      excluding: !_logic.controls_visible,
      child: AnimatedSlide(
        offset: _logic.controls_visible ? Offset.zero : hidden_offset,
        duration: ComicReaderStyle.controls_duration(context),
        curve: ComicReaderStyle.controls_curve,
        child: AnimatedOpacity(
          opacity: _logic.controls_visible ? 1 : 0,
          duration: ComicReaderStyle.controls_duration(context),
          child: child,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_device == null) return _build_reader(context);
    return Obx(() {
      final dark = _device!.dark.value;
      return Theme(
        data: Theme.of(context).copyWith(
          brightness: dark ? Brightness.dark : Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: ColorConstants.themeColor,
            brightness: dark ? Brightness.dark : Brightness.light,
          ),
        ),
        child: Builder(builder: _build_reader),
      );
    });
  }

  Widget _build_reader(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_logic, _auto]),
    builder: (context, _) {
      final reading = _logic.reading;
      final media = MediaQuery.of(context);
      return PopScope(
        onPopInvokedWithResult: (did_pop, result) {
          if (did_pop) {
            _auto.stop();
            unawaited(_logic.flush());
          }
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: Theme.of(context).brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: ComicReaderStyle.canvas_color(context),
            body: WindowContentLayout(
              max_width: ComicReaderStyle.canvas_max_width,
              child: Stack(
                children: [
                  Positioned.fill(
                    // 与顶栏使用同一时长/曲线：当前图片随顶栏下移，避免实色栏盖住正文。
                    // 仅缩短纵向视口，保留原滚动控制器、图片宽度及章内阅读锚点。
                    child: AnimatedPadding(
                      padding: EdgeInsets.only(
                        top: _logic.controls_visible
                            ? media.viewPadding.top +
                                  ComicReaderStyle.top_bar_height(context)
                            : 0,
                      ),
                      duration: ComicReaderStyle.controls_duration(context),
                      curve: ComicReaderStyle.controls_curve,
                      child: _build_canvas(context, reading),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: _controls(
                      context,
                      hidden_offset: const Offset(0, -1),
                      child: ComicReaderTopScrim(
                        title: reading?.chapter.title ?? tr('comics.read'),
                        on_back: _on_back,
                        on_share: reading == null ? null : _on_share,
                        on_collect: _detail == null || _detail!.loading
                            ? null
                            : _detail!.collect,
                        collected: _detail?.collected ?? false,
                        collecting: _detail?.collecting ?? false,
                      ),
                    ),
                  ),
                  if (reading != null)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _controls(
                        context,
                        hidden_offset: const Offset(0, 1),
                        child: ComicReaderBottomScrim(
                          on_open_catalog: _on_catalog,
                          on_progress: _on_progress,
                          on_appearance: _on_appearance,
                          on_comments: _on_comments,
                          comment_count:
                              _comment_count ?? reading.comic.comment_count,
                        ),
                      ),
                    ),
                  if (_auto.running)
                    Positioned(
                      bottom:
                          media.viewPadding.bottom +
                          ComicReaderStyle.auto_button_inset,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AutoReadSettingsButton(
                          is_dark:
                              Theme.of(context).brightness == Brightness.dark,
                          on_tap: _on_auto_settings,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _build_canvas(BuildContext context, ComicReading? reading) {
    if (_logic.loading) return const ComicReaderSkeleton();
    if (reading == null || _logic.error != null) {
      return Center(
        child: ComicsEmptyState(
          loading: _logic.loading,
          error: _logic.error,
          message: tr('comics.unavailable'),
          foreground_color: ComicReaderStyle.foreground(context),
          on_retry: () => unawaited(
            _logic.load(
              _logic.current_chapter_id,
              initial_page: widget.initial_page,
            ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(
          0.0,
          WindowLayoutScope.resolve_max_width(
            context,
            ComicReaderStyle.canvas_max_width,
          ),
        );
        _logic.set_width(width);
        return GestureDetector(
          key: const ValueKey('comic_reader_touch_surface'),
          onTapUp: (details) => _on_canvas_tap(details, constraints.maxHeight),
          behavior: HitTestBehavior.opaque,
          child: NotificationListener<ScrollNotification>(
            onNotification: _on_scroll_notification,
            child: Center(
              child: SizedBox(
                width: width,
                child: CustomScrollView(
                  controller: _logic.scroll,
                  scrollCacheExtent: const ScrollCacheExtent.viewport(1.5),
                  slivers: [
                    SliverVariedExtentList.builder(
                      itemCount: reading.images.length,
                      itemExtentBuilder: (index, dimensions) =>
                          _logic.image_height(index),
                      itemBuilder: (context, index) => ComicReaderImage(
                        key: ValueKey('${reading.chapter.id}:$index'),
                        image: reading.images[index],
                        page_index: index,
                        width: width,
                        on_ratio: (ratio) => _logic.report_ratio(
                          index,
                          ratio,
                          chapter_id: reading.chapter.id,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ComicReaderChapterEnd(
                        has_next_chapter: reading.next_chapter_id > 0,
                        on_next_chapter: () {
                          _auto.stop();
                          unawaited(
                            _logic.load(
                              reading.next_chapter_id,
                              initial_page: 0,
                            ),
                          );
                        },
                        on_comments: _on_comments,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
