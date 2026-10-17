// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

import 'package:app/pages/comics/reader/style.dart';

/// 阅读页顶部细进度条：贴在画布最上方，随阅读位置推进。
class ComicReaderProgressBar extends StatelessWidget {
  /// 当前页码（从 0 开始）。
  final int page_index;

  /// 总页数。
  final int page_count;

  const ComicReaderProgressBar({
    super.key,
    required this.page_index,
    required this.page_count,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = page_count <= 0
        ? 0
        : ((page_index + 1) / page_count).clamp(0.0, 1.0);

    return SizedBox(
      height: ComicReaderStyle.progress_track_height,
      child: Stack(
        children: <Widget>[
          /// 未读轨道。
          Positioned.fill(
            child: ColoredBox(color: ComicReaderStyle.progress_inactive_color),
          ),

          /// 已读部分。
          FractionallySizedBox(
            widthFactor: progress,
            child: ColoredBox(color: ComicReaderStyle.progress_active_color),
          ),
        ],
      ),
    );
  }
}
