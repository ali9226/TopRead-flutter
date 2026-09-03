// ignore_for_file: non_constant_identifier_names

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
}

/// TODO 创作者作品的本地 UI 草稿模型。
///
/// 当前阶段不接后端，页面通过该模型完成新增、编辑、筛选和状态预览。
class CreatorWorkDraft {
  /// TODO 本地稳定标识。
  final String local_id;

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

  /// TODO 作者选中的分类名称。
  final List<String> categories;

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

  const CreatorWorkDraft({
    required this.local_id,
    required this.title,
    required this.introduction,
    required this.work_type,
    required this.is_completed,
    required this.language_code,
    required this.categories,
    required this.short_content,
    required this.chapters,
    required this.status,
    required this.release_mode,
    required this.scheduled_publish_time,
    required this.update_time,
    this.is_demo = false,
  });

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
    List<String>? categories,
    String? short_content,
    List<CreatorChapterDraft>? chapters,
    CreatorWorkStatus? status,
    CreatorReleaseMode? release_mode,
    DateTime? scheduled_publish_time,
    bool clear_scheduled_publish_time = false,
    DateTime? update_time,
    bool? is_demo,
  }) {
    return CreatorWorkDraft(
      local_id: local_id,
      title: title ?? this.title,
      introduction: introduction ?? this.introduction,
      work_type: work_type ?? this.work_type,
      is_completed: is_completed ?? this.is_completed,
      language_code: language_code ?? this.language_code,
      categories: categories ?? this.categories,
      short_content: short_content ?? this.short_content,
      chapters: chapters ?? this.chapters,
      status: status ?? this.status,
      release_mode: release_mode ?? this.release_mode,
      scheduled_publish_time: clear_scheduled_publish_time
          ? null
          : scheduled_publish_time ?? this.scheduled_publish_time,
      update_time: update_time ?? this.update_time,
      is_demo: is_demo ?? this.is_demo,
    );
  }
}
