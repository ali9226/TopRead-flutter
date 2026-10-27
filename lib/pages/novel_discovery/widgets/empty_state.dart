// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/pages/comics/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 网络失败与真正空库存分别展示，保留刷新与重试入口。
class NovelDiscoveryEmptyState extends StatelessWidget {
  const NovelDiscoveryEmptyState({
    super.key,
    this.error,
    required this.message,
    this.on_retry,
  });
  final String? error;
  final String message;
  final VoidCallback? on_retry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      vertical: LayoutConfig.space_72,
      horizontal: LayoutConfig.page_horizontal_padding,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          error == null
              ? Icons.auto_stories_outlined
              : Icons.cloud_off_outlined,
          size: LayoutConfig.touch_target_size,
          color: ComicsStyle.muted(context),
        ),
        const SizedBox(height: LayoutConfig.space_16),
        Text(
          error == null ? message : tr('novel_discovery.discovery_load_failed'),
          textAlign: TextAlign.center,
          style: ComicsStyle.text(context),
        ),
        if (error != null && on_retry != null) ...[
          const SizedBox(height: LayoutConfig.space_16),
          OutlinedButton.icon(
            onPressed: on_retry,
            style: ComicsStyle.outlined_button(context).copyWith(
              overlayColor: const WidgetStatePropertyAll(
                ColorConstants.transparent,
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(tr('novel_discovery.retry')),
          ),
        ],
      ],
    ),
  );
}
