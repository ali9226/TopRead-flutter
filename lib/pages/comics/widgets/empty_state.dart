// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/comics/style.dart';
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
      vertical: 72,
      horizontal: ComicsStyle.page_padding,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (loading)
          const CircularProgressIndicator()
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
            style: ComicsStyle.outlined_button(context),
            onPressed: on_retry,
            icon: const Icon(Icons.refresh),
            label: Text(tr('comics.retry')),
          ),
        ],
      ],
    ),
  );
}
