import 'dart:async';

import 'package:app/api/results_type.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/draft_persistence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('首次提交依次创建、完整保存短篇正文、提交同一作品', () async {
    final backend = _Backend();
    final result = await CreatorDraftPersistence(backend: backend).save(
      _draft(), languageId: 29, submitForReview: true,
    );
    expect(backend.calls, ['create', 'save', 'submit']);
    expect(result.status, CreatorWorkStatus.reviewing);
    expect(result.novel_id, 42);
    expect(result.revision_id, 51);
    expect(result.novel_language_id, 63);
    expect(result.language_id, 29);
    expect(result.lock_version, 1);
    expect(backend.saved.single.short_content, '  保留正文\n换行  ');
    expect(backend.saved.single.chapters, isEmpty);
    expect(backend.submitted.single.revision_id, 51);
  });

  test('保存失败不提交，重试复用创建好的作品与修订 ID', () async {
    final backend = _Backend()..saveFails = true;
    final session = CreatorDraftPersistence(backend: backend);
    await expectLater(session.save(_draft(), languageId: 1, submitForReview: true),
      throwsA(isA<CreatorDraftException>()));
    expect(backend.calls, ['create', 'save']);
    backend.saveFails = false;
    final result = await session.save(_draft(), languageId: 1, submitForReview: true);
    expect(backend.calls, ['create', 'save', 'save', 'submit']);
    expect(backend.saved.map((work) => work.novel_id), [42, 42]);
    expect(result.status, CreatorWorkStatus.reviewing);
  });

  test('提交失败后重试使用最新乐观锁，且保持章节身份和顺序', () async {
    final original = _draft().copy_with(
      novel_id: 101, revision_id: 102, lock_version: 8,
      work_type: CreatorWorkType.long,
      chapters: [
        CreatorChapterDraft(local_id: 'second', title: '第二章', content: '乙', update_time: DateTime(2026)),
        CreatorChapterDraft(local_id: 'first', title: '第一章', content: '甲', update_time: DateTime(2026)),
      ],
    );
    final backend = _Backend()..submitFails = true;
    final session = CreatorDraftPersistence(initialWork: original, backend: backend);
    await expectLater(session.save(original, languageId: 1, submitForReview: true),
      throwsA(isA<CreatorDraftException>()));
    backend.submitFails = false;
    await session.save(original, languageId: 1, submitForReview: true);
    expect(backend.calls, ['save', 'submit', 'save', 'submit']);
    expect(backend.saved.map((work) => work.lock_version), [8, 9]);
    expect(backend.saved.last.chapters.map((chapter) => chapter.local_id), ['second', 'first']);
  });

  test('请求过程中重复点击不会再次创建作品', () async {
    final backend = _Backend()..waitForCreate = Completer<void>();
    final session = CreatorDraftPersistence(backend: backend);
    final first = session.save(_draft(), languageId: 1);
    await expectLater(session.save(_draft(), languageId: 1), throwsA(isA<CreatorDraftException>()));
    backend.waitForCreate!.complete();
    await first;
    expect(backend.calls, ['create', 'save']);
  });

  test('每个新编辑会话都创建独立草稿', () async {
    final backend = _Backend();
    await CreatorDraftPersistence(backend: backend).save(_draft(), languageId: 1);
    await CreatorDraftPersistence(backend: backend).save(_draft(), languageId: 1);
    expect(backend.calls, ['create', 'save', 'create', 'save']);
  });
}

CreatorWorkDraft _draft() => CreatorWorkDraft(
  local_id: 'draft', title: '小说', introduction: '简介', work_type: CreatorWorkType.short,
  is_completed: true, language_code: 'zh', category_ids: [8], short_content: '  保留正文\n换行  ',
  chapters: const [], status: CreatorWorkStatus.draft, release_mode: CreatorReleaseMode.immediate,
  scheduled_publish_time: null, update_time: DateTime(2026), rights_confirmed: true,
);

class _Backend extends CreatorDraftBackend {
  final calls = <String>[];
  final saved = <CreatorWorkDraft>[];
  final submitted = <CreatorWorkDraft>[];
  bool saveFails = false;
  bool submitFails = false;
  Completer<void>? waitForCreate;

  @override
  Future<ResultsType<Map<String, dynamic>>> create(CreatorWorkDraft work, int languageId) async {
    calls.add('create');
    await waitForCreate?.future;
    return _result(true, {'novel_id': '42', 'revision_id': '51', 'novel_language_id': '63'});
  }

  @override
  Future<ResultsType<Map<String, dynamic>>> save(CreatorWorkDraft work, int languageId) async {
    calls.add('save');
    saved.add(work);
    return _result(!saveFails, {'lock_version': '${(work.lock_version ?? 0) + 1}'});
  }

  @override
  Future<ResultsType<Map<String, dynamic>>> submit(CreatorWorkDraft work) async {
    calls.add('submit');
    submitted.add(work);
    return _result(!submitFails, {});
  }
}

ResultsType<Map<String, dynamic>> _result(bool ok, Map<String, dynamic> data) =>
    ResultsType<Map<String, dynamic>>()..status = ok..content = data;
