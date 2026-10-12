import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/util/language_util/index.dart';
import '../logic.dart';
import '../style.dart';

/// 小说 ID 胶囊徽标组件。
///
/// 展示在标题文字后方的小号胶囊标签，点击后复制 ID 到剪贴板。
/// 视觉设计：
/// 1. 胶囊形（全圆角）发丝描边 + 极浅填充，弱化为标题的附属信息；
/// 2. "ID" 前缀与数字双色分层，数字更实、一眼可读；
/// 3. 数字与复制图标之间以竖向发丝线分隔，形成"值 / 操作"两段式结构；
/// 4. 按压时轻微缩放并加深填充，模仿 iOS 轻按手感；
/// 5. 复制成功后图标平滑切换为成功对勾并短暂停留。
///
/// 仅登录且 debug = 2 的用户可见，由父组件 [TitleWithStoryId] 控制渲染时机。
class StoryIdBadge extends StatefulWidget {
  /// 小说 ID，点击时复制该值。
  final int story_id;

  /// 基准文字颜色，徽标文字/描边/背景均由该颜色叠加透明度得到。
  final Color base_color;

  const StoryIdBadge({
    super.key,
    required this.story_id,
    required this.base_color,
  });

  @override
  State<StoryIdBadge> createState() => _StoryIdBadgeState();
}

class _StoryIdBadgeState extends State<StoryIdBadge> {
  /// 是否处于按压态，控制缩放与填充加深。
  bool _is_pressed = false;

  /// 是否处于复制成功态，控制图标切换为成功对勾。
  bool _is_copied = false;

  /// 复制成功态自动回退定时器。
  Timer? _copied_reset_timer;

  @override
  void dispose() {
    // 页面销毁时清理定时器，避免回调泄漏。
    _copied_reset_timer?.cancel();
    super.dispose();
  }

