// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:app/config/font_config.dart';

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/page_background_decor/index.dart';
import 'package:app/components/page_top_gradient_overlay/index.dart';
import 'package:app/components/fixed_bottom_navigation/style.dart'
    as fixed_nav_style;
import 'package:app/components/floating_back_to_top/index.dart';
import 'package:app/components/floating_back_to_top/style.dart'
    as floating_back_to_top_style;
import 'package:app/components/load_more_footer/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/message_data.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/util/dialog/show_message.dart';
import 'package:app/pages/message/style.dart';
import 'package:app/pages/message/widgets/message_item_card.dart';
import 'package:app/pages/message/widgets/message_skeleton.dart';
import 'package:app/pages/message/widgets/no_login_entry.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/stores/message_store.dart';
import 'package:app/stores/shell_tab_info.dart';
import 'package:app/util/utc_time_util.dart';

/// 消息页面。
///
/// 数据由全局 MessageStore 管理，每次切到此页面时自动刷新。
class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final DeviceInfo device_info = Get.find<DeviceInfo>();
  final UserInformation user_information = Get.find<UserInformation>();
  final MessageStore message_store = Get.find<MessageStore>();
  final ShellTabInfo shell_tab_info = Get.find<ShellTabInfo>();
  final ScrollController _scroll_controller = ScrollController();

  /// 回顶按钮显隐。
  bool _show_back_to_top = false;

  /// 上次点击时间戳，用于防止连续快速点击。
  DateTime? _last_tap_time;

  /// tab 变化监听器。
  Worker? _tab_worker;

  /// 评论颜色（清透蓝）。
  static const Color _comment_color = Color(0xFF8DB7FF);

  /// 点赞颜色（暖珊瑚）。
  static const Color _like_color = Color(0xFFFF9E80);

  /// 收藏颜色（主题金）。
  static const Color _favorite_color = Color(0xFFFFD45A);

  /// 客服回复颜色（清新绿）。
  static const Color _chat_reply_color = Color(0xFF67C23A);

  /// 顶部统计数据。
  List<_quick_stat_item> get quick_stat_list => <_quick_stat_item>[
    _quick_stat_item(
      title: easy.tr('message.stats.comment'),
      total: message_store.comment_total.value,
      unread: message_store.comment_unread.value,
      color: _comment_color,
      type: 2,
    ),
    _quick_stat_item(
      title: easy.tr('message.stats.like'),
      total: message_store.like_total.value,
      unread: message_store.like_unread.value,
      color: _like_color,
      type: 3,
    ),
    _quick_stat_item(
      title: easy.tr('message.stats.favorite'),
      total: message_store.favorite_total.value,
      unread: message_store.favorite_unread.value,
      color: _favorite_color,
      type: 5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scroll_controller.addListener(_on_scroll);

    // TODO 首次加载阻塞等待，后续静默后台刷新
    if (message_store.has_loaded) {
      message_store.silent_refresh();
    } else {
      message_store.refresh();
    }

    // TODO 监听 tab 切换，每次切到消息 tab 时刷新数据
    _tab_worker = ever(shell_tab_info.activePath, (String path) {
      if (path == '/message' && user_information.isLoggedIn.value) {
        message_store.silent_refresh();
      }
    });
  }

  @override
  void dispose() {
    _tab_worker?.dispose();
    _scroll_controller.removeListener(_on_scroll);
    _scroll_controller.dispose();
    super.dispose();
  }

  void _on_scroll() {
    if (!_scroll_controller.hasClients) return;

    final double offset = _scroll_controller.offset;
    final bool next_show = offset > 180;
    if (next_show != _show_back_to_top) {
      setState(() {
        _show_back_to_top = next_show;
      });
    }

    // TODO 接近底部加载更多
    if (_scroll_controller.position.extentAfter < 260) {
      message_store.load_more();
    }
  }

  Future<void> _on_refresh() async {
    await message_store.refresh();
  }

  /// 点击统计卡片：切换筛选类型。
  void _on_stat_tap(int type) {
    final int? new_type = message_store.filter_type == type ? null : type;
    message_store.set_filter_type(new_type);
  }

  Future<void> _scroll_to_top() async {
    if (!_scroll_controller.hasClients) return;
    await _scroll_controller.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  /// 点击消息卡片：防抖 + 跳转 + 后台标记已读。
  ///
  /// 500ms 内的连续点击只响应第一次，防止快速连点导致多次路由跳转。
  /// 标记已读不阻塞跳转，在后台异步执行。
  void _on_message_tap(MessageData message) {
    final DateTime now = DateTime.now();
    if (_last_tap_time != null &&
        now.difference(_last_tap_time!).inMilliseconds < 500) {
      return;
    }
    _last_tap_time = now;

    if (message.type == MessageType.system) return;

    // 客服回复消息：跳转到在线客服页面
    if (message.type == MessageType.chat_reply) {
      message_store.update_chat_unread(0);
      routerUtil(path: '/customer_service_chat', type: 'push');
      return;
    }

    final int novel_id = message.novel_id;
    final int publish_status = message.novel_publish_status;
    final int comment_id = message.comment_id;

    if (novel_id <= 0) return;

    // 先跳转，不阻塞
    if (publish_status == 4) {
      String path = '/short_story_read?id=$novel_id';
      if (comment_id > 0) path += '&comment_id=$comment_id';
      routerUtil(path: path, type: 'push');
    } else {
      String path =
          '/read?id=$novel_id&title=${Uri.encodeComponent(message.novel_title)}';
      if (comment_id > 0) path += '&comment_id=$comment_id';
      routerUtil(path: path, type: 'push');
    }

    // 后台异步标记已读，不 await
    message_store.mark_as_read(message.id);
  }

  /// TODO 删除消息。
  Future<void> _delete_message(MessageData message) async {
    await message_store.delete_message(message.id);
  }

  /// TODO 根据消息类型获取 SVG 图标名称。
  String _get_icon_name_by_type(int type) {
    switch (type) {
      case MessageType.system:
        return 'message';
      case MessageType.comment_reply:
        return 'message';
      case MessageType.comment_like:
        return 'love_02';
      case MessageType.novel_like:
        return 'love_02';
      case MessageType.novel_favorite:
        return 'not_favorited';
      case MessageType.chat_reply:
        return 'message';
      default:
        return 'message';
    }
  }

  /// TODO 根据消息类型获取颜色。
  /// 评论：comment_reply（type=2）→ 蓝色
  /// 点赞：comment_like（type=3）+ novel_like（type=4）→ 红色
  /// 收藏：novel_favorite（type=5）→ 金色
  /// 客服回复：chat_reply（type=6）→ 绿色
  Color _get_color_by_type(int type) {
    switch (type) {
      case MessageType.system:
        return _favorite_color;
      case MessageType.comment_reply:
        return _comment_color;
      case MessageType.comment_like:
        return _like_color;
      case MessageType.novel_like:
        return _like_color;
      case MessageType.novel_favorite:
        return _favorite_color;
      case MessageType.chat_reply:
        return _chat_reply_color;
      default:
        return _favorite_color;
    }
  }

  /// TODO 格式化相对时间。
  String _format_time(String time_str) {
    if (time_str.isEmpty) return '';
    final DateTime? message_time = parse_utc_time_to_local(time_str);
    if (message_time == null) return time_str;

    final Duration diff = DateTime.now().difference(message_time);
    if (diff.inMinutes < 1) return easy.tr('message.time.just_now');
    if (diff.inMinutes < 60) {
      return easy
          .tr('message.time.minutes_ago')
          .replaceAll('{0}', '${diff.inMinutes}');
    }
    if (diff.inHours < 24) {
      return easy
          .tr('message.time.hours_ago')
          .replaceAll('{0}', '${diff.inHours}');
    }
    if (diff.inDays < 7) {
      return easy
          .tr('message.time.days_ago')
          .replaceAll('{0}', '${diff.inDays}');
    }
    return '${message_time.month}/${message_time.day}';
  }

  @override
  Widget build(BuildContext context) {
    final String localeCode = context.locale.languageCode;

    return Obx(key: ValueKey(localeCode), () {
      final bool is_dark = device_info.theme.value == ThemeMode.dark;
      final bool is_logged_in = user_information.isLoggedIn.value;
      final Color background_color = is_dark
          ? ColorConstants.nightBackgroundColor
          : const Color(0xFFF6F7FB);
      final Color primary_text_color = is_dark
          ? ColorConstants.whiteColor
          : ColorConstants.lightTextColor;
      final Color secondary_text_color = is_dark
          ? ColorConstants.whiteColor.withValues(alpha: 0.62)
          : ColorConstants.hintColor;

      final double status_bar_height = MediaQuery.paddingOf(context).top;

      // TODO 从 store 获取数据（分桶存储，已按类型筛选）
      final List<MessageData> messages = message_store.message_list;
      final bool has_more = message_store.has_more;
      final int? selected_type = message_store.filter_type;

      return Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: background_color,
        body: Stack(
          children: <Widget>[
            PageBackgroundDecor(is_dark: is_dark),
            if (is_logged_in)
              RefreshIndicator(
                color: ColorConstants.themeColor,
                onRefresh: _on_refresh,
                child: ListView(
                  controller: _scroll_controller,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: MessageStyle.page_padding.copyWith(
                    top: status_bar_height + MessageStyle.page_top_padding,
                  ),
                  children: <Widget>[
                    Text(
                      easy.tr('message.title'),
                      style: TextStyle(
                        color: primary_text_color,
                        fontSize: MessageStyle.title_size,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: quick_stat_list.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final _quick_stat_item item = entry.value;
                        final bool is_selected = selected_type == item.type;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index == quick_stat_list.length - 1
                                  ? 0
                                  : MessageStyle.quick_stat_item_gap,
                            ),
                            child: GestureDetector(
                              onTap: () => _on_stat_tap(item.type),
                              child: _quick_stat_card(
                                is_dark: is_dark,
                                title: item.title,
                                total: item.total,
                                unread: item.unread,
                                accent_color: item.color,
                                title_color: primary_text_color,
                                subtitle_color: secondary_text_color,
                                is_selected: is_selected,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          selected_type == null
                              ? easy.tr('message.all_messages')
                              : quick_stat_list
                                    .firstWhere(
                                      (s) => s.type == selected_type,
                                      orElse: () => quick_stat_list.first,
                                    )
                                    .title,
                          style: TextStyle(
                            color: secondary_text_color,
                            fontSize: 13,
                            fontWeight: FontConfig.adjustedWeight(
                              FontWeight.w500,
                            ),
                          ),
                        ),
                        if (message_store.unread_total.value > 0)
                          GestureDetector(
                            onTap: () => message_store.mark_all_as_read(),
                            child: Text(
                              easy.tr('message.mark_all_read'),
                              style: TextStyle(
                                color: ColorConstants.dangerColor,
                                fontSize: 12,
                                fontWeight: FontConfig.adjustedWeight(
                                  FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (messages.isEmpty && !message_store.has_loaded)
                      MessageSkeleton(is_dark: is_dark)
                    else if (messages.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: Column(
                            children: <Widget>[
                              Icon(
                                Icons.inbox_rounded,
                                size: 48,
                                color: secondary_text_color.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                easy.tr('message.empty'),
                                style: TextStyle(
                                  color: secondary_text_color,
                                  fontSize: 13,
                                  fontWeight: FontConfig.adjustedWeight(
                                    FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...messages.asMap().entries.map((entry) {
                        final MessageData message = entry.value;
                        final Color accent_color = _get_color_by_type(
                          message.type,
                        );
                        // 客服消息使用 store 中的未读数
                        final int unread_count =
                            message.type == MessageType.chat_reply
                            ? message_store.chat_unread.value
                            : 0;
                        return _AnimatedMessageItem(
                          key: ValueKey(message.identity_key),
                          message: message,
                          accent_color: accent_color,
                          on_tap: () => _on_message_tap(message),
                          on_delete: () => _delete_message(message),
                          get_icon_name: _get_icon_name_by_type,
                          format_time: _format_time,
                          unread_count: unread_count,
                        );
                      }),
                    if (messages.isNotEmpty)
                      LoadMoreFooter(
                        is_dark: is_dark,
                        is_loading: message_store.is_loading,
                        has_more: has_more,
                        on_load_more: message_store.load_more,
                      ),
                  ],
                ),
              )
            else
              NoLoginEntry(
                is_dark: is_dark,
                status_bar_height: status_bar_height,
                primary_text_color: primary_text_color,
                secondary_text_color: secondary_text_color,
              ),
            PageTopGradientOverlay(background_color: background_color),
            if (is_logged_in)
              FloatingBackToTop(
                show: _show_back_to_top,
                isDark: is_dark,
                onTap: _scroll_to_top,
                right: floating_back_to_top_style.FloatingBackToTopStyle.right,
                visibleBottom:
                    fixed_nav_style.Style.bar_height +
                    floating_back_to_top_style
                        .FloatingBackToTopStyle
                        .offset_from_bottom_nav +
                    MediaQuery.paddingOf(context).bottom,
                hiddenBottom:
                    fixed_nav_style.Style.bar_height +
                    floating_back_to_top_style
                        .FloatingBackToTopStyle
                        .hidden_offset +
                    MediaQuery.paddingOf(context).bottom,
              ),
          ],
        ),
      );
    });
  }

  /// 构建消息页顶部统计卡。
  Widget _quick_stat_card({
    required bool is_dark,
    required String title,
    required int total,
    required int unread,
    required Color accent_color,
    required Color title_color,
    required Color subtitle_color,
    bool is_selected = false,
  }) {
    final Color start_color = is_dark
        ? Color.alphaBlend(
            accent_color.withValues(alpha: 0.20),
            const Color(0xFF171C28),
          )
        : accent_color.withValues(alpha: 0.16);
    final Color end_color = is_dark
        ? Color.alphaBlend(
            accent_color.withValues(alpha: 0.08),
            const Color(0xFF12121C),
          )
        : accent_color.withValues(alpha: 0.05);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(MessageStyle.quick_stat_radius),
      child: Ink(
        height: MessageStyle.quick_stat_height,
        padding: MessageStyle.quick_stat_padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(MessageStyle.quick_stat_radius),
          border: is_selected
              ? Border.all(color: accent_color, width: 1.5)
              : Border.all(color: accent_color.withValues(alpha: 0.22)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[start_color, end_color],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: is_dark ? 0.18 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -10,
              right: -12,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent_color.withValues(alpha: is_dark ? 0.18 : 0.10),
                ),
              ),
            ),
            Positioned(
              bottom: -16,
              left: -20,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent_color.withValues(alpha: is_dark ? 0.10 : 0.06),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  width: 22,
                  height: 4,
                  decoration: BoxDecoration(
                    color: accent_color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                // TODO 总数 + 未读数
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${total.clamp(0, 99)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: title_color,
                        fontSize: 22,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                      ),
                    ),
                    if (unread > 0) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '${unread.clamp(0, 99)}${easy.tr('message.stats.unread_suffix')}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: accent_color,
                              fontSize: 11,
                              fontWeight: FontConfig.adjustedWeight(
                                FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // TODO 标题
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtitle_color,
                    fontSize: 12,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 顶部统计模型。
class _quick_stat_item {
  final String title;
  final int total;
  final int unread;
  final Color color;
  final int type;

  const _quick_stat_item({
    required this.title,
    required this.total,
    required this.unread,
    required this.color,
    required this.type,
  });
}

/// 带入场动画的消息卡片组件。
///
/// 新增的消息从右侧滑入并淡入显示，与删除时的滑出动画对称。
class _AnimatedMessageItem extends StatefulWidget {
  final MessageData message;
  final Color accent_color;
  final VoidCallback on_tap;
  final VoidCallback on_delete;
  final String Function(int) get_icon_name;
  final String Function(String) format_time;
  final int unread_count;

  const _AnimatedMessageItem({
    super.key,
    required this.message,
    required this.accent_color,
    required this.on_tap,
    required this.on_delete,
    required this.get_icon_name,
    required this.format_time,
    this.unread_count = 0,
  });

  @override
  State<_AnimatedMessageItem> createState() => _AnimatedMessageItemState();
}

class _AnimatedMessageItemState extends State<_AnimatedMessageItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide_animation;
  late final Animation<double> _fade_animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 75),
      vsync: this,
    );
    _slide_animation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade_animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide_animation,
      child: FadeTransition(
        opacity: _fade_animation,
        child: Padding(
          padding: const EdgeInsets.only(
            bottom: MessageStyle.card_margin_bottom,
          ),
          child: Dismissible(
            key: ValueKey(widget.message.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: ColorConstants.dangerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(MessageStyle.card_radius),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: ColorConstants.dangerColor,
                size: 22,
              ),
            ),
            confirmDismiss: (direction) async {
              bool confirmed = false;
              await showMessage(
                message: easy.tr('message.delete_confirm_content'),
                leftButtonText: easy.tr('common.cancel'),
                rightButtonText: easy.tr('common.confirm'),
                rightButtonColor: ColorConstants.dangerColor,
                iconData: Icons.delete_outline_rounded,
                iconColor: ColorConstants.dangerColor,
                onRightPressed: () async {
                  confirmed = true;
                },
              );
              return confirmed;
            },
            onDismissed: (_) => widget.on_delete(),
            child: GestureDetector(
              onTap: widget.on_tap,
              child: MessageItemCard(
                icon_name: widget.get_icon_name(widget.message.type),
                title: widget.message.display_title,
                subtitle: widget.message.display_subtitle,
                time_text: widget.format_time(widget.message.send_time),
                badge_text: widget.message.display_badge,
                accent_color: widget.accent_color,
                message_type: widget.message.type,
                is_unread: widget.message.is_unread,
                novel_cover: widget.message.has_novel_cover
                    ? widget.message.novel_cover
                    : null,
                unread_count: widget.unread_count,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
