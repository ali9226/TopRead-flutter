import 'dart:async';
import 'package:app/config/font_config.dart';

import 'package:flutter/material.dart';

import 'package:app/components/recommend_book_card/book_list_item.dart';
import 'package:app/components/novel_cover/adaptive_cover.dart';
import 'package:app/components/recommend_book_card/style.dart';
import 'package:app/components/recommend_book_card/widgets/card_dislike_overlay.dart';
import 'package:app/config/color_config.dart';

/// 推荐书籍卡片组件。
///
/// 展示单本推荐书籍信息，包含：
/// - 封面图片（带角标和附加信息）
/// - 标题（最多两行）
/// - 简介（最多两行）
/// - 标签列表
///
/// 交互特性：
/// - 按下时文字区域轻微缩放，图片保持不变
/// - 长按触发卡片内部遮罩，垂直居中显示"不喜欢"按钮
/// - 点击"不喜欢"触发删除回调
/// - 点击遮罩或关闭按钮关闭弹窗
/// - 弹窗状态由父组件统一管理
class RecommendBookCard extends StatefulWidget {
  /// 当前书籍数据。
  final BookListItem item;

  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 点击卡片的回调。
  final VoidCallback? on_tap;

  /// 长按触发"不喜欢"删除的回调。
  final VoidCallback? on_dislike;

  /// 是否强制显示不喜欢弹窗（由父组件控制）。
  final bool show_overlay;

  /// 弹窗关闭回调（通知父组件）。
  final VoidCallback? on_overlay_close;

  /// 长按触发回调（通知父组件显示弹窗）。
  final VoidCallback? on_long_press;

  const RecommendBookCard({
    super.key,
    required this.item,
    required this.is_dark,
    this.on_tap,
    this.on_dislike,
    this.show_overlay = false,
    this.on_overlay_close,
    this.on_long_press,
  });

  @override
  State<RecommendBookCard> createState() => _RecommendBookCardState();
}

