// ignore_for_file: non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/config/color_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 加载、真实空结果和接口失败明确区分，并为失败提供操作入口。
class ComicsEmptyState extends StatelessWidget {
  final bool loading;
  final String? error;
  final String message;
  final VoidCallback? on_retry;
  final Color? foreground_color;
  const ComicsEmptyState({
    super.key,
    this.loading = false,
    this.error,
    required this.message,
    this.on_retry,
    this.foreground_color,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      vertical: LayoutConfig.space_72,
      horizontal: ComicsStyle.page_padding,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (loading)
          CircularProgressIndicator(color: ColorConstants.themeColor)
        else
          Icon(
            error == null
                ? Icons.auto_stories_outlined
                : Icons.cloud_off_outlined,
            size: 48,
            color: foreground_color ?? ComicsStyle.muted(context),
          ),
        const SizedBox(height: ComicsStyle.gap),
        Text(
          loading ? tr('comics.loading') : error ?? message,
          textAlign: TextAlign.center,
          style: ComicsStyle.text(
            context,
            color: foreground_color ?? ComicsStyle.muted(context),
          ),
        ),
        if (!loading && error != null && on_retry != null) ...<Widget>[
          const SizedBox(height: ComicsStyle.gap),
          OutlinedButton.icon(
            // TODO 阅读画布固定近黑，显式前景色同时用于重试操作，不能随日间主题变成黑字。
            style: foreground_color == null
                ? ComicsStyle.outlined_button(context)
                : ComicsStyle.outlined_button(context).copyWith(
                    foregroundColor: WidgetStatePropertyAll(foreground_color),
                    side: WidgetStatePropertyAll(
                      BorderSide(color: foreground_color!),
                    ),
                  ),
            onPressed: on_retry,
            icon: const Icon(Icons.refresh),
            label: Text(tr('comics.retry')),
          ),
        ],
      ],
    ),
  );
}
