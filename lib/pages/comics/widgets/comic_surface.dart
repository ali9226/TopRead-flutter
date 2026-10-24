// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/comics/widgets/comic_surface_style.dart';
import 'package:flutter/material.dart';

/// 图片与文字共用一个完整卡面，边框盖在内容前景，阴影仅绘制一次。
class ComicSurface extends StatelessWidget {
  const ComicSurface({
    super.key,
    required this.child,
    required this.is_dark,
    this.selected = false,
    this.radius = ComicSurfaceStyle.card_radius,
  });

  final Widget child;
  final bool is_dark;
  final bool selected;
  final double radius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: ComicSurfaceStyle.shadows(is_dark),
    ),
    child: Material(
      color: ComicSurfaceStyle.background(is_dark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: ComicSurfaceStyle.border(is_dark, selected: selected),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  );
}
