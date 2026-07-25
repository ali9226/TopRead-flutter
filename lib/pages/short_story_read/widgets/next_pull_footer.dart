import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:app/config/font_config.dart';

/// 底部上拉查看下一篇提示组件。
///
/// 当用户从正文底部向上拉动时，显示"查看下一篇"提示文字和箭头图标。
/// 间隔条和下一篇内容已移至主滚动区域，本组件仅负责上拉手势的视觉反馈。
///
/// 交互规则：
/// - 上拉距离未达到触发阈值时提示文字透明度为 0
/// - 上拉距离达到触发阈值后提示文字渐显，箭头旋转
///
/// 参数：
/// - [is_dark] 是否为夜间模式
/// - [pull_offset] 当前上拉的视觉位移距离
/// - [trigger_distance] 触发切换的阈值距离
/// - [localized_texts] 内置多语种文案
class NextPullFooter extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 当前上拉的视觉位移距离。
  final double pull_offset;

  /// 触发切换的阈值距离。
  final double trigger_distance;

  /// 内置多语种文案。
  final Map<String, String> localized_texts;

  const NextPullFooter({
    super.key,
    required this.is_dark,
    required this.pull_offset,
    required this.trigger_distance,
    required this.localized_texts,
  });

  @override
  Widget build(BuildContext context) {
    // 没有上拉偏移时不显示任何内容。
    if (pull_offset <= 0) {
      return const SizedBox.shrink();
    }

    // 计算上拉进度（0.0 ~ 1.0）。
    final double progress =
        (pull_offset / trigger_distance).clamp(0.0, 1.0);

    // 判断是否已达到触发阈值。
    final bool ready = pull_offset >= trigger_distance;

    // 根据主题模式选择次要文字颜色。
    final Color secondary_color = is_dark
        ? ShortStoryReadStyle.secondary_dark_color
        : ShortStoryReadStyle.secondary_light_color;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Opacity(
          opacity: progress,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // 提示文字（"查看下一篇"）。
                AnimatedOpacity(
                  opacity: ready ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    localized_texts['view_next'] ?? 'View next story',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                      color: secondary_color,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // 箭头图标，根据状态旋转方向。
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
          ),
        ),
      ),
    );
  }
}
