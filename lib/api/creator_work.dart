import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';

/// 创作者作品API
class CreatorWorkApi {
  /// 获取创作配置
  static Future<ResultsType<Map<String, dynamic>>> getFormConfig() {
    return postRequest<Map<String, dynamic>>(
      path: 'creator_work/get_form_config',
      fromJson: (json) => json,
    );
  }

  /// 创建作品草稿
  static Future<ResultsType<Map<String, dynamic>>> createDraft({
    required int workType,
    required int languageId,
    String? title,
    String? subtitle,
    String? introduction,
  }) {
    return postRequest<Map<String, dynamic>>(
      path: 'creator_work/create_draft',
      showTips: false,
      parameter: {
        'work_type': workType,
        'language_id': languageId,
        'work_language_id': languageId,
        if (title != null && title.isNotEmpty) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (introduction != null) 'introduction': introduction,
      },
      fromJson: (json) => json,
    );
  }

  /// 查询我的作品列表
  static Future<ResultsType<Map<String, dynamic>>> inquire({
    int? workType,
    int? publicStatus,
    int? initialAuditStatus,
    int? serializationStatus,
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) {
    return postRequest<Map<String, dynamic>>(
      path: 'creator_work/inquire',
      parameter: {
        if (workType != null) 'work_type': workType,
        if (publicStatus != null) 'public_status': publicStatus,
        if (initialAuditStatus != null)
          'initial_audit_status': initialAuditStatus,
        if (serializationStatus != null)
          'serialization_status': serializationStatus,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        'page': page,
        'page_size': pageSize,
      },
      fromJson: (json) => json,
    );
  }

  /// 获取作品详情
  static Future<ResultsType<Map<String, dynamic>>> getInfo({
    required int novelId,
  }) {
    return postRequest<Map<String, dynamic>>(
      path: 'creator_work/get_info',
      showTips: false,
      parameter: {'novel_id': novelId},
      fromJson: (json) => json,
    );
  }

  /// 保存作品资料草稿
  static Future<ResultsType<Map<String, dynamic>>> saveDraft({
    required int novelId,
    required int revisionId,
    String? title,
    String? subtitle,
    String? introduction,
    String? coverUrl,
    int? coverWidth,
    int? coverHeight,
    String? contentUrl,
    int? wordCount,
    int? serializationStatus,
    List<Map<String, dynamic>>? categorySnapshot,
    int? lockVersion,
    Map<String, List<int>>? preferences,
    int? savedStep,
    bool? rightsConfirmed,
    int? releaseMode,
    String? scheduledPublishTime,
    String? tempChapterTitle,
    String? tempChapterContent,
    int? languageId,
    String? shortContent,
    int? workType,
    List<Map<String, dynamic>>? chapters,
  }) {
    return postRequest<Map<String, dynamic>>(
      path: 'creator_work/save_draft',
      showTips: false,
      parameter: {
        'novel_id': novelId,
        'revision_id': revisionId,
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (introduction != null) 'introduction': introduction,
        if (coverUrl != null) 'cover_url': coverUrl,
        if (coverWidth != null) 'cover_width': coverWidth,
        if (coverHeight != null) 'cover_height': coverHeight,
        if (contentUrl != null) 'content_url': contentUrl,
        if (wordCount != null) 'word_count': wordCount,
        if (serializationStatus != null)
          'serialization_status': serializationStatus,
        if (categorySnapshot != null) 'category_snapshot': categorySnapshot,
        if (lockVersion != null) 'lock_version': lockVersion,
        if (preferences != null) 'preferences': preferences,
        if (savedStep != null) 'saved_step': savedStep,
        if (rightsConfirmed != null) 'rights_confirmed': rightsConfirmed,
        if (releaseMode != null) 'release_mode': releaseMode,
        if (scheduledPublishTime != null)
          'scheduled_publish_time': scheduledPublishTime,
        if (tempChapterTitle != null) 'temp_chapter_title': tempChapterTitle,
        if (tempChapterContent != null)
          'temp_chapter_content': tempChapterContent,
        if (languageId != null) 'language_id': languageId,
        if (languageId != null) 'work_language_id': languageId,
        if (shortContent != null) 'short_content': shortContent,
        if (workType != null) 'work_type': workType,
        if (chapters != null) 'chapters': chapters,
      },
      fromJson: (json) => json,
    );
  }

  /// 提交审核
  static Future<ResultsType<Map<String, dynamic>>> submit({
    required int novelId,
    required int revisionId,
    required int submissionType,
    String? submitNote,
  }) {
    return postRequest<Map<String, dynamic>>(
      path: 'creator_work/submit',
      showTips: false,
      parameter: {
        'novel_id': novelId,
        'revision_id': revisionId,
        'submission_type': submissionType,
        if (submitNote != null) 'submit_note': submitNote,
      },
      fromJson: (json) => json,
    );
  }

  /// 撤回审核
  static Future<ResultsType<Map<String, dynamic>>> withdrawSubmission({
    required int submissionId,
  }) {
    return postRequest<Map<String, dynamic>>(
      path: 'creator_work/withdraw_submission',
      parameter: {'submission_id': submissionId},
      fromJson: (json) => json,
    );
  }

  /// 获取创作者统计数据
  static Future<ResultsType<Map<String, dynamic>>> dashboard() {
    return postRequest<Map<String, dynamic>>(
      path: 'creator_work/dashboard',
      fromJson: (json) => json,
    );
  }

  /// 获取草稿列表
  static Future<ResultsType<Map<String, dynamic>>> getDraftList({
    int page = 1,
    int pageSize = 20,
  }) {
    return postRequest<Map<String, dynamic>>(
      path: 'creator_work/get_draft_list',
      parameter: {'page': page, 'page_size': pageSize},
      fromJson: (json) => json,
    );
  }

  /// 删除作品
  static Future<ResultsType<Map<String, dynamic>>> deleteWork({
    required int novelId,
  }) {
    return postRequest<Map<String, dynamic>>(
      path: 'creator_work/delete',
      parameter: {'novel_id': novelId},
      fromJson: (json) => json,
    );
  }
}
