// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';

/// 后端返回的作品数据模型
class CreatorWorkModel {
  /// 作品ID
  final int id;

  /// 作品标题
  final String title;

  /// 作品类型：1=长篇，2=短篇
  final int work_type;

  /// 连载状态：1=连载中，2=已完结
  final int serialization_status;

  /// 公开状态：1=未公开，2=已公开，3=作者下架，4=平台下架
  final int public_status;

  /// 首次审核状态：1=草稿，2=待审核，3=通过，4=驳回
  final int initial_audit_status;

  /// 兼容的发布状态
  final int publish_status;

  /// 阅读数
  final int read_count;

  /// 点赞数
  final int like_count;

  /// 收藏数
  final int favorite_count;

  /// 评论数
  final int comment_count;

  /// 最新章节号
  final int? latest_chapter_no;

  /// 最近内容更新时间
  final String? latest_update_time;

  /// 第一次公开发布时间
  final String? first_publish_time;

  /// 最近一次新内容公开时间
  final String? last_publish_time;

  /// 作者最后编辑草稿时间
  final String? creator_update_time;

  /// 创建时间
  final String create_time;

  /// 语种标题
  final String? language_title;

  /// 封面URL
  final String? cover_url;

  /// 章节数
  final int chapter_count;

  /// 字数
  final int word_count;

  /// 简介
  final String? introduction;

  /// 草稿修订ID
  final int? draft_revision_id;

  /// 草稿状态
  final int? draft_status;

  /// 待审核的审核单
  final Map<String, dynamic>? pending_submission;

  /// 定时发布时间
  final String? scheduled_publish_time;

  CreatorWorkModel({
    required this.id,
    required this.title,
    required this.work_type,
    required this.serialization_status,
    required this.public_status,
    required this.initial_audit_status,
    required this.publish_status,
    required this.read_count,
    required this.like_count,
    required this.favorite_count,
    required this.comment_count,
    this.latest_chapter_no,
    this.latest_update_time,
    this.first_publish_time,
    this.last_publish_time,
    this.creator_update_time,
    required this.create_time,
    this.language_title,
    this.cover_url,
    required this.chapter_count,
    required this.word_count,
    this.introduction,
    this.draft_revision_id,
    this.draft_status,
    this.pending_submission,
    this.scheduled_publish_time,
  });

  /// 从JSON解析
  factory CreatorWorkModel.fromJson(Map<String, dynamic> json) {
    return CreatorWorkModel(
      id: _parseInt(json['id']),
      title: json['title'] ?? '',
      work_type: _parseInt(json['work_type']),
      serialization_status: _parseInt(json['serialization_status']),
      public_status: _parseInt(json['public_status']),
      initial_audit_status: _parseInt(json['initial_audit_status']),
      publish_status: _parseInt(json['publish_status']),
      read_count: _parseInt(json['read_count']),
      like_count: _parseInt(json['like_count']),
      favorite_count: _parseInt(json['favorite_count']),
      comment_count: _parseInt(json['comment_count']),
      latest_chapter_no: _parseIntNullable(json['latest_chapter_no']),
      latest_update_time: json['latest_update_time'],
      first_publish_time: json['first_publish_time'],
      last_publish_time: json['last_publish_time'],
      creator_update_time: json['creator_update_time'],
      create_time: json['create_time'] ?? '',
      language_title: json['language_title'],
      cover_url: json['cover_url'],
      chapter_count: _parseInt(json['chapter_count']),
      word_count: _parseInt(json['word_count']),
      introduction: json['introduction'],
      draft_revision_id: _parseIntNullable(json['draft_revision_id']),
      draft_status: _parseIntNullable(json['draft_status']),
      pending_submission: json['pending_submission'],
      scheduled_publish_time: json['scheduled_publish_time'],
    );
  }

  /// 是否为长篇
  bool get is_long_novel => work_type == 1;

  /// 草稿接口的 id 是修订 ID；列表和导航始终以 novel_id 标识作品。
  factory CreatorWorkModel.fromDraftJson(Map<String, dynamic> json) {
    return CreatorWorkModel.fromJson({
      ...json,
      'id': json['novel_id'],
      'draft_revision_id': json['revision_id'] ?? json['id'],
      'draft_status': json['revision_status'] ?? 1,
      'initial_audit_status': _parseInt(json['initial_audit_status']) == 4
          ? 4
          : 1,
      'public_status': 1,
      'creator_update_time': json['update_time'] ?? json['creator_update_time'],
    });
  }

