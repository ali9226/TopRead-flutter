// ignore_for_file: non_constant_identifier_names

import 'package:app/components/reader_top_bar/index.dart';
import 'package:app/components/reader_top_bar/share_icon.dart';
import 'package:app/components/reader_top_bar/style.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 长篇导航显示当前章节标题，收藏请求期间保留即时切换后的星形。
class ReadTopBar extends StatelessWidget {
  const ReadTopBar({
    super.key,
    required this.is_dark,
    required this.show,
    required this.on_back,
    required this.on_favorite_tap,
    required this.on_share,
    required this.is_favorited,
    this.title = '',
    this.is_favorite_loading = false,
    this.is_loading = false,
  });
  final bool is_dark;
  final bool show;
  final VoidCallback on_back;
  final VoidCallback on_favorite_tap;
  final VoidCallback on_share;
  final bool is_favorited;
  final String title;
  final bool is_favorite_loading;
  final bool is_loading;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    final height = ReaderTopBarStyle.toolbar_height(context);
    return AnimatedPositioned(
      duration: ReaderTopBarStyle.reduce_motion(context)
          ? Duration.zero
          : ReaderTopBarStyle.visibility_duration,
      curve: Curves.easeOutCubic,
      top: show ? 0 : -(top + height),
      left: 0,
      right: 0,
      child: Obx(
        () => ReaderTopBar(
          is_dark: is_dark,
          title: title,
          on_back: on_back,
          on_favorite: on_favorite_tap,
          on_share: on_share,
          favorited: is_favorited,
          favorite_loading: is_favorite_loading,
          loading: is_loading,
          share_icon: ReaderShareIcon(is_dark: is_dark),
          show_share: Get.find<ProjectConfigStore>().current.is_share_enabled,
        ),
      ),
    );
  }
}
