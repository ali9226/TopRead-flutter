import 'package:app/api/creator_work.dart';
import 'package:app/api/results_type.dart';
import 'package:app/pages/author_center/models/creator_work.dart';

/// 编辑器只在完整保存成功后提交，创建成功的 ID 会保留以供失败重试。
class CreatorDraftPersistence {
  final CreatorDraftBackend backend;
  int? _novelId;
  int? _revisionId;
  int? _novelLanguageId;
  int? _lockVersion;
  bool _busy = false;

  CreatorDraftPersistence({
    CreatorWorkDraft? initialWork,
    this.backend = const CreatorDraftBackend(),
  }) : _novelId = initialWork?.novel_id,
       _revisionId = initialWork?.revision_id,
       _novelLanguageId = initialWork?.novel_language_id,
       _lockVersion = initialWork?.lock_version;

  Future<CreatorWorkDraft> save(
    CreatorWorkDraft work, {
    required int languageId,
    bool submitForReview = false,
  }) async {
    if (_busy) throw const CreatorDraftException('正在保存，请稍候');
    _busy = true;
    try {
      if (_novelId == null) {
        final created = await backend.create(work, languageId);
        _requireSuccess(created, '创建草稿失败，请重试');
        _novelId = _parseIntNullable(created.content?['novel_id']);
        _revisionId = _parseIntNullable(created.content?['revision_id']);
        _novelLanguageId = _parseIntNullable(
          created.content?['novel_language_id'],
        );
        _lockVersion = _parseIntNullable(created.content?['lock_version']) ?? 0;
      }
      if (_novelId == null || _revisionId == null) {
        throw const CreatorDraftException('草稿信息不完整，请返回创作者中心重新打开');
      }
      var saved = work.copy_with(
        novel_id: _novelId,
        revision_id: _revisionId,
        novel_language_id: _novelLanguageId,
        language_id: languageId,
        lock_version: _lockVersion,
        status: CreatorWorkStatus.draft,
      );
      final result = await backend.save(saved, languageId);
      _requireSuccess(result, '保存草稿失败，请重试');
      _lockVersion =
          _parseIntNullable(result.content?['lock_version']) ?? _lockVersion;
      saved = saved.copy_with(
        lock_version: _lockVersion,
        update_time: DateTime.now(),
      );
      if (submitForReview) {
        final submitted = await backend.submit(saved);
        _requireSuccess(submitted, '提交审核失败，请重试');
        saved = saved.copy_with(status: CreatorWorkStatus.reviewing);
      }
      return saved;
    } finally {
      _busy = false;
    }
  }

  void _requireSuccess(
    ResultsType<Map<String, dynamic>> result,
    String fallback,
  ) {
    if (!result.status) {
      throw CreatorDraftException(
        creatorDraftErrorMessage(result.message, fallback),
      );
    }
  }
}

/// 服务端草稿读写边界，便于验证创建、保存、提交的顺序与失败重试。
class CreatorDraftBackend {
  const CreatorDraftBackend();

  Future<ResultsType<Map<String, dynamic>>> create(
    CreatorWorkDraft work,
    int languageId,
  ) => CreatorWorkApi.createDraft(
    workType: work.work_type == CreatorWorkType.long ? 1 : 2,
    languageId: languageId,
    title: work.title,
    introduction: work.introduction,
  );

  Future<ResultsType<Map<String, dynamic>>> save(
    CreatorWorkDraft work,
    int languageId,
  ) => CreatorWorkApi.saveDraft(
    novelId: work.novel_id!,
    revisionId: work.revision_id!,
    title: work.title,
    introduction: work.introduction,
    coverUrl: work.cover_url,
    wordCount: work.word_count,
    serializationStatus: work.is_completed ? 2 : 1,
    categorySnapshot: work.category_ids
        .map((id) => <String, dynamic>{'category_id': id})
        .toList(),
    lockVersion: work.lock_version,
    preferences: work.preferences,
    savedStep: work.saved_step,
    rightsConfirmed: work.rights_confirmed,
    releaseMode: work.release_mode == CreatorReleaseMode.immediate ? 1 : 2,
    scheduledPublishTime: work.scheduled_publish_time?.toIso8601String(),
    tempChapterTitle: work.work_type == CreatorWorkType.long
        ? work.chapter_title
        : '',
    tempChapterContent: work.work_type == CreatorWorkType.long
        ? work.chapter_content
        : null,
    languageId: languageId,
    shortContent: work.work_type == CreatorWorkType.short
        ? work.short_content
        : null,
    workType: work.work_type == CreatorWorkType.long ? 1 : 2,
    chapters: work.chapters.map((chapter) => chapter.to_json()).toList(),
  );

  Future<ResultsType<Map<String, dynamic>>> submit(CreatorWorkDraft work) =>
      CreatorWorkApi.submit(
        novelId: work.novel_id!,
        revisionId: work.revision_id!,
        submissionType: 1,
      );
}

class CreatorDraftException implements Exception {
  final String message;
  const CreatorDraftException(this.message);
  @override
  String toString() => message;
}

/// 旧版后端可能返回翻译 key；向用户展示可读的中文提示。
String creatorDraftErrorMessage(String message, String fallback) {
  return message.trim().isNotEmpty &&
          RegExp(r'[\u4e00-\u9fff]').hasMatch(message)
      ? message
      : fallback;
}

int? _parseIntNullable(dynamic value) {
  if (value is int) return value;
  if (value is num && value.isFinite) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
