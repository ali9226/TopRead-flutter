// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';

import 'package:app/components/network_cover_image/index.dart';
import 'package:app/components/home/style.dart';

class ReadingBannerSlide extends StatelessWidget {
  /// 海报主标题。
  final String title;

  /// 海报副标题。
  final String subtitle;

  /// 右上角角标文案。
  final String badge;

  /// 底部高亮提示文案。
  final String highlight;

  /// 海报本地图片路径。
  final String image_path;

  /// 海报网络图片地址。
  final String image_url;

  /// 当前是否为夜间主题。
  final bool isDark;

  /// 点击海报时的回调函数。
  final VoidCallback? onTap;

  /// 首页单张海报组件。
  const ReadingBannerSlide({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.highlight,
    required this.image_path,
    required this.image_url,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    /// 标题最多显示两行，避免多语种长度差异导致内容溢出。
    const int title_max_lines = 2;

    /// 副标题最多显示两行，超出时省略。
    const int subtitle_max_lines = 2;

    /// 高亮提示保持单行，避免底部容器撑高。
    const int highlight_max_lines = 1;

    /// 当前是否需要展示角标。
    final bool show_badge = badge.trim().isNotEmpty;

    /// 当前是否需要展示高亮文案。
    final bool show_highlight = highlight.trim().isNotEmpty;

    /// 当前是否需要展示主标题。
    final bool show_title = title.trim().isNotEmpty;

    /// 当前是否需要展示副标题。
    final bool show_subtitle = subtitle.trim().isNotEmpty;

    /// 构建海报内容容器。
    Widget build_banner_content() {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Style.banner_radius),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // 底层优先显示网络封面，失败时回退到本地占位图。
            _build_background_image(),
            // 中间层叠加纵向渐变，保证文案在不同封面上都有足够可读性。
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    isDark
                        ? Colors.black.withValues(alpha: 0.20)
                        : const Color(0xFFFFF3C4).withValues(alpha: 0.10),
                    isDark
                        ? Colors.black.withValues(alpha: 0.62)
                        : const Color(0xFF7A5B1F).withValues(alpha: 0.36),
                  ],
                ),
              ),
            ),
            // 有角标时在右上角放置装饰圆形，增强视觉层次。
            if (show_badge)
              Positioned(
                top: Style.banner_decoration_circle_top,
                right: Style.banner_decoration_circle_right,
                child: Container(
                  width: Style.banner_decoration_circle_size,
                  height: Style.banner_decoration_circle_size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.20),
                  ),
                ),
              ),
            // 顶层放置文案与角标内容区。
            Padding(
              padding: Style.banner_padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 右上角业务角标（如“必看”“限时”）。
                  if (show_badge)
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Style.banner_badge_horizontal_padding,
                          vertical: Style.banner_badge_vertical_padding,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.16)
                              : Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(
                            Style.banner_badge_radius,
                          ),
                        ),
                        child: Text(
                          badge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Style.banner_badge_font_size,
                            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  // 将主文案推到底部，更符合阅读海报的视觉习惯。
                  const Spacer(),
                  // 标题存在时渲染主标题，并在有副标题时增加间距。
                  if (show_title) ...<Widget>[
                    Text(
                      title,
                      maxLines: title_max_lines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Style.banner_title_font_size,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w900),
                        height: Style.banner_title_height,
                      ),
                    ),
                    if (show_subtitle)
                      const SizedBox(height: Style.banner_title_top_spacing),
                  ],
                  // 副标题存在时渲染副标题。
                  if (show_subtitle)
                    Text(
                      subtitle,
                      maxLines: subtitle_max_lines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: Style.banner_subtitle_font_size,
                        height: Style.banner_subtitle_height,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                      ),
                    ),
                  // 高亮文案存在时渲染底部强调条。
                  if (show_highlight) ...<Widget>[
                    const SizedBox(height: Style.banner_highlight_top_spacing),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Style.banner_highlight_horizontal_padding,
                        vertical: Style.banner_highlight_vertical_padding,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.26),
                        borderRadius: BorderRadius.circular(
                          Style.banner_highlight_radius,
                        ),
                      ),
                      child: Text(
                        highlight,
                        maxLines: highlight_max_lines,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Style.banner_highlight_font_size,
                          fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    /// 如果提供了点击回调，使用 GestureDetector 包裹以支持交互。
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: build_banner_content(),
      );
    }

    return build_banner_content();
  }

  /// 构建海报背景图。
  ///
  /// 优先展示接口返回的网络图片；
  /// 如果网络图片为空，则回退到本地默认海报。
  Widget _build_background_image() {
    if (image_url.trim().isNotEmpty) {
      return NetworkCoverImage(
        image_url: image_url,
        width: double.infinity,
        height: double.infinity,
        border_radius: Style.banner_radius,
        is_dark: isDark,
      );
    }

    return Image.asset(
      image_path,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: isDark ? const Color(0xFF1D2435) : const Color(0xFFDDE4EF),
        );
      },
    );
  }
}
