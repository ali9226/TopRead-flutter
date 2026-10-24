import 'package:app/config/font_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'style.dart';

/// 保留读者真实头像，缺失或失败时以昵称首字代替无关的随机插图。
class ReadReviewerAvatar extends StatelessWidget {
  const ReadReviewerAvatar({
    super.key,
    required this.avatar_url,
    required this.user_name,
    required this.is_dark,
  });
  final String avatar_url;
  final String user_name;
  final bool is_dark;

  @override
  Widget build(BuildContext context) {
    final initial = user_name
        .trim()
        .characters
        .take(1)
        .toString()
        .toUpperCase();
    final fallback = ColoredBox(
      color: CommentItemStyle.avatar_background(is_dark),
      child: Center(
        child: initial.isEmpty
            ? Icon(
                Icons.person_outline_rounded,
                size: CommentItemStyle.avatar_fallback_icon_size,
                color: CommentItemStyle.name_color(is_dark),
              )
            : Text(
                initial,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: CommentItemStyle.avatar_initial_size,
                  color: CommentItemStyle.avatar_initial_color(is_dark),
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                ),
              ),
      ),
    );
    final cache_size =
        (CommentItemStyle.avatar_size * MediaQuery.devicePixelRatioOf(context))
            .ceil();
    return RepaintBoundary(
      child: ClipOval(
        child: SizedBox.square(
          dimension: CommentItemStyle.avatar_size,
          child: avatar_url.trim().isEmpty
              ? fallback
              : CachedNetworkImage(
                  imageUrl: avatar_url.trim(),
                  fit: BoxFit.cover,
                  memCacheWidth: cache_size,
                  memCacheHeight: cache_size,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  placeholder: (_, _) => fallback,
                  errorWidget: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}
