import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/long_novel_editor/chapter_editing_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('切换、排序和删除使用稳定章节 ID，未完成输入不会丢失或重复创建', () {
    final title = TextEditingController();
    final content = TextEditingController();
    final rows = List.generate(
      300,
      (i) => CreatorChapterDraft(
        local_id: 'c$i',
        title: '章节$i',
        content: '正文$i',
        update_time: DateTime(2026),
      ),
    );
    final session = ChapterEditingSession(
      chapters: rows,
      titleController: title,
      contentController: content,
    );
    addTearDown(() {
      session.dispose();
      title.dispose();
      content.dispose();
    });
    session.select(2);
    content.text = '第三章尚未写完的修改';
    title.text = '';
    session.select(299);
    expect(content.text, '正文299');
    session.select(2);
    expect(content.text, '第三章尚未写完的修改');
    expect(title.text, '');
    expect(rows.length, 300);
    session.reorder(2, 0);
    expect(session.activeIndex, 0);
    expect(rows.first.local_id, 'c2');
    session.remove(1);
    expect(session.activeIndex, 0);
    session.remove(0);
    expect(session.activeIndex, 0);
    expect(content.text, rows.first.content);
    final changes = session.changeVersion;
    session.select(10);
    expect(session.changeVersion, changes, reason: '只切换章节不应提示有未保存修改');
    session.add();
    final total = rows.length;
    session.add();
    expect(rows.length, total);
  });

  test('恢复旧临时章一次，空作品直接输入也有独立章节身份', () {
    final title = TextEditingController(text: '临时章');
    final content = TextEditingController(text: '未完成正文');
    final rows = <CreatorChapterDraft>[];
    final session = ChapterEditingSession(
      chapters: rows,
      titleController: title,
      contentController: content,
    );
    expect(rows.single.content, '未完成正文');
    session.remove(0);
    content.text = '新正文';
    expect(rows.single.content, '新正文');
    expect(rows.single.title, '');
    session.dispose();
    title.dispose();
    content.dispose();
  });
}
