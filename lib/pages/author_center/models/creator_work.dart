// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

/// TODO 创作者作品篇幅类型。
enum CreatorWorkType {
  /// TODO 长篇作品，正文按章节管理。
  long,

  /// TODO 短篇作品，正文在作品编辑页内一次性完成。
  short,
}

/// TODO 创作者作品当前状态。
enum CreatorWorkStatus {
  /// TODO 仅作者可见的草稿。
  draft,

  /// TODO 已提交且等待后台审核。
  reviewing,

  /// TODO 审核通过并等待指定时间发布。
  scheduled,

  /// TODO 已经公开发布。
  published,

  /// TODO 审核被驳回，可继续修改后重新提交。
  rejected,
}

/// TODO 审核通过后的发布方式。
enum CreatorReleaseMode {
  /// TODO 审核通过后立即发布。
  immediate,

  /// TODO 审核通过后到指定时间再发布。
  scheduled,
}

/// TODO 长篇章节的本地 UI 草稿模型。
class CreatorChapterDraft {
  /// TODO 本地稳定标识，用于编辑、删除和列表动画。
  final String local_id;

  /// TODO 章节标题。
  final String title;

  /// TODO 章节正文。
  final String content;

  /// TODO 最近一次在本地编辑的时间。
  final DateTime update_time;

  const CreatorChapterDraft({
    required this.local_id,
    required this.title,
    required this.content,
    required this.update_time,
  });

  /// TODO 使用最新字段生成新实例，避免直接修改已有对象。
  CreatorChapterDraft copy_with({
    String? title,
    String? content,
    DateTime? update_time,
  }) {
    return CreatorChapterDraft(
      local_id: local_id,
      title: title ?? this.title,
      content: content ?? this.content,
      update_time: update_time ?? this.update_time,
    );
  }

  /// TODO 按非空白字符计算字数，UI 阶段用于实时反馈。
  int get word_count => content.replaceAll(RegExp(r'\s+'), '').length;

  /// TODO 转换为 JSON Map。
  Map<String, dynamic> to_json() {
    return <String, dynamic>{
      'local_id': local_id,
      'title': title,
      'content': content,
      'update_time': update_time.millisecondsSinceEpoch,
    };
  }

  /// TODO 从 JSON Map 解析。
  factory CreatorChapterDraft.from_json(Map<String, dynamic> json) {
    return CreatorChapterDraft(
      local_id: json['local_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      update_time: DateTime.fromMillisecondsSinceEpoch(
        json['update_time'] is int
            ? json['update_time']
            : int.tryParse(json['update_time']?.toString() ?? '0') ?? 0,
      ),
    );
  }
}

/// TODO 创作者作品的本地 UI 草稿模型。
///
/// 编辑器通过该模型恢复服务端草稿，并在保存或提交后返回最新状态。
class CreatorWorkDraft {
  /// TODO 本地稳定标识。
  final String local_id;

  /// 后端作品ID（已保存到后端时有值）。
  final int? novel_id;

  /// 后端修订版本ID（已保存到后端时有值）。
  final int? revision_id;

  /// 后端语种版本ID（已保存到后端时有值）。
  final int? novel_language_id;

  /// 原始语种 ID，按服务端配置保存。
  final int? language_id;

  /// 乐观锁版本号。
  final int? lock_version;

  /// TODO 作品标题。
  final String title;

  /// TODO 作品简介。
  final String introduction;

  /// TODO 长篇或短篇。
  final CreatorWorkType work_type;

  /// TODO 是否已完结。
  final bool is_completed;

  /// TODO 原始创作语种代码。
  final String language_code;

  /// TODO 作者选中的分类 id 列表。
  final List<int> category_ids;

  /// TODO 短篇正文；长篇时保持为空。
  final String short_content;

  /// TODO 长篇章节列表；短篇时保持为空。
  final List<CreatorChapterDraft> chapters;

  /// TODO 当前作品状态。
  final CreatorWorkStatus status;

  /// TODO 审核通过后的发布方式。
  final CreatorReleaseMode release_mode;

  /// TODO 定时发布时刻；立即发布时为空。
  final DateTime? scheduled_publish_time;

  /// TODO 最近一次本地编辑时间。
  final DateTime update_time;

  /// TODO 是否为仅供开发阶段查看布局的示例作品。
  final bool is_demo;

  /// TODO 已上传的封面 URL。
  final String? cover_url;

