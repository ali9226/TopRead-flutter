import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/components/novel_cover/style.dart';
import 'package:app/components/novel_cover/skeleton_animation.dart';

/// 小说封面组件。
///
/// 展示规则：
/// 1. 如果有网络封面URL，优先直接展示网络封面；
/// 2. 如果没有网络封面URL，从 1.png ~ 21.png 中稳定随机一张作为背景；
/// 3. 在默认背景图上按封面尺寸自适应展示小说简介文字；
/// 4. 网络封面加载失败时，也使用默认背景 + 简介文字兜底。
class NovelCover extends StatefulWidget {
  /// 封面图片URL地址。
  final String? image_url;

  /// 小说简介内容。
  final String? description;

  /// 图片展示宽度。
  final double? width;

  /// 图片展示高度。
  final double? height;

  /// 图片圆角大小。
  final double? border_radius;

  /// 图片填充方式。
  final BoxFit fit;

  /// 当前是否为夜间主题。
  ///
  /// 如果外部没有显式传入，则自动根据当前主题亮度推断。
  final bool? is_dark;

  /// 保留旧参数，避免外部调用处还传了 error_text 导致编译报错。
  ///
  /// 当前组件已不再展示错误文案，图片失败会直接显示默认背景 + 简介。
  final String? error_text;

  const NovelCover({
    super.key,
    this.image_url,
    this.description,
    this.width,
    this.height,
    this.border_radius,
    this.fit = BoxFit.cover,
    this.is_dark,
    this.error_text,
  });

  @override
  State<NovelCover> createState() => _NovelCoverState();
}

class _NovelCoverState extends State<NovelCover> {
  /// 简介为空时使用的随机默认背景图序号。
  late int _empty_description_fallback_index;

  @override
  void initState() {
    super.initState();
    _empty_description_fallback_index = _generate_random_fallback_cover_index();
  }

