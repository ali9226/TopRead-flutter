import 'package:app/components/work_detail_skeleton/index.dart';
import 'package:flutter/material.dart';

/// 长篇初次加载展示真实封面简介结构，章节跳转另用正文骨架。
class ReadSkeleton extends StatelessWidget {
  const ReadSkeleton({super.key, required this.is_dark, this.on_back});

  final bool is_dark;
  final VoidCallback? on_back;

  @override
  Widget build(BuildContext context) =>
      WorkDetailSkeleton(is_dark: is_dark, on_back: on_back);
}
