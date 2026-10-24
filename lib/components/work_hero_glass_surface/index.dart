import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'style.dart';

/// 仅封装模糊底图、薄描边及顶部高光；内容由各作品类型提供。
class WorkHeroGlassSurface extends StatelessWidget {
  const WorkHeroGlassSurface({
    super.key,
    required this.child,
    required this.on_hero,
    required this.is_dark,
    this.surface_key,
    this.highlight_key,
  });

  final Widget child;
  final bool on_hero;
  final bool is_dark;
  final Key? surface_key;
  final Key? highlight_key;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(WorkHeroGlassSurfaceStyle.radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: WorkHeroGlassSurfaceStyle.shadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: WorkHeroGlassSurfaceStyle.blur_sigma,
            sigmaY: WorkHeroGlassSurfaceStyle.blur_sigma,
          ),
          child: DecoratedBox(
            key: surface_key,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: WorkHeroGlassSurfaceStyle.border(
                  on_hero: on_hero,
                  is_dark: is_dark,
                ),
                width: WorkHeroGlassSurfaceStyle.border_width,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: WorkHeroGlassSurfaceStyle.colors(
                  on_hero: on_hero,
                  is_dark: is_dark,
                ),
              ),
            ),
            child: Stack(
              children: [
                child,
                PositionedDirectional(
                  top: 0,
                  start: 0,
                  end: 0,
                  height: WorkHeroGlassSurfaceStyle.highlight_height,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      key: highlight_key,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: WorkHeroGlassSurfaceStyle.highlight(
                            on_hero: on_hero,
                            is_dark: is_dark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
