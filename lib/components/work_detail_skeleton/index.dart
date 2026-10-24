import 'package:app/components/work_section_card/style.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:flutter/material.dart';

import 'body.dart';
import 'hero.dart';
import 'kind.dart';
import 'pulse.dart';

export 'kind.dart';
export 'pulse.dart';
export 'text_line.dart';

/// 与加载后的三类作品详情共用封面海报、纸面和响应式尺寸。
class WorkDetailSkeleton extends StatelessWidget {
  const WorkDetailSkeleton({
    super.key,
    required this.is_dark,
    this.kind = WorkDetailSkeletonKind.novel,
    this.on_back,
  });

  final bool is_dark;
  final WorkDetailSkeletonKind kind;
  final VoidCallback? on_back;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: kind == WorkDetailSkeletonKind.short_story
        ? is_dark
              ? ShortStoryReadStyle.bg_dark_color
              : ShortStoryReadStyle.bg_light_color
        : WorkSectionCardStyle.background(is_dark),
    child: SkeletonPulse(
      is_dark: is_dark,
      child: SingleChildScrollView(
        key: const ValueKey('work_detail_skeleton_scroll'),
        physics: const NeverScrollableScrollPhysics(),
        // 海报背景与纸面铺满调用方的阅读列，仅海报前景由真实组件限制宽度。
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WorkDetailSkeletonHero(
              is_dark: is_dark,
              kind: kind,
              on_back: on_back,
            ),
            WorkDetailSkeletonBody(is_dark: is_dark, kind: kind),
          ],
        ),
      ),
    ),
  );
}
