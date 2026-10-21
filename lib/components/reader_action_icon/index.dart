import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// TODO 阅读器单色操作图标：三种内容类型共用资源和着色，避免 SVG 内置填色造成视觉差异。
class ReaderActionIcon extends StatelessWidget {
  const ReaderActionIcon({
    super.key,
    required this.name,
    required this.color,
    this.size = 22,
  });
  final String name;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/svg/$name.svg',
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    excludeFromSemantics: true,
  );
}
