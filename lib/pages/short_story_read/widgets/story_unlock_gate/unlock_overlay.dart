import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import 'decorative_line.dart';

/// 覆盖在折叠正文底部的渐变遮罩和解锁卡片。
class UnlockOverlay extends StatelessWidget {
  const UnlockOverlay({
    required this.remaining_count,
    required this.is_dark,
    required this.is_cjk,
    required this.is_unlocking,
    required this.on_unlock,
    super.key,
  });

  /// 待解锁内容的字数或单词数。
  final int remaining_count;

  /// 是否为夜间模式。
  final bool is_dark;

  /// 当前语种是否为 CJK 语系。
  final bool is_cjk;

  /// 激励广告是否正在加载或展示。
  final bool is_unlocking;

  /// 观看广告回调。
  final VoidCallback on_unlock;

  @override
  Widget build(BuildContext context) {
    final Color background_color = is_dark
        ? ShortStoryReadStyle.bg_dark_color
        : ShortStoryReadStyle.bg_light_color;
    final Color card_color = is_dark
        ? ShortStoryReadStyle.unlock_card_dark_color
        : ShortStoryReadStyle.unlock_card_light_color;
    final Color border_color = is_dark
        ? ShortStoryReadStyle.unlock_border_dark_color
        : ShortStoryReadStyle.unlock_border_light_color;
    final Color hint_text_color = is_dark
        ? ShortStoryReadStyle.unlock_hint_dark_color
        : ShortStoryReadStyle.unlock_hint_light_color;

    return DecoratedBox(
      key: const ValueKey<String>('story_unlock_gradient_overlay'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            background_color.withValues(alpha: 0),
            background_color.withValues(alpha: 0.6),
            background_color.withValues(alpha: 0.94),
            background_color,
          ],
          stops: ShortStoryReadStyle.unlock_gradient_stops,
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ShortStoryReadStyle.unlock_card_outer_horizontal_padding,
            0,
            ShortStoryReadStyle.unlock_card_outer_horizontal_padding,
            ShortStoryReadStyle.unlock_card_bottom_padding,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: ShortStoryReadStyle.unlock_card_max_width,
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: is_cjk
                    ? ShortStoryReadStyle.unlock_card_horizontal_padding_cjk
                    : ShortStoryReadStyle
                          .unlock_card_horizontal_padding_alphabetic,
                vertical: is_cjk
                    ? ShortStoryReadStyle.unlock_card_vertical_padding_cjk
                    : ShortStoryReadStyle
                          .unlock_card_vertical_padding_alphabetic,
              ),
              decoration: BoxDecoration(
                color: card_color,
                borderRadius: BorderRadius.circular(
                  ShortStoryReadStyle.unlock_card_radius,
                ),
                border: Border.all(color: border_color),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: is_dark
                          ? ShortStoryReadStyle.unlock_shadow_alpha_dark
                          : ShortStoryReadStyle.unlock_shadow_alpha_light,
                    ),
                    blurRadius: ShortStoryReadStyle.unlock_shadow_blur_radius,
                    offset: const Offset(
                      0,
                      ShortStoryReadStyle.unlock_shadow_offset_y,
                    ),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildRemainingCountRow(hint_text_color, border_color),
                  SizedBox(
                    height: is_cjk
                        ? ShortStoryReadStyle.unlock_button_top_spacing_cjk
                        : ShortStoryReadStyle
                              .unlock_button_top_spacing_alphabetic,
                  ),
                  _buildUnlockButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建剩余字数提示行，包含装饰线和提示文案。
  Widget _buildRemainingCountRow(Color hint_text_color, Color border_color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        DecorativeLine(
          color: border_color,
          fade_towards_end: false,
        ),
        SizedBox(
          width: is_cjk
              ? ShortStoryReadStyle.unlock_line_spacing_cjk
              : ShortStoryReadStyle.unlock_line_spacing_alphabetic,
        ),
        Flexible(
          flex: ShortStoryReadStyle.unlock_message_flex,
          child: Text(
            easy.tr(
              is_cjk
                  ? 'short_story_read.locked_remaining_characters'
                  : 'short_story_read.locked_remaining_words',
              namedArgs: <String, String>{
                'count': remaining_count.toString(),
              },
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: hint_text_color,
              fontSize: is_cjk
                  ? ShortStoryReadStyle.unlock_message_font_size_cjk
                  : ShortStoryReadStyle.unlock_message_font_size_alphabetic,
              height: is_cjk
                  ? ShortStoryReadStyle.unlock_message_height_cjk
                  : ShortStoryReadStyle.unlock_message_height_alphabetic,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            ),
          ),
        ),
        SizedBox(
          width: is_cjk
              ? ShortStoryReadStyle.unlock_line_spacing_cjk
              : ShortStoryReadStyle.unlock_line_spacing_alphabetic,
        ),
        DecorativeLine(
          color: border_color,
          fade_towards_end: true,
        ),
      ],
    );
  }

  /// 构建解锁按钮，支持加载状态切换。
  Widget _buildUnlockButton() {
    return Semantics(
      button: true,
      enabled: !is_unlocking,
      label: easy.tr('short_story_read.watch_ad_to_continue'),
      child: SizedBox(
        width: double.infinity,
        height: is_cjk
            ? ShortStoryReadStyle.unlock_button_height_cjk
            : ShortStoryReadStyle.unlock_button_height_alphabetic,
        child: Material(
          color: ColorConstants.themeColor,
          borderRadius: BorderRadius.circular(
            ShortStoryReadStyle.unlock_button_radius,
          ),
          child: InkWell(
            onTap: is_unlocking ? null : on_unlock,
            borderRadius: BorderRadius.circular(
              ShortStoryReadStyle.unlock_button_radius,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: ShortStoryReadStyle.unlock_button_switch_duration,
                child: is_unlocking
                    ? SizedBox(
                        key: const ValueKey<String>('loading'),
                        width: ShortStoryReadStyle.unlock_loading_indicator_size,
                        height:
                            ShortStoryReadStyle.unlock_loading_indicator_size,
                        child: CircularProgressIndicator(
                          strokeWidth:
                              ShortStoryReadStyle.unlock_loading_stroke_width,
                          color: ShortStoryReadStyle.unlock_button_text_color,
                        ),
                      )
                    : Row(
                        key: const ValueKey<String>('label'),
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.play_arrow_rounded,
                            size: ShortStoryReadStyle.unlock_button_icon_size,
                            color: ShortStoryReadStyle.unlock_button_text_color,
                          ),
                          const SizedBox(
                            width: ShortStoryReadStyle.unlock_button_icon_spacing,
                          ),
                          Flexible(
                            child: Text(
                              easy.tr(
                                'short_story_read.watch_ad_to_continue',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    ShortStoryReadStyle.unlock_button_text_color,
                                fontSize: is_cjk
                                    ? ShortStoryReadStyle
                                          .unlock_button_font_size_cjk
                                    : ShortStoryReadStyle
                                          .unlock_button_font_size_alphabetic,
                                fontWeight: FontConfig.adjustedWeight(
                                  FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
