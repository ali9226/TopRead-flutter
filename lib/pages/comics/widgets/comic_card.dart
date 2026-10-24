// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/models/comics.dart';
import 'package:app/components/content_category_tag/index.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/comics/widgets/comic_image.dart';
import 'package:app/util/router/router_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 瀑布流漫画卡片，视觉语言与首页推荐卡片保持一致。
///
/// 结构：封面（角标 + 渐变信息条）→ 标题 → 简介 → 分类标签。
/// 标签颜色按漫画 id 稳定取色，日夜主题下均保持可读对比度。
/// 交互与首页推荐卡片一致：按下时文字区域轻微缩放，封面保持不变。
/// 设计参数统一由 [ComicCardStyle] 管理。
class ComicCard extends StatefulWidget {
  /// 漫画数据。
  final ComicItem comic;

  /// 点击回调；为空时默认跳转漫画详情页。
  final VoidCallback? on_tap;

  const ComicCard({super.key, required this.comic, this.on_tap});

  @override
  State<ComicCard> createState() => _ComicCardState();
}

class _ComicCardState extends State<ComicCard>
    with SingleTickerProviderStateMixin {
  /// 文字区域按压缩放动画控制器。
  late final AnimationController _press_scale_controller;

  /// 文字区域按压缩放动画：1.0 → [ComicCardStyle.press_text_scale]。
  late final Animation<double> _press_scale_animation;

  /// 指针按下时的初始位置，用于判断是否滑动以取消缩放。
  Offset _pointer_start_position = Offset.zero;

  @override
  void initState() {
    super.initState();
    _press_scale_controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: ComicCardStyle.press_scale_duration_ms,
      ),
    );
    _press_scale_animation =
        Tween<double>(begin: 1.0, end: ComicCardStyle.press_text_scale).animate(
          CurvedAnimation(
            parent: _press_scale_controller,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void dispose() {
    _press_scale_controller.dispose();
    super.dispose();
  }

  /// 指针按下：启动文字区域缩放动画。
  void _on_pointer_down(PointerDownEvent event) {
    _pointer_start_position = event.position;
    _press_scale_controller.forward();
  }

  /// 指针移动：超过阈值时恢复缩放，避免列表滚动过程中卡片仍处于压缩状态。
  void _on_pointer_move(PointerMoveEvent event) {
    if (!_press_scale_controller.isAnimating &&
        _press_scale_controller.value == 0) {
      return;
    }
    final double distance = (event.position - _pointer_start_position).distance;
    if (distance > ComicCardStyle.press_move_cancel_threshold) {
      _press_scale_controller.reverse();
    }
  }

  /// 指针抬起：回弹恢复文字区域缩放。
  void _on_pointer_up(PointerUpEvent event) {
    _press_scale_controller.reverse();
  }

  /// 指针取消：回弹恢复文字区域缩放。
  void _on_pointer_cancel(PointerCancelEvent event) {
    _press_scale_controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    /// 卡片背景色：日间纯白，夜间深蓝灰。
    final bool is_dark = ComicsStyle.is_dark(context);
    final bool is_cjk = ComicsStyle.is_cjk(context);
    final Color card_bg = is_dark
        ? ComicCardStyle.card_dark_bg
        : ComicCardStyle.card_light_bg;

    /// 标题颜色。
    final Color title_color = is_dark
        ? ComicCardStyle.title_dark
        : ComicCardStyle.title_light;

    /// 简介颜色。
    final Color description_color = is_dark
        ? ComicCardStyle.description_dark
        : ComicCardStyle.description_light;

    /// 点击波纹色。
    final Color ripple_color = ColorConstants.themeColor.withValues(
      alpha: ComicCardStyle.ripple_opacity,
    );

    /// 点击高亮色。
    final Color highlight_color = ColorConstants.themeColor.withValues(
      alpha: ComicCardStyle.highlight_opacity,
    );

    /// CJK 与拉丁语系使用不同字阶、行高与字距。
    final double title_font_size = is_cjk
        ? ComicCardStyle.title_font_size_cjk
        : ComicCardStyle.title_font_size_alphabetic;
    final double title_height = is_cjk
        ? ComicCardStyle.title_height_cjk
        : ComicCardStyle.title_height_alphabetic;
    final double description_font_size = is_cjk
        ? ComicCardStyle.description_font_size_cjk
        : ComicCardStyle.description_font_size_alphabetic;
    final double description_height = is_cjk
        ? ComicCardStyle.description_height_cjk
        : ComicCardStyle.description_height_alphabetic;
    final double description_top_spacing = is_cjk
        ? ComicCardStyle.description_top_spacing_cjk
        : ComicCardStyle.description_top_spacing_alphabetic;
    final double? title_letter_spacing = is_cjk
        ? null
        : ComicCardStyle.title_letter_spacing_alphabetic;
    final double? description_letter_spacing = is_cjk
        ? null
        : ComicCardStyle.description_letter_spacing_alphabetic;

    final String display_title = widget.comic.title.trim();
    final String display_description = widget.comic.description.trim();

    /// 分类标签最多展示 [ComicCardStyle.max_tag_count] 个，与首页推荐卡片一致。
    final List<Map<String, dynamic>> tags = widget.comic.categories
        .take(ComicCardStyle.max_tag_count)
        .toList();

    return Semantics(
      button: true,
      label: widget.comic.author_name.isEmpty
          ? display_title
          : tr(
              'comics.card_semantic',
              namedArgs: <String, String>{
                'title': display_title,
                'author': widget.comic.author_name,
              },
            ),
      child: Listener(
        onPointerDown: _on_pointer_down,
        onPointerMove: _on_pointer_move,
        onPointerUp: _on_pointer_up,
        onPointerCancel: _on_pointer_cancel,
        child: Material(
          color: card_bg,
          borderRadius: BorderRadius.circular(ComicCardStyle.card_radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap:
                widget.on_tap ??
                () => routerUtil(path: '/comics/detail?id=${widget.comic.id}'),
            splashFactory: InkRipple.splashFactory,
            splashColor: ripple_color,
            highlightColor: highlight_color,
            radius: 240,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                /// 封面区域：角标 + 底部信息条，不参与按压缩放。
                _build_cover_area(),

                /// 文字区域：按下时轻微缩放，抬起回弹。
                AnimatedBuilder(
                  animation: _press_scale_animation,
                  builder: (BuildContext context, Widget? child) {
                    return Transform.scale(
                      scale: _press_scale_animation.value,
                      alignment: Alignment.topCenter,
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      ComicCardStyle.content_padding_h,
                      ComicCardStyle.content_padding_top,
                      ComicCardStyle.content_padding_h,
                      ComicCardStyle.content_padding_bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        /// 标题。
                        Text(
                          display_title,
                          maxLines: ComicCardStyle.title_max_lines,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: title_color,
                            fontSize: title_font_size,
                            height: title_height,
                            letterSpacing: title_letter_spacing,
                            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                          ),
                        ),

                        /// 简介。
                        if (display_description.isNotEmpty) ...<Widget>[
                          SizedBox(height: description_top_spacing),
                          Text(
                            display_description,
                            maxLines: ComicCardStyle.description_max_lines,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: description_color,
                              fontSize: description_font_size,
                              height: description_height,
                              letterSpacing: description_letter_spacing,
                              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                            ),
                          ),
                        ],

                        /// 分类标签。
                        if (tags.isNotEmpty) ...<Widget>[
                          const SizedBox(
                            height: ComicCardStyle.tag_top_spacing,
                          ),
                          Wrap(
                            spacing: ComicCardStyle.tag_spacing,
                            runSpacing: ComicCardStyle.tag_run_spacing,
                            children: List<Widget>.generate(tags.length, (
                              int index,
                            ) {
                              return _build_tag_item(
                                label: ComicsStyle.category_name(
                                  context,
                                  tags[index],
                                ),
                                color: _tag_color(index),
                                card_bg: card_bg,
                                is_cjk: is_cjk,
                              );
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建封面区域：封面图、完结/连载角标、底部章节信息条。
  Widget _build_cover_area() {
    return Stack(
      children: <Widget>[
        /// 封面图：上圆角裁切，保持漫画竖版比例。
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(ComicCardStyle.card_radius),
            topRight: Radius.circular(ComicCardStyle.card_radius),
          ),
          child: AspectRatio(
            aspectRatio: ComicsStyle.cover_ratio,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ComicImage(
                  url: widget.comic.cover_url,
                  semantic_label: widget.comic.title,
                ),

                /// 底部渐变 + 章节信息。
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      ComicCardStyle.cover_meta_padding_h,
                      ComicCardStyle.cover_meta_padding_top,
                      ComicCardStyle.cover_meta_padding_h,
                      0,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          ColorConstants.shadowColor.withValues(alpha: ComicCardStyle.cover_gradient_top_opacity),
                          ColorConstants.shadowColor.withValues(alpha: ComicCardStyle.cover_gradient_bottom_opacity),
                        ],
                      ),
                    ),
                    child: Text(
                      tr(
                        'comics.chapter_count',
                        namedArgs: <String, String>{
                          'count': '${widget.comic.chapter_count}',
                        },
                      ),
                      style: TextStyle(
                        color: ColorConstants.whiteColor,
                        fontSize: ComicCardStyle.cover_meta_font_size,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                        shadows: <Shadow>[
                          Shadow(
                            color: ColorConstants.lightTextColor.withValues(alpha: ComicCardStyle.cover_meta_shadow_opacity),
                            blurRadius: 8,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        /// 完结 / 连载角标。
        Positioned(
          top: ComicCardStyle.cover_badge_margin.top,
          left: ComicCardStyle.cover_badge_margin.left,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ColorConstants.lightTextColor.withValues(alpha: ComicCardStyle.cover_badge_background_opacity),
              borderRadius: BorderRadius.circular(
                ComicCardStyle.cover_badge_radius,
              ),
            ),
            child: Padding(
              padding: ComicCardStyle.cover_badge_padding,
              child: Text(
                tr(
                  widget.comic.completion_status == 'completed'
                      ? 'comics.completed'
                      : 'comics.ongoing',
                ),
                style: TextStyle(
                  color: ColorConstants.whiteColor,
                  fontSize: ComicCardStyle.cover_badge_font_size,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建单个分类标签：浅色底 + 同色文字。
  ///
  /// [label] 标签文案。
  /// [color] 标签主色。
  /// [card_bg] 卡片背景色，用于混合出浅色底。
  /// [is_cjk] 当前语种是否为 CJK，决定标签字阶与内边距。
  Widget _build_tag_item({
    required String label,
    required Color color,
    required Color card_bg,
    required bool is_cjk,
  }) {
    return ContentCategoryTag(
      label: label,
      color: color,
      surface_color: card_bg,
      is_cjk: is_cjk,
    );
  }

  /// 按漫画 id 与标签序号稳定取色，保证同一漫画的标签颜色不随刷新变化。
  ///
  /// [index] 标签在列表中的序号。
  Color _tag_color(int index) {
    if (ColorConstants.tagColorList.isEmpty) return ColorConstants.themeColor;
    final int safe_index =
        (widget.comic.id * ComicCardStyle.tag_color_id_factor +
            index * ComicCardStyle.tag_color_index_factor) %
        ColorConstants.tagColorList.length;
    return ColorConstants.tagColorList[safe_index];
  }
}
