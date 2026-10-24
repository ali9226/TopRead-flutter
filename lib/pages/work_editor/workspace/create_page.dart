// ignore_for_file: non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/util/language_util/language_permission.dart';
import 'creation_request.dart';
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
  final _creation_request = WorkspaceCreationRequest();
  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  Future<void> create() async {
    if (busy || language == null) return;
    // 提交前重新检查当前可见配置，防止打开页面后撤销中文权限仍提交旧 ID。
    final store = Get.isRegistered<LanguageStore>()
        ? Get.find<LanguageStore>()
        : null;
    final language_is_visible =
        store?.visible_language_list.any(
          (item) =>
              item.id == language &&
              LanguagePermission.is_language_allowed(item.language_code),
        ) ??
        false;
    if (!language_is_visible) {
      setState(() {
        language = null;
        error = tr('creator_center.config_not_loaded');
      });
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await _creation_request.create(
        title: title.text,
        work_type: type,
        language_id: language!,
      );
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
        appBar: WindowAppBar(
          child: AppBar(title: Text(tr('creator_workspace.create'))),
        ),
        body: const WindowContentLayout(
          child: Center(child: Text('语种配置尚未加载，请稍后重试')),
        ),
      );
    }
    return Obx(() {
      final locked = busy || _creation_request.has_pending;
      final languages = store.visible_language_list.toList();
      // 已选项不再可见时重新选择默认值，避免 Dropdown 使用不存在的初始 ID。
      if (!languages.any((item) => item.id == language)) {
        final locale_code = LanguagePermission.resolve_language_code(
          context.locale.languageCode,
        );
        final preferred = languages.where(
          (item) => item.language_code == locale_code,
        );
        final english = languages.where((item) => item.language_code == 'en');
        language = preferred.isNotEmpty
            ? preferred.first.id
            : english.isNotEmpty
            ? english.first.id
            : languages.isEmpty
            ? null
            : languages.first.id;
      }
      return Scaffold(
        appBar: WindowAppBar(
          child: AppBar(title: Text(tr('creator_workspace.create'))),
        ),
        body: WindowContentLayout(
          child: ListView(
            padding: const EdgeInsets.all(LayoutConfig.space_20),
            children: [
              Text(tr('creator_workspace.create_hint')),
              const SizedBox(height: LayoutConfig.space_20),
              TextField(
                controller: title,
                enabled: !locked,
                maxLength: 255,
                decoration: InputDecoration(
                  labelText: tr('creator_workspace.work_title'),
                ),
              ),
              const SizedBox(height: LayoutConfig.space_16),
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
                onSelectionChanged: locked
                    ? null
                    : (v) => setState(() {
                        type = v.first;
                      }),
              ),
              const SizedBox(height: LayoutConfig.space_20),
              DropdownButtonFormField<int>(
                // 重建状态并关闭旧菜单，避免已展开的下拉保留被撤销的中文选项。
                key: ValueKey<String>(
                  '$language:${languages.map((item) => item.id).join(',')}',
                ),
                initialValue: language,
                decoration: InputDecoration(
                  labelText: tr('creator_workspace.language'),
                ),
                items: languages
                    .map(
                      (l) =>
                          DropdownMenuItem(value: l.id, child: Text(l.title)),
                    )
                    .toList(),
                onChanged: locked
                    ? null
                    : (value) => setState(() {
                        language = value;
                      }),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: LayoutConfig.space_16,
                  ),
                  child: Text(error!),
                ),
              const SizedBox(height: LayoutConfig.space_24),
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
        ),
      );
    });
  }
}
