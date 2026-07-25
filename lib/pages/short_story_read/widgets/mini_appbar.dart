import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:app/pages/short_story_read/style.dart';
import 'package:app/config/font_config.dart';

/// 迷你标题栏组件。
///
/// 固定显示在页面顶部，包含：
/// - 返回按钮
/// - 标题文字（带淡入/滑入动画）
/// - 金币图标（带重复上下弹跳动画）
///
/// 当完整导航栏（[FullAppbar]）隐藏时仍然可见，
/// 为用户提供基本的导航信息和返回能力。
///
/// 可以覆盖状态栏区域，需要外部传入 [status_bar_height] 进行适配。
class MiniAppbar extends StatefulWidget {
  /// 标题文字。
  final String title;

  /// 是否为夜间模式。
  final bool is_dark;

  /// 返回按钮点击回调。
  final VoidCallback on_back;

  /// 状态栏高度（用于顶部内边距适配）。
  final double status_bar_height;

  /// 是否显示标题。
  ///
  /// 当内容标题在可视区域内时可设为 false 隐藏，
  /// 避免重复显示标题。默认为 true。
  final bool show_title;

  const MiniAppbar({
    super.key,
    required this.title,
    required this.is_dark,
    required this.on_back,
    required this.status_bar_height,
    this.show_title = true,
  });

  @override
  State<MiniAppbar> createState() => _MiniAppbarState();
}

class _MiniAppbarState extends State<MiniAppbar>
    with SingleTickerProviderStateMixin {
  /// 金币图标弹跳动画控制器（无限循环，正反播放）。
  late AnimationController _bounce_controller;

  /// 金币图标弹跳位移动画（-3px ~ 3px 范围内上下移动）。
  late Animation<double> _bounce_animation;

  @override
  void initState() {
    super.initState();

    // 初始化弹跳动画控制器（1 秒一个周期，自动正反播放）。
    _bounce_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // 弹跳位移动画：在 -3px 到 3px 之间平滑过渡。
    _bounce_animation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(
        parent: _bounce_controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _bounce_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// 背景色（夜间模式使用卡片背景色，日间模式使用导航栏背景色）。
    final Color bg_color = widget.is_dark
        ? ShortStoryReadStyle.card_dark_bg
        : ShortStoryReadStyle.appbar_light_bg;

    /// 标题文字颜色。
    final Color title_color = widget.is_dark
        ? ShortStoryReadStyle.title_dark_color
        : ShortStoryReadStyle.title_light_color;

    return Container(
      padding: EdgeInsets.only(top: widget.status_bar_height),
      color: bg_color,
      child: SizedBox(
        height: ShortStoryReadStyle.mini_appbar_height,
        child: Row(
          children: <Widget>[
            /// 返回按钮（箭头朝左，使用 180° 旋转实现）。
            IconButton(
              icon: Transform.rotate(
                angle: 3.14159,
                child: SvgPicture.asset(
                  'assets/svg/right.svg',
                  width: 16,
                  height: 16,
                  colorFilter:
                      ColorFilter.mode(title_color, BlendMode.srcIn),
                ),
              ),
              onPressed: widget.on_back,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),

            /// 标题文字（带淡入和滑入动画，垂直居中）。
            Expanded(
              child: AnimatedOpacity(
                opacity: widget.show_title ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedSlide(
                  offset:
                      widget.show_title ? Offset.zero : const Offset(0, -0.5),
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                      color: title_color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),

            /// 金币图标（带重复上下弹跳动画）。
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: AnimatedBuilder(
                animation: _bounce_animation,
                builder: (BuildContext context, Widget? child) {
                  return Transform.translate(
                    offset: Offset(0, _bounce_animation.value),
                    child: child,
                  );
                },
                child: SvgPicture.asset(
                  'assets/svg/gold.svg',
                  width: 16,
                  height: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
