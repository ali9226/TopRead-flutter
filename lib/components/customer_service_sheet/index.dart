// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/components/bottom_sheet_drag_handle/index.dart';
import 'package:app/util/language_util/index.dart';
import 'style.dart';
import 'logic.dart';
import 'widgets/chat_message_list.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/emoji_panel.dart';

/// 在线客服聊天底部弹窗组件。
///
/// 从屏幕底部弹出，高度为屏幕 90%，展示类似微信的实时聊天界面。
/// 支持已登录用户和匿名访客两种身份。
class CustomerServiceSheet extends StatefulWidget {
    /// 是否为夜间模式。
    final bool is_dark;

    /// 关闭弹窗回调。
    final VoidCallback on_close;

    const CustomerServiceSheet({
        super.key,
        required this.is_dark,
        required this.on_close,
    });

    @override
    State<CustomerServiceSheet> createState() => _CustomerServiceSheetState();
}

class _CustomerServiceSheetState extends State<CustomerServiceSheet> {
    /// 聊天逻辑。
    late ChatLogic _logic;

    @override
    void initState() {
        super.initState();
        _logic = ChatLogic(context, () {
            if (mounted) setState(() {});
        });
    }

    @override
    void dispose() {
        _logic.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        /// 当前语种代码。
        final String locale_code = context.locale.languageCode;

        /// 是否为 CJK 语系。
        final bool is_cjk = LanguageUtil.is_cjk_language(locale_code);

        /// 背景色。
        final Color background_color = widget.is_dark
            ? CustomerServiceSheetStyle.background_color_dark
            : CustomerServiceSheetStyle.background_color_light;

        /// 标题颜色。
        final Color title_color = widget.is_dark
            ? CustomerServiceSheetStyle.title_color_dark
            : CustomerServiceSheetStyle.title_color_light;

        /// 标题字号。
        final double title_font_size = is_cjk
            ? CustomerServiceSheetStyle.nav_title_font_size_cjk
            : CustomerServiceSheetStyle.nav_title_font_size_alphabetic;

        /// 屏幕高度。
        final double screen_height = MediaQuery.of(context).size.height;

        return Container(
            width: double.infinity,
            height: screen_height * CustomerServiceSheetStyle.height_ratio,
            decoration: BoxDecoration(
                color: background_color,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(CustomerServiceSheetStyle.border_radius_top),
                    topRight: Radius.circular(CustomerServiceSheetStyle.border_radius_top),
                ),
            ),
            child: Column(
                children: <Widget>[
                    /// 顶部拖拽指示条。
                    BottomSheetDragHandle(is_dark: widget.is_dark),

                    /// 顶部导航栏。
                    _build_nav_bar(title_color, title_font_size),

                    /// 分隔线。
                    Divider(
                        height: 0.5,
                        color: widget.is_dark
                            ? CustomerServiceSheetStyle.divider_color_dark
                            : CustomerServiceSheetStyle.divider_color_light,
                    ),

                    /// 聊天消息列表。
                    Expanded(
                        child: GestureDetector(
                            onTap: () {
                                // TODO 点击聊天区域收起表情面板和键盘
                                if (_logic.show_emoji_panel) {
                                    _logic.toggle_emoji_panel();
                                }
                                _logic.focus_node.unfocus();
                            },
                            child: ChatMessageList(
                                messages: _logic.messages,
                                is_dark: widget.is_dark,
                                scroll_controller: _logic.scroll_controller,
                                is_loading: _logic.is_loading,
                            ),
                        ),
                    ),

                    /// 表情面板（条件显示）。
                    if (_logic.show_emoji_panel)
                        EmojiPanel(
                            is_dark: widget.is_dark,
                            on_emoji_selected: (emoji) {
                                _logic.send_emoji_message(emoji);
                            },
                        ),

                    /// 输入栏。
                    ChatInputBar(
                        is_dark: widget.is_dark,
                        text_controller: _logic.text_controller,
                        focus_node: _logic.focus_node,
                        show_emoji_panel: _logic.show_emoji_panel,
                        on_send: _logic.send_text_message,
                        on_toggle_emoji: _logic.toggle_emoji_panel,
                        on_pick_image: _logic.pick_and_send_image,
                    ),
                ],
            ),
        );
    }

    /// 构建顶部导航栏。
    Widget _build_nav_bar(Color title_color, double font_size) {
        return SizedBox(
            height: CustomerServiceSheetStyle.nav_bar_height,
            child: Stack(
                children: <Widget>[
                    /// 标题。
                    Center(
                        child: Text(
                            easy.tr('customer_service_sheet.title'),
                            style: TextStyle(
                                fontSize: font_size,
                                fontWeight: CustomerServiceSheetStyle.nav_title_font_weight,
                                color: title_color,
                            ),
                        ),
                    ),

                    /// 关闭按钮。
                    Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: GestureDetector(
                            onTap: widget.on_close,
                            child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Icon(
                                    Icons.close,
                                    size: 24,
                                    color: title_color,
                                ),
                            ),
                        ),
                    ),
                ],
            ),
        );
    }
}

/// 显示在线客服聊天弹窗的便捷方法。
///
/// 参数：
/// - [context] BuildContext。
/// - [is_dark] 当前是否为夜间模式，不传则自动根据主题判断。
void showCustomerServiceSheet({
    required BuildContext context,
    bool? is_dark,
}) {
    /// 是否为夜间模式。
    final bool current_is_dark =
        is_dark ?? Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (BuildContext ctx) {
            return CustomerServiceSheet(
                is_dark: current_is_dark,
                on_close: () => Navigator.pop(ctx),
            );
        },
    );
}
