import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/message/style.dart';

/// 消息列表骨架屏，带 shimmer 流光动画。
///
/// 布局与 [MessageItemCard] 保持一致：
/// 左侧圆形图标占位 + 右侧标题行/内容行占位。
class MessageSkeleton extends StatefulWidget {
  final bool is_dark;
  final int count;

  const MessageSkeleton({super.key, required this.is_dark, this.count = 6});

  @override
  State<MessageSkeleton> createState() => _MessageSkeletonState();
}

class _MessageSkeletonState extends State<MessageSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.linear);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            final double dx = _animation.value * 2.0;
            return LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.28),
                Colors.white.withValues(alpha: 0.12),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
              begin: Alignment(-1.0 + dx, 0.0),
              end: Alignment(0.0 + dx, 0.0),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Column(
        children: List.generate(widget.count, (_) => _build_item()),
      ),
    );
  }

  Widget _build_item() {
    final Color card_color =
        widget.is_dark ? const Color(0xFF171C28) : Colors.white;
    final Color block_color =
        widget.is_dark ? const Color(0xFF2A2A3C) : const Color(0xFFF0F0F0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: MessageStyle.card_padding,
        decoration: BoxDecoration(
          color: card_color,
          borderRadius: BorderRadius.circular(MessageStyle.card_radius),
          border: Border.all(
            color: ColorConstants.themeColor.withValues(
              alpha: widget.is_dark ? 0.18 : 0.10,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左侧圆形图标占位
            Container(
              width: MessageStyle.icon_wrap_size,
              height: MessageStyle.icon_wrap_size,
              decoration: BoxDecoration(
                color: block_color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // 右侧内容区
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题行：标题占位 + 时间占位
                  Row(
                    children: [
                      Container(
                        width: 100,
                        height: 14,
                        decoration: BoxDecoration(
                          color: block_color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 40,
                        height: 11,
                        decoration: BoxDecoration(
                          color: block_color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 内容行：副标题占位 + 标签占位
                  Row(
                    children: [
                      Container(
                        width: 160,
                        height: 12,
                        decoration: BoxDecoration(
                          color: block_color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 36,
                        height: 18,
                        decoration: BoxDecoration(
                          color: block_color,
                          borderRadius: BorderRadius.circular(
                            MessageStyle.badge_radius,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