class _RecommendBookCardState extends State<RecommendBookCard>
    with SingleTickerProviderStateMixin {
  /// 文字缩放动画控制器。
  late AnimationController _scale_animation_controller;

  /// 文字缩放动画：1.0 → 0.96。
  late Animation<double> _scale_animation;

  /// 长按计时器。
  Timer? _long_press_timer;

  /// 手指是否仍在按下状态。
  bool _is_pointer_down = false;

  /// 标记长按已触发（防止重复触发）。
  bool _long_press_fired = false;

  /// 手指按下时的初始位置，用于判断是否滑动。
  Offset _pointer_start_position = Offset.zero;

  @override
  void initState() {
    super.initState();
    _scale_animation_controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: RecommendBookCardStyle.scale_animation_duration_ms,
      ),
    );

    _scale_animation = Tween<double>(
      begin: 1.0,
      end: RecommendBookCardStyle.long_press_text_scale,
    ).animate(CurvedAnimation(
      parent: _scale_animation_controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _long_press_timer?.cancel();
    _scale_animation_controller.dispose();
    super.dispose();
  }

  /// 手指按下：启动缩放动画和长按计时器。
  void _on_pointer_down(PointerDownEvent event) {
    if (widget.show_overlay) return;

    _is_pointer_down = true;
    _long_press_fired = false;
    _pointer_start_position = event.position;
    _scale_animation_controller.forward();
    _long_press_timer = Timer(
      Duration(milliseconds: RecommendBookCardStyle.long_press_duration_ms),
      _on_long_press_triggered,
    );
  }

  /// 手指移动：超过阈值时取消长按（列表滚动场景）。
  void _on_pointer_move(PointerMoveEvent event) {
    if (widget.show_overlay) return;

    if (_is_pointer_down && !_long_press_fired) {
      final double distance =
          (event.position - _pointer_start_position).distance;
      if (distance > RecommendBookCardStyle.move_cancel_threshold) {
        _cancel_long_press();
      }
    }
  }

  /// 手指抬起：取消计时器，恢复缩放。
  void _on_pointer_up(PointerUpEvent event) {
    _is_pointer_down = false;
    _long_press_timer?.cancel();
    if (!widget.show_overlay) {
      _scale_animation_controller.reverse();
    }
  }

  /// 手指移出：取消计时器，恢复缩放。
  void _on_pointer_cancel(PointerCancelEvent event) {
    _is_pointer_down = false;
    _long_press_timer?.cancel();
    if (!widget.show_overlay) {
      _scale_animation_controller.reverse();
    }
  }

  /// 取消长按：停止计时器，恢复缩放动画。
  void _cancel_long_press() {
    _long_press_timer?.cancel();
    if (_scale_animation_controller.isAnimating ||
        _scale_animation_controller.value > 0) {
      _scale_animation_controller.reverse();
    }
  }

  /// 长按到达指定时长时触发：通知父组件显示弹窗。
  void _on_long_press_triggered() {
    if (_is_pointer_down && !_long_press_fired) {
      _long_press_fired = true;
      widget.on_long_press?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    /// 卡片背景色。
    final Color card_bg = widget.is_dark
        ? RecommendBookCardStyle.card_dark_bg
        : RecommendBookCardStyle.card_light_bg;

    /// 标题颜色。
    final Color title_color = widget.is_dark
        ? Colors.white
        : const Color(0xFF161C28);

    /// 简介颜色。
    final Color description_color = widget.is_dark
        ? Colors.white.withValues(alpha: 0.62)
        : const Color(0xFF8B93A2);

    /// 波纹颜色。
    final Color ripple_color = ColorConstants.themeColor.withValues(
      alpha: RecommendBookCardStyle.ripple_opacity,
    );

    /// 高亮颜色。
    final Color highlight_color = ColorConstants.themeColor.withValues(
      alpha: RecommendBookCardStyle.highlight_opacity,
    );

    return Listener(
      onPointerDown: _on_pointer_down,
      onPointerMove: _on_pointer_move,
      onPointerUp: _on_pointer_up,
      onPointerCancel: _on_pointer_cancel,
      child: Material(
        color: card_bg,
        borderRadius: BorderRadius.circular(
          RecommendBookCardStyle.card_radius,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.show_overlay ? null : widget.on_tap,
          splashFactory: InkRipple.splashFactory,
          splashColor: ripple_color,
          highlightColor: highlight_color,
          radius: 240,
          child: Stack(
            children: <Widget>[
              /// 卡片内容：封面 + 文字区域。
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  /// 封面区域：图片不参与缩放。
                  _build_cover_area(),

                  /// 文字区域：按下时轻微缩放。
                  AnimatedBuilder(
                    animation: _scale_animation,
                    builder: (BuildContext context, Widget? child) {
                      return Transform.scale(
                        scale: _scale_animation.value,
                        alignment: Alignment.topCenter,
                        child: child,
                      );
                    },
                    child: Padding(
                      padding: RecommendBookCardStyle.content_padding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          /// 标题。
                          Text(
                            widget.item.title,
                            maxLines: RecommendBookCardStyle.title_max_lines,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: title_color,
                              fontSize: RecommendBookCardStyle.title_font_size,
                              height: RecommendBookCardStyle.title_height,
                              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                            ),
                          ),

                          /// 简介。
                          if (widget.item.has_description) ...<Widget>[
                            const SizedBox(
                              height: RecommendBookCardStyle.description_top_spacing,
                            ),
                            Text(
                              widget.item.description,
                              maxLines: RecommendBookCardStyle.description_max_lines,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: description_color,
                                fontSize: RecommendBookCardStyle.description_font_size,
                                height: RecommendBookCardStyle.description_height,
                                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                              ),
                            ),
                          ],

                          /// 标签列表。
                          if (widget.item.has_tags) ...<Widget>[
                            const SizedBox(
                              height: RecommendBookCardStyle.tag_top_spacing,
                            ),
                            Wrap(
                              spacing: RecommendBookCardStyle.tag_spacing,
                              runSpacing: RecommendBookCardStyle.tag_run_spacing,
                              children: widget.item.tag_list
                                  .map(
                                    (BookListTagItem tag_item) =>
                                        _build_tag_item(
                                          tag_item: tag_item,
                                          is_dark: widget.is_dark,
                                        ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              /// 不喜欢叠加层：由父组件控制显示/隐藏。
              Positioned.fill(
                child: CardDislikeOverlay(
                  is_dark: widget.is_dark,
                  visible: widget.show_overlay,
                  on_dislike: widget.on_dislike,
                  on_close: widget.on_overlay_close,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建封面区域。
  Widget _build_cover_area() {
    return Stack(
      children: <Widget>[
        // 自适应封面：宽度固定为容器宽度，高度根据图片实际宽高比自动调整。
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(RecommendBookCardStyle.card_radius),
            topRight: Radius.circular(RecommendBookCardStyle.card_radius),
          ),
          child: AdaptiveNovelCover(
            image_url: widget.item.cover_url,
            description: widget.item.description,
            width: double.infinity,
            min_height: RecommendBookCardStyle.cover_min_height,
            max_height: RecommendBookCardStyle.cover_max_height,
            border_radius: 0,
            is_dark: widget.is_dark,
            default_aspect_ratio: widget.item.cover_aspect_ratio,
            error_text: '封面',
          ),
        ),
        if (widget.item.has_cover_badge)
          Positioned(
            top: RecommendBookCardStyle.cover_badge_margin.top,
            left: RecommendBookCardStyle.cover_badge_margin.left,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(
                  alpha: RecommendBookCardStyle.cover_badge_background_opacity,
                ),
                borderRadius: BorderRadius.circular(
                  RecommendBookCardStyle.cover_badge_radius,
                ),
              ),
              child: Padding(
                padding: RecommendBookCardStyle.cover_badge_padding,
                child: Text(
                  widget.item.cover_badge,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: RecommendBookCardStyle.cover_badge_font_size,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                  ),
                ),
              ),
            ),
          ),
        if (widget.item.has_cover_meta_text)
          Positioned(
            left: RecommendBookCardStyle.cover_meta_margin.left,
            right: RecommendBookCardStyle.cover_meta_margin.right,
            bottom: RecommendBookCardStyle.cover_meta_margin.bottom,
            child: Text(
              widget.item.cover_meta_text,
              style: TextStyle(
                color: Colors.white,
                fontSize: RecommendBookCardStyle.cover_meta_font_size,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                shadows: <Shadow>[
                  Shadow(
                    color: Colors.black.withValues(
                      alpha: RecommendBookCardStyle.cover_meta_shadow_opacity,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// 构建单个标签。
  Widget _build_tag_item({
    required BookListTagItem tag_item,
    required bool is_dark,
  }) {
    final Color tag_background_color = Color.alphaBlend(
      tag_item.color.withValues(
        alpha: RecommendBookCardStyle.tag_background_opacity,
      ),
      is_dark ? RecommendBookCardStyle.card_dark_bg : RecommendBookCardStyle.card_light_bg,
    );

    return Container(
      padding: RecommendBookCardStyle.tag_padding,
      decoration: BoxDecoration(
        color: tag_background_color,
        borderRadius: BorderRadius.circular(RecommendBookCardStyle.tag_radius),
      ),
      child: Text(
        tag_item.label,
        style: TextStyle(
          color: tag_item.color.withValues(
            alpha: RecommendBookCardStyle.tag_text_opacity,
          ),
          fontSize: RecommendBookCardStyle.tag_font_size,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
        ),
      ),
    );
  }
}
