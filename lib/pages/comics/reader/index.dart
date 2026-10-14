// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import 'package:app/models/comics.dart';
import 'package:app/pages/comics/reader/image_page.dart';
import 'package:app/pages/comics/reader/logic.dart';
import 'package:app/pages/comics/reader/style.dart';
import 'package:app/pages/comics/reader/widgets/bottom_scrim.dart';
import 'package:app/pages/comics/reader/widgets/chapter_end.dart';
import 'package:app/pages/comics/reader/widgets/progress_bar.dart';
import 'package:app/pages/comics/reader/widgets/top_scrim.dart';
import 'package:app/pages/comics/widgets/empty_state.dart';
import 'package:app/util/router/router_util.dart';

/// 漫画阅读页：全黑沉浸画布 + 顶部/底部渐变遮罩控件 + 章节收尾引导。
///
/// 轻触任意位置切换控件显隐；控件隐藏时画布完全贴边。
class ComicReaderPage extends StatefulWidget {
  /// 章节 ID。
  final int chapter_id;

  /// 起始页码（从 0 开始）。
  final int initial_page;

  const ComicReaderPage({
    super.key,
    required this.chapter_id,
    this.initial_page = 0,
  });

  @override
  State<ComicReaderPage> createState() => _ComicReaderPageState();
}

class _ComicReaderPageState extends State<ComicReaderPage>
    with WidgetsBindingObserver {
  /// 阅读逻辑控制器。
  final ComicReaderLogic _logic = ComicReaderLogic();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _logic.load(widget.chapter_id, initial_page: widget.initial_page);
  }

  /// 应用退到后台时立即持久化进度。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_logic.save_progress());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logic.dispose();
    super.dispose();
  }

  /// 返回上一页；栈底时回首页。
  void _on_back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      routerUtil(path: '/', type: 'replace');
    }
  }

  /// 打开作品目录。
  void _on_open_catalog() {
    final reading = _logic.reading;
    if (reading == null) return;
    routerUtil(path: '/comics/detail?id=${reading.comic.id}');
  }

  /// 打开章节评论。
  void _on_open_comments() {
    final reading = _logic.reading;
    if (reading == null) return;
    routerUtil(
      path:
          '/comics/comments?comic_id=${reading.comic.id}&chapter_id=${reading.chapter.id}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _logic,
      builder: (context, child) {
        final reading = _logic.reading;
        return Scaffold(
          backgroundColor: ComicReaderStyle.canvas_background,
          body: _build_body(context, reading),
        );
      },
    );
  }

  /// 页面主体：画布 + 顶部控件 + 底部控件，全层叠布局。
  Widget _build_body(BuildContext context, ComicReading? reading) {
    return Stack(
      children: <Widget>[
        /// 沉浸式阅读画布。
        Positioned.fill(child: _build_canvas(context, reading)),

        /// 顶部细进度条（常驻，贴最上沿）。
        if (reading != null && reading.images.length > 1)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ComicReaderProgressBar(
              page_index: _logic.page_index,
              page_count: reading.images.length,
            ),
          ),

        /// 顶部渐变工具条（显隐带动画）。
        AnimatedPositioned(
          duration: const Duration(
            milliseconds: ComicReaderStyle.controls_animation_ms,
          ),
          curve: ComicReaderStyle.controls_curve,
          top: _logic.controls_visible
              ? 0
              : -(MediaQuery.paddingOf(context).top +
                    ComicReaderStyle.top_bar_height +
                    8),
          left: 0,
          right: 0,
          child: reading == null
              ? const SizedBox.shrink()
              : ComicReaderTopScrim(
                  title: reading.chapter.title,
                  on_back: _on_back,
                  on_open_catalog: _on_open_catalog,
                  on_comments: _on_open_comments,
                ),
        ),

        /// 底部渐变控制条（显隐带动画）。
        if (reading != null)
          AnimatedPositioned(
            duration: const Duration(
              milliseconds: ComicReaderStyle.controls_animation_ms,
            ),
            curve: ComicReaderStyle.controls_curve,
            left: 0,
            right: 0,
            bottom: _logic.controls_visible
                ? 0
                : -ComicReaderStyle.controls_slide_offset -
                      MediaQuery.paddingOf(context).bottom,
            child: ComicReaderBottomScrim(
              page_index: _logic.page_index,
              page_count: reading.images.length,
              has_previous_chapter: reading.previous_chapter_id > 0,
              has_next_chapter: reading.next_chapter_id > 0,
              on_previous_chapter: () => _logic.load(reading.previous_chapter_id),
              on_next_chapter: () => _logic.load(reading.next_chapter_id),
            ),
          ),
      ],
    );
  }

  /// 沉浸式阅读画布：加载态或长条图片流。
  Widget _build_canvas(BuildContext context, ComicReading? reading) {
    if (_logic.loading || reading == null) {
      return Center(
        child: ComicsEmptyState(
          loading: _logic.loading,
          error: _logic.error,
          message: tr('comics.unavailable'),
          foreground_color: Colors.white70,
          on_retry: () => _logic.load(_logic.current_chapter_id),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.clamp(
          0.0,
          ComicReaderStyle.canvas_max_width,
        );
        _logic.set_width(width);
        return GestureDetector(
          onTap: _logic.toggle_controls,
          behavior: HitTestBehavior.translucent,
          child: Center(
            child: SizedBox(
              width: width,
              child: CustomScrollView(
                controller: _logic.scroll,
                scrollCacheExtent: const ScrollCacheExtent.viewport(1.5),
                slivers: <Widget>[
                  /// 变高图片流：只构建视口附近的图片。
                  SliverVariedExtentList.builder(
                    itemCount: reading.images.length,
                    itemExtentBuilder: (index, dimensions) =>
                        _logic.image_height(index),
                    itemBuilder: (context, index) => ComicReaderImage(
                      key: ValueKey('${reading.chapter.id}:$index'),
                      image: reading.images[index],
                      page_index: index,
                      width: width,
                      on_ratio: (ratio) => _logic.report_ratio(index, ratio),
                    ),
                  ),

                  /// 章节收尾引导。
                  SliverToBoxAdapter(
                    child: ComicReaderChapterEnd(
                      has_next_chapter: reading.next_chapter_id > 0,
                      on_next_chapter: () => _logic.load(reading.next_chapter_id),
                      on_comments: _on_open_comments,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
