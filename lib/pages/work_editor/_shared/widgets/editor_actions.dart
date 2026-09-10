// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/work_editor/_shared/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 长短篇共用顶栏草稿按钮，沿用已有尺寸、颜色和位置。
class EditorSaveDraftButton extends StatelessWidget {
  const EditorSaveDraftButton({
    super.key,
    required this.is_saving,
    required this.on_save,
  });

  final bool is_saving;
  final VoidCallback on_save;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: WorkEditorStyle.page_padding),
    child: ElevatedButton(
      onPressed: is_saving ? null : on_save,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorConstants.themeColor,
        foregroundColor: ColorConstants.lightTextColor,
        elevation: 0,
        padding: WorkEditorStyle.save_button_padding,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            WorkEditorStyle.save_button_radius,
          ),
        ),
        textStyle: TextStyle(
          fontSize: WorkEditorStyle.save_button_font_size,
          fontWeight: AuthorStyle.emphasis_weight,
        ),
      ),
      child: Text(
        tr(
          is_saving ? 'creator_workspace.saving' : 'creator_center.save_draft',
        ),
      ),
    ),
  );
}

/// 两种篇幅共用底部操作栏，不改变原有按钮布局与键盘避让规则。
class EditorBottomBar extends StatelessWidget {
  const EditorBottomBar({
    super.key,
    required this.is_dark,
    required this.is_cjk,
    required this.current_step,
    required this.is_last_step,
    required this.primary_title,
    required this.on_primary,
    required this.on_previous,
    this.on_save_draft,
    this.primary_icon,
  });

  final bool is_dark;
  final bool is_cjk;
  final int current_step;
  final bool is_last_step;
  final String primary_title;
  final VoidCallback? on_primary;
  final VoidCallback on_previous;
  final VoidCallback? on_save_draft;

  /// 管理页可使用新增或编辑图标；未指定时保持步骤导航原有图标。
  final IconData? primary_icon;

  @override
  Widget build(BuildContext context) {
    final show_secondary = current_step > 0 || on_save_draft != null;
    final font_size = is_cjk
        ? WorkEditorStyle.action_font_size_cjk
        : WorkEditorStyle.action_font_size_alphabetic;
    final outline_style = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(WorkEditorStyle.action_height),
      foregroundColor: AuthorStyle.primary_text(is_dark),
      side: BorderSide(color: AuthorStyle.border(is_dark)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WorkEditorStyle.action_radius),
      ),
    );
    return Container(
      constraints: const BoxConstraints(
        minHeight: WorkEditorStyle.bottom_bar_min_height,
      ),
      padding: EdgeInsets.fromLTRB(
        WorkEditorStyle.bottom_bar_horizontal_padding,
        WorkEditorStyle.bottom_bar_vertical_padding,
        WorkEditorStyle.bottom_bar_horizontal_padding,
        WorkEditorStyle.bottom_bar_vertical_padding +
            MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AuthorStyle.surface(is_dark),
        border: Border(top: BorderSide(color: AuthorStyle.border(is_dark))),
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: WorkEditorStyle.content_max_width,
          ),
          child: Row(
            children: [
              if (current_step == 0 && on_save_draft != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: on_save_draft,
                    style: outline_style,
                    child: Text(
                      tr('creator_center.save_draft'),
                      style: TextStyle(
                        fontSize: font_size,
                        fontWeight: AuthorStyle.emphasis_weight,
                      ),
                    ),
                  ),
                )
              else if (current_step > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: on_previous,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(tr('creator_center.previous')),
                    style: outline_style,
                  ),
                ),
              if (show_secondary)
                const SizedBox(width: WorkEditorStyle.action_spacing),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: on_primary,
                  icon: Icon(
                    primary_icon ??
                        (is_last_step
                            ? Icons.send_rounded
                            : Icons.arrow_forward_rounded),
                    size: 19,
                  ),
                  label: Text(primary_title),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      WorkEditorStyle.action_height,
                    ),
                    backgroundColor: AuthorStyle.gold,
                    foregroundColor: WorkEditorStyle.action_foreground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        WorkEditorStyle.action_radius,
                      ),
                    ),
                    textStyle: TextStyle(
                      fontSize: font_size,
                      fontWeight: AuthorStyle.title_weight,
                    ),
                    iconAlignment: IconAlignment.end,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
