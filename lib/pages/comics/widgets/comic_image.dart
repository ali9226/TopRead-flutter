// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/comics/style.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 封面和图片页共用缓存与失败重试。URL 不重复编码，避免 OBS 的 %20 被改成 %2520。
class ComicImage extends StatefulWidget {
  final String url;
  final String semantic_label;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// 缩略图按实际像素宽度解码；阅读器不传此值，保留完整图片清晰度。
  final int? cache_width;
  const ComicImage({
    super.key,
    required this.url,
    required this.semantic_label,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cache_width,
  });
  @override
  State<ComicImage> createState() => _ComicImageState();
}

class _ComicImageState extends State<ComicImage> {
  int _attempt = 0;
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    await CachedNetworkImage.evictFromCache(widget.url);
    if (!mounted) return;
    setState(() {
      _attempt++;
      _retrying = false;
    });
  }

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: widget.semantic_label,
    child: widget.url.isEmpty
        ? ColoredBox(
            color: ComicsStyle.outline(context),
            child: const Center(child: Icon(Icons.photo_outlined)),
          )
        : CachedNetworkImage(
            key: ValueKey('${widget.url}:$_attempt'),
            imageUrl: widget.url,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            memCacheWidth: widget.cache_width,
            fadeInDuration: const Duration(milliseconds: 180),
            placeholder: (context, url) => ColoredBox(
              color: ComicsStyle.outline(context),
              child: const Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (context, url, error) => ColoredBox(
              color: ComicsStyle.outline(context),
              child: Center(
                child: IconButton(
                  tooltip: tr('comics.retry_image'),
                  onPressed: _retrying ? null : _retry,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
            ),
          ),
  );
}
