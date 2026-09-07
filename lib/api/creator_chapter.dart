import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';

/// 创作者章节API
class CreatorChapterApi {
  /// 查询章节列表
  static Future<ResultsType<Map<String, dynamic>>> inquire({
    required int novelId,
  }) {
    return postRequest<Map<String, dynamic>>(
      path: 'creator_chapter/inquire',
      parameter: {
        'novel_id': novelId,
      },
      fromJson: (json) => json,
    );
  }

  /// 创建章节草稿
  static Future<ResultsType<Map<String, dynamic>>> createDraft({
    required int novelId,
    required int novelLanguageId,
    required String title,
  }) {
    return postRequest<Map<String, dynamic>>(
      path: 'creator_chapter/create_draft',
      parameter: {
        'novel_id': novelId,
        'novel_language_id': novelLanguageId,
        'title': title,
      },
      fromJson: (json) => json,
    );
  }

  /// 获取章节详情
  static Future<ResultsType<Map<String, dynamic>>> getInfo({
    required int revisionId,
  }) {
    return postRequest<Map<String, dynamic>>(
      path: 'creator_chapter/get_info',
      parameter: {
        'revision_id': revisionId,
      },
      fromJson: (json) => json,
    );
  }

  /// 保存章节草稿
  static Future<ResultsType<Map<String, dynamic>>> saveDraft({
    required int revisionId,
    String? title,
    String? contentUrl,
    int? wordCount,
    int? lockVersion,
  }) {
    return postRequest<Map<String, dynamic>>(
      path: 'creator_chapter/save_draft',
      parameter: {
        'revision_id': revisionId,
        if (title != null) 'title': title,
        if (contentUrl != null) 'content_url': contentUrl,
        if (wordCount != null) 'word_count': wordCount,
        if (lockVersion != null) 'lock_version': lockVersion,
      },
      fromJson: (json) => json,
    );
  }

  /// 提交章节审核
  static Future<ResultsType<Map<String, dynamic>>> submit({
    required int novelId,
    required List<int> chapterRevisionIds,
    String? submitNote,
  }) {
    return postRequest<Map<String, dynamic>>(
      path: 'creator_chapter/submit',
      parameter: {
        'novel_id': novelId,
        'chapter_revision_ids': chapterRevisionIds,
        if (submitNote != null) 'submit_note': submitNote,
      },
      fromJson: (json) => json,
    );
  }

  /// 批量提交章节审核
  static Future<ResultsType<Map<String, dynamic>>> batchSubmit({
    required int novelId,
    required List<int> chapterRevisionIds,
    String? submitNote,
  }) {
    return submit(
      novelId: novelId,
      chapterRevisionIds: chapterRevisionIds,
      submitNote: submitNote,
    );
  }

  /// 删除章节草稿
  static Future<ResultsType<Map<String, dynamic>>> deleteDraft({
    required int revisionId,
  }) {
    return postRequest<Map<String, dynamic>>(
      path: 'creator_chapter/delete_draft',
      parameter: {
        'revision_id': revisionId,
      },
      fromJson: (json) => json,
    );
  }
}
