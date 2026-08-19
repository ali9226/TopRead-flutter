import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:app/components/novel_cover/index.dart';
import 'package:app/components/novel_cover/style.dart';

/// 自适应宽高比的小说封面组件。
///
/// 根据网络图片的实际尺寸自动计算宽高比，
/// 宽度固定，高度自适应，适用于瀑布流布局。
///
/// 使用方式：
/// ```dart
/// AdaptiveNovelCover(
///   image_url: 'https://example.com/cover.jpg',
///   width: 120,
///   description: '小说简介',
/// )
/// ```
class AdaptiveNovelCover extends StatefulWidget {
  /// 封面图片URL地址。
  final String? image_url;

  /// 小说简介内容（用于 NovelCover 兜底展示）。
  final String? description;

  /// 固定宽度。传入 [double.infinity] 时会自动使用父容器的实际宽度。
  final double width;

  /// 最小高度限制，避免图片过矮。
  final double min_height;

  /// 最大高度限制，避免图片过高。
  final double max_height;

  /// 图片圆角大小。
  final double? border_radius;

  /// 当前是否为夜间主题。
  final bool? is_dark;

  /// 默认宽高比（图片加载失败或无URL时使用）。
  final double default_aspect_ratio;

  /// 图片填充方式。
  final BoxFit fit;

  /// 封面加载失败时显示的错误文本。
  final String? error_text;

  const AdaptiveNovelCover({
    super.key,
    this.image_url,
    this.description,
    required this.width,
    this.min_height = 80,
    this.max_height = 300,
    this.border_radius,
    this.is_dark,
    this.default_aspect_ratio = 0.72,
    this.fit = BoxFit.cover,
    this.error_text,
  });

  @override
  State<AdaptiveNovelCover> createState() => _AdaptiveNovelCoverState();
}

class _AdaptiveNovelCoverState extends State<AdaptiveNovelCover> {
  /// 图片实际宽高比（宽/高），null 表示尚未加载完成。
  double? _image_aspect_ratio;

  /// 当前正在加载的图片URL，用于避免重复加载。
  String? _loading_url;

  @override
  void initState() {
    super.initState();
    _resolve_image_dimensions();
  }

  @override
  void didUpdateWidget(covariant AdaptiveNovelCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String old_url = (oldWidget.image_url ?? '').trim();
    final String new_url = (widget.image_url ?? '').trim();
    if (old_url != new_url) {
      _image_aspect_ratio = null;
      _resolve_image_dimensions();
    }
  }

  /// 解析图片实际尺寸，计算宽高比。
  ///
  /// 通过 CachedNetworkImage 的缓存机制获取图片信息，
  /// 避免重复网络请求。
  void _resolve_image_dimensions() {
    final String url = (widget.image_url ?? '').trim();
    if (url.isEmpty) return;

    _loading_url = url;

    // 使用 ImageProvider 获取图片尺寸。
    final ImageProvider provider = CachedNetworkImageProvider(url);
    final ImageStream stream = provider.resolve(const ImageConfiguration());

    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        if (!mounted || _loading_url != url) return;
        final double image_width = image.image.width.toDouble();
        final double image_height = image.image.height.toDouble();
        if (image_height > 0) {
          setState(() {
            _image_aspect_ratio = image_width / image_height;
          });
        }
        stream.removeListener(listener);
      },
      onError: (Object error, StackTrace? stackTrace) {
        // 加载失败时使用默认宽高比，不设置 _image_aspect_ratio。
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final double effective_border_radius =
        widget.border_radius ?? NovelCoverStyle.default_border_radius;

    // 当宽度为无限大时，使用 LayoutBuilder 获取父容器的实际宽度。
    if (widget.width == double.infinity) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double actual_width = constraints.maxWidth;
          final double cover_height = _calculate_height(actual_width);

          return NovelCover(
            image_url: widget.image_url,
            description: widget.description,
            width: actual_width,
            height: cover_height,
            border_radius: effective_border_radius,
            is_dark: widget.is_dark,
            fit: widget.fit,
            error_text: widget.error_text,
          );
        },
      );
    }

    // 宽度为固定值时，直接计算高度。
    final double cover_height = _calculate_height(widget.width);

    return NovelCover(
      image_url: widget.image_url,
      description: widget.description,
      width: widget.width,
      height: cover_height,
      border_radius: effective_border_radius,
      is_dark: widget.is_dark,
      fit: widget.fit,
      error_text: widget.error_text,
    );
  }

  /// 根据给定宽度和图片宽高比计算封面高度。
  ///
  /// [width] - 封面宽度。
  /// 返回值 - 限制在 [min_height] 和 [max_height] 之间的高度值。
  double _calculate_height(double width) {
    final double aspect_ratio =
        _image_aspect_ratio ?? widget.default_aspect_ratio;
    double height = width / aspect_ratio;
    return height.clamp(widget.min_height, widget.max_height);
  }
}
