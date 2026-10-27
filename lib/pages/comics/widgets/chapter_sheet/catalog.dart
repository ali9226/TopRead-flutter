// ignore_for_file: non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:app/components/positioning/index.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/widgets/chapter_sheet/style.dart';
import 'package:app/pages/comics/widgets/chapter_sheet/chapter_tile.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 固定工具栏与懒加载章节列表共用定位状态；排序和窗口变化后保持当前阅读章节。
class ComicChapterCatalog extends StatefulWidget {
  const ComicChapterCatalog({
    super.key,
    required this.logic,
    this.current_chapter_id,
    this.on_open,
    this.shrink_wrap = false,
  });
  final bool shrink_wrap;
  final int? current_chapter_id;
  final ValueChanged<ComicChapter>? on_open;
  final ComicDetailLogic logic;

  @override
  State<ComicChapterCatalog> createState() => _ComicChapterCatalogState();
}

class _ComicChapterCatalogState extends State<ComicChapterCatalog> {
  bool _descending = false;
  bool _current_visible = true;
  bool _is_locating = false;
  final ScrollController _fallback_scroll = ScrollController();
  ScrollController? _scroll;
  double _row_extent = 0;
  int _current_display_index = -1;
  Object? _layout_signature;
  int _position_version = 0;
  int _locate_revision = 0;

