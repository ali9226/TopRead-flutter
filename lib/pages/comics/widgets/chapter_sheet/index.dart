// ignore_for_file: non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:app/pages/short_story_read/widgets/catalog/catalog_header.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/widgets/chapter_sheet/catalog.dart';
import 'package:app/pages/comics/widgets/chapter_sheet/style.dart';
import 'package:app/pages/comics/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// TODO 详情与阅读器共用目录入口；传入 on_open 时留在阅读器内切章，否则走详情的统一阅读路由。
Future<void> show_comic_chapter_sheet(
  BuildContext context, {
  required int comic_id,
  String? language,
  int? current_chapter_id,
  ValueChanged<ComicChapter>? on_open,
  ComicDetailLogic? controller,
}) {
  // 页面内容可能通过 WindowContentLayout 把 MediaQuery 宽度改为 600；
  // 背景属于根导航窗口，应从根 Navigator 取得真实窗口宽度。
  final window_context = Navigator.of(context, rootNavigator: true).context;
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: false,
    // 路由本身负责铺满底部，包括系统手势区；内容限宽仅作用于内部控件。
    backgroundColor: ComicChapterSheetStyle.background(
      ComicDetailStyle.is_dark(context),
    ),
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(ComicChapterSheetStyle.radius),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    constraints: BoxConstraints.tightFor(
      width: MediaQuery.sizeOf(window_context).width,
    ),
    builder: (context) => ComicChapterSheet(
      comic_id: comic_id,
      language: language,
      current_chapter_id: current_chapter_id,
      on_open: on_open,
      controller: controller,
    ),
  );
}

/// TODO 目录会话独立拥有加载与滚动状态；详情可注入已加载控制器以保留实时续读状态。
class ComicChapterSheet extends StatefulWidget {
  const ComicChapterSheet({
    super.key,
    required this.comic_id,
    this.language,
    this.current_chapter_id,
    this.on_open,
    this.controller,
  });
  final int comic_id;
  final String? language;
  final int? current_chapter_id;
  final ValueChanged<ComicChapter>? on_open;
  final ComicDetailLogic? controller;

  @override
  State<ComicChapterSheet> createState() => _ComicChapterSheetState();
}

class _ComicChapterSheetState extends State<ComicChapterSheet> {
  late final ComicDetailLogic _logic =
      widget.controller ?? ComicDetailLogic(widget.comic_id);
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    if (_logic.detail == null) _logic.load(language: widget.language);
  }

  @override
  void dispose() {
    _scroll.dispose();
    if (widget.controller == null) _logic.dispose();
    super.dispose();
  }

  void _open(ComicChapter chapter) {
    final resume =
        chapter.id ==
        (widget.current_chapter_id ?? _logic.resume_record?.chapter.id);
    Navigator.pop(context);
    if (widget.on_open != null) {
      widget.on_open!(chapter);
    } else {
      _logic.open_chapter(chapter.id, resume: resume);
    }
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.sizeOf(context).height *
            ComicChapterSheetStyle.height_ratio,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          key: const ValueKey('comic_chapter_sheet_surface'),
          color: ComicChapterSheetStyle.background(
            ComicDetailStyle.is_dark(context),
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(ComicChapterSheetStyle.radius),
          ),
          clipBehavior: Clip.antiAlias,
          child: WindowContentLayout(
            expand_height: false,
            max_width: ComicChapterSheetStyle.max_width,
            // 列表视口延伸到窗口底部；列表尾部和定位按钮各自避让手势区。
            child: AnimatedBuilder(
              animation: _logic,
              builder: (context, _) {
                final detail = _logic.detail;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CatalogHeader(
                      is_dark: ComicDetailStyle.is_dark(context),
                      title: tr('comics.chapters'),
                      on_close: () => Navigator.pop(context),
                    ),
                    Flexible(
                      fit: FlexFit.loose,
                      child: detail == null
                          ? Padding(
                              padding: const EdgeInsets.all(
                                LayoutConfig.space_24,
                              ),
                              child: ComicsEmptyState(
                                loading: _logic.loading,
                                error: _logic.error,
                                message: tr('comics.empty_chapters'),
                                on_retry: _logic.load,
                              ),
                            )
                          : PrimaryScrollController(
                              controller: _scroll,
                              child: ComicChapterCatalog(
                                logic: _logic,
                                current_chapter_id: widget.current_chapter_id,
                                on_open: _open,
                                shrink_wrap: true,
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
