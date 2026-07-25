import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:app/config/font_config.dart';

/// 顶部下拉查看上一篇提示组件。
///
/// 当用户从正文顶部向下拉动时，显示上一篇小说的标题和提示文字。
/// 组件会根据拉动距离动态调整透明度、缩放和位置。
///
/// 交互规则：
/// - 下拉距离未达到触发阈值时显示"下拉查看"
/// - 下拉距离达到触发阈值后显示"松开查看"
/// - 组件位置跟随下拉距离移动，提供视觉反馈
///
/// 参数：
/// - [is_dark] 是否为夜间模式
/// - [status_bar_height] 状态栏高度
/// - [pull_offset] 当前下拉的视觉位移距离
/// - [trigger_distance] 触发切换的阈值距离
/// - [previous_title] 上一篇小说的标题
class PreviousPullHeader extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 状态栏高度。
  final double status_bar_height;

  /// 当前下拉的视觉位移距离。
  final double pull_offset;

  /// 触发切换的阈值距离。
  final double trigger_distance;

  /// 上一篇小说的标题。
  final String previous_title;

  /// 内置多语种文案。
  final Map<String, String> localized_texts;

  const PreviousPullHeader({
    super.key,
    required this.is_dark,
    required this.status_bar_height,
    required this.pull_offset,
    required this.trigger_distance,
    required this.previous_title,
    required this.localized_texts,
  });

  @override
  Widget build(BuildContext context) {
    // 当没有上一篇小说且没有下拉偏移时，不显示任何内容。
    if (previous_title.isEmpty && pull_offset <= 0) {
      return const SizedBox.shrink();
    }

    // 计算下拉进度（0.0 ~ 1.0）。
    final double progress =
        (pull_offset / trigger_distance).clamp(0.0, 1.0);

    // 判断是否已达到触发阈值。
    final bool ready = pull_offset >= trigger_distance;

    // 根据主题模式选择文字颜色。
    final Color text_color = is_dark
        ? ShortStoryReadStyle.title_dark_color
        : ShortStoryReadStyle.title_light_color;

    // 根据主题模式选择次要文字颜色。
    final Color secondary_color = is_dark
        ? ShortStoryReadStyle.secondary_dark_color
        : ShortStoryReadStyle.secondary_light_color;

    // 计算组件跟随下拉距离的偏移量（42% 的跟随比例，最大 72 像素）。
    final double follow_offset = (pull_offset * 0.42).clamp(0.0, 72.0);

    // 计算缩放比例（从 0.96 到 1.0）。
    final double scale = 0.96 + 0.04 * progress;

    return Positioned(
      // 顶部位置：状态栏高度 + 基础间距 + 跟随偏移。
      top: status_bar_height + 8 + follow_offset,
      left: ShortStoryReadStyle.page_horizontal_padding,
      right: ShortStoryReadStyle.page_horizontal_padding,
      height: 132,
      child: IgnorePointer(
        child: Opacity(
          // 透明度与下拉进度同步。
          opacity: progress,
          child: Transform.scale(
            // 缩放比例与下拉进度同步。
            scale: scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // 提示文字行：文字 + 箭头图标。
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // 提示文字，使用 AnimatedSwitcher 实现淡入淡出切换。
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: Text(
                        ready
                            ? localized_texts['release_view'] ??
                                'Release to view'
                            : localized_texts['pull_down_view'] ??
                                'Pull to view',
                        key: ValueKey<bool>(ready),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                          color: secondary_color,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // 箭头图标，AnimatedRotation 独立于文字，实现平滑旋转过渡。
                    AnimatedRotation(
                      turns: ready ? -0.25 : 0.25,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: SvgPicture.asset(
                        'assets/svg/right.svg',
                        width: 12,
                        height: 12,
                        colorFilter: ColorFilter.mode(
                          secondary_color,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 上一篇小说标题。
                Text(
                  previous_title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                    color: text_color,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
