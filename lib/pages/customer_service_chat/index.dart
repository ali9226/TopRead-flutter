// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:get/get.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/stores/customer_service_chat_history_store.dart';
import 'package:app/components/network_cover_image/index.dart';
import 'package:app/components/svg_icon/index.dart';
import 'style.dart';
import 'logic.dart';
import 'widgets/message_bubble.dart';
import 'widgets/emoji_panel.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/image_picker_page.dart' as picker;

/// 在线客服聊天页面。
///
/// 独立页面，类似微信聊天界面。
/// 使用 Scaffold + resizeToAvoidBottomInset 实现键盘弹出时
/// 输入栏自动上移，消息列表自动缩小，保持流畅体验。
class CustomerServiceChatPage extends StatefulWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  const CustomerServiceChatPage({super.key, required this.is_dark});

  @override
  State<CustomerServiceChatPage> createState() =>
      _CustomerServiceChatPageState();
}

class _CustomerServiceChatPageState extends State<CustomerServiceChatPage>
    with WidgetsBindingObserver {
  /// 聊天逻辑。
  late ChatLogic _logic;

  /// 键盘是否可见。
  bool _is_keyboard_visible = false;

  @override
  void initState() {
    super.initState();
    _logic = ChatLogic(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logic.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;

    // TODO 使用当前页面所属 View，避免多窗口环境误读其他窗口的键盘。
    final view = View.of(context);
    final double keyboard_height =
        view.viewInsets.bottom / view.devicePixelRatio;
    final bool keyboard_now_visible = keyboard_height > 0;

    if (keyboard_now_visible == _is_keyboard_visible) return;

    if (keyboard_now_visible) {
      _logic.close_emoji_panel();
    }
    _is_keyboard_visible = keyboard_now_visible;

    _logic.scroll_to_bottom();
  }

  @override
  Widget build(BuildContext context) {
    final String locale_code = context.locale.languageCode;
    final bool is_cjk = LanguageUtil.is_cjk_language(locale_code);

    final Color nav_bg = widget.is_dark
        ? CustomerServiceChatStyle.nav_bg_color_dark
        : CustomerServiceChatStyle.nav_bg_color_light;

    final Color title_color = widget.is_dark
        ? CustomerServiceChatStyle.title_color_dark
        : CustomerServiceChatStyle.title_color_light;

    final double title_font_size = is_cjk
        ? CustomerServiceChatStyle.nav_title_font_size_cjk
        : CustomerServiceChatStyle.nav_title_font_size_alphabetic;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: widget.is_dark
          ? CustomerServiceChatStyle.page_bg_color_dark
          : CustomerServiceChatStyle.page_bg_color_light,
      appBar: AppBar(
        toolbarHeight: CustomerServiceChatStyle.nav_bar_height,
        backgroundColor: nav_bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: title_color,
          ),
        ),
        title: Text(
          easy.tr('customer_service_sheet.title'),
          style: TextStyle(
            fontSize: title_font_size,
            fontWeight: CustomerServiceChatStyle.nav_title_font_weight,
            color: title_color,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: _dismiss_input,
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: <Widget>[
            Expanded(
              child: GetBuilder<CustomerServiceChatHistoryStore>(
                builder: (_) => _build_message_list(),
              ),
            ),
            Divider(
              height: 0.5,
              thickness: 0.5,
              color: widget.is_dark
                  ? CustomerServiceChatStyle.divider_color_dark
                  : CustomerServiceChatStyle.divider_color_light,
            ),
            ChatInputBar(
              is_dark: widget.is_dark,
              text_controller: _logic.text_controller,
              focus_node: _logic.focus_node,
              show_emoji_panel: _logic.show_emoji_panel,
              include_bottom_safe_area: !_logic.show_emoji_panel,
              on_send: _logic.send_text_message,
              on_toggle_emoji: _logic.toggle_emoji_panel,
              on_pick_image: _open_image_picker,
            ),
            _build_emoji_panel(),
          ],
        ),
      ),
    );
  }

  /// 收起当前输入方式。
  void _dismiss_input() {
    _logic.focus_node.unfocus();
    _logic.close_emoji_panel();
  }

  /// 构建固定高度的表情面板，避免键盘高度改变网格底部留白。
  Widget _build_emoji_panel() {
    return ClipRect(
      child: AnimatedContainer(
        duration: CustomerServiceChatStyle.emoji_panel_animation_duration,
        curve: Curves.easeOutCubic,
        height: _logic.show_emoji_panel
            ? CustomerServiceChatStyle.emoji_panel_default_height
            : 0,
        child: EmojiPanel(
          is_dark: widget.is_dark,
          on_emoji_selected: _logic.insert_emoji,
        ),
      ),
    );
  }

  /// 弹出图片来源选择（相册/拍照）。
  Future<void> _open_image_picker() async {
    _logic.focus_node.unfocus();
    _logic.close_emoji_panel();

    final List<String>? uploaded_urls = await picker.show_image_source_sheet(
      context,
      widget.is_dark,
    );

    if (!mounted) return;
    if (uploaded_urls != null && uploaded_urls.isNotEmpty) {
      _logic.send_image_messages(uploaded_urls);
    }
  }

  /// 构建消息列表。
  Widget _build_message_list() {
    if (_logic.messages.isEmpty) {
      if (_logic.is_initial_loading) {
        return Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: CustomerServiceChatStyle.loading_color,
            ),
          ),
        );
      }
      return _build_empty_state();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _logic.handle_scroll_notification,
      child: ListView.builder(
        controller: _logic.scroll_controller,
        reverse: true,
        addAutomaticKeepAlives: false,
        scrollCacheExtent: const ScrollCacheExtent.pixels(
          CustomerServiceChatStyle.list_cache_extent,
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: CustomerServiceChatStyle.list_padding_h,
          vertical: CustomerServiceChatStyle.list_padding_v,
        ),
        itemCount: _logic.messages.length + 1,
        itemBuilder: (context, index) {
          // TODO 反向列表的最后一项位于物理顶部，高度始终固定。
          if (index == _logic.messages.length) {
            return _build_history_status();
          }

          final ChatMessageItem item = _logic.messages[index];
          final bool is_admin = item.sender_type == 2;

          return RepaintBoundary(
            key: ValueKey<String>(item.local_key),
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: CustomerServiceChatStyle.message_spacing,
              ),
              child: _build_message_row(item, is_admin),
            ),
          );
        },
      ),
    );
  }

  /// TODO 构建固定高度的历史状态区，防止加载状态切换推动消息。
  Widget _build_history_status() {
    Widget child = const SizedBox.shrink();
    if (_logic.is_loading_history) {
      child = SizedBox(
        key: const ValueKey<String>('loading'),
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: CustomerServiceChatStyle.loading_color,
        ),
      );
    } else if (!_logic.has_more_history) {
      child = Text(
        easy.tr('chat.no_more_messages'),
        key: const ValueKey<String>('completed'),
        style: TextStyle(
          fontSize: 12,
          fontWeight: CustomerServiceChatStyle.message_font_weight,
          color: widget.is_dark
              ? CustomerServiceChatStyle.history_text_color_dark
              : CustomerServiceChatStyle.history_text_color_light,
        ),
      );
    }

    return SizedBox(
      key: const ValueKey<String>('history_status'),
      height: CustomerServiceChatStyle.history_status_height,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 140),
          child: child,
        ),
      ),
    );
  }

  /// 构建单条消息行。
  ///
  /// 微信风格布局：
  /// - 用户消息：靠右对齐，头像在右
  /// - 管理员消息：靠左对齐，头像在左
  Widget _build_message_row(ChatMessageItem item, bool is_admin) {
    final Widget bubble = MessageBubble(
      is_admin: is_admin,
      message_type: item.message_type,
      content: item.content,
      server_content: item.server_content,
      create_time: item.create_time,
      is_dark: widget.is_dark,
      sender_name: item.sender_name,
      is_uploading: item.is_uploading,
    );

    if (is_admin) {
      return Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _build_avatar(item.sender_name, true),
          const SizedBox(width: CustomerServiceChatStyle.avatar_bubble_spacing),
          Flexible(child: bubble),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Flexible(child: bubble),
          const SizedBox(width: CustomerServiceChatStyle.avatar_bubble_spacing),
          _build_avatar('', false),
        ],
      );
    }
  }

  /// 构建头像。
  ///
  /// 用户头像：使用 user_info 中的真实头像。
  /// 管理员头像：使用 logo.svg。
  Widget _build_avatar(String name, bool is_admin) {
    if (is_admin) {
      return Container(
        width: CustomerServiceChatStyle.avatar_size,
        height: CustomerServiceChatStyle.avatar_size,
        decoration: BoxDecoration(
          color: widget.is_dark
              ? CustomerServiceChatStyle.bubble_admin_bg_dark
              : CustomerServiceChatStyle.bubble_admin_bg_light,
          borderRadius: BorderRadius.circular(
            CustomerServiceChatStyle.avatar_radius,
          ),
          border: Border.all(
            color: widget.is_dark
                ? CustomerServiceChatStyle.divider_color_dark
                : CustomerServiceChatStyle.divider_color_light,
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            CustomerServiceChatStyle.avatar_radius,
          ),
          child: Center(
            child: SvgIcon(
              name: 'logo',
              width: CustomerServiceChatStyle.admin_avatar_logo_size,
              height: CustomerServiceChatStyle.admin_avatar_logo_size,
              color: widget.is_dark ? Colors.white : null,
            ),
          ),
        ),
      );
    }

    final UserInformation user_info = Get.find<UserInformation>();
    final String avatar_url = user_info.userInfo.value?.avatarUrl ?? '';

    if (avatar_url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(
          CustomerServiceChatStyle.avatar_radius,
        ),
        child: NetworkCoverImage(
          image_url: avatar_url,
          width: CustomerServiceChatStyle.avatar_size,
          height: CustomerServiceChatStyle.avatar_size,
          border_radius: CustomerServiceChatStyle.avatar_radius,
          fit: BoxFit.cover,
          is_dark: widget.is_dark,
        ),
      );
    }

    return Container(
      width: CustomerServiceChatStyle.avatar_size,
      height: CustomerServiceChatStyle.avatar_size,
      decoration: BoxDecoration(
        color: CustomerServiceChatStyle.bubble_user_bg,
        borderRadius: BorderRadius.circular(
          CustomerServiceChatStyle.avatar_radius,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: 20,
          color: CustomerServiceChatStyle.bubble_user_text,
        ),
      ),
    );
  }

  /// 构建空状态。
  Widget _build_empty_state() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SvgIcon(
            name: 'logo',
            width: 64,
            height: 64,
            color: widget.is_dark ? Colors.white : null,
          ),
          const SizedBox(height: 16),
          Text(
            easy.tr('customer_service_sheet.empty_hint'),
            style: TextStyle(
              fontSize: CustomerServiceChatStyle.empty_font_size,
              fontWeight: CustomerServiceChatStyle.message_font_weight,
              color: widget.is_dark
                  ? CustomerServiceChatStyle.history_text_color_dark
                  : CustomerServiceChatStyle.empty_text_color,
            ),
          ),
        ],
      ),
    );
  }
}
