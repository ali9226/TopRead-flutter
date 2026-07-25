import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:app/components/network_cover_image/style.dart';
import 'package:app/config/font_config.dart';

/// 自适应宽高比的网络封面图组件。
///
/// 通过 [ImageProvider.resolve] 在图片加载完成后获取真实像素尺寸，
/// 动态计算宽高比并驱动 [AspectRatio] 更新，从而让瀑布流中每张封面
/// 都按原始比例展示，而非使用固定默认值。
///
/// 加载过程中使用骨架屏占位，加载失败时展示统一的错误占位。
class CoverImage extends StatefulWidget {
  /// 封面图片地址。
  final String image_url;

  /// 图片加载失败时展示的占位文案。
  final String? error_text;

  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 默认宽高比（图片加载完成前或加载失败时使用）。
  static const double _default_aspect_ratio = 0.74;

  const CoverImage({
    super.key,
    required this.image_url,
    required this.is_dark,
    this.error_text,
  });

  @override
  State<CoverImage> createState() => _CoverImageState();
}

/// [CoverImage] 的状态类。
class _CoverImageState extends State<CoverImage> with SingleTickerProviderStateMixin {
  /// 当前解析到的宽高比，为 `null` 时表示尚未解析完成。
  double? _resolved_aspect_ratio;

  /// 图片是否加载失败。
  bool _has_error = false;

  /// 骨架屏动画控制器。
  late final AnimationController _animation_controller;

  /// 骨架屏动画进度。
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _animation_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _animation = CurvedAnimation(
      parent: _animation_controller,
      curve: Curves.easeInOut,
    );

    _resolve_aspect_ratio();
  }

  @override
  void didUpdateWidget(CoverImage old_widget) {
    super.didUpdateWidget(old_widget);

    if (old_widget.image_url != widget.image_url) {
      setState(() {
        _resolved_aspect_ratio = null;
        _has_error = false;
      });
      _resolve_aspect_ratio();
    }
  }

  @override
  void dispose() {
    _animation_controller.dispose();
    super.dispose();
  }

  /// 通过 [CachedNetworkImageProvider.resolve] 获取图片真实尺寸并计算宽高比。
  ///
  /// 使用 [CachedNetworkImageProvider] 替代 [NetworkImage]，
  /// 图片会持久化到磁盘缓存，页面返回时直接读取本地文件，
  /// 不会因为内存缓存被挤出而重复发起网络请求。
  void _resolve_aspect_ratio() {
    final ImageProvider provider = CachedNetworkImageProvider(widget.image_url);
    final ImageStream stream = provider.resolve(const ImageConfiguration());

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo image_info, bool _) {
        final double ratio =
            image_info.image.width / image_info.image.height;
        if (mounted) {
          setState(() {
            _resolved_aspect_ratio = ratio;
          });
        }
        stream.removeListener(listener);
      },
      onError: (Object _, StackTrace? __) {
        if (mounted) {
          setState(() {
            _has_error = true;
          });
        }
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    /// 当前使用的宽高比：解析完成则用真实值，否则用默认值。
    final double aspect_ratio =
        _resolved_aspect_ratio ?? CoverImage._default_aspect_ratio;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
      child: AspectRatio(
        aspectRatio: aspect_ratio,
        child: _has_error
            ? _build_error_placeholder()
            : _build_image(aspect_ratio: aspect_ratio),
      ),
    );
  }

  /// 构建图片展示区域。
  ///
  /// 使用 [CachedNetworkImage] 替代 [Image.network]，
  /// 图片会持久化到磁盘缓存，页面返回时无需重新下载。
  /// 加载中展示骨架屏，加载失败展示错误占位。
  Widget _build_image({required double aspect_ratio}) {
    return CachedNetworkImage(
      imageUrl: widget.image_url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      placeholder: (BuildContext context, String url) => _build_skeleton(),
      errorWidget: (
        BuildContext context,
        String url,
        Object error,
      ) {
        return _build_error_placeholder();
      },
    );
  }

  /// 构建骨架屏占位。
  ///
  /// 使用渐变动画模拟加载效果，与 [NetworkCoverLoadingSkeleton] 风格一致。
  Widget _build_skeleton() {
    final Color base_color = widget.is_dark
        ? NetworkCoverImageStyle.dark_skeleton_base_color
        : NetworkCoverImageStyle.light_skeleton_base_color;

    final Color highlight_color = widget.is_dark
        ? NetworkCoverImageStyle.dark_skeleton_highlight_color
        : NetworkCoverImageStyle.light_skeleton_highlight_color;

    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        final double slide_value = Tween<double>(
          begin: -1,
          end: 1,
        ).transform(_animation.value);

        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment(-1.6 + slide_value, -0.3),
              end: Alignment(1.6 + slide_value, 0.3),
              colors: <Color>[
                base_color,
                base_color,
                highlight_color,
                base_color,
                base_color,
              ],
              stops: NetworkCoverImageStyle.skeleton_gradient_stops,
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: const ColoredBox(color: Colors.white),
        );
      },
    );
  }

  /// 构建加载失败占位。
  Widget _build_error_placeholder() {
    final Color background_color = widget.is_dark
        ? NetworkCoverImageStyle.dark_error_background_color
        : NetworkCoverImageStyle.light_error_background_color;

    final Color foreground_color = widget.is_dark
        ? NetworkCoverImageStyle.dark_error_foreground_color
        : NetworkCoverImageStyle.light_error_foreground_color;

    return ColoredBox(
      color: background_color,
      child: Center(
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
            if ((widget.error_text ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(
                height: NetworkCoverImageStyle.error_content_gap,
              ),
              Text(
                widget.error_text!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground_color.withValues(
                    alpha: NetworkCoverImageStyle.error_text_opacity,
                  ),
                  fontSize: NetworkCoverImageStyle.error_text_font_size,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
