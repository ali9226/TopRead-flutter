import 'package:flutter/material.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/components/work_section_card/style.dart';

/// 简介区域保留纯净连续纸面，避免装饰纹理和多层卡片干扰正文。
class ComicWarmPaper extends StatelessWidget {
  const ComicWarmPaper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: WorkSectionCardStyle.background(ComicDetailStyle.is_dark(context)),
    child: child,
  );
}

/// 海报的圆角过渡之后，章节入口与简介共用同一背景色。
class ComicContentSurface extends StatelessWidget {
  const ComicContentSurface({
    super.key,
    required this.child,
    required this.is_dark,
  });
  final Widget child;
  final bool is_dark;

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: WorkSectionCardStyle.background(is_dark), child: child);
}