  int? get _current_id =>
      widget.current_chapter_id ??
      widget.logic.resume_record?.chapter.id ??
      widget.logic.start_chapter_id;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = PrimaryScrollController.maybeOf(context) ?? _fallback_scroll;
    if (identical(next, _scroll)) return;
    _scroll?.removeListener(_check_current_visibility);
    _scroll = next..addListener(_check_current_visibility);
    _layout_signature = null;
  }

  @override
  void dispose() {
    _position_version++;
    _locate_revision++;
    _scroll?.removeListener(_check_current_visibility);
    _fallback_scroll.dispose();
    super.dispose();
  }

  /// 固定行高让远端章节也可以直接定位，保持千章目录的懒加载。
  Future<void> _locate_current({required bool animate}) async {
    final scroll = _scroll;
    final index = _current_display_index;
    if ((animate && _is_locating) ||
        index < 0 ||
        scroll == null ||
        !scroll.hasClients ||
        !scroll.position.hasContentDimensions) {
      return;
    }
    final position = scroll.position;
    final card_height = _row_extent - ComicChapterCatalogStyle.card_gap;
    final offset =
        (index * _row_extent - (position.viewportDimension - card_height) / 2)
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
    final revision = ++_locate_revision;
    _is_locating = true;
    try {
      if (animate && !MediaQuery.disableAnimationsOf(context)) {
        await scroll.animateTo(
          offset,
          duration: ComicChapterCatalogStyle.jump_duration,
          curve: Curves.easeInOutCubic,
        );
      } else {
        scroll.jumpTo(offset);
      }
    } finally {
      if (revision == _locate_revision) {
        _is_locating = false;
        if (mounted) _check_current_visibility();
      }
    }
  }

  void _check_current_visibility() {
    final scroll = _scroll;
    if (!mounted || scroll == null || !scroll.hasClients || _row_extent <= 0) {
      return;
    }
    final index = _current_display_index;
    final position = scroll.position;
    if (!position.hasContentDimensions) return;
    final top = index * _row_extent;
    final bottom = top + _row_extent - ComicChapterCatalogStyle.card_gap;
    final visible =
        index < 0 ||
        (bottom > position.pixels &&
            top < position.pixels + position.viewportDimension);
    if (visible != _current_visible) {
      setState(() => _current_visible = visible);
    }
  }

  void _schedule_current_position(Object signature) {
    if (_layout_signature == signature) return;
    _layout_signature = signature;
    final version = ++_position_version;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && version == _position_version) {
        unawaited(_locate_current(animate: false));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chapters = widget.logic.readable_chapters;
    final display = _descending ? chapters.reversed.toList() : chapters;
    final current_id = _current_id;
    final current_index = chapters.indexWhere(
      (chapter) => chapter.id == current_id,
    );
    _current_display_index = current_index < 0 || !_descending
        ? current_index
        : chapters.length - current_index - 1;
    final numbers = {
      for (var index = 0; index < chapters.length; index++)
        chapters[index].id: index + 1,
    };
    final dark = ComicDetailStyle.is_dark(context);
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final scaler = MediaQuery.textScalerOf(context);
    final title_extent =
        scaler.scale(
          cjk
              ? ComicChapterCatalogStyle.title_size_cjk
              : ComicChapterCatalogStyle.title_size_alphabetic,
        ) *
        ComicChapterCatalogStyle.title_height *
        2;
    final metadata_extent =
        scaler.scale(
          cjk
              ? ComicChapterCatalogStyle.metadata_size_cjk
              : ComicChapterCatalogStyle.metadata_size_alphabetic,
        ) *
        ComicChapterCatalogStyle.metadata_height;
    final row_extent =
        math.max(
          ComicChapterCatalogStyle.card_min_height,
          title_extent +
              metadata_extent +
              ComicChapterCatalogStyle.metadata_gap +
              ComicChapterCatalogStyle.card_padding * 2 +
              scaler.scale(ComicChapterCatalogStyle.font_metric_allowance),
        ) +
        ComicChapterCatalogStyle.card_gap;

    _row_extent = row_extent;
    return LayoutBuilder(
      builder: (context, constraints) {
        _schedule_current_position((
          current_id,
          chapters.length,
          _descending,
          row_extent,
          constraints.maxWidth,
          constraints.maxHeight,
        ));
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ComicChapterCatalogStyle.horizontal_padding,
              ),
              child: SizedBox(
                key: const ValueKey('comic_chapter_sheet_toolbar'),
                height: ComicChapterCatalogStyle.toolbar_height,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr(
                          'comics.chapter_count_label',
                          namedArgs: {'count': '${chapters.length}'},
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: cjk
                              ? ComicChapterCatalogStyle.count_size_cjk
                              : ComicChapterCatalogStyle.count_size_alphabetic,
                          color: ComicDetailStyle.muted(context),
                          fontWeight: ComicDetailStyle.weight_regular,
                        ),
                      ),
                    ),
                    const SizedBox(width: ComicChapterCatalogStyle.toolbar_gap),
                    Container(
                      width: cjk ? 124 : 150,
                      height: ComicChapterCatalogStyle.sort_height,
                      padding: const EdgeInsets.all(LayoutConfig.space_2),
                      decoration: BoxDecoration(
                        color: dark
                            ? ColorConstants
                                  .pages_comics_widgets_chapter_sheet_catalog_tone
                            : ColorConstants
                                  .pages_comics_widgets_chapter_sheet_catalog_tone_ffeeedeb,
                        borderRadius: BorderRadius.circular(
                          ComicChapterCatalogStyle.sort_radius,
                        ),
                      ),
                      child: Row(
                        children: [
                          _sort_option(context, descending: false, cjk: cjk),
                          _sort_option(context, descending: true, cjk: cjk),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.logic.loading)
              const LinearProgressIndicator(minHeight: 2),
            Flexible(
              fit: FlexFit.loose,
              child: Stack(
                key: const ValueKey('comic_chapter_sheet_list_region'),
                children: [
                  CustomScrollView(
                    key: const PageStorageKey('comic_chapters_scroll'),
                    controller: _scroll,
                    primary: false,
                    shrinkWrap: widget.shrink_wrap,
                    slivers: [
                      if (!widget.logic.loading && chapters.isEmpty)
                        SliverToBoxAdapter(
                          child: Center(
                            child: Text(
                              tr('comics.empty_chapters'),
                              style: TextStyle(
                                color: ComicDetailStyle.muted(context),
                              ),
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          ComicChapterCatalogStyle.horizontal_padding,
                          0,
                          ComicChapterCatalogStyle.horizontal_padding,
                          MediaQuery.paddingOf(context).bottom +
                              ComicChapterCatalogStyle.toolbar_gap,
                        ),
                        sliver: SliverFixedExtentList(
                          itemExtent: row_extent,
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final chapter = display[index];
                            final selected = chapter.id == current_id;
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: ComicChapterCatalogStyle.card_gap,
                              ),
                              child: ComicDetailChapterTile(
                                key: ValueKey(chapter.id),
                                number: numbers[chapter.id]!,
                                chapter: chapter,
                                is_dark: dark,
                                selected: selected,
                                on_open: () {
                                  if (widget.on_open != null) {
                                    widget.on_open!(chapter);
                                  } else {
                                    widget.logic.open_chapter(
                                      chapter.id,
                                      resume: selected,
                                    );
                                  }
                                },
                              ),
                            );
                          }, childCount: display.length),
                        ),
                      ),
                    ],
                  ),
                  PositioningButton(
                    key: const ValueKey('comic_chapter_sheet_location'),
                    show: chapters.isNotEmpty && !_current_visible,
                    is_dark: dark,
                    icon_color: ColorConstants.dangerColor,
                    right: ComicChapterCatalogStyle.location_inset,
                    bottom:
                        ComicChapterCatalogStyle.location_inset +
                        MediaQuery.paddingOf(context).bottom,
                    on_tap: () => unawaited(_locate_current(animate: true)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sort_option(
    BuildContext context, {
    required bool descending,
    required bool cjk,
  }) {
    final selected = descending == _descending;
    return Expanded(
      child: Tooltip(
        message: tr(
          descending ? 'comics.sort_descending' : 'comics.sort_ascending',
        ),
        child: Semantics(
          button: true,
          selected: selected,
          child: InkWell(
            onTap: () {
              if (_descending != descending) {
                setState(() => _descending = descending);
              }
            },
            splashFactory: NoSplash.splashFactory,
            highlightColor: ColorConstants.transparent,
            hoverColor: ColorConstants.transparent,
            focusColor: ColorConstants.transparent,
            borderRadius: BorderRadius.circular(
              ComicChapterCatalogStyle.sort_radius,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ComicChapterCatalogStyle.sort_padding,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? (ComicDetailStyle.is_dark(context)
                          ? ColorConstants
                                .pages_comics_widgets_chapter_sheet_catalog_tone_ff4a4028
                          : ColorConstants
                                .pages_comics_widgets_chapter_sheet_catalog_tone_fffff4cf)
                    : ColorConstants.transparent,
                borderRadius: BorderRadius.circular(
                  ComicChapterCatalogStyle.sort_radius,
                ),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tr(
                      descending
                          ? 'comics.order_descending'
                          : 'comics.order_ascending',
                    ),
                    style: TextStyle(
                      fontSize: cjk
                          ? ComicChapterCatalogStyle.sort_size_cjk
                          : ComicChapterCatalogStyle.sort_size_alphabetic,
                      color: selected
                          ? ComicDetailStyle.ink(context)
                          : ComicDetailStyle.muted(context),
                      fontWeight: ComicDetailStyle.weight_regular,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
