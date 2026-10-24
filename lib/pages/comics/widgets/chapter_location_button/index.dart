// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/pages/comics/widgets/chapter_location_button/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// TODO 使用短篇目录的定位 SVG，在漫画章节工具栏中平滑显隐。
class ComicChapterLocationButton extends StatelessWidget {
  /// TODO show 控制显隐；is_dark 对齐所在工具栏主题；on_tap 定位当前阅读章节。
  const ComicChapterLocationButton({
    super.key,
    required this.show,
    required this.is_dark,
    required this.on_tap,
  });

  final bool show;
  final bool is_dark;
  final VoidCallback on_tap;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : ComicChapterLocationButtonStyle.duration;
    return AnimatedSize(
      duration: duration,
      curve: ComicChapterLocationButtonStyle.curve,
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: show ? ComicChapterLocationButtonStyle.extent : 0,
        height: ComicChapterLocationButtonStyle.extent,
        child: AnimatedOpacity(
          opacity: show ? 1 : 0,
          duration: duration,
          curve: ComicChapterLocationButtonStyle.curve,
          child: AnimatedScale(
            scale: show ? 1 : ComicChapterLocationButtonStyle.hidden_scale,
            duration: duration,
            curve: ComicChapterLocationButtonStyle.curve,
            child: IgnorePointer(
              ignoring: !show,
              child: ExcludeSemantics(
                excluding: !show,
                child: IconButton(
                  tooltip: tr('comics.jump_to_current'),
                  onPressed: on_tap,
                  style: IconButton.styleFrom(
                    foregroundColor: ColorConstants.dangerColor,
                    overlayColor: is_dark
                        ? ColorConstants.whiteColor
                        : ColorConstants.dangerColor,
                  ),
                  icon: SvgPicture.asset(
                    'assets/svg/positioning.svg',
                    width: ComicChapterLocationButtonStyle.icon_size,
                    height: ComicChapterLocationButtonStyle.icon_size,
                    colorFilter: const ColorFilter.mode(
                      ColorConstants.dangerColor,
                      BlendMode.srcIn,
                    ),
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
