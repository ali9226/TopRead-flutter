// ignore_for_file: non_constant_identifier_names

import 'package:app/components/content_category_tag/style.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';

export 'style.dart';

/// TODO 纯展示分类标签，供首页、长短篇小说与漫画复用。
/// [color] 保留上游稳定配色；[surface_color] 用于卡片内将半透明底混合为实色。
/// [is_dark]、[is_cjk] 默认从页面主题和语种读取，已有页面也可显式传入。
class ContentCategoryTag extends StatelessWidget {
  const ContentCategoryTag({
    super.key,
    required this.label,
    required this.color,
    this.surface_color,
    this.is_dark,
    this.is_cjk,
  });

  final String label;
  final Color color;
  final Color? surface_color;
  final bool? is_dark;
  final bool? is_cjk;

  @override
  Widget build(BuildContext context) {
    final dark = is_dark ?? Theme.of(context).brightness == Brightness.dark;
    final cjk =
        is_cjk ??
        LanguageUtil.is_cjk_language(
          Localizations.localeOf(context).languageCode,
        );
    final tint = color.withValues(
      alpha: dark
          ? ContentCategoryTagStyle.background_alpha_dark
          : ContentCategoryTagStyle.background_alpha_light,
    );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: cjk
            ? ContentCategoryTagStyle.padding_h_cjk
            : ContentCategoryTagStyle.padding_h_alphabetic,
        vertical: ContentCategoryTagStyle.padding_v,
      ),
      decoration: BoxDecoration(
        color: surface_color == null
            ? tint
            : Color.alphaBlend(tint, surface_color!),
        borderRadius: BorderRadius.circular(ContentCategoryTagStyle.radius),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color.withValues(alpha: ContentCategoryTagStyle.text_alpha),
          fontSize: cjk
              ? ContentCategoryTagStyle.font_size_cjk
              : ContentCategoryTagStyle.font_size_alphabetic,
          height: cjk
              ? ContentCategoryTagStyle.line_height_cjk
              : ContentCategoryTagStyle.line_height_alphabetic,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
        ),
      ),
    );
  }
}
