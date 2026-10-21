// ignore_for_file: non_constant_identifier_names

import 'package:app/components/reader_top_bar/index.dart';
import 'package:flutter/material.dart';

/// TODO 漫画与长篇共用顶部视觉；漫画保留原有章节标题和业务回调。
class ComicReaderTopScrim extends StatelessWidget {
  const ComicReaderTopScrim({
    super.key,
    required this.title,
    required this.on_back,
    this.comic_title = '',
    this.on_share,
    this.on_collect,
    this.collected = false,
    this.collecting = false,
    VoidCallback? on_open_catalog,
    VoidCallback? on_comments,
  });
  final String title;
  final String comic_title;
  final VoidCallback on_back;
  final VoidCallback? on_share;
  final VoidCallback? on_collect;
  final bool collected;
  final bool collecting;

  @override
  Widget build(BuildContext context) => ReaderTopBar(
    is_dark: Theme.of(context).brightness == Brightness.dark,
    title: title,
    on_back: on_back,
    on_share: on_share,
    on_favorite: on_collect,
    favorited: collected,
    favorite_loading: collecting,
  );
}