  DateTime get updatedAt =>
      DateTime.tryParse(
        creator_update_time ?? latest_update_time ?? create_time,
      )?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);

  /// 是否为短篇
  bool get is_short_novel => work_type == 2;

  /// 是否为草稿
  bool get is_draft => initial_audit_status == 1;

  /// 是否待审核
  bool get is_reviewing => initial_audit_status == 2;

  /// 是否已通过审核
  bool get is_approved => initial_audit_status == 3;

  /// 是否被驳回
  bool get is_rejected => initial_audit_status == 4;

  /// 是否已公开
  bool get is_published => public_status == 2;

  /// 是否已下架
  bool get is_off_shelf => public_status == 3 || public_status == 4;

  /// 是否待发布（已审核通过但未公开，等待定时发布）
  bool get is_pending_publish =>
      is_approved && public_status == 1 && scheduled_publish_time != null;

  /// 获取定时发布时间
  DateTime? get scheduled_publish_datetime {
    if (scheduled_publish_time == null) return null;
    return DateTime.tryParse(scheduled_publish_time!)?.toLocal();
  }

  /// 获取状态文本
  String get status_text {
    if (is_draft) return tr('creator_center.status_draft');
    if (is_reviewing) return tr('creator_center.status_reviewing');
    if (is_rejected) return tr('creator_center.status_rejected');
    if (is_off_shelf) return tr('creator_center.status_off_shelf');
    if (is_pending_publish) return tr('creator_center.pending_publish');
    if (is_published) return tr('creator_center.status_published');
    if (is_approved) return tr('creator_center.status_approved');
    return tr('creator_center.status_unpublished');
  }

  /// 获取作品类型文本
  String get work_type_text => is_long_novel ? tr('creator_center.work_type_long') : tr('creator_center.work_type_short');

  /// 获取连载状态文本
  String get serialization_status_text =>
      serialization_status == 1 ? tr('creator_center.serialization_ongoing') : tr('creator_center.serialization_completed');

  static int _parseInt(dynamic value) => _parseIntNullable(value) ?? 0;

  static int? _parseIntNullable(dynamic value) {
    if (value is int) return value;
    if (value is num && value.isFinite) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

/// 后端返回的章节数据模型
class CreatorChapterModel {
  /// 章节修订ID
  final int id;

  /// 章节UID
  final String chapter_uid;

  /// 已发布章节ID
  final int? chapter_id;

  /// 章节序号
  final int? chapter_no;

  /// 章节标题
  final String title;

  /// 字数
  final int word_count;

  /// 修订状态：1=草稿，2=已锁定待审，3=已发布，4=驳回
  final int revision_status;

  /// 变更类型：1=新增，2=修改，3=删除申请
  final int change_type;

  /// 正文URL
  final String? content_url;

  /// 创建时间
  final String create_time;

  /// 更新时间
  final String update_time;

  /// 已发布时间
  final String? published_time;

  CreatorChapterModel({
    required this.id,
    required this.chapter_uid,
    this.chapter_id,
    this.chapter_no,
    required this.title,
    required this.word_count,
    required this.revision_status,
    required this.change_type,
    this.content_url,
    required this.create_time,
    required this.update_time,
    this.published_time,
  });

  /// 从JSON解析
  factory CreatorChapterModel.fromJson(Map<String, dynamic> json) {
    return CreatorChapterModel(
      id: _parseInt(json['id']),
      chapter_uid: json['chapter_uid'] ?? '',
      chapter_id: _parseIntNullable(json['chapter_id']),
      chapter_no: _parseIntNullable(json['chapter_no']),
      title: json['title'] ?? '',
      word_count: _parseInt(json['word_count']),
      revision_status: _parseInt(json['revision_status']),
      change_type: _parseInt(json['change_type']),
      content_url: json['content_url'],
      create_time: json['create_time'] ?? '',
      update_time: json['update_time'] ?? '',
      published_time: json['published_time'],
    );
  }

  /// 是否为草稿
  bool get is_draft => revision_status == 1;

  /// 是否待审核
  bool get is_reviewing => revision_status == 2;

  /// 是否已发布
  bool get is_published => revision_status == 3;

  /// 是否被驳回
  bool get is_rejected => revision_status == 4;

  /// 是否有已发布版本
  bool get has_published_version => chapter_id != null;

  /// 获取状态文本
  String get status_text {
    if (is_draft) return tr('creator_center.chapter_status_draft');
    if (is_reviewing) return tr('creator_center.chapter_status_reviewing');
    if (is_published) return tr('creator_center.chapter_status_published');
    if (is_rejected) return tr('creator_center.chapter_status_rejected');
    return tr('creator_center.status_unknown');
  }

  static int _parseInt(dynamic value) => _parseIntNullable(value) ?? 0;

  static int? _parseIntNullable(dynamic value) {
    if (value is int) return value;
    if (value is num && value.isFinite) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

/// 后端返回的审核单数据模型
class CreatorSubmissionModel {
  /// 审核单ID
  final int id;

  /// 审核单号
  final String submission_no;

  /// 作者ID
  final int author_id;

  /// 作者名称
  final String author_name;

  /// 作品ID
  final int novel_id;

  /// 投稿类型：1=首次投稿，2=资料更新，3=新增章节，4=章节修改，5=章节删除
  final int submission_type;

  /// 审核状态：1=待审核，2=审核中，3=通过，4=驳回，5=作者撤回
  final int status;

  /// 作者说明
  final String? submit_note;

  /// 审核说明
  final String? review_note;

  /// 审核员ID
  final int? reviewer_id;

  /// 提交时间
  final String submit_time;

  /// 审核时间
  final String? review_time;

  /// 作品标题
  final String? novel_title;

  /// 作品类型
  final int? work_type;

  /// 封面URL
  final String? cover_url;

  /// 章节数
  final int chapter_count;

  CreatorSubmissionModel({
    required this.id,
    required this.submission_no,
    required this.author_id,
    required this.author_name,
    required this.novel_id,
    required this.submission_type,
    required this.status,
    this.submit_note,
    this.review_note,
    this.reviewer_id,
    required this.submit_time,
    this.review_time,
    this.novel_title,
    this.work_type,
    this.cover_url,
    required this.chapter_count,
  });

  /// 从JSON解析
  factory CreatorSubmissionModel.fromJson(Map<String, dynamic> json) {
    return CreatorSubmissionModel(
      id: _parseInt(json['id']),
      submission_no: json['submission_no'] ?? '',
      author_id: _parseInt(json['author_id']),
      author_name: json['author_name'] ?? '',
      novel_id: _parseInt(json['novel_id']),
      submission_type: _parseInt(json['submission_type']),
      status: _parseInt(json['status']),
      submit_note: json['submit_note'],
      review_note: json['review_note'],
      reviewer_id: json['reviewer_id'] != null
          ? _parseInt(json['reviewer_id'])
          : null,
      submit_time: json['submit_time'] ?? '',
      review_time: json['review_time'],
      novel_title: json['novel_title'],
      work_type: json['work_type'] != null
          ? _parseInt(json['work_type'])
          : null,
      cover_url: json['cover_url'],
      chapter_count: _parseInt(json['chapter_count']),
    );
  }

  /// 是否待审核
  bool get is_pending => status == 1 || status == 2;

  /// 是否已通过
  bool get is_approved => status == 3;

  /// 是否已驳回
  bool get is_rejected => status == 4;

  /// 是否已撤回
  bool get is_withdrawn => status == 5;

  /// 获取状态文本
  String get status_text {
    switch (status) {
      case 1:
        return tr('creator_center.submission_status_pending');
      case 2:
        return tr('creator_center.submission_status_reviewing');
      case 3:
        return tr('creator_center.submission_status_approved');
      case 4:
        return tr('creator_center.submission_status_rejected');
      case 5:
        return tr('creator_center.submission_status_withdrawn');
      default:
        return tr('creator_center.status_unknown');
    }
  }

  /// 获取投稿类型文本
  String get submission_type_text {
    switch (submission_type) {
      case 1:
        return tr('creator_center.submission_type_first');
      case 2:
        return tr('creator_center.submission_type_update');
      case 3:
        return tr('creator_center.submission_type_add_chapter');
      case 4:
        return tr('creator_center.submission_type_edit_chapter');
      case 5:
        return tr('creator_center.submission_type_delete_chapter');
      default:
        return tr('creator_center.status_unknown');
    }
  }

  static int _parseInt(dynamic value) => _parseIntNullable(value) ?? 0;

  static int? _parseIntNullable(dynamic value) {
    if (value is int) return value;
    if (value is num && value.isFinite) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
