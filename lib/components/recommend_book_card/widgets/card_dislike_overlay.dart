import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

import 'package:app/components/recommend_book_card/style.dart';
import 'package:app/components/svg_icon/index.dart';

/// 卡片内部不喜欢叠加层组件。
///
/// 长按卡片后在卡片内部显示遮罩和"不喜欢"按钮，
/// 右上角显示关闭按钮用于关闭弹窗。
/// 支持显示/隐藏动画。
/// 弹窗仅作用于单个卡片内部，不影响其他卡片。
class CardDislikeOverlay extends StatefulWidget {
  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 是否可见。
  final bool visible;

  /// 点击"不喜欢"按钮的回调。
  final VoidCallback? on_dislike;

  /// 关闭动画完成后的回调。
  final VoidCallback? on_close;

  const CardDislikeOverlay({
    super.key,
    required this.is_dark,
    this.visible = true,
    this.on_dislike,
    this.on_close,
  });

  @override
  State<CardDislikeOverlay> createState() => _CardDislikeOverlayState();
}

class _CardDislikeOverlayState extends State<CardDislikeOverlay>
    with SingleTickerProviderStateMixin {
  /// 动画控制器。
  late AnimationController _controller;

  /// 遮罩层动画。
  late Animation<double> _overlay_animation;

  /// 不喜欢按钮滑入动画。
  late Animation<Offset> _button_slide_animation;

  /// 关闭按钮淡入动画。
  late Animation<double> _close_animation;

  /// 遮罩按下时间戳（用于判断是否是真正的点击）。
  DateTime? _overlay_pointer_down_time;

  /// 有效的点击时间阈值（毫秒）。
  static const int _tap_threshold_ms = 200;

  /// 弹窗显示时间（用于忽略长按松手触发的点击）。
  DateTime? _show_time;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: RecommendBookCardStyle.overlay_animation_duration_ms,
      ),
    );

    _overlay_animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _button_slide_animation = Tween<Offset>(
      begin: const Offset(0, 2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: RecommendBookCardStyle.dislike_slide_curve,
    ));

    _close_animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    if (widget.visible) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CardDislikeOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.visible && !oldWidget.visible) {
      _show_time = DateTime.now();
      _controller.forward(from: 0.0);
    } else if (!widget.visible && oldWidget.visible) {
      // 反向播放动画，不回调（避免影响新弹窗）
      _controller.reverse();
    }
  }

  /// 遮罩按下事件。
  void _on_overlay_pointer_down(PointerDownEvent event) {
    _overlay_pointer_down_time = DateTime.now();
  }

  /// 遮罩抬起事件：判断是否是真正的点击。
  void _on_overlay_pointer_up(PointerUpEvent event) {
    if (_overlay_pointer_down_time == null) return;

    final Duration duration = DateTime.now().difference(_overlay_pointer_down_time!);
    _overlay_pointer_down_time = null;

    // 忽略弹窗刚显示后的点击（防止长按松手触发关闭）
    if (_show_time != null) {
      final Duration since_show = DateTime.now().difference(_show_time!);
      if (since_show.inMilliseconds < 500) {
        return;
      }
    }

    // 只有按下时间足够短才算是一次点击
    if (duration.inMilliseconds < _tap_threshold_ms) {
      widget.on_close?.call();
    }
  }

  /// 遮罩取消事件。
  void _on_overlay_pointer_cancel(PointerCancelEvent event) {
    _overlay_pointer_down_time = null;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible && _controller.isDismissed) {
      return const SizedBox.shrink();
    }

    /// 遮罩层颜色。
    final Color overlay_color = RecommendBookCardStyle.overlay_color;

    /// 按钮背景色。
    final Color button_bg = widget.is_dark
        ? RecommendBookCardStyle.dislike_button_dark_bg
        : RecommendBookCardStyle.dislike_button_light_bg;

    /// 按钮文字色。
    final Color button_text_color = widget.is_dark
        ? RecommendBookCardStyle.dislike_button_dark_text
        : RecommendBookCardStyle.dislike_button_light_text;

    /// 关闭按钮背景色（半透明白色，适配夜间模式）。
    final Color close_bg = widget.is_dark
        ? RecommendBookCardStyle.close_button_dark_bg
        : RecommendBookCardStyle.close_button_light_bg;

    /// 关闭图标颜色。
    final Color close_icon_color = widget.is_dark
        ? RecommendBookCardStyle.close_icon_dark_color
        : RecommendBookCardStyle.close_icon_light_color;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            /// 遮罩层：使用 Listener 检测真正的点击（按下时间短）。
            Positioned.fill(
              child: Listener(
                onPointerDown: _on_overlay_pointer_down,
                onPointerUp: _on_overlay_pointer_up,
                onPointerCancel: _on_overlay_pointer_cancel,
                child: Container(
                  color: overlay_color.withValues(
                    alpha: _overlay_animation.value * 0.4,
                  ),
                ),
              ),
            ),

            /// 右上角关闭按钮。
            Positioned(
              top: RecommendBookCardStyle.close_button_top,
              right: RecommendBookCardStyle.close_button_right,
              child: Opacity(
                opacity: _close_animation.value,
                child: GestureDetector(
                  onTap: () {
                    widget.on_close?.call();
                  },
                  child: Container(
                    width: RecommendBookCardStyle.close_button_size,
                    height: RecommendBookCardStyle.close_button_size,
                    decoration: BoxDecoration(
                      color: close_bg,
                      borderRadius: BorderRadius.circular(
                        RecommendBookCardStyle.close_button_radius,
                      ),
                    ),
                    child: Center(
                      child: SvgIcon(
                        name: 'close',
                        width: RecommendBookCardStyle.close_icon_size,
                        height: RecommendBookCardStyle.close_icon_size,
                        color: close_icon_color,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            /// 不喜欢按钮：垂直居中，从下方滑入。
            Positioned.fill(
              child: SlideTransition(
                position: _button_slide_animation,
                child: Center(
                  child: GestureDetector(
                    onTap: widget.on_dislike,
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(
                        horizontal: RecommendBookCardStyle.dislike_button_horizontal_padding,
                      ),
                      height: RecommendBookCardStyle.dislike_button_height,
                      decoration: BoxDecoration(
                        color: button_bg,
                        borderRadius: BorderRadius.circular(
                          RecommendBookCardStyle.dislike_button_radius,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SvgIcon(
                            name: 'skip',
                            width: RecommendBookCardStyle.dislike_icon_size,
                            height: RecommendBookCardStyle.dislike_icon_size,
                            color: button_text_color,
                          ),
                          const SizedBox(width: RecommendBookCardStyle.dislike_icon_gap),
                          Text(
                            easy.tr('recommend_card.dislike'),
                            style: TextStyle(
                              fontSize: RecommendBookCardStyle.dislike_button_font_size,
                              color: button_text_color,
                              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
