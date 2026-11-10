import 'dart:math' as math;
import 'package:app/components/comment_list/index.dart';
import 'package:app/components/positioning/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'logic.dart';
import 'style.dart';
import 'widgets/book_detail_header.dart';
import 'widgets/book_detail_header_style.dart';
import 'widgets/book_header_backdrop.dart';
import 'widgets/book_introduction.dart';
import 'widgets/chapter_card.dart';
import 'widgets/continue_reading.dart';
import 'widgets/measure_size.dart';
import 'widgets/keep_alive_panel.dart';

/// TODO 作品 Hero 与目录/详情/书评三页组成的可横滑阅读面板。
class ReadDirectorySheet extends StatefulWidget {
  const ReadDirectorySheet({
    super.key,
    required this.logic,
    required this.is_dark,
    required this.current_chapter_progress_percent,
    this.on_chapter_tap,
    this.on_continue,
  });
  final Logic logic;
  final bool is_dark;
  final double current_chapter_progress_percent;
  final ValueChanged<int>? on_chapter_tap;
  final VoidCallback? on_continue;

  static Future<void> show({
    required BuildContext context,
    required Logic logic,
    required bool is_dark,
    required double current_chapter_progress_percent,
    ValueChanged<int>? on_chapter_tap,
    VoidCallback? on_continue,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: ColorConstants.transparent,
    constraints: const BoxConstraints(maxWidth: LayoutConfig.reader_max_width),
    builder: (_) => ReadDirectorySheet(
      logic: logic,
      is_dark: is_dark,
      current_chapter_progress_percent: current_chapter_progress_percent,
      on_chapter_tap: on_chapter_tap,
      on_continue: on_continue,
    ),
  );
  @override
  State<ReadDirectorySheet> createState() => _ReadDirectorySheetState();
}

class _ReadDirectorySheetState extends State<ReadDirectorySheet>
    with
        SingleTickerProviderStateMixin,
        ReadDirectoryInteractions<ReadDirectorySheet> {
  @override
  Logic get reader_logic => widget.logic;

  void _open_chapter(int index) {
    Navigator.of(context).pop();
    widget.on_chapter_tap?.call(index);
  }

  void _continue() {
    Navigator.of(context).pop();
    widget.on_continue?.call();
  }

  /// TODO 评论区使用同一份真实总数同步 Tab、Hero 和阅读页底栏。
  void _update_comment_count(int count) {
    if (!mounted) return;
    final next_count = math.max(0, count);
    if (widget.logic.comment_count == next_count) return;
    setState(() => widget.logic.update_comment_count(next_count));
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final is_comments_active = active_tab_index == 2;
    final actual_keyboard = MediaQuery.viewInsetsOf(context).bottom;
    // TODO 评论编辑器沿用公共组件的根 Overlay，键盘不再二次抬高整张面板。
    final keyboard = is_comments_active ? 0.0 : actual_keyboard;
    final detail = widget.logic.build_detail();
    final novel = widget.logic.store.novel_info.value;
    final cjk = LanguageUtil.is_cjk_language(context.locale.languageCode);
    final text_scaler = MediaQuery.textScalerOf(context);
    final has_chapters = widget.logic.chapter_list.isNotEmpty;
    final current = widget.logic.current_chapter_index.value
        .clamp(0, math.max(0, widget.logic.chapter_list.length - 1))
        .toInt();
    return AnimatedPadding(
      duration: ReadDirectorySheetStyle.transition_duration,
      padding: EdgeInsets.only(bottom: keyboard),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = math.min(
            screen.height * ReadDirectorySheetStyle.sheet_height_ratio,
            constraints.hasBoundedHeight
                ? constraints.maxHeight
                : screen.height,
          );
          final compact =
              screen.height < ReadDirectorySheetStyle.compact_height;
          final footer_estimate =
              text_scaler.scale(cjk ? 18 : 17) * 1.3 +
              (compact ? 28 : text_scaler.scale(cjk ? 12 : 11) * 1.3 + 40) +
              MediaQuery.paddingOf(context).bottom;
          final hero_limit = math.max(
            0.0,
            math.min(
              height * ReadDirectorySheetStyle.hero_max_height_ratio,
              height -
                  ReadDirectorySheetStyle.chrome_height -
                  ReadDirectorySheetStyle.tab_bar_height -
                  footer_estimate -
                  120,
            ),
          );
          final show_hero = actual_keyboard == 0 && hero_limit >= 65;
          final keyboard_focus_mode =
              actual_keyboard > 0 &&
              (height < 350 ||
                  screen.height < ReadDirectorySheetStyle.compact_height);
          final bg = ReadDirectorySheetStyle.getSheetColor(widget.is_dark);
          return SizedBox(
            height: height,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(
                  ReadDirectorySheetStyle.sheet_border_radius,
                ),
              ),
              child: Material(
                color: ReadDirectorySheetStyle.hero_surface(widget.is_dark),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: ColorConstants.whiteColor.withValues(alpha: .3),
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(
                        ReadDirectorySheetStyle.sheet_border_radius,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (!keyboard_focus_mode)
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              bottom: -ReadDirectorySheetStyle.body_radius,
                              child: BookHeaderBackdrop(
                                key: const ValueKey(
                                  'read_directory_header_backdrop',
                                ),
                                cover_url: detail.cover_url,
                                is_dark: widget.is_dark,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _chrome(context),
                                if (show_hero)
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight: hero_limit,
                                    ),
                                    child: SingleChildScrollView(
                                      child: BookDetailHeader(
                                        detail: detail,
                                        is_dark: widget.is_dark,
                                        show_backdrop: false,
                                        chapter_count:
                                            widget.logic.chapter_list.length,
                                        favorite_count: novel?.favorite_count,
                                        subtitle: novel?.subtitle ?? '',
                                        on_focus_changed:
                                            widget.logic.update_focus_on,
                                      ),
                                    ),
                                  ),
                                _tabs(context, cjk, detail.comment_count),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ],
                        ),
                      Expanded(
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(
                                ReadDirectorySheetStyle.body_radius,
                              ),
                            ),
                          ),
                          child: TabBarView(
                            key: const ValueKey('read_directory_tab_view'),
                            controller: tab_controller,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              DirectoryKeepAlivePanel(child: _catalog()),
                              DirectoryKeepAlivePanel(
                                child: BookIntroduction(
                                  detail: detail,
                                  is_dark: widget.is_dark,
                                ),
                              ),
                              DirectoryKeepAlivePanel(
                                child: CommentSheet(
                                  key: ValueKey((
                                    'directory_reviews',
                                    detail.story_id,
                                  )),
                                  novel_id: detail.story_id,
                                  on_close: () {},
                                  embedded: true,
                                  active: is_comments_active,
                                  is_dark: widget.is_dark,
                                  on_count_changed: _update_comment_count,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (keyboard == 0 && !is_comments_active)
                        ColoredBox(
                          color: bg,
                          child: DirectoryContinueReading(
                            on_pressed: has_chapters ? _continue : null,
                            chapter_no: has_chapters
                                ? widget.logic.chapter_list[current].chapter_no
                                : 0,
                            progress: widget.current_chapter_progress_percent,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chrome(BuildContext context) => SizedBox(
    height: ReadDirectorySheetStyle.chrome_height,
    child: Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: ReadDirectorySheetStyle.handle_width,
              height: ReadDirectorySheetStyle.handle_height,
              decoration: BoxDecoration(
                color: ColorConstants.whiteColor.withValues(alpha: .85),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 0,
          child: IconButton(
            key: const ValueKey('read_directory_close'),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            style: IconButton.styleFrom(
              backgroundColor: ColorConstants.lightTextColor.withValues(
                alpha: .3,
              ),
              foregroundColor: ColorConstants.whiteColor,
              minimumSize: const Size.square(
                ReadDirectorySheetStyle.close_target,
              ),
              fixedSize: const Size.square(
                ReadDirectorySheetStyle.close_target,
              ),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(
              Icons.close_rounded,
              size: ReadDirectorySheetStyle.close_icon,
              shadows: BookDetailHeaderStyle.title_shadows,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _tabs(BuildContext context, bool cjk, int? comment_count) {
    final has_comments = (comment_count ?? 0) > 0;
    final labels = [
      tr('read.catalog'),
      tr('read.detail'),
      has_comments
          ? NumberFormat.compact(
              locale: context.locale.toString(),
            ).format(comment_count)
          : tr('read.directory_reviews'),
    ];
    const icons = [
      Icons.menu_book_outlined,
      Icons.info_outline_rounded,
      Icons.chat_bubble_outline_rounded,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ReadDirectorySheetStyle.tab_horizontal_padding,
      ),
      child: Container(
        height: ReadDirectorySheetStyle.tab_bar_height,
        decoration: BoxDecoration(
          color: ReadDirectorySheetStyle.tab_surface(widget.is_dark),
          borderRadius: BorderRadius.circular(
            ReadDirectorySheetStyle.sheet_border_radius,
          ),
          border: Border.all(
            color: ColorConstants.whiteColor.withValues(alpha: .20),
          ),
        ),
        child: TabBar(
          controller: tab_controller,
          labelColor: ColorConstants.lightTextColor,
          unselectedLabelColor: ColorConstants.whiteColor.withValues(
            alpha: .88,
          ),
          dividerColor: ColorConstants.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(3),
          labelPadding: const EdgeInsets.symmetric(
            horizontal: ReadDirectorySheetStyle.tab_label_padding,
          ),
          labelStyle: TextStyle(
            fontSize: cjk
                ? ReadDirectorySheetStyle.tab_font_size_cjk
                : ReadDirectorySheetStyle.tab_font_size_alphabetic,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: cjk
                ? ReadDirectorySheetStyle.tab_font_size_cjk
                : ReadDirectorySheetStyle.tab_font_size_alphabetic,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
            shadows: BookDetailHeaderStyle.title_shadows,
          ),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ReadDirectorySheetStyle.sheet_border_radius,
            ),
            gradient: LinearGradient(
              colors: [
                Color.lerp(
                  ColorConstants.themeColor,
                  ColorConstants.whiteColor,
                  .25,
                )!,
                ColorConstants.themeColor,
              ],
            ),
          ),
          tabs: [
            for (var i = 0; i < labels.length; i++)
              Tab(
                child: Tooltip(
                  message: i == 2 && has_comments
                      ? '${tr('read.directory_reviews')} ($comment_count)'
                      : labels[i],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icons[i],
                        size: ReadDirectorySheetStyle.tab_icon_size,
                      ),
                      const SizedBox(width: ReadDirectorySheetStyle.tab_gap),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(labels[i], maxLines: 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _catalog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) try_initial_scroll();
    });
    final indices = visible_chapter_indices;
    final ink = ReadDirectorySheetStyle.getPrimaryTextColor(widget.is_dark);
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          if (!is_search_visible || constraints.maxHeight >= 160) _toolbar(),
          if (is_search_visible)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                key: const ValueKey('read_directory_search_field'),
                controller: query_controller,
                autofocus: true,
                onChanged: change_query,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  hintText: tr('read.directory_search_hint'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  filled: true,
                  fillColor: ink.withValues(alpha: .045),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  suffixIcon: IconButton(
                    tooltip: tr('creator_center.clear_search'),
                    onPressed: () {
                      query_controller.clear();
                      change_query('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                SizedBox.expand(
                  key: catalog_viewport_key,
                  child: NotificationListener<ScrollMetricsNotification>(
                    onNotification: (_) {
                      on_catalog_scroll();
                      return false;
                    },
                    child: ListView.separated(
                      key: const ValueKey('read_directory_catalog_list'),
                      controller: catalog_scroll_controller,
                      padding: ReadDirectorySheetStyle.catalog_list_padding,
                      itemCount: indices.length,
                      separatorBuilder: (_, _) => const SizedBox(
                        height:
                            ReadDirectorySheetStyle.chapter_separator_height,
                      ),
                      itemBuilder: (context, position) {
                        final index = indices[position];
                        return DirectoryMeasureSize(
                          key: chapter_item_key(index),
                          on_change: (size) => record_chapter_size(index, size),
                          child: DirectoryChapterCard(
                            key: ValueKey('read_directory_chapter_$index'),
                            chapter: widget.logic.chapter_list[index],
                            is_current:
                                index ==
                                widget.logic.current_chapter_index.value,
                            is_dark: widget.is_dark,
                            progress_percent:
                                widget.current_chapter_progress_percent,
                            on_tap: () => _open_chapter(index),
                            on_continue: _continue,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (indices.isEmpty)
                  IgnorePointer(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(
                          ReadDirectorySheetStyle.catalog_padding,
                        ),
                        child: Text(
                          tr('read.directory_no_results'),
                          style: TextStyle(color: ink),
                        ),
                      ),
                    ),
                  ),
                if (widget.logic.chapter_list.isNotEmpty)
                  PositioningButton(
                    key: const ValueKey('read_directory_position'),
                    show: show_position_button,
                    is_dark: widget.is_dark,
                    icon_color: ColorConstants.dangerColor,
                    right: ReadDirectorySheetStyle.position_button_right,
                    bottom:
                        ReadDirectorySheetStyle.position_button_bottom_spacing,
                    on_tap: () => scroll_to_current_chapter(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar() {
    final cjk = LanguageUtil.is_cjk_language(context.locale.languageCode);
    final ink = ReadDirectorySheetStyle.getPrimaryTextColor(widget.is_dark);
    final style = TextStyle(
      color: ink.withValues(alpha: .7),
      fontSize: cjk
          ? ReadDirectorySheetStyle.toolbar_font_size_cjk
          : ReadDirectorySheetStyle.toolbar_font_size_alphabetic,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ReadDirectorySheetStyle.catalog_padding,
        vertical: 6,
      ),
      child: SizedBox(
        height: ReadDirectorySheetStyle.toolbar_height,
        child: Row(
          children: [
            Expanded(
              child: Text(
                tr(
                  'read.directory_all_chapters',
                  namedArgs: {
                    'count': widget.logic.chapter_list.length.toString(),
                  },
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
            IconButton(
              key: const ValueKey('read_directory_search_toggle'),
              tooltip: tr('read.directory_search'),
              onPressed: toggle_search,
              icon: Icon(
                is_search_visible
                    ? Icons.search_off_rounded
                    : Icons.search_rounded,
              ),
              style: IconButton.styleFrom(
                backgroundColor: ReadDirectorySheetStyle.getCardColor(
                  widget.is_dark,
                ),
                foregroundColor: ink,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: PopupMenuButton<bool>(
                key: const ValueKey('read_directory_sort'),
                initialValue: sort_descending,
                onSelected: change_sort,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: false,
                    child: Text(tr('comics.sort_ascending')),
                  ),
                  PopupMenuItem(
                    value: true,
                    child: Text(tr('comics.sort_descending')),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: ReadDirectorySheetStyle.getCardColor(widget.is_dark),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_vert_rounded, color: ink, size: 18),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          tr(
                            sort_descending
                                ? 'comics.sort_descending'
                                : 'comics.sort_ascending',
                          ),
                          style: style.copyWith(color: ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: ink,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
