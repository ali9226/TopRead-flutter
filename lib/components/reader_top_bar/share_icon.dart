// ignore_for_file: non_constant_identifier_names

import 'package:app/components/reader_top_bar/style.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:flutter/material.dart';

/// 长短篇导航共用原始双色分享图形，避免单色滤镜抹去黄色填充。
class ReaderShareIcon extends StatelessWidget {
  const ReaderShareIcon({super.key, required this.is_dark});

  final bool is_dark;

  @override
  Widget build(BuildContext context) => SvgIcon(
    name: 'share',
    width: ReaderTopBarStyle.share_icon_size,
    height: ReaderTopBarStyle.share_icon_size,
    color: ReaderTopBarStyle.share_icon_color(is_dark),
  );
}
