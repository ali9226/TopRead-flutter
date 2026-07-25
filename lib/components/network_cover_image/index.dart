import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:app/components/network_cover_image/style.dart';
import 'package:app/components/network_cover_image/widgets/loading_skeleton.dart';

/// 通用网络封面图组件。
///
/// 这个组件统一处理三件事情：
/// 1. 正常展示网络图片；
/// 2. 图片加载中展示渐变骨架屏；
/// 3. 图片加载失败时展示统一的兜底占位。
///
/// 这样首页书籍列表或后续其他小说封面场景都不需要重复写
/// `Image.network`、`loadingBuilder`、`errorBuilder` 相关逻辑。
class NetworkCoverImage extends StatelessWidget {
  /// 网络图片地址。
  final String image_url;

  /// 图片展示宽度。
  final double width;

  /// 图片展示高度。
  final double height;

  /// 图片圆角大小。
  final double border_radius;

  /// 图片填充方式。
  final BoxFit fit;

  /// 当前是否为夜间主题。
  ///
  /// 如果外部没有显式传入，则自动根据当前主题亮度推断。
  final bool? is_dark;

  /// 图片加载失败时展示的占位文案。
  final String? error_text;

  const NetworkCoverImage({
    super.key,
    required this.image_url,
    required this.width,
    required this.height,
    required this.border_radius,
    this.fit = BoxFit.cover,
    this.is_dark,
    this.error_text,
  });

  @override
  Widget build(BuildContext context) {
    /// 优先使用外部传入的主题值，避免和页面已有主题状态产生偏差。
    final bool current_is_dark =
        is_dark ?? Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(border_radius),
      child: CachedNetworkImage(
        imageUrl: image_url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (BuildContext context, String url) {
          return NetworkCoverLoadingSkeleton(
            width: width,
            height: height,
            border_radius: border_radius,
            is_dark: current_is_dark,
          );
        },
        errorWidget: (
          BuildContext context,
          String url,
          Object error,
        ) {
          /// 错误态背景色。
          final Color background_color = current_is_dark
              ? NetworkCoverImageStyle.dark_error_background_color
              : NetworkCoverImageStyle.light_error_background_color;

          /// 错误态前景色。
          final Color foreground_color = current_is_dark
              ? NetworkCoverImageStyle.dark_error_foreground_color
              : NetworkCoverImageStyle.light_error_foreground_color;

          return Container(
            width: width,
            height: height,
            color: background_color,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.menu_book_rounded,
                  size: NetworkCoverImageStyle.error_icon_size,
                  color: foreground_color.withValues(
                    alpha: NetworkCoverImageStyle.error_icon_opacity,
                  ),
                ),
                if ((error_text ?? '').isNotEmpty) ...<Widget>[
                  const SizedBox(
                    height: NetworkCoverImageStyle.error_content_gap,
                  ),
                  Text(
                    error_text!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground_color.withValues(
                        alpha: NetworkCoverImageStyle.error_text_opacity,
                      ),
                      fontSize:
                          NetworkCoverImageStyle.error_text_font_size,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
