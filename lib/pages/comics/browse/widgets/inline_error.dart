// ignore_for_file: non_constant_identifier_names

import 'package:app/config/font_config.dart';
import 'package:app/pages/comics/browse/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 加载失败只提供就地重试，不遮盖已经可用的漫画列表。
class ComicBrowseInlineError extends StatelessWidget {
  const ComicBrowseInlineError({
    super.key,
    required this.is_dark,
    required this.message,
    required this.on_retry,
  });
  final bool is_dark;
  final String message;
  final VoidCallback on_retry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: ComicBrowseStyle.horizontal_padding,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: ComicBrowseStyle.is_cjk(context)
                  ? ComicBrowseStyle.status_size_cjk
                  : ComicBrowseStyle.status_size_alphabetic,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              color: ComicBrowseStyle.muted(is_dark),
            ),
          ),
        ),
        TextButton(onPressed: on_retry, child: Text(tr('comics.retry'))),
      ],
    ),
  );
}
