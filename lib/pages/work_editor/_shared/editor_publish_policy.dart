// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/author_center/models/creator_work.dart';

/// 长短篇共用发布状态规则，页面仅负责保留各自的编辑步骤。
class EditorPublishPolicy {
  const EditorPublishPolicy(this.work);

  final CreatorWorkDraft? work;

  bool get is_published => work?.status == CreatorWorkStatus.published;
  bool get is_scheduled => work?.status == CreatorWorkStatus.scheduled;
  bool get can_save_draft => work == null || work!.can_save_draft;
  bool get show_publish_step => !is_published;
}
