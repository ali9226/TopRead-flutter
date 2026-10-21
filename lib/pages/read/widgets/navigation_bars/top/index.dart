// ignore_for_file: non_constant_identifier_names

import 'package:app/components/reader_top_bar/index.dart';
import 'package:app/components/reader_top_bar/style.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// TODO 长篇保留原本无标题的内容及业务回调，仅与漫画共用顶部视觉和动作反馈。
class ReadTopBar extends StatelessWidget {
  const ReadTopBar({
    super.key,
    required this.is_dark,
    required this.show,
    required this.on_back,
    required this.on_favorite_tap,
    required this.on_share,
    required this.is_favorited,
    this.is_favorite_loading = false,
    this.is_loading = false,
  });
  final bool is_dark;
  final bool show;
  final VoidCallback on_back;
  final VoidCallback on_favorite_tap;
  final VoidCallback on_share;
  final bool is_favorited;
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
          on_back: on_back,
          on_favorite: on_favorite_tap,
          on_share: on_share,
          favorited: is_favorited,
          favorite_loading: is_favorite_loading,
          loading: is_loading,
          show_share: Get.find<ProjectConfigStore>().current.is_share_enabled,
        ),
      ),
    );
  }
}
