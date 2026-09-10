import 'dart:convert';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'draft_persistence.dart';
import 'package:get/get.dart';
import 'package:app/stores/preference_store.dart';
import 'package:app/stores/language_store.dart';

// TODO 按账号和修订隔离恢复副本，不把一个账号的草稿带入另一个账号。
String creatorWorkRecoveryKey(int owner, int revision) =>
    'creator_work_recovery_${owner}_$revision';

// TODO 云端与本机不同时明确展示差异；只有作者选择恢复后才采用当前云端锁版本。
Future<({CreatorWorkDraft draft, bool restored})> restoreCreatorWork(
  BuildContext context,
  CreatorWorkDraft cloud,
  int owner,
) async {
  if (!cloud.can_save_draft || cloud.revision_id == null) return (draft: cloud, restored: false);
  final key = creatorWorkRecoveryKey(owner, cloud.revision_id!);
  final raw = await StorageUtil.getData(key);
  if (raw == null) return (draft: cloud, restored: false);
  final local = CreatorWorkDraft.from_json(
    Map<String, dynamic>.from(jsonDecode(raw)),
  );
  if (!context.mounted ||
      creatorDraftFingerprint(local) == creatorDraftFingerprint(cloud))
    return (draft: cloud, restored: false);
  String describe(CreatorWorkDraft work) {
    final preferences = Get.isRegistered<PreferenceStore>()
        ? Get.find<PreferenceStore>()
        : null;
    final details = <String>[];
    for (final group in preferences?.preference_list ?? []) {
      final chosen = work.preferences['${group.id}'] ?? [];
      final labels = group.data_list
          .where((item) => chosen.contains(item.id))
          .map((item) => item.title)
          .join('、');
      if (labels.isNotEmpty) details.add('${group.title}：$labels');
    }
    final language = Get.isRegistered<LanguageStore>()
        ? Get.find<LanguageStore>()
              .find_supported_language_by_code(work.language_code)
              ?.title
        : null;
    return '${work.title}\n${work.introduction}\n\n${work.short_content}\n\n${language ?? ''}\n${details.join('\n')}';
  }

  Widget preview(CreatorWorkDraft work) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SelectableText(describe(work)),
      if (work.cover_url?.isNotEmpty == true)
        Image.network(
          work.cover_url!,
          width: 90,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (_, error, stack) =>
              const Icon(Icons.broken_image_outlined),
        ),
    ],
  );
  final useLocal = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(tr('creator_workspace.recovery_title')),
        content: SizedBox(
          width: 600,
          height: 360,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('creator_workspace.recovery_hint')),
                const SizedBox(height: 16),
                Text(tr('creator_workspace.cloud_copy')),
                preview(cloud),
                const Divider(),
                Text(tr('creator_workspace.local_copy')),
                preview(local),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('creator_workspace.use_cloud')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('creator_workspace.use_local')),
          ),
        ],
      ),
    ),
  );
  if (useLocal != true) {
    await StorageUtil.removeData(key);
    return (draft: cloud, restored: false);
  }
  return (
    draft: local.copy_with(
      novel_id: cloud.novel_id,
      revision_id: cloud.revision_id,
      novel_language_id: cloud.novel_language_id,
      lock_version: cloud.lock_version,
      status: cloud.status,
    ),
    restored: true,
  );
}
