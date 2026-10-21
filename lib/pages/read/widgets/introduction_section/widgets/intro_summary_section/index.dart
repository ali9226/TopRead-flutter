import 'package:app/components/expandable_synopsis/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

/// 长篇正文与目录弹窗共同使用与漫画一致的简介卡片。
class ReadIntroSummarySection extends StatelessWidget {
  const ReadIntroSummarySection({
    super.key,
    required this.is_dark,
    required this.intro_text,
    this.initial_expanded = false,
    this.font_size,
  });
  final bool is_dark;
  final String intro_text;
  final bool initial_expanded;
  final double? font_size;

  @override
  Widget build(BuildContext context) => ExpandableSynopsis(
    description: intro_text,
    title: easy.tr('read.intro_title'),
    empty_description: easy.tr('comics.no_description'),
    expand_label: easy.tr('comics.show_more'),
    collapse_label: easy.tr('comics.show_less'),
    is_dark: is_dark,
    initial_expanded: initial_expanded,
    font_size: font_size,
    key_prefix: 'novel_about',
  );
}
