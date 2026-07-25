import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/fixed_bottom_navigation/index.dart';
import 'package:app/components/shell_tab_host/widgets/shell_tab_pane.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/device_config.dart';
import 'package:app/pages/bookshelf/index.dart';
import 'package:app/pages/home/index.dart';
import 'package:app/pages/message/index.dart';
import 'package:app/pages/user_info/index.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/shell_tab_info.dart';

/// Shell 内部首页/个人中心双 tab 宿主。
///
/// - 首页和个人中心都常驻在同一层级，不再依赖普通路由切换时整页重建。
/// - 通过双层常驻页面 + 轻量过渡动画切换活动页，未激活页面保持状态和渲染树。
/// - 底部导航左右按钮的切换既有"页面已切换"的反馈，也不会丢失页面状态。
class ShellTabHost extends StatefulWidget {
  final String activePath;

  const ShellTabHost({super.key, required this.activePath});

  @override
  State<ShellTabHost> createState() => _ShellTabHostState();
}

class _ShellTabHostState extends State<ShellTabHost> {
  final ShellTabInfo shellTabInfo = Get.find<ShellTabInfo>();

  /// 把外部路由 path 同步到 Shell 仓库。
  ///
  /// 不能在 didUpdateWidget 里直接写 Rx：
  /// 父级路由树重建过程中同步写入，会让依赖这个仓库的 Obx
  /// 在 build 中途被标记脏，触发 setState() or markNeedsBuild() called during build。
  void _scheduleSyncActivePath() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      shellTabInfo.updateActivePath(widget.activePath);
    });
  }

  @override
  void initState() {
    super.initState();
    _scheduleSyncActivePath();
  }

  @override
  void didUpdateWidget(covariant ShellTabHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activePath == widget.activePath) {
      return;
    }
    _scheduleSyncActivePath();
  }

  @override
  Widget build(BuildContext context) {
    final DeviceInfo deviceInfo = Get.find<DeviceInfo>();

    final Widget tabStack = Obx(() {
      final int activeIndex = shellTabInfo.activeIndex.value;
      return Stack(
        fit: StackFit.expand,
        children: [
          ShellTabPane(
            active: activeIndex == 0,
            slideFromLeft: true,
            child: const Home(),
          ),
          ShellTabPane(
            active: activeIndex == 1,
            slideFromLeft: false,
            child: BookshelfPage(),
          ),
          ShellTabPane(
            active: activeIndex == 2,
            slideFromLeft: false,
            child: const MessagePage(),
          ),
          ShellTabPane(
            active: activeIndex == 3,
            slideFromLeft: false,
            child: const UserInfo(),
          ),
        ],
      );
    });

    Widget content = RepaintBoundary(child: tabStack);
    if (DeviceConfig.maxWidth > 0) {
      content = Obx(() {
        final bool isDark = deviceInfo.dark.value;
        return Container(
          color: isDark
              ? ColorConstants.nightBackgroundColor
              : ColorConstants.whiteColor,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: DeviceConfig.maxWidth),
              child: RepaintBoundary(child: tabStack),
            ),
          ),
        );
      });
    }

    return Column(
      children: [
        Expanded(child: content),
        const FixedBottomNavigation(),
      ],
    );
  }
}
