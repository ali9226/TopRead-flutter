import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app/components/comment_list/models/comment_data.dart';
import 'package:app/components/comment_list/style.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';

/// 评论区底部输入栏的统一外观。
///
/// [is_editor] 为 false 时展示固定在评论面板底部的轻量预览栏；为 true 时展示
/// 真实 TextField。两种状态共用完全相同的尺寸、回复提示和按钮布局，切换时不会跳变。
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
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
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
                    /// 表情按钮区域（固定宽度）。
                    SizedBox(
                      width: CommentListStyle.emoji_button_size,
                      child: _build_emoji_button(is_dark: is_dark),
                    ),
                    const SizedBox(width: CommentListStyle.input_action_spacing),

                    /// 输入框区域（占满剩余空间，高度由外层 SizedBox 固定）。
                    Expanded(
                      child: is_editor
                          ? _build_editor(
                              input_color: input_color,
                              text_color: text_color,
                              hint_color: hint_color,
                              input_font_size: input_font_size,
                            )
                          : _build_preview(
                              input_color: input_color,
                              text_color: text_color,
                              hint_color: hint_color,
                              input_font_size: input_font_size,
                            ),
                    ),
                    const SizedBox(width: CommentListStyle.input_action_spacing),

                    /// 发送按钮。
                    _build_send_button(is_cjk: is_cjk, is_dark: is_dark),
                  ],
                ),
              ),
            ),
          ],
        ),
    );

    // 编辑框和发送按钮属于同一个 TapRegion，点操作按钮不会误触发失焦。
    // 评论列表的关闭与回复切换由父级统一协调，避免 iOS 的 onTapOutside 与
    // 评论 onTap 在同一次手势中先后执行，造成键盘刚收起又弹出。
    return is_editor ? TextFieldTapRegion(child: surface) : surface;
  }

  /// 构建常驻在评论面板底部的预览输入框。
  Widget _build_preview({
    required Color input_color,
    required Color text_color,
    required Color hint_color,
    required double input_font_size,
  }) {
    return GestureDetector(
      onTap: on_activate,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: const ValueKey<String>('comment_input_preview'),
        padding: const EdgeInsets.symmetric(
          horizontal: CommentListStyle.input_inner_padding,
        ),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: input_color,
          borderRadius: BorderRadius.circular(CommentListStyle.input_radius),
        ),
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
    );
  }

  /// 构建随键盘移动的真实输入框。
  Widget _build_editor({
    required Color input_color,
    required Color text_color,
    required Color hint_color,
    required double input_font_size,
  }) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: input_color,
        borderRadius: BorderRadius.circular(CommentListStyle.input_radius),
      ),
      child: TextField(
        controller: controller,
        focusNode: focus_node,
        maxLines: 1,
        keyboardType: TextInputType.text,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: CommentListStyle.input_inner_padding,
            vertical: 0,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  /// 构建表情按钮。
  ///
  /// 外层已通过 SizedBox 固定宽高，此处只需居中显示图标。
  Widget _build_emoji_button({required bool is_dark}) {
    final Color icon_color = is_dark
        ? CommentListStyle.secondary_dark_color
        : CommentListStyle.secondary_light_color;

    return GestureDetector(
      onTap: on_toggle_emoji,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: SvgIcon(
          name: show_emoji_panel ? 'keyboard' : 'meme',
          width: CommentListStyle.emoji_icon_size,
          height: CommentListStyle.emoji_icon_size,
          color: icon_color,
        ),
      ),
    );
  }

  /// 构建发送按钮。
  ///
  /// 无文字输入时：浅灰色背景 + 灰色文字，不可点击。
  /// 有文字输入时：主题色背景 + 黑色文字，可点击发送。
  Widget _build_send_button({required bool is_cjk, required bool is_dark}) {
    /// 按钮背景色：有文字时为主题色，无文字时为浅灰色。
    final Color bg_color = has_text
        ? ColorConstants.themeColor
        : is_dark
        ? CommentListStyle.send_disabled_dark_bg
        : CommentListStyle.send_disabled_light_bg;

    /// 按钮文字色：有文字时为黑色，无文字时为灰色。
    final Color text_color = has_text
        ? Colors.black
        : is_dark
        ? CommentListStyle.send_disabled_dark_text
        : CommentListStyle.send_disabled_light_text;

    return GestureDetector(
      onTap: has_text ? on_send : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
        child: Text(
          tr('comment.send'),
          style: TextStyle(
            fontSize: is_cjk
                ? CommentListStyle.send_button_font_size_cjk
                : CommentListStyle.send_button_font_size_alphabetic,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
            color: text_color,
          ),
        ),
      ),
    );
  }
}
