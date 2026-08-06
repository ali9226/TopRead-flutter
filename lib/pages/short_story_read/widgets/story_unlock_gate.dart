import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:app/pages/short_story_read/utils/create_story_content_preview.dart';
import 'package:app/pages/short_story_read/widgets/story_content.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

/// 短篇小说正文的激励广告解锁区域。
///
/// 解锁前只展示大约三分之一的正文，并在折叠位置使用渐变遮罩和
/// 观看广告按钮。解锁后直接展示完整正文。
class StoryUnlockGate extends StatelessWidget {
  const StoryUnlockGate({
    required this.content,
    required this.is_dark,
    required this.is_loading,
    required this.is_unlocked,
    required this.is_unlocking,
    required this.font_size,
    required this.on_unlock,
    super.key,
  });

  /// 完整正文。
  final String content;

  /// 是否为夜间模式。
  final bool is_dark;

  /// 正文是否正在加载。
  final bool is_loading;

  /// 当前短篇是否已经解锁。
  final bool is_unlocked;

  /// 激励广告是否正在加载或展示。
  final bool is_unlocking;

  /// 当前正文字号。
  final double font_size;

  /// 用户点击观看广告按钮时执行的回调。
  final VoidCallback on_unlock;

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    if (is_loading || is_unlocked || content.trim().isEmpty) {
      return StoryContent(
        content: content,
        is_dark: is_dark,
        is_loading: is_loading,
        font_size: font_size,
      );
    }

    final StoryContentPreviewData preview_data = create_story_content_preview(
      content: content,
      is_cjk: is_cjk,
      preview_ratio: ShortStoryReadStyle.locked_content_preview_ratio,
      fade_tail_count: is_cjk
          ? ShortStoryReadStyle.unlock_fade_tail_count_cjk
          : ShortStoryReadStyle.unlock_fade_tail_count_alphabetic,
    );
    if (preview_data.remaining_count <= 0) {
      return StoryContent(
        content: content,
        is_dark: is_dark,
        font_size: font_size,
      );
    }

    final double gate_height = is_cjk
        ? ShortStoryReadStyle.unlock_gate_height_cjk
        : ShortStoryReadStyle.unlock_gate_height_alphabetic;
    final double gradient_overlap_height = is_cjk
        ? ShortStoryReadStyle.unlock_gradient_overlap_height_cjk
        : ShortStoryReadStyle.unlock_gradient_overlap_height_alphabetic;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            StoryContent(
              key: const ValueKey<String>('story_unlock_faded_content'),
              content: preview_data.preview_content,
              is_dark: is_dark,
              font_size: font_size,
            ),
            SizedBox(height: gate_height),
          ],
        ),
        Positioned(
          left: -ShortStoryReadStyle.page_horizontal_padding,
          right: -ShortStoryReadStyle.page_horizontal_padding,
          bottom: 0,
          height: gate_height + gradient_overlap_height,
          child: _UnlockOverlay(
            remaining_count: preview_data.remaining_count,
            is_dark: is_dark,
            is_cjk: is_cjk,
            is_unlocking: is_unlocking,
            on_unlock: on_unlock,
          ),
        ),
      ],
    );
  }
}

/// 覆盖在折叠正文底部的渐变遮罩和解锁卡片。
class _UnlockOverlay extends StatelessWidget {
  const _UnlockOverlay({
    required this.remaining_count,
    required this.is_dark,
    required this.is_cjk,
    required this.is_unlocking,
    required this.on_unlock,
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
    final Color primary_text_color = is_dark
        ? ShortStoryReadStyle.title_dark_color
        : ShortStoryReadStyle.title_light_color;

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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      _DecorativeLine(
                        color: border_color,
                        fade_towards_end: false,
                      ),
                      SizedBox(
                        width: is_cjk
                            ? ShortStoryReadStyle.unlock_line_spacing_cjk
                            : ShortStoryReadStyle
                                  .unlock_line_spacing_alphabetic,
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
                            color: primary_text_color,
                            fontSize: is_cjk
                                ? ShortStoryReadStyle
                                      .unlock_message_font_size_cjk
                                : ShortStoryReadStyle
                                      .unlock_message_font_size_alphabetic,
                            height: is_cjk
                                ? ShortStoryReadStyle.unlock_message_height_cjk
                                : ShortStoryReadStyle
                                      .unlock_message_height_alphabetic,
                            fontWeight: FontConfig.adjustedWeight(
                              FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: is_cjk
                            ? ShortStoryReadStyle.unlock_line_spacing_cjk
                            : ShortStoryReadStyle
                                  .unlock_line_spacing_alphabetic,
                      ),
                      _DecorativeLine(
                        color: border_color,
                        fade_towards_end: true,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: is_cjk
                        ? ShortStoryReadStyle.unlock_button_top_spacing_cjk
                        : ShortStoryReadStyle
                              .unlock_button_top_spacing_alphabetic,
                  ),
                  Semantics(
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
                              duration: ShortStoryReadStyle
                                  .unlock_button_switch_duration,
                              child: is_unlocking
                                  ? SizedBox(
                                      key: const ValueKey<String>('loading'),
                                      width: ShortStoryReadStyle
                                          .unlock_loading_indicator_size,
                                      height: ShortStoryReadStyle
                                          .unlock_loading_indicator_size,
                                      child: CircularProgressIndicator(
                                        strokeWidth: ShortStoryReadStyle
                                            .unlock_loading_stroke_width,
                                        color: ShortStoryReadStyle
                                            .unlock_button_text_color,
                                      ),
                                    )
                                  : Row(
                                      key: const ValueKey<String>('label'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        const Icon(
                                          Icons.play_arrow_rounded,
                                          size: ShortStoryReadStyle
                                              .unlock_button_icon_size,
                                          color: ShortStoryReadStyle
                                              .unlock_button_text_color,
                                        ),
                                        const SizedBox(
                                          width: ShortStoryReadStyle
                                              .unlock_button_icon_spacing,
                                        ),
                                        Flexible(
                                          child: Text(
                                            easy.tr(
                                              'short_story_read.watch_ad_to_continue',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: ShortStoryReadStyle
                                                  .unlock_button_text_color,
                                              fontSize: is_cjk
                                                  ? ShortStoryReadStyle
                                                        .unlock_button_font_size_cjk
                                                  : ShortStoryReadStyle
                                                        .unlock_button_font_size_alphabetic,
                                              fontWeight:
                                                  FontConfig.adjustedWeight(
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 解锁文案两侧的水平渐变细线。
class _DecorativeLine extends StatelessWidget {
  const _DecorativeLine({required this.color, required this.fade_towards_end});

  /// 细线中心颜色。
  final Color color;

  /// 是否向右侧渐隐。
  final bool fade_towards_end;

  @override
  Widget build(BuildContext context) {
    final Color transparent_color = color.withValues(alpha: 0);
    return Expanded(
      child: Container(
        height: ShortStoryReadStyle.unlock_line_height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: fade_towards_end
                ? <Color>[color, transparent_color]
                : <Color>[transparent_color, color],
          ),
        ),
      ),
    );
  }
}
