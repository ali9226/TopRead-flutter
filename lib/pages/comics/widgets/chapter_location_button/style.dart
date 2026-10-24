import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';

/// TODO 漫画章节带与目录共用的内联定位按钮尺寸和动效。
class ComicChapterLocationButtonStyle {
  const ComicChapterLocationButtonStyle._();

  static const double extent = LayoutConfig.compact_control_height;
  static const double icon_size = LayoutConfig.icon_medium;
  static const Duration duration = Duration(milliseconds: 200);
  static const Curve curve = Curves.easeOutCubic;
  static const double hidden_scale = 0.7;
}
