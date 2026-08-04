import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app/components/comment_list/models/comment_data.dart';
import 'package:app/components/comment_list/style.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';

/// 评论区底部输入栏的统一外观。
///
/// [is_editor] 为 false 时展示固定在评论面板底部的预览栏；为 true
/// 时展示跟随键盘的 TextField。两种状态共用同一个胶囊容器、边框、
/// 表情入口和发送按钮，使 Overlay 替换时没有尺寸跳变。
class CommentComposerSurface extends StatelessWidget {
  final bool is_dark;
  final bool is_editor;
  final bool has_text;
  final bool show_emoji_panel;
  final double bottom_padding;
  final TextEditingController controller;
  final FocusNode focus_node;
  final CommentData? reply_target;
  final VoidCallback on_activate;
  final VoidCallback on_send;
  final VoidCallback on_toggle_emoji;

  const CommentComposerSurface({
    super.key,
    required this.is_dark,
    required this.is_editor,
    required this.has_text,
    required this.show_emoji_panel,
    required this.bottom_padding,
    required this.controller,
    required this.focus_node,
    required this.reply_target,
    required this.on_activate,
    required this.on_send,
    required this.on_toggle_emoji,
  });

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );
    final Color surface_color = is_dark
        ? CommentListStyle.input_bar_dark_bg
        : CommentListStyle.input_bar_light_bg;
    final Color input_color = is_dark
        ? CommentListStyle.input_dark_bg
        : CommentListStyle.input_light_bg;
    final Color input_border_color = is_dark
        ? CommentListStyle.input_border_dark_color
        : CommentListStyle.input_border_light_color;
    final Color surface_divider_color = is_dark
        ? CommentListStyle.emoji_panel_divider_dark_color
        : CommentListStyle.emoji_panel_divider_light_color;
    final Color text_color = is_dark
        ? CommentListStyle.title_dark_color
        : CommentListStyle.title_light_color;
    final Color hint_color = is_dark
        ? CommentListStyle.hint_dark_color
        : CommentListStyle.hint_light_color;
    final double input_font_size = is_cjk
        ? CommentListStyle.input_font_size_cjk
        : CommentListStyle.input_font_size_alphabetic;

    final Widget surface = Material(
      color: surface_color,
      child: DecoratedBox(
        key: ValueKey<String>(
          is_editor ? 'comment_composer_editor' : 'comment_composer_preview',
        ),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: surface_divider_color,
              width: CommentListStyle.emoji_panel_divider_thickness,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: CommentListStyle.input_horizontal_padding,
            right: CommentListStyle.input_horizontal_padding,
            top: CommentListStyle.input_top_padding,
            bottom: CommentListStyle.input_bottom_padding + bottom_padding,
          ),
          child: SizedBox(
            height: CommentListStyle.input_height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _build_input_capsule(
                    input_color: input_color,
                    input_border_color: input_border_color,
                    text_color: text_color,
                    hint_color: hint_color,
                    input_font_size: input_font_size,
                  ),
                ),
                const SizedBox(width: CommentListStyle.input_action_spacing),
                _build_send_button(is_cjk: is_cjk, is_dark: is_dark),
              ],
            ),
          ),
        ),
      ),
    );

    // TextField 与右侧按钮属于同一 TapRegion，点按表情或发送时不会
    // 先触发 TextField 的外部失焦，避免 iOS 键盘短暂收起后再弹出。
    return is_editor ? TextFieldTapRegion(child: surface) : surface;
  }

  /// 构建同时容纳文字区和表情入口的胶囊输入框。
  Widget _build_input_capsule({
    required Color input_color,
    required Color input_border_color,
    required Color text_color,
    required Color hint_color,
    required double input_font_size,
  }) {
    return Material(
      color: input_color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CommentListStyle.input_radius),
        side: BorderSide(color: input_border_color),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: <Widget>[
          Expanded(
            child: is_editor
                ? _build_editor(
                    text_color: text_color,
                    hint_color: hint_color,
                    input_font_size: input_font_size,
                  )
                : _build_preview(
                    text_color: text_color,
                    hint_color: hint_color,
                    input_font_size: input_font_size,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              right: CommentListStyle.emoji_button_right_padding,
            ),
            child: _build_emoji_button(is_dark: is_dark),
          ),
        ],
      ),
    );
  }

  /// 构建常驻在评论面板底部的预览文字区。
  Widget _build_preview({
    required Color text_color,
    required Color hint_color,
    required double input_font_size,
  }) {
    return InkWell(
      key: const ValueKey<String>('comment_input_preview'),
      onTap: on_activate,
      child: Padding(
        padding: const EdgeInsets.only(
          left: CommentListStyle.input_inner_padding,
          right: CommentListStyle.input_action_spacing,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder:
                (BuildContext context, TextEditingValue value, Widget? child) {
                  final bool has_preview_text = value.text.trim().isNotEmpty;
                  final String preview_text = has_preview_text
                      ? value.text
                      : reply_target == null
                      ? tr('comment.input_hint')
                      : '${tr('comment.reply_to')} ${reply_target!.nickname}';

                  return Text(
                    preview_text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: input_font_size,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                      color: has_preview_text ? text_color : hint_color,
                    ),
                  );
                },
          ),
        ),
      ),
    );
  }

  /// 构建随键盘移动的真实输入区。
  Widget _build_editor({
    required Color text_color,
    required Color hint_color,
    required double input_font_size,
  }) {
    return TextField(
      controller: controller,
      focusNode: focus_node,
      maxLines: 1,
      keyboardType: TextInputType.text,
      keyboardAppearance: is_dark ? Brightness.dark : Brightness.light,
      textInputAction: TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
      cursorColor: ColorConstants.themeColor,
      cursorWidth: CommentListStyle.input_cursor_width,
      scrollPadding: EdgeInsets.zero,
      style: TextStyle(
        fontSize: input_font_size,
        height: CommentListStyle.input_text_line_height,
        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
        color: text_color,
      ),
      decoration: InputDecoration(
        hintText: reply_target == null
            ? tr('comment.input_hint')
            : '${tr('comment.reply_to')} ${reply_target!.nickname}',
        hintStyle: TextStyle(
          fontSize: input_font_size,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
          color: hint_color,
        ),
        contentPadding: const EdgeInsets.only(
          left: CommentListStyle.input_inner_padding,
          right: CommentListStyle.input_action_spacing,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        isDense: true,
      ),
    );
  }

  /// 构建胶囊内的表情/键盘切换按钮。
  Widget _build_emoji_button({required bool is_dark}) {
    final Color idle_icon_color = is_dark
        ? CommentListStyle.secondary_dark_color
        : CommentListStyle.secondary_light_color;
    final Color active_bg_color = is_dark
        ? CommentListStyle.emoji_active_dark_bg
        : CommentListStyle.emoji_active_light_bg;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>(
          is_editor
              ? 'comment_emoji_button_editor'
              : 'comment_emoji_button_preview',
        ),
        onTap: on_toggle_emoji,
        borderRadius: BorderRadius.circular(
          CommentListStyle.emoji_button_radius,
        ),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: CommentListStyle.input_state_animation_duration_ms,
          ),
          curve: Curves.easeOutCubic,
          width: CommentListStyle.emoji_button_size,
          height: CommentListStyle.emoji_button_size,
          decoration: BoxDecoration(
            color: show_emoji_panel ? active_bg_color : Colors.transparent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(
              milliseconds: CommentListStyle.input_state_animation_duration_ms,
            ),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              show_emoji_panel
                  ? Icons.keyboard_alt_outlined
                  : Icons.sentiment_satisfied_alt_rounded,
              key: ValueKey<bool>(show_emoji_panel),
              size: CommentListStyle.emoji_icon_size,
              color: show_emoji_panel
                  ? ColorConstants.themeColor
                  : idle_icon_color,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建发送按钮，仅在有有效文字时允许点击。
  Widget _build_send_button({required bool is_cjk, required bool is_dark}) {
    final Color bg_color = has_text
        ? ColorConstants.themeColor
        : is_dark
        ? CommentListStyle.send_disabled_dark_bg
        : CommentListStyle.send_disabled_light_bg;
    final Color text_color = has_text
        ? Colors.black
        : is_dark
        ? CommentListStyle.send_disabled_dark_text
        : CommentListStyle.send_disabled_light_text;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>(
          is_editor
              ? 'comment_send_button_editor'
              : 'comment_send_button_preview',
        ),
        onTap: has_text ? on_send : null,
        borderRadius: BorderRadius.circular(
          CommentListStyle.send_button_radius,
        ),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: CommentListStyle.input_state_animation_duration_ms,
          ),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(
            minWidth: is_cjk
                ? CommentListStyle.send_button_min_width_cjk
                : CommentListStyle.send_button_min_width_alphabetic,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: CommentListStyle.send_button_horizontal_padding,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg_color,
            borderRadius: BorderRadius.circular(
              CommentListStyle.send_button_radius,
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(
              milliseconds: CommentListStyle.input_state_animation_duration_ms,
            ),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontSize: is_cjk
                  ? CommentListStyle.send_button_font_size_cjk
                  : CommentListStyle.send_button_font_size_alphabetic,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
              color: text_color,
            ),
            child: Text(tr('comment.send')),
          ),
        ),
      ),
    );
  }
}
