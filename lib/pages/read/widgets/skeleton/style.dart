import 'package:flutter/material.dart';

/// 阅读页骨架屏样式常量。
class ReadSkeletonStyle {
  /// 骨架屏动画时长。
  static const int animation_duration_ms = 1200;

  /// 骨架屏渐变停靠点。
  static const List<double> gradient_stops = <double>[
    0.10,
    0.32,
    0.50,
    0.68,
    0.90,
  ];

  /// 日间主题骨架底色。
  static const Color light_base_color = Color(0xFFE8EDF4);

  /// 日间主题骨架高亮色。
  static const Color light_highlight_color = Color(0xFFF8FAFD);

  /// 夜间主题骨架底色。
  static const Color dark_base_color = Color(0xFF222A39);

  /// 夜间主题骨架高亮色。
  static const Color dark_highlight_color = Color(0xFF374255);

  /// 封面占位宽度。
  static const double cover_width = 108;

  /// 封面占位高度。
  static const double cover_height = 144;

  /// 封面圆角。
  static const double cover_radius = 16;

  /// 标题占位高度。
  static const double title_height = 24;

  /// 标题占位宽度。
  static const double title_width = 160;

  /// 小标题占位高度。
  static const double subtitle_height = 16;

  /// 小标题占位宽度。
  static const double subtitle_width = 80;

  /// 统计项占位高度。
  static const double stats_height = 32;

  /// 统计项占位宽度。
  static const double stats_width = 60;

  /// 作者名占位宽度。
  static const double author_name_width = 64;

  /// 关注按钮占位宽度。
  static const double follow_btn_width = 44;

  /// 统计主数字宽度。
  static const double stat_major_width = 42;

  /// 统计副标题宽度。
  static const double stat_subtitle_width = 56;

  /// 标签占位高度。
  static const double tag_height = 22;

  /// 标签占位宽度。
  static const double tag_width = 48;

  /// 简介行高度。
  static const double intro_line_height = 14;

  /// 评论头像尺寸。
  static const double comment_avatar_size = 32;

  /// 评论行高度。
  static const double comment_line_height = 12;

  /// 圆角。
  static const double radius = 4;
}
