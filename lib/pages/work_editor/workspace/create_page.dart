import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/api/creator_workspace.dart';
import '../single_chapter/logic.dart';
import 'index.dart';
import 'logic.dart';

/* TODO 新建作品先建立稳定作品ID；之后的资料和每章草稿都进入同一个管理页。 */
class CreateWorkspacePage extends StatefulWidget {
  const CreateWorkspacePage({super.key});
  @override
  State<CreateWorkspacePage> createState() => _CreateWorkspacePageState();
}

class _CreateWorkspacePageState extends State<CreateWorkspacePage> {
  final title = TextEditingController();
  int type = 1;
  int? language;
  bool busy = false;
  String? error;
  String requestKey = creatorRequestKey();
  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  Future<void> create() async {
    if (busy || language == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result =
          await CreatorWorkspaceApi.call('creator_work/create_draft', {
            'title': title.text,
            'work_type': type,
            'work_language_id': language,
            'request_key': requestKey,
          });
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CreatorWorkspacePage(novelId: creatorNumber(result['novel_id'])),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.isRegistered<LanguageStore>()
        ? Get.find<LanguageStore>()
        : null;
    if (store == null) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('creator_workspace.create'))),
        body: const Center(child: Text('语种配置尚未加载，请稍后重试')),
      );
    }
    return Obx(() {
      final languages = store.supported_language_list.toList();
      language ??=
          store
              .find_supported_language_by_code(context.locale.languageCode)
              ?.id ??
          (languages.isEmpty ? null : languages.first.id);
      return Scaffold(
        appBar: AppBar(title: Text(tr('creator_workspace.create'))),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(tr('creator_workspace.create_hint')),
            const SizedBox(height: 20),
            TextField(
              controller: title,
              enabled: !busy,
              maxLength: 255,
              onChanged: (_) => requestKey = creatorRequestKey(),
              decoration: InputDecoration(
                labelText: tr('creator_workspace.work_title'),
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 1,
                  label: Text(tr('creator_workspace.long')),
                ),
                ButtonSegment(
                  value: 2,
                  label: Text(tr('creator_workspace.short')),
                ),
              ],
              selected: {type},
              onSelectionChanged: busy
                  ? null
                  : (v) => setState(() {
                      type = v.first;
                      requestKey = creatorRequestKey();
                    }),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              initialValue: language,
              decoration: InputDecoration(
                labelText: tr('creator_workspace.language'),
              ),
              items: languages
                  .map(
                    (l) => DropdownMenuItem(value: l.id, child: Text(l.title)),
                  )
                  .toList(),
              onChanged: busy
                  ? null
                  : (value) => setState(() {
                      language = value;
                      requestKey = creatorRequestKey();
                    }),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(error!),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: busy || language == null ? null : create,
              child: Text(
                tr(
                  busy
                      ? 'creator_workspace.saving'
                      : 'creator_workspace.create',
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
