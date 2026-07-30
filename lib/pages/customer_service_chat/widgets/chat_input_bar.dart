// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import '../style.dart';

/// 在线客服聊天输入栏。
///
/// 输入框会随内容在单行和多行之间自然增长，工具按钮始终保持
/// 足够的点击区域。表情面板展开时，底部安全区由表情面板负责。
class ChatInputBar extends StatefulWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 输入框控制器。
  final TextEditingController text_controller;

  /// 输入框焦点节点。
  final FocusNode focus_node;

  /// 是否正在显示表情面板。
  final bool show_emoji_panel;

  /// 是否由输入栏承载底部安全区。
  final bool include_bottom_safe_area;

  /// 发送文字消息回调。
  final VoidCallback on_send;

  /// 切换表情面板回调。
  final VoidCallback on_toggle_emoji;

  /// 选择图片回调。
  final VoidCallback on_pick_image;

  const ChatInputBar({
    super.key,
    required this.is_dark,
    required this.text_controller,
    required this.focus_node,
    required this.show_emoji_panel,
    required this.include_bottom_safe_area,
    required this.on_send,
    required this.on_toggle_emoji,
    required this.on_pick_image,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  /// 当前输入内容是否可以发送。
  bool _has_text = false;

  @override
  void initState() {
    super.initState();
    _bind_text_controller(widget.text_controller);
  }

  @override
  void didUpdateWidget(covariant ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text_controller == widget.text_controller) return;

    oldWidget.text_controller.removeListener(_on_text_changed);
    _bind_text_controller(widget.text_controller);
  }

  @override
  void dispose() {
    widget.text_controller.removeListener(_on_text_changed);
    super.dispose();
  }

  /// 绑定输入控制器并同步首次可发送状态。
  void _bind_text_controller(TextEditingController controller) {
    controller.addListener(_on_text_changed);
    _has_text = controller.text.trim().isNotEmpty;
  }

  /// 仅在“空/非空”状态变化时重建发送按钮。
  void _on_text_changed() {
    final bool now_has_text = widget.text_controller.text.trim().isNotEmpty;
    if (now_has_text == _has_text || !mounted) return;
    setState(() => _has_text = now_has_text);
  }

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );
    final Color bar_bg = widget.is_dark
        ? CustomerServiceChatStyle.input_bar_bg_dark
        : CustomerServiceChatStyle.input_bar_bg_light;
    final Color field_bg = widget.is_dark
        ? CustomerServiceChatStyle.input_field_bg_dark
        : CustomerServiceChatStyle.input_field_bg_light;
    final Color text_color = widget.is_dark
        ? CustomerServiceChatStyle.input_text_color_dark
        : CustomerServiceChatStyle.input_text_color_light;
    final Color icon_color = widget.is_dark
        ? CustomerServiceChatStyle.tool_icon_color_dark
        : CustomerServiceChatStyle.tool_icon_color_light;
    final double input_font_size = is_cjk
        ? CustomerServiceChatStyle.input_font_size_cjk
        : CustomerServiceChatStyle.input_font_size_alphabetic;
    final double bottom_safe = widget.include_bottom_safe_area
        ? MediaQuery.paddingOf(context).bottom
        : 0;

    return ColoredBox(
      color: bar_bg,
      child: Padding(
        padding: EdgeInsets.only(
          left: CustomerServiceChatStyle.input_bar_padding_h,
          right: CustomerServiceChatStyle.input_bar_padding_h,
          top: CustomerServiceChatStyle.input_bar_padding_v,
          bottom: CustomerServiceChatStyle.input_bar_padding_v + bottom_safe,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            _ChatToolButton(
              semantic_label: easy.tr('comment.emoji'),
              on_tap: widget.on_toggle_emoji,
              child: SvgIcon(
                name: widget.show_emoji_panel ? 'keyboard' : 'meme',
                width: CustomerServiceChatStyle.tool_icon_size,
                height: CustomerServiceChatStyle.tool_icon_size,
                color: widget.show_emoji_panel
                    ? CustomerServiceChatStyle.tool_icon_active_color
                    : icon_color,
              ),
            ),
            _ChatToolButton(
              semantic_label: easy.tr('comment.image'),
              on_tap: widget.on_pick_image,
              child: SvgIcon(
                name: 'image',
                width: CustomerServiceChatStyle.tool_icon_size,
                height: CustomerServiceChatStyle.tool_icon_size,
                color: icon_color,
              ),
            ),
            const SizedBox(
              width: CustomerServiceChatStyle.input_action_spacing,
            ),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: CustomerServiceChatStyle.input_field_height,
                  maxHeight: CustomerServiceChatStyle.input_field_max_height,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: field_bg,
                    borderRadius: BorderRadius.circular(
                      CustomerServiceChatStyle.input_radius,
                    ),
                  ),
                  child: TextField(
                    controller: widget.text_controller,
                    focusNode: widget.focus_node,
                    minLines: 1,
                    maxLines: null,
                    keyboardAppearance: widget.is_dark
                        ? Brightness.dark
                        : Brightness.light,
                    textInputAction: TextInputAction.newline,
                    textCapitalization: TextCapitalization.sentences,
                    cursorColor: CustomerServiceChatStyle.send_button_color,
                    cursorWidth: 2,
                    scrollPadding: const EdgeInsets.only(bottom: 24),
                    style: TextStyle(
                      fontSize: input_font_size,
                      fontWeight: CustomerServiceChatStyle.message_font_weight,
                      color: text_color,
                      height: CustomerServiceChatStyle.input_line_height,
                    ),
                    decoration: InputDecoration(
                      hintText: easy.tr('customer_service_sheet.input_hint'),
                      hintStyle: TextStyle(
                        fontSize: input_font_size,
                        fontWeight:
                            CustomerServiceChatStyle.message_font_weight,
                        color: CustomerServiceChatStyle.input_hint_color,
                        height: CustomerServiceChatStyle.input_line_height,
                      ),
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal:
                            CustomerServiceChatStyle.input_inner_padding,
                        vertical:
                            CustomerServiceChatStyle.input_content_padding_v,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: CustomerServiceChatStyle.input_action_spacing,
            ),
            _build_send_button(is_cjk),
          ],
        ),
      ),
    );
  }

  /// 构建具有明确禁用态和触控反馈的发送按钮。
  Widget _build_send_button(bool is_cjk) {
    final Color background_color = _has_text
        ? CustomerServiceChatStyle.send_button_color
        : (widget.is_dark
              ? CustomerServiceChatStyle.send_disabled_bg_dark
              : CustomerServiceChatStyle.send_disabled_bg_light);
    final Color text_color = _has_text
        ? CustomerServiceChatStyle.send_button_text_color
        : (widget.is_dark
              ? CustomerServiceChatStyle.send_disabled_text_dark
              : CustomerServiceChatStyle.send_disabled_text_light);
    final double font_size = is_cjk
        ? CustomerServiceChatStyle.send_button_font_size_cjk
        : CustomerServiceChatStyle.send_button_font_size_alphabetic;
    final double min_width = is_cjk
        ? CustomerServiceChatStyle.send_button_min_width_cjk
        : CustomerServiceChatStyle.send_button_min_width_alphabetic;

    return Semantics(
      button: true,
      enabled: _has_text,
      label: easy.tr('customer_service_sheet.send'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        height: CustomerServiceChatStyle.send_button_height,
        constraints: BoxConstraints(minWidth: min_width),
        decoration: BoxDecoration(
          color: background_color,
          borderRadius: BorderRadius.circular(
            CustomerServiceChatStyle.send_button_radius,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(
              CustomerServiceChatStyle.send_button_radius,
            ),
            onTap: _has_text ? widget.on_send : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CustomerServiceChatStyle.send_button_padding_h,
              ),
              child: Center(
                child: Text(
                  easy.tr('customer_service_sheet.send'),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: font_size,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                    color: text_color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 输入栏工具按钮，统一点击区域、语义标签和水波纹反馈。
class _ChatToolButton extends StatelessWidget {
  /// 辅助功能标签。
  final String semantic_label;

  /// 点击回调。
  final VoidCallback on_tap;

  /// 按钮内部图标。
  final Widget child;

  const _ChatToolButton({
    required this.semantic_label,
    required this.on_tap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantic_label,
      child: SizedBox(
        width: CustomerServiceChatStyle.tool_button_size,
        height: CustomerServiceChatStyle.tool_button_size,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkResponse(
            radius: CustomerServiceChatStyle.tool_button_size / 2,
            onTap: on_tap,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