  /// TODO 保存草稿时的步骤索引（用于恢复进度）。
  final int saved_step;

  /// TODO 所有偏好选择（key 为偏好分组 id，value 为已选选项 id 集合）。
  final Map<String, List<int>> preferences;

  /// TODO 是否已确认发布权声明。
  final bool rights_confirmed;

  /// TODO 长篇新增模式下的当前章节标题。
  final String chapter_title;

  /// TODO 长篇新增模式下的当前章节内容。
  final String chapter_content;

  const CreatorWorkDraft({
    required this.local_id,
    this.novel_id,
    this.revision_id,
    this.novel_language_id,
    this.lock_version,
    this.language_id,
    required this.title,
    required this.introduction,
    required this.work_type,
    required this.is_completed,
    required this.language_code,
    required this.category_ids,
    required this.short_content,
    required this.chapters,
    required this.status,
    required this.release_mode,
    required this.scheduled_publish_time,
    required this.update_time,
    this.is_demo = false,
    this.cover_url,
    this.saved_step = 0,
    this.preferences = const <String, List<int>>{},
    this.rights_confirmed = false,
    this.chapter_title = '',
    this.chapter_content = '',
  });

  /// 是否已保存到后端（有 novel_id 和 revision_id）。
  bool get is_saved_to_backend => novel_id != null && revision_id != null;

  /// TODO 返回作品当前总字数。
  int get word_count {
    if (work_type == CreatorWorkType.short) {
      return short_content.replaceAll(RegExp(r'\s+'), '').length;
    }

    return chapters.fold<int>(
      0,
      (int total, CreatorChapterDraft chapter) => total + chapter.word_count,
    );
  }

  /// TODO 使用最新字段生成新实例。
  CreatorWorkDraft copy_with({
    String? title,
    String? introduction,
    CreatorWorkType? work_type,
    bool? is_completed,
    String? language_code,
    List<int>? category_ids,
    String? short_content,
    List<CreatorChapterDraft>? chapters,
    CreatorWorkStatus? status,
    CreatorReleaseMode? release_mode,
    DateTime? scheduled_publish_time,
    bool clear_scheduled_publish_time = false,
    DateTime? update_time,
    bool? is_demo,
    String? cover_url,
    int? saved_step,
    Map<String, List<int>>? preferences,
    bool? rights_confirmed,
    String? chapter_title,
    String? chapter_content,
    int? novel_id,
    int? revision_id,
    int? novel_language_id,
    int? lock_version,
    int? language_id,
  }) {
    return CreatorWorkDraft(
      local_id: local_id,
      novel_id: novel_id ?? this.novel_id,
      revision_id: revision_id ?? this.revision_id,
      novel_language_id: novel_language_id ?? this.novel_language_id,
      lock_version: lock_version ?? this.lock_version,
      language_id: language_id ?? this.language_id,
      title: title ?? this.title,
      introduction: introduction ?? this.introduction,
      work_type: work_type ?? this.work_type,
      is_completed: is_completed ?? this.is_completed,
      language_code: language_code ?? this.language_code,
      category_ids: category_ids ?? this.category_ids,
      short_content: short_content ?? this.short_content,
      chapters: chapters ?? this.chapters,
      status: status ?? this.status,
      release_mode: release_mode ?? this.release_mode,
      scheduled_publish_time: clear_scheduled_publish_time
          ? null
          : scheduled_publish_time ?? this.scheduled_publish_time,
      update_time: update_time ?? this.update_time,
      is_demo: is_demo ?? this.is_demo,
      cover_url: cover_url ?? this.cover_url,
      saved_step: saved_step ?? this.saved_step,
      preferences: preferences ?? this.preferences,
      rights_confirmed: rights_confirmed ?? this.rights_confirmed,
      chapter_title: chapter_title ?? this.chapter_title,
      chapter_content: chapter_content ?? this.chapter_content,
    );
  }

