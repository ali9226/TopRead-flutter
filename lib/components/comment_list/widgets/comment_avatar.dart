import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:app/components/svg_icon/index.dart';

/// 评论区头像组件。
///
/// 网络头像使用磁盘与内存缓存且关闭渐入动画，避免滚动评论列表时反复解码或闪烁。
class CommentAvatar extends StatelessWidget {
  final String avatar_url;
  final int user_id;
  final double size;
  final bool is_dark;

  const CommentAvatar({
    super.key,
    required this.avatar_url,
    required this.user_id,
    required this.size,
    required this.is_dark,
  });

  @override
  Widget build(BuildContext context) {
    final String normalized_url = avatar_url.trim();
    final Widget fallback = _build_fallback();
    final int cache_size = (size * MediaQuery.devicePixelRatioOf(context))
        .round();

    return RepaintBoundary(
      child: ClipOval(
        child: normalized_url.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: normalized_url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                memCacheWidth: cache_size,
                memCacheHeight: cache_size,
                maxWidthDiskCache: cache_size,
                maxHeightDiskCache: cache_size,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (_, _) => fallback,
                errorWidget: (_, _, _) => fallback,
              ),
      ),
    );
  }

  Widget _build_fallback() {
    final int fallback_index = user_id.abs() % 10;
    final String fallback_svg =
        'avatar_${fallback_index.toString().padLeft(2, '0')}';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: is_dark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0),
        shape: BoxShape.circle,
      ),
      child: SvgIcon(
        name: fallback_svg,
        width: size,
        height: size,
        animateColor: false,
      ),
    );
  }
}
