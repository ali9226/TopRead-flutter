// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/widgets/chapter_sheet/style.dart';
import 'package:app/pages/comics/widgets/chapter_sheet/chapter_tile.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// TODO 懒加载章节目录复用 NestedScrollView 的 primary 控制器，排序保留原始编号与续读记录。
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

  /// TODO 以同一个固定行高计算跳转偏移，未构建的远端章节也能直接定位，不需创建全部卡片。
  void _jump_to_current(double row_extent) {
    final chapters = widget.logic.readable_chapters;
    final target = chapters.indexWhere(
      (chapter) =>
          chapter.id ==
          (widget.current_chapter_id ?? widget.logic.start_chapter_id),
    );
    final scroll = PrimaryScrollController.maybeOf(context);
    if (target < 0 || scroll == null || !scroll.hasClients) return;
    final index = _descending ? chapters.length - target - 1 : target;
    final position = scroll.positions.last;
    final offset =
        (ComicChapterCatalogStyle.toolbar_height + index * row_extent)
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
    scroll.animateTo(
      offset,
      duration: ComicChapterCatalogStyle.jump_duration,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapters = widget.logic.readable_chapters;
    final display = _descending ? chapters.reversed.toList() : chapters;
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
    final metadata_extent = math.max(
      ComicChapterCatalogStyle.arrow_size,
      scaler.scale(
            math.max(
              ComicChapterCatalogStyle.number_size,
              cjk
                  ? ComicChapterCatalogStyle.metadata_size_cjk
                  : ComicChapterCatalogStyle.metadata_size_alphabetic,
            ),
          ) *
          ComicChapterCatalogStyle.metadata_height,
    );
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

    return CustomScrollView(
      shrinkWrap: widget.shrink_wrap,
      key: const PageStorageKey('comic_chapters_scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: ComicChapterCatalogStyle.horizontal_padding,
          ),
          sliver: SliverToBoxAdapter(
            child: SizedBox(
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
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFF2C3039)
                          : const Color(0xFFEEEDEB),
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
                  const SizedBox(width: ComicChapterCatalogStyle.toolbar_gap),
                  IconButton(
                    tooltip: tr('comics.jump_to_current'),
                    onPressed: chapters.isEmpty
                        ? null
                        : () => _jump_to_current(row_extent),
                    style: IconButton.styleFrom(
                      backgroundColor: ComicDetailStyle.card_background(dark),
                    ),
                    icon: Icon(
                      Icons.playlist_play_rounded,
                      color: ComicDetailStyle.muted(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.logic.loading)
          const SliverToBoxAdapter(
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (!widget.logic.loading && chapters.isEmpty)
          SliverToBoxAdapter(
            child: Center(
              child: Text(
                tr('comics.empty_chapters'),
                style: TextStyle(color: ComicDetailStyle.muted(context)),
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
            delegate: SliverChildBuilderDelegate((context, index) {
              final chapter = display[index];
              final selected =
                  chapter.id ==
                  (widget.current_chapter_id ??
                      widget.logic.resume_record?.chapter.id);
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
                      widget.logic.open_chapter(chapter.id, resume: selected);
                    }
                  },
                ),
              );
            }, childCount: display.length),
          ),
        ),
      ],
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
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
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
                          ? const Color(0xFF4A4028)
                          : const Color(0xFFFFF4CF))
                    : Colors.transparent,
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
