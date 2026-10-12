import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/api/novel_language.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import '../style.dart';

/// 替换封面按钮组件。
///
/// 展示在小说标题区域的小号操作按钮，点击后调用后端接口把封面
/// 重置为默认海报封面，成功后携带新的封面信息回调给页面刷新展示。
/// 仅登录且 debug = 2 的用户可见，由父组件 [TitleWithStoryId] 控制渲染时机。
class ReplaceCoverButton extends StatefulWidget {
  /// 小说 ID，替换封面时传递给后端。
  final int story_id;

  /// 基准文字颜色，按钮文字/描边/背景均由该颜色叠加透明度得到。
  final Color base_color;

  /// 替换成功后的回调，携带新的封面地址与宽高。
  final void Function(String cover_url, int cover_width, int cover_height)
  on_cover_replaced;

  const ReplaceCoverButton({
    super.key,
    required this.story_id,
    required this.base_color,
    required this.on_cover_replaced,
  });

  @override
  State<ReplaceCoverButton> createState() => _ReplaceCoverButtonState();
}

class _ReplaceCoverButtonState extends State<ReplaceCoverButton> {
  /// 是否处于按压态，控制缩放与填充加深。
  bool _is_pressed = false;

  /// 是否正在请求接口，防止重复点击。
  bool _is_loading = false;

  /// 处理按钮点击：请求替换封面，成功后提示并回调刷新。
  Future<void> _on_button_tap() async {
    // 请求进行中忽略重复点击。
    if (_is_loading) return;
    setState(() => _is_loading = true);

    // 调用替换封面接口；失败提示由 postRequest 统一处理。
    final ReplaceCoverResult? result = await update_novel_cover(
      widget.story_id,
    );

    // 页面已销毁时不再更新状态。
    if (!mounted) return;
    setState(() => _is_loading = false);

    // 接口失败或未返回封面信息时不继续刷新。
    if (result == null) return;

    // 成功提示并把新封面信息交给页面刷新展示。
    showBottomTip('封面已替换');
    widget.on_cover_replaced(
      result.cover_url,
      result.cover_width,
      result.cover_height,
    );
  }

  @override
  Widget build(BuildContext context) {
    /// 背景填充透明度（按压时加深）。
    final double background_alpha = _is_pressed
        ? TitleWithStoryIdStyle.replace_button_pressed_background_alpha
        : TitleWithStoryIdStyle.replace_button_background_alpha;

    /// 描边透明度（按压时加深）。
    final double border_alpha = _is_pressed
        ? TitleWithStoryIdStyle.replace_button_pressed_border_alpha
        : TitleWithStoryIdStyle.replace_button_border_alpha;

    /// 按钮文字颜色。
    final Color content_color = widget.base_color.withValues(
      alpha: TitleWithStoryIdStyle.replace_button_content_alpha,
    );

    return GestureDetector(
      // opaque：点击落在文字间隙也能命中，保证整块按钮可点。
      behavior: HitTestBehavior.opaque,
      onTap: _on_button_tap,
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
          // 按钮与左侧徽标保持固定间距。
          margin: const EdgeInsetsDirectional.only(
            start: TitleWithStoryIdStyle.replace_button_left_spacing,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: TitleWithStoryIdStyle.replace_button_padding_horizontal,
            vertical: TitleWithStoryIdStyle.replace_button_padding_vertical,
          ),
          decoration: BoxDecoration(
            // 轻填充 + 发丝描边，弱化为标题附属操作。
            color: widget.base_color.withValues(alpha: background_alpha),
            borderRadius: BorderRadius.circular(
              TitleWithStoryIdStyle.replace_button_border_radius,
            ),
            border: Border.all(
              width: TitleWithStoryIdStyle.replace_button_border_width,
              color: widget.base_color.withValues(alpha: border_alpha),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // 操作图标：请求中展示进度圈，空闲展示封面图标。
              if (_is_loading)
                SizedBox(
                  width: TitleWithStoryIdStyle.replace_button_icon_size,
                  height: TitleWithStoryIdStyle.replace_button_icon_size,
                  child: CircularProgressIndicator(
                    strokeWidth: TitleWithStoryIdStyle
                        .replace_button_loading_stroke_width,
                    color: content_color,
                  ),
                )
              else
                Icon(
                  Icons.image_outlined,
                  size: TitleWithStoryIdStyle.replace_button_icon_size,
                  color: content_color,
                ),
              const SizedBox(
                width: TitleWithStoryIdStyle.replace_button_icon_spacing,
              ),
              // 按钮文案。
              Text(
                '替换封面',
                style: TextStyle(
                  fontSize: TitleWithStoryIdStyle.replace_button_font_size,
                  fontWeight: TitleWithStoryIdStyle.replace_button_font_weight,
                  letterSpacing:
                      TitleWithStoryIdStyle.replace_button_letter_spacing,
                  color: content_color,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
