// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
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

  @override
  Widget build(BuildContext context) {
    final dark = widget.is_dark;
    final primary = AuthorStyle.primary_text(dark);
    final secondary = AuthorStyle.secondary_text(dark);
    final accent = dark ? AuthorStyle.gold : AuthorStyle.deep_gold;
    final index = widget.active_chapter_index;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: AuthorStyle.surface(dark),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        key: const ValueKey('chapter_directory_button'),
                        onTap: _openDirectory,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: AuthorStyle.gold.withValues(
                                    alpha: dark ? .13 : .18,
                                  ),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(
                                  Icons.format_list_bulleted_rounded,
                                  color: accent,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '章节目录',
                                      style: TextStyle(
                                        color: primary,
                                        fontSize: 14,
                                        fontWeight: AuthorStyle.title_weight,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${widget.chapters.length} 章 · ${widget.chapter_word_count} 字',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: secondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.unfold_more_rounded,
                                color: secondary,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    tooltip: '新建章节',
                    onPressed: widget.on_save_current_chapter,
                    style: IconButton.styleFrom(
                      backgroundColor: AuthorStyle.gold,
                      foregroundColor: const Color(0xFF332A08),
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AuthorStyle.surface(dark),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AuthorStyle.border(dark)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 8, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              index < 0 ? '开始第一章' : '第 ${index + 1} 章',
                              style: TextStyle(
                                color: accent,
                                fontSize: 12,
                                fontWeight: AuthorStyle.emphasis_weight,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: '上一章',
                            onPressed: index > 0
                                ? () => widget.on_edit_chapter(index - 1)
                                : null,
                            icon: const Icon(Icons.chevron_left_rounded),
                          ),
                          IconButton(
                            tooltip: '下一章',
                            onPressed:
                                index >= 0 && index + 1 < widget.chapters.length
                                ? () => widget.on_edit_chapter(index + 1)
                                : null,
                            icon: const Icon(Icons.chevron_right_rounded),
                          ),
                          PopupMenuButton<String>(
                            tooltip: '章节操作',
                            icon: Icon(
                              Icons.more_horiz_rounded,
                              color: secondary,
                            ),
                            color: AuthorStyle.surface(dark),
                            onSelected: (value) {
                              if (value == 'import') widget.on_file_upload();
                              if (value == 'delete' && index >= 0) {
                                widget.on_delete_chapter(index);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'import',
                                child: Text('从文件导入正文'),
                              ),
                              if (index >= 0)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    '删除本章',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
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
                                fontWeight: AuthorStyle.title_weight,
                              ),
                              decoration: InputDecoration(
                                hintText: '为这一章起个名字',
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
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: AuthorStyle.gold,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Text(
                                  '${widget.current_word_count} 字',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
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
                                hintText: '故事从这里继续…',
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                '切换章节保留输入 · 点击「保存草稿」同步修改',
                textAlign: TextAlign.center,
                style: TextStyle(color: secondary, fontSize: 11),
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
    final indexes = [
      for (var i = 0; i < widget.chapters.length; i++)
        if (_query.isEmpty ||
            widget.chapters[i].title.toLowerCase().contains(
              _query.toLowerCase(),
            ) ||
            '${i + 1}' == _query.replaceAll(RegExp(r'[第章\s]'), ''))
          i,
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        initialChildSize: .84,
        minChildSize: .5,
        maxChildSize: .96,
        expand: false,
        builder: (context, controller) => Container(
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
                              '章节目录',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: AuthorStyle.title_weight,
                                color: text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _ordering
                                  ? '拖动右侧手柄调整顺序'
                                  : '共 ${widget.chapters.length} 章 · 选择一章继续写作',
                              style: TextStyle(color: secondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: '关闭目录',
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
                      hintText: '搜索章节名，或输入章号',
                      hintStyle: TextStyle(color: secondary, fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded, color: secondary),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: '清除搜索',
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
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: indexes.isEmpty
                      ? Center(
                          child: Text(
                            _query.isEmpty ? '还没有章节，开始你的第一章吧' : '没有找到相关章节',
                            style: TextStyle(color: secondary),
                          ),
                        )
                      : _ordering
                      ? ReorderableListView.builder(
                          scrollController: controller,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          buildDefaultDragHandles: false,
                          itemCount: indexes.length,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _query.isEmpty && widget.chapters.length > 1
                            ? () => setState(() => _ordering = !_ordering)
                            : null,
                        icon: Icon(
                          _ordering
                              ? Icons.check_rounded
                              : Icons.swap_vert_rounded,
                          size: 18,
                        ),
                        label: Text(_ordering ? '完成排序' : '排序'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: text,
                          side: BorderSide(color: AuthorStyle.border(dark)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(
                            context,
                            const _ChapterAction('new'),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 19),
                          label: const Text('新建章节'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AuthorStyle.gold,
                            foregroundColor: const Color(0xFF332A08),
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
    );
  }

  Widget _row(int index) {
    final chapter = widget.chapters[index];
    final active = chapter.local_id == _activeId;
    final dark = widget.isDark;
    final accent = dark ? AuthorStyle.gold : AuthorStyle.deep_gold;
    return Padding(
      key: ValueKey(chapter.local_id),
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: active
            ? AuthorStyle.gold.withValues(alpha: dark ? .10 : .11)
            : AuthorStyle.surface(dark),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => Navigator.pop(context, _ChapterAction('select', index)),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: active
                    ? AuthorStyle.gold.withValues(alpha: .6)
                    : AuthorStyle.border(dark),
              ),
              borderRadius: BorderRadius.circular(14),
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
                      fontWeight: AuthorStyle.emphasis_weight,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.title.isEmpty ? '未命名章节' : chapter.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: AuthorStyle.primary_text(dark),
                          fontWeight: AuthorStyle.emphasis_weight,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${chapter.word_count} 字${active ? ' · 正在编辑' : ''}',
                        style: TextStyle(
                          color: active
                              ? accent
                              : AuthorStyle.secondary_text(dark),
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
                    active
                        ? Icons.edit_note_rounded
                        : Icons.chevron_right_rounded,
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
