// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/installation/models/creator_work.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreatorWorkDraft', () {
    test('长篇总字数由所有章节非空白字符组成', () {
      final DateTime now = DateTime(2026, 9, 3);
      final CreatorWorkDraft work = CreatorWorkDraft(
        local_id: 'work_1',
        title: '测试长篇',
        introduction: '',
        work_type: CreatorWorkType.long,
        is_completed: false,
        language_code: 'zh',
        categories: const <String>['奇幻'],
        short_content: '',
        chapters: <CreatorChapterDraft>[
          CreatorChapterDraft(
            local_id: 'chapter_1',
            title: '第一章',
            content: '一 二\n三',
            update_time: now,
          ),
          CreatorChapterDraft(
            local_id: 'chapter_2',
            title: '第二章',
            content: '四五',
            update_time: now,
          ),
        ],
        status: CreatorWorkStatus.draft,
        release_mode: CreatorReleaseMode.immediate,
        scheduled_publish_time: null,
        update_time: now,
      );

      expect(work.word_count, 5);
    });

    test('短篇总字数忽略正文中的空格和换行', () {
      final DateTime now = DateTime(2026, 9, 3);
      final CreatorWorkDraft work = CreatorWorkDraft(
        local_id: 'work_2',
        title: '测试短篇',
        introduction: '',
        work_type: CreatorWorkType.short,
        is_completed: true,
        language_code: 'zh',
        categories: const <String>['悬疑'],
        short_content: '一 二\n三四',
        chapters: const <CreatorChapterDraft>[],
        status: CreatorWorkStatus.reviewing,
        release_mode: CreatorReleaseMode.scheduled,
        scheduled_publish_time: now.add(const Duration(days: 1)),
        update_time: now,
      );

      expect(work.word_count, 4);
    });

    test('copy_with 可以清除定时发布时间', () {
      final DateTime now = DateTime(2026, 9, 3);
      final CreatorWorkDraft work = CreatorWorkDraft(
        local_id: 'work_3',
        title: '定时作品',
        introduction: '',
        work_type: CreatorWorkType.short,
        is_completed: true,
        language_code: 'zh',
        categories: const <String>[],
        short_content: '正文',
        chapters: const <CreatorChapterDraft>[],
        status: CreatorWorkStatus.scheduled,
        release_mode: CreatorReleaseMode.scheduled,
        scheduled_publish_time: now.add(const Duration(days: 1)),
        update_time: now,
      );

      final CreatorWorkDraft immediate_work = work.copy_with(
        release_mode: CreatorReleaseMode.immediate,
        clear_scheduled_publish_time: true,
      );

      expect(immediate_work.release_mode, CreatorReleaseMode.immediate);
      expect(immediate_work.scheduled_publish_time, isNull);
    });
  });
}
