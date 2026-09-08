// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/components/bottom_sheet_drag_handle/index.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/util/dialog/show_message.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

/// 正文只显示当前章，目录按需打开并虚拟化构建。
class LongContentEditor extends StatefulWidget {
  final bool is_dark;
  final bool is_editing;
  final List<CreatorChapterDraft> chapters;
  final int active_chapter_index;
  final int chapter_word_count;
  final TextEditingController chapter_title_controller;
  final TextEditingController chapter_content_controller;
  final int current_word_count;
  final VoidCallback on_content_changed;
  final VoidCallback on_file_upload;
  final VoidCallback on_save_current_chapter;
  final ValueChanged<int> on_edit_chapter;
  final ValueChanged<int> on_delete_chapter;
  final void Function(int oldIndex, int newIndex) on_reorder_chapters;

  const LongContentEditor({
    super.key,
    required this.is_dark,
    required this.is_editing,
    required this.chapters,
    this.active_chapter_index = -1,
    required this.chapter_word_count,
    required this.chapter_title_controller,
    required this.chapter_content_controller,
    required this.current_word_count,
    required this.on_content_changed,
    required this.on_file_upload,
    required this.on_edit_chapter,
    required this.on_save_current_chapter,
    required this.on_delete_chapter,
    required this.on_reorder_chapters,
  });

  @override
  State<LongContentEditor> createState() => _LongContentEditorState();
}

class _LongContentEditorState extends State<LongContentEditor> {
  final _scroll = ScrollController();
  String? get _activeId =>
      widget.active_chapter_index >= 0 &&
          widget.active_chapter_index < widget.chapters.length
      ? widget.chapters[widget.active_chapter_index].local_id
      : null;
  String? _lastActiveId;

