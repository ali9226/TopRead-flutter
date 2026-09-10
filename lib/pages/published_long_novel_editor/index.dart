// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import '../work_editor/workspace/index.dart';

/// 已发布长篇专用路由；资料保持原有两步表单，章节逐章编辑和发布。
class PublishedLongNovelEditorPage extends StatelessWidget {
  const PublishedLongNovelEditorPage({super.key, required this.novel_id});

  final int novel_id;

  @override
  Widget build(BuildContext context) => CreatorWorkspacePage(novelId: novel_id);
}
