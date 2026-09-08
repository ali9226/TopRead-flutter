import 'package:flutter/material.dart';
import 'package:app/pages/author_center/models/creator_work.dart';

/// 章节以稳定 ID 选中，输入直接写入当前工作副本；切换不会新建或丢失章节。
class ChapterEditingSession extends ChangeNotifier {
  ChapterEditingSession({
    required this.chapters,
    required this.titleController,
    required this.contentController,
  }) {
    if (titleController.text.isNotEmpty || contentController.text.isNotEmpty) {
      chapters.add(_newChapter(titleController.text, contentController.text));
      _activeId = chapters.last.local_id;
    } else if (chapters.isNotEmpty) {
      _activeId = chapters.first.local_id;
    }
    _loadSelection();
    titleController.addListener(_storeInput);
    contentController.addListener(_storeInput);
  }

  final List<CreatorChapterDraft> chapters;
  final TextEditingController titleController;
  final TextEditingController contentController;
  String? _activeId;
  bool _selecting = false;
  int _sequence = 0;
  int changeVersion = 0;

  int get activeIndex => chapters.indexWhere((c) => c.local_id == _activeId);

  CreatorChapterDraft _newChapter(String title, String content) =>
      CreatorChapterDraft(
        local_id:
            'chapter_${DateTime.now().microsecondsSinceEpoch}_${_sequence++}',
        title: title,
        content: content,
        update_time: DateTime.now(),
      );

  void _storeInput() {
    if (_selecting) return;
    if (activeIndex < 0) {
      if (titleController.text.isEmpty && contentController.text.isEmpty) {
        return;
      }
      chapters.add(_newChapter('', ''));
      _activeId = chapters.last.local_id;
    }
    final index = activeIndex;
    final old = chapters[index];
    if (old.title == titleController.text &&
        old.content == contentController.text) {
      return;
    }
    chapters[index] = old.copy_with(
      title: titleController.text,
      content: contentController.text,
      update_time: DateTime.now(),
    );
    changeVersion++;
    notifyListeners();
  }

  void select(int index) {
    if (index < 0 || index >= chapters.length || index == activeIndex) return;
    _activeId = chapters[index].local_id;
    _loadSelection();
    notifyListeners();
  }

  void add() {
    // 已有空白新章时复用，避免连点产生大量空章。
    if (activeIndex >= 0 &&
        chapters[activeIndex].title.trim().isEmpty &&
        chapters[activeIndex].content.trim().isEmpty) {
      return;
    }
    chapters.add(_newChapter('', ''));
    _activeId = chapters.last.local_id;
    _loadSelection();
    changeVersion++;
    notifyListeners();
  }

  void remove(int index) {
    if (index < 0 || index >= chapters.length) return;
    final removed = chapters.removeAt(index);
    if (removed.local_id == _activeId) {
      _activeId = chapters.isEmpty
          ? null
          : chapters[index.clamp(0, chapters.length - 1)].local_id;
      _loadSelection();
    }
    changeVersion++;
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    final chapter = chapters.removeAt(oldIndex);
    chapters.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, chapter);
    changeVersion++;
    notifyListeners();
  }

  void _loadSelection() {
    _selecting = true;
    final chapter = activeIndex < 0 ? null : chapters[activeIndex];
    titleController.text = chapter?.title ?? '';
    contentController.text = chapter?.content ?? '';
    _selecting = false;
  }

  @override
  void dispose() {
    titleController.removeListener(_storeInput);
    contentController.removeListener(_storeInput);
    super.dispose();
  }
}
