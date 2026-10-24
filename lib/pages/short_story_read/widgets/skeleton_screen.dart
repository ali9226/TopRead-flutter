import 'package:app/components/work_detail_skeleton/index.dart';
import 'package:flutter/material.dart';

/// 短篇首屏与加载后的封面简介一致，阅读正文及底栏不提前出现。
class SkeletonScreen extends StatelessWidget {
  const SkeletonScreen({super.key, required this.is_dark, this.on_back});

  final bool is_dark;
  final VoidCallback? on_back;

  @override
  Widget build(BuildContext context) => WorkDetailSkeleton(
    is_dark: is_dark,
    kind: WorkDetailSkeletonKind.short_story,
    on_back: on_back,
  );
}
