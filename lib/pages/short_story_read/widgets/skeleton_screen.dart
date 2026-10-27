import 'package:app/components/work_detail_skeleton/index.dart';
import 'package:flutter/material.dart';

/// 短篇首屏同时预示真实封面简介和正文，业务底栏仍由阅读页控制。
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
