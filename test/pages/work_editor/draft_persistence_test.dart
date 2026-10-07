// ignore_for_file: non_constant_identifier_names

import 'package:app/api/results_type.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/_shared/draft_persistence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('创建响应丢失后以原参数重试，再保存作者最新正文和语种', () async {
    final backend = _DraftBackend([_result(status: false), _created_result()]);
    final persistence = CreatorDraftPersistence(backend: backend);
    final original = _work(title: '原始标题', content: '原始正文');
    final edited = original.copy_with(
      title: '修改标题',
      introduction: '修改简介',
      short_content: '新增正文',
      language_code: 'en',
    );

    await expectLater(
      persistence.save(original, languageId: 1),
      throwsA(isA<CreatorDraftException>()),
    );
    final saved = await persistence.save(edited, languageId: 2);

    expect(backend.creates, hasLength(2));
    expect(backend.creates[1].work.title, original.title);
    expect(backend.creates[1].work.introduction, original.introduction);
    expect(backend.creates[1].language_id, 1);
    expect(backend.creates[1].request_key, backend.creates[0].request_key);
    expect(backend.creates[0].request_key, isNotEmpty);
    expect(backend.saves, hasLength(1));
    expect(backend.saves.single.work.title, edited.title);
    expect(backend.saves.single.work.short_content, edited.short_content);
    expect(backend.saves.single.language_id, 2);
    expect(saved.novel_id, 11);
    expect(saved.revision_id, 21);
    expect(saved.language_id, 2);
  });

  test('服务端明确拒绝创建后以新标识提交修正后的参数', () async {
    final backend = _DraftBackend([
      _result(status: false, rejected: true),
      _created_result(),
    ]);
    final persistence = CreatorDraftPersistence(backend: backend);
    final original = _work(title: '原始标题', content: '原始正文');
    final edited = original.copy_with(title: '修正标题', language_code: 'en');

    await expectLater(
      persistence.save(original, languageId: 1),
      throwsA(isA<CreatorDraftException>()),
    );
    await persistence.save(edited, languageId: 2);

    expect(backend.creates[1].work.title, edited.title);
    expect(backend.creates[1].language_id, 2);
    expect(
      backend.creates[1].request_key,
      isNot(backend.creates[0].request_key),
    );
  });

  test('创建响应缺少修订编号时保留请求以补齐身份', () async {
    final backend = _DraftBackend([
      _result(status: true, content: {'novel_id': 11}),
      _created_result(),
    ]);
    final persistence = CreatorDraftPersistence(backend: backend);
    final original = _work(title: '原始标题', content: '原始正文');

    await expectLater(
      persistence.save(original, languageId: 1),
      throwsA(isA<CreatorDraftException>()),
    );
    final saved = await persistence.save(original, languageId: 1);

    expect(backend.creates, hasLength(2));
    expect(backend.creates[1].request_key, backend.creates[0].request_key);
    expect(backend.saves, hasLength(1));
    expect(saved.novel_id, 11);
    expect(saved.revision_id, 21);
  });
}

/// 固定作品快照，避免测试结果依赖时间或表单组件。
CreatorWorkDraft _work({required String title, required String content}) =>
    CreatorWorkDraft(
      local_id: 'local_work',
      title: title,
      introduction: '原始简介',
      work_type: CreatorWorkType.short,
      is_completed: true,
      language_code: 'zh',
      category_ids: [1],
      short_content: content,
      chapters: [],
      status: CreatorWorkStatus.draft,
      release_mode: CreatorReleaseMode.immediate,
      scheduled_publish_time: null,
      update_time: DateTime(2026, 1, 1),
    );

ResultsType<Map<String, dynamic>> _created_result() => _result(
  status: true,
  content: {
    'novel_id': 11,
    'revision_id': 21,
    'novel_language_id': 31,
    'lock_version': 0,
  },
);

ResultsType<Map<String, dynamic>> _result({
  required bool status,
  bool rejected = false,
  Map<String, dynamic>? content,
}) => ResultsType<Map<String, dynamic>>()
  ..status = status
  ..serverRejected = rejected
  ..content = content;

typedef _DraftRequest = ({
  CreatorWorkDraft work,
  int language_id,
  String? request_key,
});

/// 记录创建和保存边界，模拟响应丢失、服务端拒绝和正常幂等重放。
class _DraftBackend extends CreatorDraftBackend {
  _DraftBackend(this.create_results);

  final List<ResultsType<Map<String, dynamic>>> create_results;
  final List<_DraftRequest> creates = [];
  final List<_DraftRequest> saves = [];

  @override
  Future<ResultsType<Map<String, dynamic>>> create(
    CreatorWorkDraft work,
    int languageId, {
    String? requestKey,
  }) async {
    creates.add((work: work, language_id: languageId, request_key: requestKey));
    return create_results.removeAt(0);
  }

  @override
  Future<ResultsType<Map<String, dynamic>>> save(
    CreatorWorkDraft work,
    int languageId, {
    String? requestKey,
  }) async {
    saves.add((work: work, language_id: languageId, request_key: requestKey));
    return _result(status: true, content: {'lock_version': 1});
  }
}
