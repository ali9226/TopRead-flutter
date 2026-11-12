import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/services/patch/patch_update_status.dart';
import 'logic.dart';
import 'style.dart';

/// TODO 仅 debug=2 用户展示进程内热更状态；订阅快照，不主动检查或安装补丁。
class PatchStatusPanel extends StatelessWidget {
  const PatchStatusPanel({
    super.key,
    required this.enabled,
    required this.is_dark,
    required this.is_cjk,
    this.status,
  });
  final bool enabled;
  final bool is_dark;
  final bool is_cjk;
  final ValueListenable<PatchUpdateStatus>? status;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();
    final text_color = is_dark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;
    return ValueListenableBuilder<PatchUpdateStatus>(
      valueListenable: status ?? patch_update_status,
      builder: (context, value, _) => Container(
        key: const ValueKey('patch_status_panel'),
        width: double.infinity,
        margin: const EdgeInsets.all(PatchPanelStyle.padding),
        padding: const EdgeInsets.all(PatchPanelStyle.padding),
        decoration: BoxDecoration(
          color: text_color.withValues(alpha: PatchPanelStyle.surface_alpha),
          borderRadius: BorderRadius.circular(PatchPanelStyle.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              is_cjk ? '热更新状态' : 'Hot update status',
              style: TextStyle(
                color: text_color,
                fontSize: is_cjk
                    ? PatchPanelStyle.title_cjk
                    : PatchPanelStyle.title_alphabetic,
                fontWeight: PatchPanelStyle.weight,
              ),
            ),
            const SizedBox(height: PatchPanelStyle.gap),
            Text(
              '${is_cjk ? '是否正在热更新' : 'Update in progress'}：${value.running ? (is_cjk ? '是' : 'Yes') : (is_cjk ? '否' : 'No')} · ${patch_stage_text(value.stage, is_cjk)}',
              style: TextStyle(color: text_color),
            ),
            if (value.running || value.stage == 'pending_restart') ...[
              const SizedBox(height: PatchPanelStyle.gap),
              LinearProgressIndicator(
                key: const ValueKey('patch_download_progress'),
                value: value.stage == 'pending_restart'
                    ? 1
                    : value.stage == 'downloading'
                    ? value.progress
                    : null,
                minHeight: PatchPanelStyle.progress_height,
                color: text_color,
                backgroundColor: text_color.withValues(
                  alpha: PatchPanelStyle.surface_alpha,
                ),
              ),
            ],
            if (patch_progress_text(value, is_cjk).isNotEmpty) ...[
              const SizedBox(height: PatchPanelStyle.gap),
              Text(
                patch_progress_text(value, is_cjk),
                key: const ValueKey('patch_progress_text'),
                style: TextStyle(color: text_color),
              ),
            ],
            const SizedBox(height: PatchPanelStyle.gap),
            SelectableText(
              value.detail,
              key: const ValueKey('patch_status_detail'),
              style: TextStyle(
                color: text_color.withValues(
                  alpha: PatchPanelStyle.muted_alpha,
                ),
                fontSize: is_cjk
                    ? PatchPanelStyle.detail_cjk
                    : PatchPanelStyle.detail_alphabetic,
                height: PatchPanelStyle.line_height,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
