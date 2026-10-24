// ignore_for_file: non_constant_identifier_names

import 'package:app/components/reader_top_bar/index.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/pages/comics/reader/style.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  Widget build(BuildContext context) {
    // 阅读页与短篇相同，分享按钮实时遵循项目配置开关。
    if (Get.isRegistered<ProjectConfigStore>()) {
      final config = Get.find<ProjectConfigStore>();
      return Obx(
        () => _bar(context, show_share: config.current.is_share_enabled),
      );
    }
    return _bar(context, show_share: true);
  }

  Widget _bar(BuildContext context, {required bool show_share}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ReaderTopBar(
      is_dark: dark,
      title: title,
      on_back: on_back,
      on_share: on_share,
      on_favorite: on_collect,
      favorited: collected,
      favorite_loading: collecting,
      show_share: show_share,
      favorite_icon: SvgIcon(
        name: collected ? 'user_selected' : 'not_favorited',
        width: ComicReaderStyle.top_favorite_icon_size,
        height: ComicReaderStyle.top_favorite_icon_size,
        color: ComicReaderStyle.top_favorite_icon_color(
          dark,
          collected: collected,
        ),
      ),
      share_icon: SvgIcon(
        name: 'share',
        width: ComicReaderStyle.top_share_icon_size,
        height: ComicReaderStyle.top_share_icon_size,
        color: ComicReaderStyle.top_share_icon_color(dark),
      ),
    );
  }
}
