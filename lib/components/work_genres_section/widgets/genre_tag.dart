import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

import '../style.dart';

/// 分类胶囊保留完整文字，短标签统一最小高度，长标签和系统大字自然增长。
class WorkGenreTag extends StatelessWidget {
  const WorkGenreTag({
    super.key,
    required this.label,
    required this.color,
    required this.is_dark,
    required this.is_cjk,
    this.compact = false,
  });

  final String label;
  final Color color;
  final bool is_dark;
  final bool is_cjk;

  /// 海报区内使用更紧凑的胶囊尺寸。
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(
      minHeight: compact
          ? WorkGenresSectionStyle.hero_tag_min_height
          : WorkGenresSectionStyle.tag_min_height,
    ),
    padding: EdgeInsets.symmetric(
      horizontal: compact
          ? WorkGenresSectionStyle.hero_tag_padding_h
          : WorkGenresSectionStyle.tag_padding_horizontal,
      vertical: compact
          ? WorkGenresSectionStyle.hero_tag_padding_v
          : WorkGenresSectionStyle.tag_padding_vertical,
    ),
    decoration: BoxDecoration(
      color: WorkGenresSectionStyle.tag_background(color, is_dark),
      borderRadius: BorderRadius.circular(WorkGenresSectionStyle.tag_radius),
    ),
    child: Text(
      label,
      softWrap: true,
      style: TextStyle(
        color: WorkGenresSectionStyle.tag_foreground(color),
        fontSize: compact
            ? (is_cjk
                  ? WorkGenresSectionStyle.hero_tag_font_cjk
                  : WorkGenresSectionStyle.hero_tag_font_alphabetic)
            : (is_cjk
                  ? WorkGenresSectionStyle.tag_font_size_cjk
                  : WorkGenresSectionStyle.tag_font_size_alphabetic),
        height: is_cjk
            ? WorkGenresSectionStyle.tag_height_cjk
            : WorkGenresSectionStyle.tag_height_alphabetic,
        fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
      ),
    ),
  );
}
