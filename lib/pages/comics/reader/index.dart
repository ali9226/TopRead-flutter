import 'package:app/components/window_content_layout/index.dart';
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
import 'package:app/pages/comics/reader/widgets/top_scrim.dart';
import 'package:app/pages/comics/widgets/empty_state.dart';
import 'package:app/util/router/router_util.dart';

/// TODO 阅读画布按需加载原比例图片，操作底板覆盖安全区并使用自身高度滑出，字号增大也不会残留。
class ComicReaderPage extends StatefulWidget {
  final int chapter_id;
  final int? initial_page;
  final ComicReaderLogic? controller;
  const ComicReaderPage({
    super.key,
    required this.chapter_id,
    this.initial_page,
    this.controller,
  });
  @override
  State<ComicReaderPage> createState() => _ComicReaderPageState();
}

class _ComicReaderPageState extends State<ComicReaderPage>
    with WidgetsBindingObserver {
  late final ComicReaderLogic _logic;
  @override
  void initState() {
    super.initState();
    _logic = widget.controller ?? ComicReaderLogic();
    WidgetsBinding.instance.addObserver(this);
    unawaited(
      _logic.load(widget.chapter_id, initial_page: widget.initial_page),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_logic.flush());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logic.dispose();
    super.dispose();
  }

  void _on_back() {
    unawaited(_logic.flush());
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      routerUtil(path: '/', type: 'replace');
    }
  }

  void _on_open_catalog() {
    final reading = _logic.reading;
    if (reading == null) return;
    unawaited(_logic.flush());
    routerUtil(
      path:
          '/comics/detail?id=${reading.comic.id}&language=${reading.language.language}',
    );
  }

  void _on_open_comments() {
    final reading = _logic.reading;
    if (reading == null) return;
    unawaited(_logic.flush());
    routerUtil(
      path:
          '/comics/comments?comic_id=${reading.comic.id}&chapter_id=${reading.chapter.id}',
    );
  }

  Widget _controls({required Widget child, required Offset hidden_offset}) =>
      IgnorePointer(
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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _logic,
    builder: (context, child) {
      final reading = _logic.reading;
      return PopScope(
        onPopInvokedWithResult: (did_pop, result) {
          if (did_pop) unawaited(_logic.flush());
        },
        child: Scaffold(
          backgroundColor: ComicReaderStyle.canvas_background,
          body: Stack(
            children: <Widget>[
              Positioned.fill(child: _build_canvas(reading)),
              Align(
                alignment: Alignment.topCenter,
                child: _controls(
                  hidden_offset: const Offset(0, -1),
                  child: ComicReaderTopScrim(
                    title: reading?.chapter.title ?? tr('comics.read'),
                    comic_title: reading?.comic.title ?? '',
                    on_back: _on_back,
                    on_open_catalog: _on_open_catalog,
                    on_comments: _on_open_comments,
                  ),
                ),
              ),
              if (reading != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _controls(
                    hidden_offset: const Offset(0, 1),
                    child: ComicReaderBottomScrim(
                      page_index: _logic.page_index,
                      page_count: reading.images.length,
                      has_previous_chapter:
                          !_logic.loading && reading.previous_chapter_id > 0,
                      has_next_chapter:
                          !_logic.loading && reading.next_chapter_id > 0,
                      on_previous_chapter: () => unawaited(
                        _logic.load(
                          reading.previous_chapter_id,
                          initial_page: 0,
                        ),
                      ),
                      on_next_chapter: () => unawaited(
                        _logic.load(reading.next_chapter_id, initial_page: 0),
                      ),
                      on_open_catalog: _on_open_catalog,
                      on_comments: _on_open_comments,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  Widget _build_canvas(ComicReading? reading) {
    if (_logic.loading || reading == null || _logic.error != null) {
      return Center(
        child: ComicsEmptyState(
          loading: _logic.loading,
          error: _logic.error,
          message: tr('comics.unavailable'),
          foreground_color: Colors.white70,
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
          onTap: _logic.toggle_controls,
          behavior: HitTestBehavior.translucent,
          child: Center(
            child: SizedBox(
              width: width,
              child: CustomScrollView(
                controller: _logic.scroll,
                scrollCacheExtent: const ScrollCacheExtent.viewport(1.5),
                slivers: <Widget>[
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
                      on_next_chapter: () => unawaited(
                        _logic.load(reading.next_chapter_id, initial_page: 0),
                      ),
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
