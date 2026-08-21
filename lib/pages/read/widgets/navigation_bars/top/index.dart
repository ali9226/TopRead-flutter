import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/stores/project_config_store.dart';

/// 阅读页顶部导航栏组件。
///
/// 返回按钮 + 书架图标 + 收藏按钮 + 分享按钮。
class ReadTopBar extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 是否显示导航栏。
  final bool show;

  /// 返回按钮回调。
  final VoidCallback on_back;

  /// 收藏按钮回调。
  final VoidCallback on_favorite_tap;

  /// 分享按钮回调。
  final VoidCallback on_share;

  /// 是否已收藏。
  final bool is_favorited;

  /// 是否正在收藏请求中。
  final bool is_favorite_loading;

  /// 是否正在加载内容。
  ///
  /// 为 true 时右侧图标显示骨架屏动画，内容加载完成后才显示真实图标。
  final bool is_loading;

  const ReadTopBar({
    super.key,
    required this.is_dark,
    required this.show,
    required this.on_back,
    required this.on_favorite_tap,
    required this.on_share,
    required this.is_favorited,
    this.is_favorite_loading = false,
    this.is_loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final double status_bar_height = MediaQuery.viewPaddingOf(context).top;

    /// 导航栏高度（不含状态栏）。
    const double appbar_height = 44.0;

    /// 背景色。
    final Color bg_color = is_dark ? const Color(0xFF161B22) : Colors.white;

    /// 左侧图标颜色（返回按钮）。
    final Color left_icon_color = is_dark
        ? Colors.white
        : const Color(0xFF1F1A12);

    /// 右侧图标颜色（夜间模式与底部导航栏图标颜色一致，降低透明度避免过于刺眼）。
    final Color right_icon_color = is_dark
        ? Colors.white.withValues(alpha: 0.7)
        : const Color(0xFF1F1A12);

    /// 骨架屏底色。
    final Color skeleton_base_color = is_dark
        ? const Color(0xFF252836)
        : const Color(0xFFF0F1F5);

    /// 骨架屏高亮色。
    final Color skeleton_highlight_color = is_dark
        ? const Color(0xFF384356)
        : const Color(0xFFF7F9FC);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: show ? 0 : -(status_bar_height + appbar_height),
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: status_bar_height),
        color: bg_color,
        child: SizedBox(
          height: appbar_height,
          child: Row(
            children: <Widget>[
              /// 返回按钮（箭头朝左，使用 180° 旋转实现）。
              IconButton(
                icon: Transform.rotate(
                  angle: 3.14159,
                  child: SvgIcon(
                    name: 'right',
                    width: 20,
                    height: 20,
                    color: left_icon_color,
                  ),
                ),
                onPressed: on_back,
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(),
              ),

              const Spacer(),

              /// 收藏按钮（加载时显示骨架屏，完成后显示真实图标）。
              is_loading
                  ? Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: _IconSkeleton(
                        size: 22,
                        base_color: skeleton_base_color,
                        highlight_color: skeleton_highlight_color,
                      ),
                    )
                  : GestureDetector(
                      onTap: is_favorite_loading ? null : on_favorite_tap,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.elasticOut,
                          tween: Tween<double>(begin: 0.6, end: 1.0),
                          builder: (context, scale, child) {
                            return Transform.scale(scale: scale, child: child);
                          },
                          key: ValueKey(is_favorited),
                          child: SvgIcon(
                            name: is_favorited
                                ? 'user_selected'
                                : 'not_favorited',
                            width: 22,
                            height: 22,
                            color: is_favorited
                                ? (is_dark
                                      ? const Color(
                                          0xFFD0D4DB,
                                        ).withValues(alpha: 0.82)
                                      : null)
                                : right_icon_color,
                          ),
                        ),
                      ),
                    ),

              /// 分享按钮随远端项目配置实时显示或隐藏。
              Obx(() {
                final bool is_share_enabled =
                    Get.find<ProjectConfigStore>().current.is_share_enabled;
                if (!is_share_enabled) return const SizedBox.shrink();

                return is_loading
                    ? Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _IconSkeleton(
                          size: 20,
                          base_color: skeleton_base_color,
                          highlight_color: skeleton_highlight_color,
                        ),
                      )
                    : GestureDetector(
                        onTap: on_share,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: SvgIcon(
                            name: 'share',
                            width: 20,
                            height: 20,
                            color: is_dark
                                ? const Color(
                                    0xFFD0D4DB,
                                  ).withValues(alpha: 0.82)
                                : right_icon_color,
                          ),
                        ),
                      );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// 图标骨架屏组件。
///
/// 在内容加载期间显示圆形骨架屏动画，替代真实的收藏和分享图标。
class _IconSkeleton extends StatefulWidget {
  /// 骨架屏尺寸（宽高相等）。
  final double size;

  /// 骨架屏底色。
  final Color base_color;

  /// 骨架屏高亮色。
  final Color highlight_color;

  const _IconSkeleton({
    required this.size,
    required this.base_color,
    required this.highlight_color,
  });

  @override
  State<_IconSkeleton> createState() => _IconSkeletonState();
}

class _IconSkeletonState extends State<_IconSkeleton>
    with SingleTickerProviderStateMixin {
  /// 动画控制器。
  late final AnimationController _animation_controller;

  /// 动画曲线。
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
  }

  @override
  void dispose() {
    _animation_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: AnimatedBuilder(
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
                  widget.base_color,
                  widget.base_color,
                  widget.highlight_color,
                  widget.base_color,
                  widget.base_color,
                ],
                stops: const <double>[0.10, 0.32, 0.50, 0.68, 0.90],
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop,
            child: Container(
              width: widget.size,
              height: widget.size,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }
}