  /// 处理徽标点击：复制 ID 并短暂展示成功反馈。
  Future<void> _on_badge_tap() async {
    // 执行复制并弹出底部提示。
    await copy_story_id(widget.story_id);

    // 页面已销毁时不再更新状态。
    if (!mounted) return;

    // 进入成功态并重置回退定时器。
    setState(() => _is_copied = true);
    _copied_reset_timer?.cancel();
    _copied_reset_timer = Timer(
      TitleWithStoryIdStyle.copied_state_duration,
      () {
        // 定时器触发时若仍挂载则回退为普通复制图标。
        if (mounted) setState(() => _is_copied = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    /// 当前语种是否为 CJK，用于选择徽标字号。
    final bool is_cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );

    /// "ID" 前缀字号。
    final double prefix_font_size = is_cjk
        ? TitleWithStoryIdStyle.badge_prefix_font_size_cjk
        : TitleWithStoryIdStyle.badge_prefix_font_size_alphabetic;

    /// ID 数字字号。
    final double number_font_size = is_cjk
        ? TitleWithStoryIdStyle.badge_number_font_size_cjk
        : TitleWithStoryIdStyle.badge_number_font_size_alphabetic;

    /// 背景填充透明度（按压时加深）。
    final double background_alpha = _is_pressed
        ? TitleWithStoryIdStyle.badge_pressed_background_alpha
        : TitleWithStoryIdStyle.badge_background_alpha;

    /// 描边透明度（按压时加深）。
    final double border_alpha = _is_pressed
        ? TitleWithStoryIdStyle.badge_pressed_border_alpha
        : TitleWithStoryIdStyle.badge_border_alpha;

    /// "ID" 前缀文字颜色（弱化标签层）。
    final Color prefix_color = widget.base_color.withValues(
      alpha: TitleWithStoryIdStyle.badge_prefix_alpha,
    );

    /// ID 数字颜色（主可读层）。
    final Color number_color = widget.base_color.withValues(
      alpha: TitleWithStoryIdStyle.badge_number_alpha,
    );

    /// 操作区（分隔线 + 图标）颜色。
    final Color action_color = widget.base_color.withValues(
      alpha: TitleWithStoryIdStyle.badge_icon_alpha,
    );

    return GestureDetector(
      // opaque：点击落在文字间隙也能命中，保证整块徽标可点。
      behavior: HitTestBehavior.opaque,
      onTap: _on_badge_tap,
      // 按下即进入按压态，模拟轻按反馈。
      onTapDown: (_) => setState(() => _is_pressed = true),
      // 抬起/取消立即退出按压态，保证回弹及时。
      onTapUp: (_) => setState(() => _is_pressed = false),
      onTapCancel: () => setState(() => _is_pressed = false),
      child: AnimatedScale(
        // 按压时整体轻微缩小，营造 iOS 风格的轻按手感。
        scale: _is_pressed
            ? TitleWithStoryIdStyle.pressed_scale
            : 1.0,
        duration: TitleWithStoryIdStyle.press_duration,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          // 背景/描边随按压态平滑过渡，避免颜色跳变。
          duration: TitleWithStoryIdStyle.color_animation_duration,
          curve: Curves.easeOut,
          // 徽标与左侧标题文字保持固定间距。
          margin: const EdgeInsetsDirectional.only(
            start: TitleWithStoryIdStyle.badge_left_spacing,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: TitleWithStoryIdStyle.badge_padding_horizontal,
            vertical: TitleWithStoryIdStyle.badge_padding_vertical,
          ),
          decoration: BoxDecoration(
            // 极浅填充 + 发丝描边，勾勒胶囊轮廓但不干扰标题阅读。
            color: widget.base_color.withValues(alpha: background_alpha),
            borderRadius: BorderRadius.circular(
              TitleWithStoryIdStyle.badge_border_radius,
            ),
            border: Border.all(
              width: TitleWithStoryIdStyle.badge_border_width,
              color: widget.base_color.withValues(alpha: border_alpha),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // "ID" 前缀：弱化的小标签文字。
              Text(
                'ID',
                style: TextStyle(
                  fontSize: prefix_font_size,
                  fontWeight: TitleWithStoryIdStyle.badge_prefix_font_weight,
                  letterSpacing:
                      TitleWithStoryIdStyle.badge_prefix_letter_spacing,
                  color: prefix_color,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: TitleWithStoryIdStyle.badge_prefix_spacing),
              // ID 数字：更实的可读层。
              Text(
                '${widget.story_id}',
                style: TextStyle(
                  fontSize: number_font_size,
                  fontWeight: TitleWithStoryIdStyle.badge_number_font_weight,
                  letterSpacing:
                      TitleWithStoryIdStyle.badge_number_letter_spacing,
                  color: number_color,
                  height: 1.2,
                ),
              ),
              // 数字与操作区之间的间距。
              const SizedBox(width: TitleWithStoryIdStyle.badge_divider_spacing),
              // 竖向发丝分隔线，划分"值 / 操作"两段。
              Container(
                width: TitleWithStoryIdStyle.badge_divider_width,
                height: TitleWithStoryIdStyle.badge_divider_height,
                color: action_color,
              ),
              // 分隔线与图标之间的间距。
              const SizedBox(width: TitleWithStoryIdStyle.badge_divider_spacing),
              // 图标区：复制成功时平滑切换为成功对勾。
              AnimatedSwitcher(
                duration: TitleWithStoryIdStyle.icon_switch_duration,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeOut,
                // 淡入淡出 + 轻微缩放，切换更柔和。
                transitionBuilder:
                    (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.7, end: 1.0)
                              .animate(animation),
                          child: child,
                        ),
                      );
                    },
                child: _is_copied
                    // 成功对勾：使用成功绿，明确告知复制已完成。
                    ? Icon(
                        Icons.check_rounded,
                        key: const ValueKey<String>('copied'),
                        size: TitleWithStoryIdStyle.badge_icon_size,
                        color: TitleWithStoryIdStyle.copied_icon_color,
                      )
                    // 默认复制图标：与操作区同色。
                    : Icon(
                        Icons.copy_rounded,
                        key: const ValueKey<String>('copy'),
                        size: TitleWithStoryIdStyle.badge_icon_size,
                        color: action_color,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
