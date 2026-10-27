// ignore_for_file: non_constant_identifier_names

import 'package:app/components/share_sheet/layout_style.dart';
import 'package:app/components/share_sheet/share_channel_uri.dart';
import 'package:app/components/share_sheet/share_feedback.dart';
import 'package:app/components/share_sheet/share_work_url.dart';
import 'package:app/components/share_sheet/style.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/share_channels.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'share_icon_item.dart';

/// 所有作品/摘录预览复用同一个渠道数组；窄屏和大字时自动换行。
class ShareChannelGrid extends StatelessWidget {
  const ShareChannelGrid({
    super.key,
    required this.work_id,
    required this.title,
    required this.is_dark,
    this.work_kind = WorkShareKind.novel,
    this.language,
    this.on_generate_image,
  });

  final int work_id;
  final String title;
  final bool is_dark;
  final WorkShareKind work_kind;
  final String? language;
  final VoidCallback? on_generate_image;

  @override
  Widget build(BuildContext context) {
    final channels = enabled_share_channels(
      include_generate_image: on_generate_image != null,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
        final columns =
            (constraints.maxWidth /
                    (ShareLayoutStyle.min_channel_width * scale))
                .floor()
                .clamp(1, ShareLayoutStyle.max_channel_columns);
        return Wrap(
          runSpacing: ShareLayoutStyle.row_spacing,
          children: channels
              .map(
                (channel) => SizedBox(
                  width: constraints.maxWidth / columns,
                  child: ShareIconItem(
                    key: ValueKey('share_channel_${channel.id}'),
                    icon_widget: SvgIcon(
                      name: channel.icon_name,
                      width: ShareSheetStyle.icon_inner_size,
                      height: ShareSheetStyle.icon_inner_size,
                      color: is_dark ? ColorConstants.whiteColor : null,
                    ),
                    label: channel.label_key.isEmpty
                        ? channel.label
                        : tr(channel.label_key, context: context),
                    icon_color: is_dark
                        ? ColorConstants.whiteColor
                        : ColorConstants.lightTextColor,
                    is_dark: is_dark,
                    on_tap: () => _activate(context, channel),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Future<void> _activate(
    BuildContext context,
    ShareChannelDefinition channel,
  ) async {
    if (channel.action == ShareChannelAction.generate_image) {
      on_generate_image?.call();
      return;
    }
    try {
      final work_url = share_work_url(
        work_id: work_id,
        work_kind: work_kind,
        language: language,
      );
      if (channel.action == ShareChannelAction.copy_link) {
        await Clipboard.setData(ClipboardData(text: work_url.toString()));
        if (context.mounted) {
          show_share_feedback(context, 'share_sheet.copy_success');
        }
        return;
      }
      final uri = share_channel_uri(
        action: channel.action,
        work_url: work_url,
        title: title,
      );
      final opened =
          uri != null &&
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        show_share_feedback(context, 'share_sheet.channel_unavailable');
      }
    } catch (_) {
      if (context.mounted) {
        show_share_feedback(
          context,
          channel.action == ShareChannelAction.copy_link
              ? 'share_sheet.copy_failed'
              : 'share_sheet.channel_unavailable',
        );
      }
    }
  }
}
