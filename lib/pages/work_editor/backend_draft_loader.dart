import 'dart:convert';

import 'package:app/api/creator_work.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/stores/language_store.dart';
import 'package:get/get.dart';

import 'draft_persistence.dart';

/// 列表仅用于选作品；进入编辑器前必须读取完整草稿与章节正文。
Future<CreatorWorkDraft> loadCreatorWorkDraft(int novelId) async {
  try {
    final result = await CreatorWorkApi.getInfo(novelId: novelId);
    if (!result.status || result.content == null) {
      throw CreatorDraftException(
        creatorDraftErrorMessage(result.message, '获取草稿失败，请稍后重试'),
      );
    }
    return creatorWorkDraftFromBackend(result.content!);
  } on CreatorDraftException {
    rethrow;
  } catch (_) {
    throw const CreatorDraftException('获取草稿失败，请稍后重试');
  }
}

CreatorWorkDraft creatorWorkDraftFromBackend(Map<String, dynamic> data) {
  final draft = _map(data['draft']);
  final novel = _map(data['novel']);
  final novelId = _parseIntNullable(draft['novel_id'] ?? novel['id']);
  final revisionId = _parseIntNullable(draft['id'] ?? draft['revision_id']);
  if (draft.isEmpty ||
      novelId == null ||
      revisionId == null ||
      (_parseIntNullable(draft['revision_status']) ?? 1) != 1) {
    throw const CreatorDraftException('该作品已提交审核或没有可编辑的草稿');
  }
  final workType =
      _parseIntNullable(draft['work_type'] ?? novel['work_type']) == 1
      ? CreatorWorkType.long
      : CreatorWorkType.short;
  final preferences = <String, List<int>>{};
  _map(draft['preferences']).forEach((key, value) {
    if (value is List) {
      preferences[key] = value.map(_parseIntNullable).whereType<int>().toList();
    }
  });
  final categorySnapshot = _list(draft['category_snapshot']);
  final categories = categorySnapshot.isNotEmpty
      ? categorySnapshot
      : _list(data['categories']);
  final categoryIds = categories
      .map((value) => _parseIntNullable(_map(value)['category_id']))
      .whereType<int>()
      .toSet()
      .toList();
  final languageId = _parseIntNullable(
    draft['language_id'] ?? novel['language_id'],
  );
  String languageCode = (draft['language_code'] ?? novel['language_code'] ?? '')
      .toString();
  if (Get.isRegistered<LanguageStore>()) {
    for (final language in Get.find<LanguageStore>().language_list) {
      if (language.id == languageId) {
        languageCode = language.language_code;
        break;
      }
    }
  }
  // ID 仍保存在模型中；缺少语种配置时不会以界面语种覆盖原始语种。
  if (languageCode.isEmpty) languageCode = 'zh';
  final chapters = <CreatorChapterDraft>[];
  if (workType == CreatorWorkType.long) {
    if (data['chapters'] is! List) {
      throw const CreatorDraftException('章节数据不完整，请稍后重试');
    }
    for (final raw in _list(data['chapters'])) {
      final chapter = _map(raw);
      final content = chapter['content'];
      if (content is! String) {
        throw const CreatorDraftException('章节正文未加载完成，请稍后重试');
      }
      final localId = (chapter['local_id'] ?? chapter['chapter_uid'] ?? '')
          .toString();
      if (localId.isEmpty) {
        throw const CreatorDraftException('章节信息不完整，请稍后重试');
      }
      chapters.add(
        CreatorChapterDraft(
          local_id: localId,
          title: chapter['title']?.toString() ?? '',
          content: content,
          update_time:
              _date(chapter['update_time']) ??
              DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
    }
  }
  return CreatorWorkDraft(
    local_id: 'work_$novelId',
    novel_id: novelId,
    revision_id: revisionId,
    novel_language_id: _parseIntNullable(
      draft['novel_language_id'] ?? novel['novel_language_id'],
    ),
    language_id: languageId,
    lock_version: _parseIntNullable(draft['lock_version']) ?? 0,
    title: draft['title']?.toString() ?? '',
    introduction: draft['introduction']?.toString() ?? '',
    work_type: workType,
    is_completed: _parseIntNullable(draft['serialization_status']) == 2,
    language_code: languageCode,
    category_ids: categoryIds,
    short_content: workType == CreatorWorkType.short
        ? (draft['short_content'] ?? draft['temp_chapter_content'] ?? '')
              .toString()
        : '',
    chapters: chapters,
    status: CreatorWorkStatus.draft,
    release_mode: _parseIntNullable(draft['release_mode']) == 2
        ? CreatorReleaseMode.scheduled
        : CreatorReleaseMode.immediate,
    scheduled_publish_time: _date(draft['scheduled_publish_time']),
    update_time:
        _date(draft['update_time']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    cover_url: draft['cover_url']?.toString(),
    saved_step: (_parseIntNullable(draft['saved_step']) ?? 0).clamp(0, 3),
    preferences: preferences,
    rights_confirmed:
        draft['rights_confirmed'] == true ||
        _parseIntNullable(draft['rights_confirmed']) == 1,
    chapter_title: workType == CreatorWorkType.long
        ? draft['temp_chapter_title']?.toString() ?? ''
        : '',
    chapter_content: workType == CreatorWorkType.long
        ? draft['temp_chapter_content']?.toString() ?? ''
        : '',
  );
}

Map<String, dynamic> _map(dynamic value) {
  if (value is String) {
    try {
      return _map(jsonDecode(value));
    } catch (_) {
      return {};
    }
  }
  return value is Map ? Map<String, dynamic>.from(value) : {};
}

List<dynamic> _list(dynamic value) {
  if (value is String) {
    try {
      return _list(jsonDecode(value));
    } catch (_) {
      return [];
    }
  }
  return value is List ? value : [];
}

int? _parseIntNullable(dynamic value) {
  if (value is int) return value;
  if (value is num && value.isFinite) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _date(dynamic value) {
  if (value is DateTime) return value;
  final timestamp = _parseIntNullable(value);
  if (timestamp != null) {
    return DateTime.fromMillisecondsSinceEpoch(
      timestamp < 100000000000 ? timestamp * 1000 : timestamp,
    );
  }
  return DateTime.tryParse(value?.toString() ?? '');
}
