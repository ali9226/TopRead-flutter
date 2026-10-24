// ignore_for_file: non_constant_identifier_names

import 'package:app/components/catalog_card/style.dart';
import 'package:app/config/color_config.dart';
import 'package:app/components/work_section_card/style.dart';
import 'package:flutter/material.dart';

export 'style.dart';

/// TODO 短篇目录、漫画目录与推荐列表共享卡片表面，保留各自的点击与缩放交互。
class CatalogCardSurface extends StatelessWidget {
  const CatalogCardSurface({
    super.key,
    required this.is_dark,
    required this.child,
    this.selected = false,
  });
  final bool is_dark;
  final Widget child;
  final bool selected;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(CatalogCardStyle.radius),
      boxShadow: WorkSectionCardStyle.shadows(is_dark),
    ),
    child: Material(
      color: CatalogCardStyle.card_background(is_dark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CatalogCardStyle.radius),
        side: selected
            ? BorderSide(
                color: ColorConstants.dangerColor.withValues(
                  alpha: CatalogCardStyle.border_alpha,
                ),
                width: CatalogCardStyle.border_width,
              )
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  );
}
