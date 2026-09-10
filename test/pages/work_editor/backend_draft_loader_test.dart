import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/backend_draft_loader.dart';
import 'package:app/pages/work_editor/draft_persistence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('旧审核修订状态2不能覆盖服务端未定时标记，仍可保存草稿', () {
    final data = _data();
    data['is_scheduled'] = false;
    (data['draft'] as Map)['revision_status'] = 2;
    final work = creatorWorkDraftFromBackend(data);
    expect(work.status, CreatorWorkStatus.draft);
    expect(work.can_save_draft, isTrue);
  });

  test('旧审核状态不带定时批次时不能推断为定时发布', () {
    final data = _data();
    (data['draft'] as Map)['revision_status'] = 2;
    data['pending_submission'] = {'status': 1, 'release_status': 2};
    expect(creatorWorkDraftFromBackend(data).status, CreatorWorkStatus.draft);
  });
  test('历史已发布作品没有修订指针时仍可编辑，不伪造修订编号', () {
    final data = _data();
    (data['novel'] as Map)['public_status'] = 3;
    (data['draft'] as Map)['id'] = null;
    (data['draft'] as Map)['revision_status'] = 3;
    final work = creatorWorkDraftFromBackend(data);
    expect(work.status, CreatorWorkStatus.published);
    expect(work.revision_id, isNull);
    expect(work.can_save_draft, isFalse);
  });

  test('定时发布预览使用发布批次时间并禁止草稿保存', () {
    final data = _data();
    data['is_scheduled'] = true;
    data['scheduled_publish_time'] = '2099-01-01T01:00:00Z';
    (data['draft'] as Map)['revision_status'] = 2;
    final work = creatorWorkDraftFromBackend(data);
    expect(work.status, CreatorWorkStatus.scheduled);
    expect(work.scheduled_publish_time, DateTime.utc(2099, 1, 1, 1));
    expect(work.can_save_draft, isFalse);
  });
  test('恢复短篇正文、数字字符串 ID、封面、偏好和步骤', () {
    final work = creatorWorkDraftFromBackend(_data());
    expect(work.novel_id, 12);
    expect(work.revision_id, 23);
    expect(work.novel_language_id, 34);
    expect(work.language_id, 77);
    expect(work.lock_version, 9);
    expect(work.short_content, '  正文\n尾部  ');
    expect(work.chapter_content, isEmpty);
    expect(work.cover_url, 'https://example.com/cover.jpg');
    expect(work.category_ids, [6]);
    expect(work.preferences['2'], [6]);
    expect(work.rights_confirmed, isTrue);
    expect(work.saved_step, 3);
    expect(work.release_mode, CreatorReleaseMode.immediate);
  });

  test('恢复长篇独立章节顺序、内容及尚未完成的临时章节', () {
    final data = _data();
    (data['draft'] as Map)['work_type'] = '1';
    data['chapters'] = [
      {
        'local_id': 'chapter_b',
        'title': '第二章',
        'content': '  内容 B\n',
        'update_time': '2026-09-08 13:00:00',
      },
      {
        'chapter_uid': 'chapter_a',
        'title': '第一章',
        'content': '内容 A',
        'update_time': 1788814800000,
      },
    ];
    final work = creatorWorkDraftFromBackend(data);
    expect(work.chapters.map((chapter) => chapter.local_id), [
      'chapter_b',
      'chapter_a',
    ]);
    expect(work.chapters.first.content, '  内容 B\n');
    expect(work.short_content, isEmpty);
    expect(work.chapter_content, '  正文\n尾部  ');
    expect(work.chapter_title, '未完成章节');
  });

  test('章节数据或正文未完整读取时禁止以空内容打开编辑器', () {
    final data = _data();
    (data['draft'] as Map)['work_type'] = 1;
    expect(
      () => creatorWorkDraftFromBackend(data),
      throwsA(isA<CreatorDraftException>()),
    );
    data['chapters'] = [
      {'local_id': 'chapter', 'title': '正文缺失'},
    ];
    expect(
      () => creatorWorkDraftFromBackend(data),
      throwsA(isA<CreatorDraftException>()),
    );
  });

  test('已提交稿没有可编辑修订时拒绝打开', () {
    final data = _data()..['draft'] = null;
    expect(
      () => creatorWorkDraftFromBackend(data),
      throwsA(isA<CreatorDraftException>()),
    );
  });
}

Map<String, dynamic> _data() => {
  'novel': <String, dynamic>{'id': '12'},
  'draft': <String, dynamic>{
    'id': '23',
    'novel_id': '12',
    'novel_language_id': '34',
    'language_id': '77',
    'lock_version': '9',
    'revision_status': '1',
    'work_type': '2',
    'title': '草稿',
    'temp_chapter_content': '  正文\n尾部  ',
    'temp_chapter_title': '未完成章节',
    'cover_url': 'https://example.com/cover.jpg',
    'preferences': '{"2":["6"]}',
    'category_snapshot': '[{"category_id":"6"}]',
    'saved_step': '9',
    'rights_confirmed': '1',
    'release_mode': '1',
    'update_time': '2026-09-08 12:00:00',
  },
};
