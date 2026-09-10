import 'dart:convert';
import 'package:app/pages/work_editor/single_chapter/logic.dart';
import 'package:app/api/creator_work.dart';
import 'package:app/api/results_type.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:easy_localization/easy_localization.dart';

// TODO 同一会话串行保存，重试未知结果时复用原快照与请求标识。
class CreatorDraftPersistence {
  final CreatorDraftBackend backend;
  int? _novelId;
  int? _revisionId;
  int? _novelLanguageId;
  int? _lockVersion;
  CreatorWorkStatus _status;
  bool _busy = false;
  CreatorWorkDraft? _pendingWork;
  int? _pendingLanguage;
  String? _pendingKey;
  CreatorWorkDraft? _pendingPublish;
  String? _publishKey;
  final String _createKey = creatorRequestKey();

  CreatorDraftPersistence({
    CreatorWorkDraft? initialWork,
    this.backend = const CreatorDraftBackend(),
  }) : _novelId = initialWork?.novel_id,
       _revisionId = initialWork?.revision_id,
       _novelLanguageId = initialWork?.novel_language_id,
       _lockVersion = initialWork?.lock_version,
       _status = initialWork?.status ?? CreatorWorkStatus.draft;

  Future<CreatorWorkDraft> save(
    CreatorWorkDraft work, {
    required int languageId,
    bool publish = false,
    bool submitForReview = false,
  }) async {
    if (_busy) throw CreatorDraftException(tr('creator_center.busy_saving'));
    _busy = true;
    try {
      final shouldPublish = publish || submitForReview;
      // TODO 先确认上一次发布结果，禁止网络重试先保存已被发布/锁定的草稿。
      if (_pendingPublish != null) {
        final prior = _pendingPublish!;
        final published = await _publishPending();
        if (creatorDraftFingerprint(prior) == creatorDraftFingerprint(work)) {
          return published;
        }
      }
      if (_status == CreatorWorkStatus.scheduled) {
        if (!shouldPublish) {
          throw CreatorDraftException(tr('creator_center.scheduled_no_draft'));
        }
        _pendingPublish = work.copy_with(
          novel_id: _novelId,
          revision_id: _revisionId,
          novel_language_id: _novelLanguageId,
          language_id: languageId,
          lock_version: _lockVersion,
          status: CreatorWorkStatus.scheduled,
        );
        _publishKey = creatorRequestKey();
        return await _publishPending();
      }
      if (_status == CreatorWorkStatus.published) {
        if (!shouldPublish) {
          throw CreatorDraftException(
            tr('creator_center.published_cannot_save_draft'),
          );
        }
        _pendingPublish = work.copy_with(
          novel_id: _novelId,
          revision_id: _revisionId,
          novel_language_id: _novelLanguageId,
          language_id: languageId,
          status: CreatorWorkStatus.published,
          release_mode: CreatorReleaseMode.immediate,
          clear_scheduled_publish_time: true,
        );
        _publishKey = creatorRequestKey();
        return await _publishPending();
      }
      if (_novelId == null) {
        final created = await backend.create(
          work,
          languageId,
          requestKey: _createKey,
        );
        _requireSuccess(created, tr('creator_center.create_draft_failed'));
        _novelId = _parseIntNullable(created.content?['novel_id']);
        _revisionId = _parseIntNullable(created.content?['revision_id']);
        _novelLanguageId = _parseIntNullable(
          created.content?['novel_language_id'],
        );
        _lockVersion = _parseIntNullable(created.content?['lock_version']) ?? 0;
      }
      if (_novelId == null || _revisionId == null) {
        throw CreatorDraftException(tr('creator_center.draft_incomplete'));
      }
      CreatorWorkDraft? saved;
      if (_pendingWork != null) {
        final prior = _pendingWork!;
        final priorLanguage = _pendingLanguage!;
        final retried = await _savePending();
        if (priorLanguage == languageId &&
            creatorDraftFingerprint(prior) == creatorDraftFingerprint(work)) {
          saved = retried;
        }
      }
      if (saved == null) {
        _pendingWork = work.copy_with(
          novel_id: _novelId,
          revision_id: _revisionId,
          novel_language_id: _novelLanguageId,
          language_id: languageId,
          lock_version: _lockVersion,
          status: CreatorWorkStatus.draft,
        );
        _pendingLanguage = languageId;
        _pendingKey = creatorRequestKey();
        saved = await _savePending();
      }
      if (shouldPublish) {
        _pendingPublish = saved;
        _publishKey = creatorRequestKey();
        return await _publishPending();
      }
      return saved;
    } finally {
      _busy = false;
    }
  }

  // TODO 发布响应丢失时重放同一个操作；服务端返回拒绝才允许修改后重新提交。
  Future<CreatorWorkDraft> _publishPending() async {
    final work = _pendingPublish!;
    final result = await backend.publish(work, requestKey: _publishKey);
    if (result.serverRejected) {
      _pendingPublish = null;
      _publishKey = null;
    }
    _requireSuccess(result, tr('creator_center.publish_failed'));
    _status =
        _parseIntNullable(result.content?['release_status']) == 2 ||
            (result.content?['release_status'] == null &&
                work.release_mode == CreatorReleaseMode.scheduled)
        ? CreatorWorkStatus.scheduled
        : CreatorWorkStatus.published;
    _revisionId =
        _parseIntNullable(result.content?['revision_id']) ?? _revisionId;
    _pendingPublish = null;
    _publishKey = null;
    return work.copy_with(
      status: _status,
      revision_id: _revisionId,
      update_time: DateTime.now(),
    );
  }

