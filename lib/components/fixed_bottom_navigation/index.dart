// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/shell_tab_info.dart';
import 'package:app/stores/message_store.dart';
import 'package:app/stores/user_information.dart';

import 'logic.dart';
import 'style.dart';
import 'widgets/navigation_item.dart';
import 'widgets/night_panel_decor.dart';
import 'widgets/side_ripple_painter.dart';

/// 固定底部导航组件。
///
/// 当前组件职责只保留在 UI 宿主层：
/// 1. 订阅 tab 和主题状态；
/// 2. 组织整条底栏布局；
/// 3. 承接跨按钮共享的波纹动画。
class FixedBottomNavigation extends StatefulWidget {
  const FixedBottomNavigation({super.key});

  @override
  State<FixedBottomNavigation> createState() => _FixedBottomNavigationState();
}

class _FixedBottomNavigationState extends State<FixedBottomNavigation>
    with SingleTickerProviderStateMixin {
  /// Shell 层级的 tab 状态仓库。
  final ShellTabInfo shell_tab_info = Get.find<ShellTabInfo>();

  /// 设备主题仓库。
  final DeviceInfo device_info = Get.find<DeviceInfo>();

  /// 消息仓库（用于获取未读数角标）。
  final MessageStore message_store = Get.find<MessageStore>();

  /// 用户信息仓库（用于判断登录状态）。
  final UserInformation user_info = Get.find<UserInformation>();

  /// 当前组件的交互逻辑对象。
  final Logic logic = Logic();

  /// 整条底部导航的测量 key。
  final GlobalKey _bar_key = GlobalKey();

  /// 点击波纹动画控制器。
  late final AnimationController _ripple_controller;

  /// 当前这次波纹的起点坐标。
  Offset? _ripple_origin;

  @override
  void initState() {
    super.initState();
    _ripple_controller = AnimationController(
      vsync: this,
      duration: Style.ripple_duration,
    );
  }

  @override
  void dispose() {
    _ripple_controller.dispose();
    super.dispose();
  }

  /// 触发一次底栏点击波纹。
  ///
  /// 参数：
  /// - `global_position`：手势按下时的全局坐标。
  void _trigger_ripple(Offset global_position) {
    final BuildContext? nav_context = _bar_key.currentContext;
    if (nav_context == null) {
      return;
    }

    final RenderBox? box = nav_context.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }

    setState(() {
      _ripple_origin = box.globalToLocal(global_position);
    });

    _ripple_controller
      ..stop()
      ..forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final String active_path = shell_tab_info.activePath.value;
      final bool is_dark = device_info.theme.value == ThemeMode.dark;
      final EdgeInsets view_padding = MediaQuery.viewPaddingOf(context);
      final double bottom_inset = view_padding.bottom;
      final double horizontal_inset = Style.horizontal_inset(view_padding);
      final Color shadow_color = is_dark
          ? Style.dark_shadow_color()
          : Style.light_shadow_color();

      return DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: shadow_color,
              blurRadius: Style.shadow_blur_radius,
              offset: Style.shadow_offset,
            ),
          ],
        ),
        child: SizedBox(
          key: _bar_key,
          height: Style.bar_height + bottom_inset,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Style.panel_background_color(is_dark: is_dark),
                    gradient: is_dark ? Style.night_panel_gradient() : null,
                  ),
                ),
                if (is_dark) const NightPanelDecor(),
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _ripple_controller,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: SideRipplePainter(
                          progress: _ripple_controller.value,
                          origin: _ripple_origin,
                          color: Style.ripple_color(),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: horizontal_inset,
                    right: horizontal_inset,
                    bottom: bottom_inset,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: NavigationItem(
                          tab_path: '/',
                          icon_name: active_path == '/'
                              ? 'home_selected'
                              : 'home_selected_no',
                          is_active: active_path == '/',
                          is_dark: is_dark,
                          on_tap_down: (details) =>
                              _trigger_ripple(details.globalPosition),
                          on_tap: () => logic.go_to('/'),
                        ),
                      ),
                      Expanded(
                        child: NavigationItem(
                          tab_path: '/bookshelf',
                          icon_name: active_path == '/bookshelf'
                              ? 'bookshelf_selected'
                              : 'bookshelf_selected_no',
                          is_active: active_path == '/bookshelf',
                          is_dark: is_dark,
                          on_tap_down: (details) =>
                              _trigger_ripple(details.globalPosition),
                          on_tap: () => logic.go_to('/bookshelf'),
                        ),
                      ),
                      Expanded(
                        child: NavigationItem(
                          tab_path: '/message',
                          icon_name: active_path == '/message'
                              ? 'message_selected'
                              : 'message_selected_no',
                          is_active: active_path == '/message',
                          is_dark: is_dark,
                          on_tap_down: (details) =>
                              _trigger_ripple(details.globalPosition),
                          on_tap: () => logic.go_to('/message'),
                          // 未登录时不显示角标。
                          badge_count: user_info.isLoggedIn.value
                              ? message_store.unread_total.value
                              : 0,
                        ),
                      ),
                      Expanded(
                        child: NavigationItem(
                          tab_path: '/user_info',
                          icon_name: active_path == '/user_info'
                              ? 'user_selected'
                              : 'user_selected_no',
                          is_active: active_path == '/user_info',
                          is_dark: is_dark,
                          on_tap_down: (details) =>
                              _trigger_ripple(details.globalPosition),
                          on_tap: () => logic.go_to('/user_info'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
