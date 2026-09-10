// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'long_novel_editor/index.dart';
import '../short_novel_editor/index.dart';

/// 兼容已有调用，编辑逻辑由独立的长篇、短篇页面维护。
class CreatorWorkEditorPage extends StatelessWidget {
  const CreatorWorkEditorPage({
    super.key,
    this.initial_work,
    this.metadataOnly = false,
    this.saveOnly = false,
    this.restorePending = false,
  });

  final CreatorWorkDraft? initial_work;
  final bool metadataOnly;
  final bool saveOnly;
  final bool restorePending;

  @override
  Widget build(BuildContext context) =>
      initial_work?.work_type == CreatorWorkType.short
      ? ShortNovelEditorPage(
          initial_work: initial_work,
          metadataOnly: metadataOnly,
          saveOnly: saveOnly,
          restorePending: restorePending,
        )
      : LongNovelEditorPage(
          initial_work: initial_work,
          metadataOnly: metadataOnly,
          saveOnly: saveOnly,
          restorePending: restorePending,
        );
}
