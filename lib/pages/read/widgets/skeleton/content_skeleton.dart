import 'package:flutter/material.dart';
import 'package:app/pages/read/widgets/content/style.dart';
import 'package:app/pages/read/widgets/main_list/style.dart';
import 'package:app/pages/read/widgets/skeleton/style.dart';

/// 正文内容骨架屏组件。
///
/// 用于目录跳转章节时显示，只展示正文段落的骨架，不包含小说介绍。
class ReadContentSkeleton extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  const ReadContentSkeleton({super.key, required this.is_dark});

  @override
  Widget build(BuildContext context) {
    final Color base_color = is_dark
        ? ReadSkeletonStyle.dark_base_color
        : ReadSkeletonStyle.light_base_color;
    final double status_bar_height = MediaQuery.viewPaddingOf(context).top;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        MainListStyle.page_horizontal_padding,
        status_bar_height + ContentStyle.reading_padding.top,
        MainListStyle.page_horizontal_padding,
        ContentStyle.reading_padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 章节标题占位。
          _buildBox(width: 160, height: 22, color: base_color),
          const SizedBox(height: 32),
          // 正文段落占位（多行不同宽度模拟真实段落）。
          _buildBox(width: double.infinity, height: 16, color: base_color),
          const SizedBox(height: 14),
          _buildBox(width: double.infinity, height: 16, color: base_color),
          const SizedBox(height: 14),
          _buildBox(width: double.infinity, height: 16, color: base_color),
          const SizedBox(height: 14),
          _buildBox(width: 240, height: 16, color: base_color),
          const SizedBox(height: 28),
          _buildBox(width: double.infinity, height: 16, color: base_color),
          const SizedBox(height: 14),
          _buildBox(width: double.infinity, height: 16, color: base_color),
          const SizedBox(height: 14),
          _buildBox(width: 200, height: 16, color: base_color),
          const SizedBox(height: 28),
          _buildBox(width: double.infinity, height: 16, color: base_color),
          const SizedBox(height: 14),
          _buildBox(width: double.infinity, height: 16, color: base_color),
          const SizedBox(height: 14),
          _buildBox(width: double.infinity, height: 16, color: base_color),
          const SizedBox(height: 14),
          _buildBox(width: 180, height: 16, color: base_color),
        ],
      ),
    );
  }

  /// 构建骨架占位块。
  Widget _buildBox({
    required double width,
    required double height,
    required Color color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