  @override
  void didUpdateWidget(LongContentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_lastActiveId != _activeId) {
      _lastActiveId = _activeId;
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openDirectory() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final action = await showModalBottomSheet<_ChapterAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChapterDirectory(
        chapters: List.of(widget.chapters),
        activeIndex: widget.active_chapter_index,
        isDark: widget.is_dark,
        onReorder: widget.on_reorder_chapters,
      ),
    );
    if (!mounted || action == null) return;
    switch (action.kind) {
      case 'new':
        widget.on_save_current_chapter();
      case 'delete':
        widget.on_delete_chapter(action.index);
      default:
        widget.on_edit_chapter(action.index);
    }
  }

  Future<void> _showChapterActions(BuildContext context, int index) async {
    final dark = widget.is_dark;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AuthorStyle.surface(dark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BottomSheetDragHandle(is_dark: dark),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: SvgIcon(
                    name: 'upgrade',
                    width: 20,
                    height: 20,
                    color: AuthorStyle.primary_text(dark),
                  ),
                  title: Text(easy.tr('creator_center.import_from_file')),
                  onTap: () => Navigator.pop(context, 'import'),
                ),
              ),
              if (index >= 0)
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: SvgIcon(
                      name: 'delete',
                      width: 20,
                      height: 20,
                      color: ColorConstants.dangerColor,
                    ),
                    title: Text(
                      easy.tr('creator_center.delete_this_chapter'),
                      style: TextStyle(color: ColorConstants.dangerColor),
                    ),
                    onTap: () => Navigator.pop(context, 'delete'),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'import') {
      widget.on_file_upload();
    } else if (action == 'delete' && index >= 0) {
      await _confirmDeleteChapter(index);
    }
  }

  Future<void> _confirmDeleteChapter(int index) async {
    bool confirmed = false;
    await showMessage(
      message: easy.tr('creator_center.delete_chapter_confirm'),
      iconData: Icons.delete_outline_rounded,
      iconColor: ColorConstants.dangerColor,
      leftButtonText: easy.tr('common.cancel'),
      rightButtonText: easy.tr('creator_center.delete'),
      rightButtonColor: ColorConstants.dangerColor,
      onRightPressed: () async => confirmed = true,
    );
    if (confirmed && mounted) {
      widget.on_delete_chapter(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.is_dark;
    final primary = AuthorStyle.primary_text(dark);
    final secondary = AuthorStyle.secondary_text(dark);
    final accent = dark ? Colors.white : ColorConstants.lightTextColor;
    final index = widget.active_chapter_index;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    key: const ValueKey('chapter_directory_button'),
                    onTap: _openDirectory,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgIcon(
                          name: 'bookshelf_selected',
                          width: 18,
                          height: 18,
                          color: dark ? Colors.white : ColorConstants.lightTextColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          easy.tr('creator_center.chapter_directory'),
                          style: TextStyle(
                            color: accent,
                            fontSize: 14,
                            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, color: accent, size: 18),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.on_save_current_chapter,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: ColorConstants.themeColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.add_rounded, size: 18, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AuthorStyle.border(dark)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              index < 0
                                  ? easy.tr('creator_center.start_first_chapter')
                                  : easy.tr('creator_center.chapter_number', namedArgs: {'number': '${index + 1}'}),
                              style: TextStyle(
                                color: accent,
                                fontSize: 15,
                                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: easy.tr('creator_center.previous_chapter'),
                            onPressed: index > 0
                                ? () => widget.on_edit_chapter(index - 1)
                                : null,
                            icon: const Icon(Icons.chevron_left_rounded),
                          ),
                          IconButton(
                            tooltip: easy.tr('creator_center.next_chapter'),
                            onPressed:
                                index >= 0 && index + 1 < widget.chapters.length
                                ? () => widget.on_edit_chapter(index + 1)
                                : null,
                            icon: const Icon(Icons.chevron_right_rounded),
                          ),
                          GestureDetector(
                            onTap: () => _showChapterActions(context, index),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8,3, 8),
                              child: SvgIcon(
                                name: 'three_dots',
                                width: 20,
                                height: 20,
                                color: secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              key: const ValueKey('chapter_title_input'),
                              controller: widget.chapter_title_controller,
                              maxLines: null,
                              style: TextStyle(
                                color: primary,
                                fontSize: 23,
                                height: 1.4,
                                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                              ),
                              decoration: InputDecoration(
                                hintText: easy.tr('creator_center.chapter_title_hint'),
                                hintStyle: TextStyle(
                                  color: secondary.withValues(alpha: .7),
                                  fontWeight: FontWeight.normal,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              key: const ValueKey('chapter_content_input'),
                              controller: widget.chapter_content_controller,
                              minLines: 16,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              style: TextStyle(
                                color: primary,
                                fontSize: 16,
                                height: 1.9,
                                letterSpacing: .3,
                              ),
                              decoration: InputDecoration(
                                hintText: easy.tr('creator_center.chapter_content_hint'),
                                hintStyle: TextStyle(
                                  color: secondary.withValues(alpha: .65),
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '共${widget.chapters.length}章',
                    style: TextStyle(color: secondary, fontSize: 11),
                  ),
                  Container(
                    width: 1,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: AuthorStyle.border(dark),
                  ),
                  Text(
                    '${widget.current_word_count}字',
                    style: TextStyle(color: secondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterAction {
  const _ChapterAction(this.kind, [this.index = -1]);
  final String kind;
  final int index;
}

class _ChapterDirectory extends StatefulWidget {
  const _ChapterDirectory({
    required this.chapters,
    required this.activeIndex,
    required this.isDark,
    required this.onReorder,
  });
  final List<CreatorChapterDraft> chapters;
  final int activeIndex;
  final bool isDark;
  final void Function(int, int) onReorder;
  @override
  State<_ChapterDirectory> createState() => _ChapterDirectoryState();
}

class _ChapterDirectoryState extends State<_ChapterDirectory> {
  final _search = TextEditingController();
  String _query = '';
  bool _ordering = false;
  late final String? _activeId = widget.activeIndex < 0
      ? null
      : widget.chapters[widget.activeIndex].local_id;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDark;
    final text = AuthorStyle.primary_text(dark);
    final secondary = AuthorStyle.secondary_text(dark);
    final accent = dark ? Colors.white : ColorConstants.lightTextColor;
    final indexes = [
      for (var i = 0; i < widget.chapters.length; i++)
        if (_query.isEmpty ||
            widget.chapters[i].title.toLowerCase().contains(
              _query.toLowerCase(),
            ) ||
            '${i + 1}' == _query.replaceAll(RegExp(r'[第章\s]'), ''))
          i,
    ];
    final bool keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        initialChildSize: .84,
        minChildSize: .5,
        maxChildSize: .96,
        expand: false,
        builder: (context, controller) => Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AuthorStyle.surface(dark),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AuthorStyle.border(dark),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 10, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              easy.tr('creator_center.chapter_directory'),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                                color: text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _ordering
                                  ? easy.tr('creator_center.chapter_directory_reorder_hint')
                                  : easy.tr('creator_center.chapter_summary', namedArgs: {
                                      'count': '${widget.chapters.length}',
                                      'words': '',
                                    }) + ' · ' + easy.tr('creator_center.chapter_directory_hint'),
                              style: TextStyle(color: secondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: easy.tr('creator_center.close_directory'),
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: secondary),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                  child: TextField(
                    controller: _search,
                    onChanged: (value) => setState(() {
                      _query = value.trim();
                      _ordering = false;
                    }),
                    style: TextStyle(color: text, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: easy.tr('creator_center.search_chapter_hint'),
                      hintStyle: TextStyle(color: secondary, fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded, color: secondary),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: easy.tr('creator_center.clear_search'),
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                      filled: true,
                      fillColor: AuthorStyle.secondary_surface(dark),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(LayoutConfig.section_radius),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(LayoutConfig.section_radius),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: indexes.isEmpty
                      ? Center(
                          child: Text(
                            _query.isEmpty
                                ? easy.tr('creator_center.no_chapters_yet')
                                : easy.tr('creator_center.no_chapter_found'),
                            style: TextStyle(color: secondary),
                          ),
                        )
                      : _ordering
                      ? ReorderableListView.builder(
                          scrollController: controller,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          buildDefaultDragHandles: false,
                          itemCount: indexes.length,
                          proxyDecorator: (child, index, animation) => child,
                          onReorderItem: (oldIndex, targetIndex) {
                            final newIndex = targetIndex > oldIndex
                                ? targetIndex + 1
                                : targetIndex;
                            widget.onReorder(oldIndex, newIndex);
                            setState(() {
                              final chapter = widget.chapters.removeAt(
                                oldIndex,
                              );
                              widget.chapters.insert(
                                newIndex > oldIndex ? newIndex - 1 : newIndex,
                                chapter,
                              );
                            });
                          },
                          itemBuilder: (context, index) => _row(index),
                        )
                      : ListView.builder(
                          controller: controller,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          itemCount: indexes.length,
                          itemBuilder: (context, index) => _row(indexes[index]),
                        ),
                ),
                if (!keyboardVisible)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _query.isEmpty && widget.chapters.length > 1
                              ? () => setState(() => _ordering = !_ordering)
                              : null,
                          icon: Icon(
                            _ordering ? Icons.check_rounded : Icons.swap_vert_rounded,
                            size: 18,
                          ),
                          label: Text(_ordering
                              ? easy.tr('creator_center.reorder_done')
                              : easy.tr('creator_center.reorder')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: text,
                            side: BorderSide(color: AuthorStyle.border(dark)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => Navigator.pop(
                              context,
                              const _ChapterAction('new'),
                            ),
                            icon: SvgIcon(
                              name: 'add',
                              width: 19,
                              height: 19,
                              color: dark ? const Color(0xFF1A1A18) : Colors.white,
                            ),
                            label: Text(easy.tr('creator_center.new_chapter')),
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: dark ? const Color(0xFF1A1A18) : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _row(int index) {
    final chapter = widget.chapters[index];
    final active = chapter.local_id == _activeId;
    final dark = widget.isDark;
    final accent = dark ? Colors.white : ColorConstants.lightTextColor;
    return Padding(
      key: ValueKey(chapter.local_id),
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: active
            ? accent.withValues(alpha: dark ? .10 : .11)
            : AuthorStyle.surface(dark),
        borderRadius: BorderRadius.circular(LayoutConfig.section_radius),
        child: InkWell(
          onTap: () => Navigator.pop(context, _ChapterAction('select', index)),
          borderRadius: BorderRadius.circular(LayoutConfig.section_radius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: active
                    ? accent.withValues(alpha: .6)
                    : AuthorStyle.border(dark),
              ),
              borderRadius: BorderRadius.circular(LayoutConfig.section_radius),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    '${index + 1}'.padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 15,
                      color: active ? accent : AuthorStyle.secondary_text(dark),
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.title.isEmpty
                            ? easy.tr('creator_center.untitled_work')
                            : chapter.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: AuthorStyle.primary_text(dark),
                          fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${chapter.word_count} ' +
                            (easy.tr('creator_center.chapter_word_count', namedArgs: {'count': ''}).trim()) +
                            (active ? ' · ${easy.tr("creator_center.editing")}' : ''),
                        style: TextStyle(
                          color: active ? accent : AuthorStyle.secondary_text(dark),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_ordering)
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: AuthorStyle.secondary_text(dark),
                      ),
                    ),
                  )
                else
                  Icon(
                    active ? Icons.edit_note_rounded : Icons.chevron_right_rounded,
                    color: active ? accent : AuthorStyle.secondary_text(dark),
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
