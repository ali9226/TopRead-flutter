// ignore_for_file: non_constant_identifier_names

import 'package:app/components/window_content_layout/index.dart';
import 'package:app/pages/comics/editor/logic.dart';
import 'package:app/pages/comics/editor/style.dart';
import 'package:app/pages/comics/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 编辑器底部操作栏：保存草稿 + 提交审核 + 更多（下架）。
class ComicEditorActionBar extends StatelessWidget {
  /// 编辑器逻辑层。
  final ComicEditorLogic logic;

  /// 是否允许操作（审核中锁定）。
  final bool enabled;

  /// 保存草稿回调。
  final VoidCallback on_save_draft;

  /// 提交审核回调。
  final VoidCallback on_submit;

  /// 下架漫画回调；新建作品时隐藏入口。
  final VoidCallback? on_hide;

  const ComicEditorActionBar({
    super.key,
    required this.logic,
    required this.enabled,
    required this.on_save_draft,
    required this.on_submit,
    this.on_hide,
  });

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = ComicsStyle.is_cjk(context);
    return Container(
      decoration: BoxDecoration(
        color: ComicsStyle.surface(context),
        border: Border(top: BorderSide(color: ComicsStyle.outline(context))),
      ),
      child: SafeArea(
        top: false,
        child: WindowContentLayout(
          expand_height: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ComicEditorStyle.action_bar_padding_h,
              vertical: ComicEditorStyle.action_bar_padding_v,
            ),
            child: Row(
              children: <Widget>[
                /// 下架入口（已有作品且可编辑时）。
                if (on_hide != null)
                  IconButton(
                    tooltip: tr('comics.remove_comic'),
                    onPressed: enabled ? on_hide : null,
                    icon: const Icon(Icons.visibility_off_outlined),
                    color: ComicsStyle.muted(context),
                  ),

                /// 保存草稿。
                Expanded(
                  child: OutlinedButton(
                    onPressed: enabled && !logic.busy ? on_save_draft : null,
                    style: ComicEditorStyle.secondary_button(context),
                    child: logic.saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(tr('comics.save_draft')),
                  ),
                ),
                SizedBox(width: is_cjk ? 8 : 10),

                /// 提交审核：主题金主按钮。
                Expanded(
                  child: ElevatedButton(
                    onPressed: enabled && !logic.busy ? on_submit : null,
                    style: ComicEditorStyle.primary_button(context),
                    child: logic.submitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(tr('comics.submit_review')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
