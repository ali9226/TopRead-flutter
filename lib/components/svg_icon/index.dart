import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart' show rootBundle;

// TODO SVG图标显示
class SvgIcon extends StatefulWidget {
  // TODO 原始 svg 文本缓存：
  // TODO - 用于保留图标内部原本已经写死的多色信息；
  // TODO - 外部需要着色时，只给没有显式 fill 的节点补色，不覆盖原始配色；
  // TODO - 同时也顺手承担第一次读取 asset 文本后的缓存职责。
  static final Map<String, String> _svg_source_cache = <String, String>{};





  final String name;
  final double? width;
  final double? height;
  final Color? color;
  final double opacity; // 新增透明度参数
  final Duration duration;
  final bool animateColor;

  const SvgIcon({
    super.key,
    required this.name,
    this.width,
    this.height,
    this.color,
    this.opacity = 1.0, // 默认 1
    this.duration = const Duration(milliseconds: 300),
    this.animateColor = true,
  });

  @override
  State<SvgIcon> createState() => _SvgIconState();

  // TODO 预热单个 svg 资源到 flutter_svg 全局缓存。
  // TODO 这样后续页面第一次真正渲染这个图标时，就不会再临时触发 svg 编译和缓存写入。
  static Future<void> warm_up_icon(
    String name, {
    BuildContext? context,
  }) async {
    await _warm_up_source('assets/svg/$name.svg');
  }

  // TODO 预热任意 svg 资源路径。
  // TODO 给全局资源预热器复用，避免只能传 icon name。
  static Future<void> warm_up_asset(
    String asset_path, {
    BuildContext? context,
  }) async {
    await _warm_up_source(asset_path);
  }

  static Future<void> _warm_up_source(String asset_path) async {
    if (_svg_source_cache.containsKey(asset_path)) {
      return;
    }
    final String source = await rootBundle.loadString(asset_path);
    _svg_source_cache[asset_path] = _sanitizeSvgSource(source);
  }

  // TODO 统一清理项目里旧 SVG 中 flutter_svg 兼容性较差的 style 节点。
  // TODO 这里放在静态层，是为了让“预热”和“实际渲染”走同一套清洗规则。
  static String _sanitizeSvgSource(String svg) {
    return svg
        .replaceAll(
          RegExp(r'<style\b[^>]*>[\s\S]*?</style>', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'<style\b[^>]*/>', caseSensitive: false),
          '',
        );
  }
}

class _SvgIconState extends State<SvgIcon> with SingleTickerProviderStateMixin {
  String? _svgString;
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _load_svg_source();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    _colorAnimation = ColorTween(
      begin: widget.color,
      end: widget.color,
    ).animate(_controller);

    _listener = () {
      if (!mounted) return;
      setState(() {});
    };
    _colorAnimation.addListener(_listener);

    if (widget.animateColor && widget.color != null) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  Future<void> _load_svg_source() async {
    final String asset_path = 'assets/svg/${widget.name}.svg';
    if (!SvgIcon._svg_source_cache.containsKey(asset_path)) {
      SvgIcon._svg_source_cache[asset_path] = await rootBundle.loadString(
        asset_path,
      );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _svgString = SvgIcon._svg_source_cache[asset_path];
    });
  }

  @override
  void didUpdateWidget(covariant SvgIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.name != widget.name) {
      _svgString = null;
      _load_svg_source();
    }

    if (oldWidget.color != widget.color) {
      _colorAnimation.removeListener(_listener);
      _colorAnimation = ColorTween(
        begin: widget.animateColor ? oldWidget.color : widget.color,
        end: widget.color,
      ).animate(_controller);
      _colorAnimation.addListener(_listener);

      if (widget.animateColor &&
          (oldWidget.color != null || widget.color != null)) {
        _controller.forward(from: 0);
      } else {
        _controller.value = 1;
      }
    }
  }

  @override
  void dispose() {
    _colorAnimation.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  // TODO 选择性补色：
  // TODO - 如果节点本身已经带 fill，就保留原始颜色；
  // TODO - 只有没有显式 fill 的 path/circle/rect 等节点，才补成外部传入颜色；
  // TODO - 这样既能兼容项目里大量“自带多色的 svg”，也能维持原先单色图标的统一着色能力。
  String _apply_selective_color(String svg, Color? color) {
    final String sanitizedSvg = SvgIcon._sanitizeSvgSource(svg);
    if (color == null) {
      return sanitizedSvg;
    }

    final String colorHex =
        '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

    return sanitizedSvg.replaceAllMapped(
      RegExp(r'<(path|circle|rect|polygon|ellipse)(\s[^>]*)?>'),
      (match) {
        final String tag = match[1]!;
        final String attrs = match[2] ?? '';

        if (attrs.contains(RegExp(r'fill="[^"]*"'))) {
          return '<$tag$attrs>';
        }

        return '<$tag$attrs fill="$colorHex">';
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_svgString == null) {
      return SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
      );
    }

    final Color? resolvedColor = _colorAnimation.value;
    final String effectiveSvg = _apply_selective_color(_svgString!, resolvedColor);

    // 计算最终透明度：组件自身透明度 * 颜色通道透明度。
    final double effectiveOpacity = widget.opacity * (resolvedColor?.opacity ?? 1.0);

    return Opacity(
      opacity: effectiveOpacity,
      child: SvgPicture.string(
        effectiveSvg,
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        fit: BoxFit.contain,
      ),
    );
  }
}