  /// TODO 转换为 JSON Map（用于本地持久化）。
  Map<String, dynamic> to_json() {
    return <String, dynamic>{
      'local_id': local_id,
      'novel_id': novel_id,
      'revision_id': revision_id,
      'novel_language_id': novel_language_id,
      'lock_version': lock_version,
      'language_id': language_id,
      'title': title,
      'introduction': introduction,
      'work_type': work_type.index,
      'is_completed': is_completed,
      'language_code': language_code,
      'category_ids': category_ids,
      'short_content': short_content,
      'chapters': chapters.map((CreatorChapterDraft c) => c.to_json()).toList(),
      'status': status.index,
      'release_mode': release_mode.index,
      'scheduled_publish_time': scheduled_publish_time?.millisecondsSinceEpoch,
      'update_time': update_time.millisecondsSinceEpoch,
      'is_demo': is_demo,
      'cover_url': cover_url,
      'saved_step': saved_step,
      'preferences': preferences.map((key, value) => MapEntry(key, value)),
      'rights_confirmed': rights_confirmed,
      'chapter_title': chapter_title,
      'chapter_content': chapter_content,
    };
  }

  /// TODO 从 JSON Map 解析。
  factory CreatorWorkDraft.from_json(Map<String, dynamic> json) {
    return CreatorWorkDraft(
      local_id: json['local_id']?.toString() ?? '',
      novel_id: json['novel_id'] != null
          ? (json['novel_id'] is int
                ? json['novel_id']
                : int.tryParse(json['novel_id'].toString()))
          : null,
      revision_id: json['revision_id'] != null
          ? (json['revision_id'] is int
                ? json['revision_id']
                : int.tryParse(json['revision_id'].toString()))
          : null,
      novel_language_id: json['novel_language_id'] != null
          ? (json['novel_language_id'] is int
                ? json['novel_language_id']
                : int.tryParse(json['novel_language_id'].toString()))
          : null,
      lock_version: json['lock_version'] != null
          ? (json['lock_version'] is int
                ? json['lock_version']
                : int.tryParse(json['lock_version'].toString()))
          : null,
      language_id: int.tryParse(json['language_id']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      introduction: json['introduction']?.toString() ?? '',
      work_type:
          CreatorWorkType.values[json['work_type'] is int
              ? json['work_type']
              : int.tryParse(json['work_type']?.toString() ?? '0') ?? 0],
      is_completed: json['is_completed'] == true,
      language_code: json['language_code']?.toString() ?? 'zh',
      category_ids:
          (json['category_ids'] as List<dynamic>?)
              ?.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
              .toList() ??
          <int>[],
      short_content: json['short_content']?.toString() ?? '',
      chapters:
          (json['chapters'] as List<dynamic>?)
              ?.map(
                (e) => CreatorChapterDraft.from_json(
                  e is Map<String, dynamic> ? e : <String, dynamic>{},
                ),
              )
              .toList() ??
          <CreatorChapterDraft>[],
      status:
          CreatorWorkStatus.values[json['status'] is int
              ? json['status']
              : int.tryParse(json['status']?.toString() ?? '0') ?? 0],
      release_mode:
          CreatorReleaseMode.values[json['release_mode'] is int
              ? json['release_mode']
              : int.tryParse(json['release_mode']?.toString() ?? '0') ?? 0],
      scheduled_publish_time: json['scheduled_publish_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['scheduled_publish_time'] is int
                  ? json['scheduled_publish_time']
                  : int.tryParse(json['scheduled_publish_time'].toString()) ??
                        0,
            )
          : null,
      update_time: DateTime.fromMillisecondsSinceEpoch(
        json['update_time'] is int
            ? json['update_time']
            : int.tryParse(json['update_time']?.toString() ?? '0') ?? 0,
      ),
      is_demo: json['is_demo'] == true,
      cover_url: json['cover_url']?.toString(),
      saved_step: json['saved_step'] is int
          ? json['saved_step']
          : int.tryParse(json['saved_step']?.toString() ?? '0') ?? 0,
      preferences: _parse_preferences(json['preferences']),
      rights_confirmed: json['rights_confirmed'] == true,
      chapter_title: json['chapter_title']?.toString() ?? '',
      chapter_content: json['chapter_content']?.toString() ?? '',
    );
  }

  /// TODO 解析偏好 JSON。
  static Map<String, List<int>> _parse_preferences(dynamic raw) {
    if (raw == null) return <String, List<int>>{};

    // 处理 JSON 字符串
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return _parse_preferences(decoded);
        }
      } catch (_) {}
      return <String, List<int>>{};
    }

    if (raw is! Map) return <String, List<int>>{};
    final Map<String, List<int>> result = {};
    raw.forEach((key, value) {
      if (key is String && value is List) {
        result[key] = value
            .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
            .toList();
      }
    });
    return result;
  }
}
