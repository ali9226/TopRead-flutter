// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/_shared/backend_draft_loader.dart';
import 'package:app/pages/long_novel_editor/index.dart';
import 'package:app/pages/published_long_novel_editor/index.dart';
import 'package:app/pages/short_novel_editor/index.dart';
import 'package:flutter/material.dart';

// TODO 同一路由支持新增与带编号编辑；直接打开链接时仍以服务端状态选择编辑方式。
class CreatorEditorRoute extends StatefulWidget {
  const CreatorEditorRoute({super.key, required this.work_type, this.novel_id, this.initial_work});
  final CreatorWorkType work_type;
  final int? novel_id;
  final CreatorWorkDraft? initial_work;

  @override
  State<CreatorEditorRoute> createState() => _CreatorEditorRouteState();
}

class _CreatorEditorRouteState extends State<CreatorEditorRoute> {
  late final Future<CreatorWorkDraft?> _work = _load();

  Future<CreatorWorkDraft?> _load() async {
    if (widget.initial_work != null) return widget.initial_work;
    if (widget.novel_id == null) return null;
    final summary = await loadCreatorWorkDraft(widget.novel_id!, includeChapters: false);
    if (summary.work_type == CreatorWorkType.long && summary.status != CreatorWorkStatus.published) {
      return loadCreatorWorkDraft(widget.novel_id!);
    }
    return summary;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<CreatorWorkDraft?>(
    future: _work,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return Scaffold(appBar: AppBar(), body: Center(child: Text('${snapshot.error}')));
      }
      final work = snapshot.data;
      final type = work?.work_type ?? widget.work_type;
      if (type == CreatorWorkType.short) return ShortNovelEditorPage(initial_work: work);
      if (work?.status == CreatorWorkStatus.published) {
        return PublishedLongNovelEditorPage(novel_id: work!.novel_id!);
      }
      return LongNovelEditorPage(initial_work: work);
    },
  );
}
