import 'package:app/components/expandable_synopsis/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 漫画沿用公共简介卡片，并保留已有交互定位键。
class ComicAboutStory extends StatelessWidget {
  const ComicAboutStory({super.key, required this.description});
  final String description;

  @override
  Widget build(BuildContext context) => ExpandableSynopsis(
    description: description,
    title: tr('comics.about'),
    empty_description: tr('comics.no_description'),
    expand_label: tr('comics.show_more'),
    collapse_label: tr('comics.show_less'),
    is_dark: Theme.of(context).brightness == Brightness.dark,
    key_prefix: 'comic_about',
  );
}
