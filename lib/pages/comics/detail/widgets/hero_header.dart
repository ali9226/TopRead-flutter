// ignore_for_file: non_constant_identifier_names

import 'dart:ui';

import 'package:easy_localization/easy_localization.dart' as easy;

import 'package:flutter/material.dart';

import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/widgets/comic_image.dart';

/// 沉浸式海报头：整幅封面 + 渐变遮罩 + 悬浮返回/评论入口。
///
/// 封面按宽度铺满，高度随屏幕宽度比例变化；底部渐变过渡到内容卡片背景，
/// 保证叠加后的标题在任何封面上都清晰可读。
class ComicDetailHeroHeader extends StatelessWidget {
  /// 作品详情数据。
  final ComicDetail detail;

  /// 返回按钮点击回调。
  final VoidCallback on_back;

  /// 评论按钮点击回调。
  final VoidCallback on_comments;

  /// 当前是否为夜间模式。
  final bool is_dark;

  const ComicDetailHeroHeader({
    super.key,
    required this.detail,
    required this.on_back,
    required this.on_comments,
    required this.is_dark,
  });

  @override
  Widget build(BuildContext context) {
    final String cover_url =
        detail.selected_language?.cover_url.isNotEmpty == true
        ? detail.selected_language!.cover_url
        : detail.comic.cover_url;

    /// 内容卡片背景色，渐变终点与此一致，形成无缝过渡。
    final Color card_bg = is_dark
        ? ComicDetailStyle.content_card_dark
        : ComicDetailStyle.content_card_light;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: _hero_height(context),
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            /// 封面图。
            ComicImage(url: cover_url, semantic_label: detail.comic.title),

            /// 遮罩层：轻微压暗 + 底部渐变到卡片背景。
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.black.withValues(
                        alpha: ComicDetailStyle.hero_scrim_opacity,
                      ),
                      Colors.black.withValues(
                        alpha: ComicDetailStyle.hero_scrim_opacity * 0.6,
                      ),
                      card_bg.withValues(
                        alpha: ComicDetailStyle.hero_gradient_end_opacity,
                      ),
                      card_bg,
                    ],
                    stops: const <double>[
                      0.0,
                      ComicDetailStyle.hero_gradient_start,
                      0.86,
                      1.0,
                    ],
                  ),
                ),
              ),
            ),

            /// 顶部悬浮操作区：返回 + 评论。
            Positioned(
              top: MediaQuery.paddingOf(context).top +
                  ComicDetailStyle.floating_action_margin.top,
              left: ComicDetailStyle.floating_action_margin.left,
              right: ComicDetailStyle.floating_action_margin.right,
              child: Row(
                children: <Widget>[
                  _FloatingGlassButton(
                    icon: Icons.arrow_back_rounded,
                    semantic_label: easy.tr('comics.cancel'),
                    is_dark: is_dark,
                    onTap: on_back,
                  ),
                  const Spacer(),
                  _FloatingGlassButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    semantic_label: easy.tr('comics.comments'),
                    is_dark: is_dark,
                    onTap: on_comments,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 计算海报高度：按屏幕宽度缩放，并限制在可读区间内。
  double _hero_height(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return (width * ComicDetailStyle.hero_height_factor).clamp(
      ComicDetailStyle.hero_min_height,
      ComicDetailStyle.hero_max_height,
    );
  }
}

/// 海报上的玻璃拟态悬浮按钮。
class _FloatingGlassButton extends StatelessWidget {
  /// 图标数据。
  final IconData icon;

  /// 无障碍语义标签。
  final String semantic_label;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 点击回调。
  final VoidCallback onTap;

  const _FloatingGlassButton({
    required this.icon,
    required this.semantic_label,
    required this.is_dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: semantic_label,
    child: Semantics(
      button: true,
      label: semantic_label,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: ComicDetailStyle.floating_button_blur,
            sigmaY: ComicDetailStyle.floating_button_blur,
          ),
          child: Material(
            color: Colors.white.withValues(
              alpha: is_dark
                  ? ComicDetailStyle.floating_button_bg_opacity * 0.7
                  : ComicDetailStyle.floating_button_bg_opacity,
            ),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox.square(
                dimension: ComicDetailStyle.back_button_size,
                child: Icon(
                  icon,
                  size: ComicDetailStyle.back_icon_size,
                  color: is_dark ? Colors.white : const Color(0xFF161C28),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