  @override
  void didUpdateWidget(covariant NovelCover oldWidget) {
    super.didUpdateWidget(oldWidget);

    final String old_cover_url = (oldWidget.image_url ?? '').trim();
    final String current_cover_url = (widget.image_url ?? '').trim();
    final String old_description = (oldWidget.description ?? '').trim();
    final String current_description = _get_trimmed_description();

    if (current_description.isEmpty &&
        (old_cover_url != current_cover_url ||
            old_description != current_description)) {
      _empty_description_fallback_index =
          _generate_random_fallback_cover_index();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool current_is_dark =
        widget.is_dark ?? Theme.of(context).brightness == Brightness.dark;

    final String cover_url = (widget.image_url ?? '').trim();
    final double effective_width = _get_effective_width();
    final double effective_height = _get_effective_height();
    final double effective_border_radius = _get_effective_border_radius();

    // 有网络封面时，直接展示网络封面。
    if (cover_url.isNotEmpty) {
      return _build_network_image(
        context: context,
        current_is_dark: current_is_dark,
        cover_url: cover_url,
        effective_width: effective_width,
        effective_height: effective_height,
        effective_border_radius: effective_border_radius,
      );
    }

    // 无网络封面时，展示随机默认背景 + 简介文字。
    return _build_fallback_cover_with_description(
      context: context,
      current_is_dark: current_is_dark,
      effective_width: effective_width,
      effective_height: effective_height,
      effective_border_radius: effective_border_radius,
    );
  }

  /// 获取组件实际展示宽度。
  double _get_effective_width() {
    return widget.width ?? NovelCoverStyle.default_width;
  }

  /// 获取组件实际展示高度。
  double _get_effective_height() {
    return widget.height ?? NovelCoverStyle.default_height;
  }

  /// 获取组件实际圆角大小。
  double _get_effective_border_radius() {
    return widget.border_radius ?? NovelCoverStyle.default_border_radius;
  }

  /// 获取去除首尾空格后的简介内容。
  String _get_trimmed_description() {
    return (widget.description ?? '').trim();
  }

  /// 随机生成默认背景图序号。
  int _generate_random_fallback_cover_index() {
    return math.Random().nextInt(NovelCoverStyle.fallback_cover_count) + 1;
  }

  /// 构建网络图片展示区域。
  Widget _build_network_image({
    required BuildContext context,
    required bool current_is_dark,
    required String cover_url,
    required double effective_width,
    required double effective_height,
    required double effective_border_radius,
  }) {
    return SizedBox(
      width: effective_width,
      height: effective_height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effective_border_radius),
        child: CachedNetworkImage(
          imageUrl: cover_url,
          width: effective_width,
          height: effective_height,
          fit: widget.fit,
          placeholder: (BuildContext context, String url) {
            return _build_skeleton(
              current_is_dark: current_is_dark,
              effective_width: effective_width,
              effective_height: effective_height,
              effective_border_radius: effective_border_radius,
            );
          },
          errorWidget: (BuildContext context, String url, Object error) {
            return _build_fallback_cover_with_description(
              context: context,
              current_is_dark: current_is_dark,
              effective_width: effective_width,
              effective_height: effective_height,
              effective_border_radius: effective_border_radius,
            );
          },
        ),
      ),
    );
  }

  /// 构建骨架屏占位。
  Widget _build_skeleton({
    required bool current_is_dark,
    required double effective_width,
    required double effective_height,
    required double effective_border_radius,
  }) {
    final Color base_color = current_is_dark
        ? NovelCoverStyle.dark_skeleton_base_color
        : NovelCoverStyle.light_skeleton_base_color;

    final Color highlight_color = current_is_dark
        ? NovelCoverStyle.dark_skeleton_highlight_color
        : NovelCoverStyle.light_skeleton_highlight_color;

    return NovelCoverSkeletonAnimation(
      base_color: base_color,
      highlight_color: highlight_color,
      width: effective_width,
      height: effective_height,
      border_radius: effective_border_radius,
    );
  }

  /// 构建默认背景 + 简介文字封面。
  Widget _build_fallback_cover_with_description({
    required BuildContext context,
    required bool current_is_dark,
    required double effective_width,
    required double effective_height,
    required double effective_border_radius,
  }) {
    final String background_url = _get_stable_random_fallback_cover_url();
    final _NovelCoverPosterConfig poster_config = _build_poster_config(
      context: context,
      effective_width: effective_width,
      effective_height: effective_height,
    );

    return SizedBox(
      width: effective_width,
      height: effective_height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effective_border_radius),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CachedNetworkImage(
              imageUrl: background_url,
              width: effective_width,
              height: effective_height,
              fit: BoxFit.cover,
              placeholder: (BuildContext context, String url) {
                return _build_skeleton(
                  current_is_dark: current_is_dark,
                  effective_width: effective_width,
                  effective_height: effective_height,
                  effective_border_radius: effective_border_radius,
                );
              },
              errorWidget: (BuildContext context, String url, Object error) {
                return Container(
                  width: effective_width,
                  height: effective_height,
                  color: current_is_dark
                      ? NovelCoverStyle.dark_fallback_background_color
                      : NovelCoverStyle.light_fallback_background_color,
                );
              },
            ),
            _build_poster_overlay(poster_config),
            _build_description_text(poster_config),
          ],
        ),
      ),
    );
  }

  /// 生成稳定随机的默认背景图URL。
  ///
  /// 使用 description 的 hashCode，让同一本小说在列表刷新、页面 rebuild 时不会频繁换背景。
  String _get_stable_random_fallback_cover_url() {
    final String trimmed_description = _get_trimmed_description();
    final int index = trimmed_description.isNotEmpty
        ? _get_stable_hash(trimmed_description) %
                  NovelCoverStyle.fallback_cover_count +
              1
        : _empty_description_fallback_index;

    return '${NovelCoverStyle.fallback_cover_base_url}/$index.png';
  }

  /// 构建海报版式配置。
  _NovelCoverPosterConfig _build_poster_config({
    required BuildContext context,
    required double effective_width,
    required double effective_height,
  }) {
    final String trimmed_description = _get_trimmed_description();
    final String language_code = Localizations.localeOf(context).languageCode;
    final bool is_cjk = LanguageUtil.is_cjk_language(language_code);
    final bool is_compact =
        effective_width < NovelCoverStyle.compact_cover_width;
    final bool is_medium =
        !is_compact && effective_width < NovelCoverStyle.medium_cover_width;
    final bool is_large = effective_width >= NovelCoverStyle.large_cover_width;
    final int variant_index =
        _get_poster_seed() % NovelCoverStyle.poster_variant_count;
    final EdgeInsets padding = _get_poster_padding(
      is_compact: is_compact,
      is_medium: is_medium,
      is_large: is_large,
    );
    final double font_size = _get_poster_font_size(
      is_cjk: is_cjk,
      is_compact: is_compact,
      is_medium: is_medium,
      is_large: is_large,
    );
    final double line_height = _get_poster_line_height(
      is_cjk: is_cjk,
      is_compact: is_compact,
      is_medium: is_medium,
      is_large: is_large,
    );
    final int max_lines = _get_poster_max_lines(
      effective_height: effective_height,
      padding: padding,
      font_size: font_size,
      line_height: line_height,
      is_compact: is_compact,
      is_medium: is_medium,
      is_large: is_large,
    );

    return _NovelCoverPosterConfig(
      description_text: trimmed_description,
      overlay_type: _get_poster_overlay_type(variant_index),
      alignment: _get_poster_alignment(
        variant_index: variant_index,
        is_compact: is_compact,
      ),
      text_align: _get_poster_text_align(
        variant_index: variant_index,
        is_compact: is_compact,
      ),
      text_color: _get_poster_text_color(variant_index: variant_index),
      padding: padding,
      width_factor: _get_poster_width_factor(
        is_compact: is_compact,
        is_medium: is_medium,
        is_large: is_large,
      ),
      font_size: font_size,
      line_height: line_height,
      max_lines: max_lines,
      shadows: _build_poster_text_shadows(
        variant_index: variant_index,
        is_compact: is_compact,
      ),
    );
  }

  /// 获取稳定的海报随机种子。
  int _get_poster_seed() {
    final String trimmed_description = _get_trimmed_description();
    if (trimmed_description.isEmpty) {
      return _empty_description_fallback_index * 9973;
    }
    return _get_stable_hash(trimmed_description);
  }

  /// 获取字符串稳定哈希，避免使用 hashCode 造成不同启动间样式漂移。
  int _get_stable_hash(String value) {
    int hash = 0;
    for (final int code_unit in value.codeUnits) {
      hash = 0x1fffffff & (hash * 31 + code_unit);
    }
    return hash.abs();
  }

  /// 获取海报文字内边距。
  EdgeInsets _get_poster_padding({
    required bool is_compact,
    required bool is_medium,
    required bool is_large,
  }) {
    if (is_compact) return NovelCoverStyle.compact_description_padding;
    if (is_medium) return NovelCoverStyle.medium_description_padding;
    if (is_large) return NovelCoverStyle.large_description_padding;
    return NovelCoverStyle.description_padding;
  }

  /// 获取海报文字字号。
  double _get_poster_font_size({
    required bool is_cjk,
    required bool is_compact,
    required bool is_medium,
    required bool is_large,
  }) {
    if (is_compact) {
      return is_cjk
          ? NovelCoverStyle.compact_description_font_size_cjk
          : NovelCoverStyle.compact_description_font_size_alphabetic;
    }

    if (is_medium) {
      return is_cjk
          ? NovelCoverStyle.medium_description_font_size_cjk
          : NovelCoverStyle.medium_description_font_size_alphabetic;
    }

    if (is_large) {
      return is_cjk
          ? NovelCoverStyle.large_description_font_size_cjk
          : NovelCoverStyle.large_description_font_size_alphabetic;
    }

    return is_cjk
        ? NovelCoverStyle.description_font_size_cjk
        : NovelCoverStyle.description_font_size_alphabetic;
  }

  /// 获取海报文字行高。
  double _get_poster_line_height({
    required bool is_cjk,
    required bool is_compact,
    required bool is_medium,
    required bool is_large,
  }) {
    if (is_compact) {
      return is_cjk
          ? NovelCoverStyle.compact_description_line_height_cjk
          : NovelCoverStyle.compact_description_line_height_alphabetic;
    }

    if (is_medium) {
      return is_cjk
          ? NovelCoverStyle.medium_description_line_height_cjk
          : NovelCoverStyle.medium_description_line_height_alphabetic;
    }

    if (is_large) {
      return is_cjk
          ? NovelCoverStyle.large_description_line_height_cjk
          : NovelCoverStyle.large_description_line_height_alphabetic;
    }

    return is_cjk
        ? NovelCoverStyle.description_line_height_cjk
        : NovelCoverStyle.description_line_height_alphabetic;
  }

  /// 获取海报文字最大行数。
  int _get_poster_max_lines({
    required double effective_height,
    required EdgeInsets padding,
    required double font_size,
    required double line_height,
    required bool is_compact,
    required bool is_medium,
    required bool is_large,
  }) {
    final int base_max_lines = is_compact
        ? NovelCoverStyle.compact_description_max_lines
        : (is_medium
              ? NovelCoverStyle.medium_description_max_lines
              : (is_large
                    ? NovelCoverStyle.large_description_max_lines
                    : NovelCoverStyle.description_max_lines));
    final double available_height = math.max(
      0,
      effective_height - padding.vertical,
    );
    final int visible_line_count = math.max(
      1,
      (available_height / (font_size * line_height)).floor(),
    );
    return math.max(1, math.min(base_max_lines, visible_line_count));
  }

  /// 获取海报文字区域宽度比例。
  double _get_poster_width_factor({
    required bool is_compact,
    required bool is_medium,
    required bool is_large,
  }) {
    if (is_compact) return NovelCoverStyle.compact_description_width_factor;
    if (is_medium) return NovelCoverStyle.medium_description_width_factor;
    if (is_large) return NovelCoverStyle.large_description_width_factor;
    return NovelCoverStyle.description_width_factor;
  }

  /// 获取海报遮罩类型。
  int _get_poster_overlay_type(int variant_index) {
    switch (variant_index) {
      case 1:
        return NovelCoverStyle.poster_overlay_top_light;
      case 2:
        return NovelCoverStyle.poster_overlay_none;
      case 3:
        return NovelCoverStyle.poster_overlay_bottom_dark;
      case 4:
        return NovelCoverStyle.poster_overlay_left_light;
      case 5:
        return NovelCoverStyle.poster_overlay_light_gradient;
      case 0:
      default:
        return NovelCoverStyle.poster_overlay_dark_gradient;
    }
  }

  /// 获取海报文字位置。
  Alignment _get_poster_alignment({
    required int variant_index,
    required bool is_compact,
  }) {
    switch (variant_index) {
      case 1:
        return Alignment.topCenter;
      case 2:
        return is_compact ? Alignment.center : Alignment.topLeft;
      case 3:
        return Alignment.bottomCenter;
      case 4:
        return is_compact ? Alignment.center : Alignment.centerLeft;
      case 5:
        return is_compact ? Alignment.bottomCenter : Alignment.bottomRight;
      case 0:
      default:
        return Alignment.center;
    }
  }

  /// 获取海报文字对齐方式。
  TextAlign _get_poster_text_align({
    required int variant_index,
    required bool is_compact,
  }) {
    if (is_compact) return TextAlign.center;
    if (variant_index == 2 || variant_index == 4) return TextAlign.left;
    if (variant_index == 5) return TextAlign.right;
    return TextAlign.center;
  }

  /// 获取海报文字颜色。
  Color _get_poster_text_color({required int variant_index}) {
    switch (variant_index) {
      case 1:
      case 4:
        return NovelCoverStyle.poster_dark_text_color.withValues(
          alpha: NovelCoverStyle.description_text_opacity,
        );
      case 2:
      case 5:
        return NovelCoverStyle.poster_warm_text_color.withValues(
          alpha: NovelCoverStyle.description_text_opacity,
        );
      case 0:
      case 3:
      default:
        return Colors.white.withValues(
          alpha: NovelCoverStyle.description_text_opacity,
        );
    }
  }

  /// 构建海报文字阴影。
  List<Shadow> _build_poster_text_shadows({
    required int variant_index,
    required bool is_compact,
  }) {
    final double blur_radius = is_compact
        ? NovelCoverStyle.compact_text_shadow_blur_radius
        : NovelCoverStyle.text_shadow_blur_radius;

    if (variant_index == 1 || variant_index == 2 || variant_index == 4) {
      return <Shadow>[
        Shadow(
          color: Colors.white.withValues(
            alpha: NovelCoverStyle.light_text_shadow_opacity,
          ),
          offset: const Offset(0, NovelCoverStyle.text_shadow_offset_y),
          blurRadius: blur_radius,
        ),
      ];
    }

    return <Shadow>[
      Shadow(
        color: Colors.black.withValues(
          alpha: NovelCoverStyle.text_shadow_opacity,
        ),
        offset: const Offset(0, NovelCoverStyle.text_shadow_offset_y),
        blurRadius: blur_radius,
      ),
    ];
  }

  /// 构建海报遮罩。
  Widget _build_poster_overlay(_NovelCoverPosterConfig poster_config) {
    if (poster_config.description_text.isEmpty ||
        poster_config.overlay_type == NovelCoverStyle.poster_overlay_none) {
      return const SizedBox.shrink();
    }

    switch (poster_config.overlay_type) {
      case NovelCoverStyle.poster_overlay_top_light:
        return _build_linear_overlay(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(
              alpha: NovelCoverStyle.light_overlay_high_opacity,
            ),
            Colors.white.withValues(
              alpha: NovelCoverStyle.light_overlay_low_opacity,
            ),
            Colors.transparent,
          ],
        );
      case NovelCoverStyle.poster_overlay_bottom_dark:
        return _build_linear_overlay(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.transparent,
            Colors.black.withValues(
              alpha: NovelCoverStyle.dark_overlay_medium_opacity,
            ),
            Colors.black.withValues(
              alpha: NovelCoverStyle.dark_overlay_high_opacity,
            ),
          ],
        );
      case NovelCoverStyle.poster_overlay_left_light:
        return _build_linear_overlay(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            Colors.white.withValues(
              alpha: NovelCoverStyle.light_overlay_high_opacity,
            ),
            Colors.white.withValues(
              alpha: NovelCoverStyle.light_overlay_low_opacity,
            ),
            Colors.transparent,
          ],
        );
      case NovelCoverStyle.poster_overlay_light_gradient:
        return _build_linear_overlay(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(
              alpha: NovelCoverStyle.light_overlay_medium_opacity,
            ),
            Colors.white.withValues(
              alpha: NovelCoverStyle.light_overlay_high_opacity,
            ),
            Colors.white.withValues(
              alpha: NovelCoverStyle.light_overlay_low_opacity,
            ),
          ],
        );
      case NovelCoverStyle.poster_overlay_dark_gradient:
      default:
        return _build_linear_overlay(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.black.withValues(
              alpha: NovelCoverStyle.dark_overlay_low_opacity,
            ),
            Colors.black.withValues(
              alpha: NovelCoverStyle.dark_overlay_medium_opacity,
            ),
            Colors.black.withValues(
              alpha: NovelCoverStyle.dark_overlay_high_opacity,
            ),
          ],
        );
    }
  }

  /// 构建线性渐变遮罩。
  Widget _build_linear_overlay({
    required Alignment begin,
    required Alignment end,
    required List<Color> colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: begin, end: end, colors: colors),
      ),
    );
  }

  /// 构建简介文字。
  Widget _build_description_text(_NovelCoverPosterConfig poster_config) {
    if (poster_config.description_text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Padding(
        padding: poster_config.padding,
        child: Align(
          alignment: poster_config.alignment,
          child: FractionallySizedBox(
            widthFactor: poster_config.width_factor,
            child: Text(
              poster_config.description_text,
              maxLines: poster_config.max_lines,
              overflow: TextOverflow.ellipsis,
              textAlign: poster_config.text_align,
              style: TextStyle(
                color: poster_config.text_color,
                fontSize: poster_config.font_size,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                height: poster_config.line_height,
                shadows: poster_config.shadows,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 海报版式配置。
class _NovelCoverPosterConfig {
  /// 简介文本。
  final String description_text;

  /// 遮罩类型。
  final int overlay_type;

  /// 文字位置。
  final Alignment alignment;

  /// 文字对齐方式。
  final TextAlign text_align;

  /// 文字颜色。
  final Color text_color;

  /// 文字内边距。
  final EdgeInsets padding;

  /// 文字区域宽度比例。
  final double width_factor;

  /// 文字字号。
  final double font_size;

  /// 文字行高。
  final double line_height;

  /// 最大行数。
  final int max_lines;

  /// 文字阴影。
  final List<Shadow> shadows;

  const _NovelCoverPosterConfig({
    required this.description_text,
    required this.overlay_type,
    required this.alignment,
    required this.text_align,
    required this.text_color,
    required this.padding,
    required this.width_factor,
    required this.font_size,
    required this.line_height,
    required this.max_lines,
    required this.shadows,
  });
}
