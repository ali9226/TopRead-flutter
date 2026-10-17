// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/widgets/comic_image.dart';

/// TODO 复用小说详情的封面尺寸与留白，完整书封独立展示，取消满幅裁切和白色渐变。
class ComicDetailHeroHeader extends StatelessWidget {
  final ComicDetail detail;
  final VoidCallback on_back;
  final VoidCallback on_comments;
  final bool is_dark;
  final Widget? cover_image;
  const ComicDetailHeroHeader({
    super.key,
    required this.detail,
    required this.on_back,
    required this.on_comments,
    required this.is_dark,
    this.cover_image,
  });

  @override
  Widget build(BuildContext context) {
    final cover_url = detail.selected_language?.cover_url.isNotEmpty == true
        ? detail.selected_language!.cover_url
        : detail.comic.cover_url;
    final double top_padding = MediaQuery.paddingOf(context).top;

    return SliverToBoxAdapter(
      // TODO 封面 100% 宽度、固定高度，顶部贯穿状态栏；返回/评论浮于封面之上。
      child: SizedBox(
        key: const ValueKey('comic_detail_cover'),
        height: ComicDetailStyle.cover_height,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            /// 封面图：铺满整个区域（含状态栏），底部圆角。
            ClipRRect(
              key: const ValueKey('comic_detail_cover_art'),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(ComicDetailStyle.cover_radius),
                bottomRight: Radius.circular(ComicDetailStyle.cover_radius),
              ),
              child:
                  cover_image ??
                  ComicImage(
                    url: cover_url,
                    semantic_label: detail.comic.title,
                    fit: BoxFit.cover,
                  ),
            ),

            /// 顶部悬浮操作：下移状态栏高度，浮在封面之上。
            Positioned(
              top: top_padding + ComicDetailStyle.floating_action_margin.top,
              left: ComicDetailStyle.floating_action_margin.left,
              right: ComicDetailStyle.floating_action_margin.right,
              child: Row(
                children: <Widget>[
                  ComicDetailFloatingButton(
                    key: const ValueKey('comic_detail_back'),
                    svg_name: 'right',
                    reverse: true,
                    label: MaterialLocalizations.of(context).backButtonTooltip,
                    is_dark: is_dark,
                    on_pressed: on_back,
                  ),
                  const Spacer(),
                  ComicDetailFloatingButton(
                    key: const ValueKey('comic_detail_comments'),
                    svg_name: 'message',
                    label: easy.tr('comics.comments'),
                    is_dark: is_dark,
                    on_pressed: on_comments,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// TODO 48像素点击区内使用36像素无描边半透明圆，日黑底白图标、夜白底黑图标。
class ComicDetailFloatingButton extends StatelessWidget {
  final String svg_name;
  final bool reverse;
  final String label;
  final bool is_dark;
  final VoidCallback on_pressed;
  const ComicDetailFloatingButton({
    super.key,
    required this.svg_name,
    this.reverse = false,
    required this.label,
    required this.is_dark,
    required this.on_pressed,
  });
  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: on_pressed,
          radius: ComicDetailStyle.touch_target / 2,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: ComicDetailStyle.touch_target,
            child: Center(
              child: Material(
                color: ComicDetailStyle.floating_background(is_dark),
                shape: const CircleBorder(),
                child: SizedBox.square(
                  dimension: ComicDetailStyle.floating_visual_size,
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: reverse ? 2 : 0,
                      child: SvgIcon(
                        name: svg_name,
                        width: ComicDetailStyle.back_icon_size,
                        height: ComicDetailStyle.back_icon_size,
                        color: ComicDetailStyle.floating_foreground(is_dark),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