  // TODO 响应丢失时重试同一快照；明确拒绝后允许作者修改参数再保存。
  Future<CreatorWorkDraft> _savePending() async {
    final work = _pendingWork!;
    final result = await backend.save(
      work,
      _pendingLanguage!,
      requestKey: _pendingKey,
    );
    if (result.serverRejected) {
      _pendingWork = null;
      _pendingKey = null;
    }
    _requireSuccess(result, tr('creator_center.save_draft_failed_generic'));
    _lockVersion =
        _parseIntNullable(result.content?['lock_version']) ?? _lockVersion;
    _pendingWork = null;
    _pendingKey = null;
    return work.copy_with(
      lock_version: _lockVersion,
      update_time: DateTime.now(),
    );
  }

  void _requireSuccess(
    ResultsType<Map<String, dynamic>> result,
    String fallback,
  ) {
    if (!result.status)
      throw CreatorDraftException(
        creatorDraftErrorMessage(result.message, fallback),
      );
  }
}

// TODO 服务端草稿与发布边界；两种篇幅共享字段序列化，各自使用独立发布路由。
class CreatorDraftBackend {
  final bool metadataOnly;
  const CreatorDraftBackend({this.metadataOnly = false});

  Future<ResultsType<Map<String, dynamic>>> create(
    CreatorWorkDraft work,
    int languageId, {
    String? requestKey,
  }) => CreatorWorkApi.createDraft(
    workType: work.work_type == CreatorWorkType.long ? 1 : 2,
    languageId: languageId,
    title: work.title,
    introduction: work.introduction,
    requestKey: requestKey,
  );

  Future<ResultsType<Map<String, dynamic>>> save(
    CreatorWorkDraft work,
    int languageId, {
    String? requestKey,
  }) => CreatorWorkApi.saveDraft(
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
    requestKey: requestKey,
    preferences: work.preferences,
    savedStep: work.saved_step,
    rightsConfirmed: work.rights_confirmed,
    releaseMode: work.release_mode == CreatorReleaseMode.immediate ? 1 : 2,
    scheduledPublishTime: work.release_mode == CreatorReleaseMode.scheduled
        ? work.scheduled_publish_time?.toUtc().toIso8601String()
        : null,
    tempChapterTitle: !metadataOnly && work.work_type == CreatorWorkType.long
        ? work.chapter_title
        : null,
    tempChapterContent: !metadataOnly && work.work_type == CreatorWorkType.long
        ? work.chapter_content
        : null,
    languageId: languageId,
    shortContent: work.work_type == CreatorWorkType.short
        ? work.short_content
        : null,
    workType: work.work_type == CreatorWorkType.long ? 1 : 2,
    chapters: !metadataOnly && work.work_type == CreatorWorkType.long
        ? work.chapters.map((chapter) => chapter.to_json()).toList()
        : null,
  );

  Future<ResultsType<Map<String, dynamic>>> publish(
    CreatorWorkDraft work, {
    String? requestKey,
  }) {
    final published = work.status == CreatorWorkStatus.published;
    final scheduled = work.status == CreatorWorkStatus.scheduled;
    final parameters = <String, dynamic>{
      'novel_id': work.novel_id!,
      if (scheduled) 'replace_scheduled': true,
      'novel_language_id': work.novel_language_id,
      if (requestKey != null) 'request_key': requestKey,
      if (!published) 'revision_id': work.revision_id!,
      if (!published) 'lock_version': work.lock_version,
      if (published) 'base_revision_id': work.revision_id,
      'rights_confirmed': work.rights_confirmed,
      'release_mode':
          published || work.release_mode == CreatorReleaseMode.immediate
          ? 1
          : 2,
      if (!published && work.release_mode == CreatorReleaseMode.scheduled)
        'scheduled_publish_time': work.scheduled_publish_time
            ?.toUtc()
            .toIso8601String(),
      // TODO 已发布作品的修改在发布事务内生成版本，不调用保存草稿接口。
      if (published || scheduled) ...{
        'title': work.title,
        'introduction': work.introduction,
        'cover_url': work.cover_url ?? '',
        'serialization_status': work.is_completed ? 2 : 1,
        'preferences': work.preferences,
        'category_snapshot': work.category_ids
            .map((id) => {'category_id': id})
            .toList(),
        if (work.work_type == CreatorWorkType.short)
          'short_content': work.short_content,
        if (scheduled && work.work_type == CreatorWorkType.long)
          'chapters': work.chapters
              .map((chapter) => chapter.to_json())
              .toList(),
      },
    };
    return work.work_type == CreatorWorkType.short
        ? CreatorWorkApi.publishShort(parameters)
        : CreatorWorkApi.publishLong(parameters);
  }
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

// TODO 比较实际编辑内容，忽略服务端身份、锁版本和保存时间。
String creatorDraftFingerprint(CreatorWorkDraft draft) {
  final data = draft.to_json();
  for (final key in [
    'novel_id',
    'revision_id',
    'novel_language_id',
    'lock_version',
    'language_id',
    'update_time',
    'status',
  ]) {
    data.remove(key);
  }
  return jsonEncode(data);
}
