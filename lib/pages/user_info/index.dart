import 'package:flutter/material.dart';
import 'package:app/components/support/index.dart';
import 'package:app/config/color_config.dart';
import 'package:get/get.dart';
import 'package:app/config/theme.dart';
import 'package:app/pages/user_info/view/statistics/index.dart';
import 'package:app/pages/user_info/view/operation_list/index.dart';
import 'package:app/pages/user_info/view/user_info_top.dart';
import 'package:app/stores/shell_tab_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/stores/device_info.dart';
import 'logic.dart';
import 'style.dart';

/// 用户中心首页。
///
/// 这个页面主要充当容器页，
/// 把顶部用户资料区、统计区、操作区和客服支持区组织到同一滚动视图里，
/// 同时处理切回 tab 时的数据刷新。
class UserInfo extends StatefulWidget {
  const UserInfo({super.key});

  @override
  State<UserInfo> createState() => _UserInfoState();
}

class _UserInfoState extends State<UserInfo> {
  /// 页面逻辑层。
  late Logic logic;

  /// 设备主题仓库。
  final deviceInfo = Get.find<DeviceInfo>();

  /// 用户信息仓库。
  final userInformation = Get.find<UserInformation>();

  /// 底部壳层 tab 状态仓库。
  final shellTabInfo = Get.find<ShellTabInfo>();

  /// 全屏 loading 遮罩状态。
  bool _loading = false;

  /// 是否已有刷新请求正在进行。
  bool _refreshing = false;

  /// 顶部用户信息组件的 key，用于调用其方法。
  final GlobalKey _userInfoTopKey = GlobalKey();

  /// 监听“用户中心 tab 被再次激活”的 worker。
  Worker? _tabActivationWorker;

  @override
  void initState() {
    super.initState();
    logic = Logic();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      /// 首次进入页面时静默刷新一次用户资料。
      _refreshUserInfo(showSuccessTip: false, showLoading: false);
    });

    // UserInfo 已经不再依赖“重新创建页面实例”触发刷新。
    // 现在通过 shell tab 激活事件判断：
    // - 第一次 initState 后的首次加载仍然保留；
    // - 后续只要用户再次切回个人中心，就会按需刷新一次资料。
    _tabActivationWorker = ever<int>(shellTabInfo.userInfoActivationTick, (_) {
      if (!mounted) return;
      if (shellTabInfo.activePath.value != '/user_info') return;
      _refreshUserInfo(showSuccessTip: false, showLoading: false);
    });
  }

  @override
  void dispose() {
    /// 页面销毁时取消 tab 激活监听。
    _tabActivationWorker?.dispose();
    super.dispose();
  }

  Future<void> _refreshUserInfo({
    bool showSuccessTip = true,
    bool showLoading = true,
    bool updateAvatar = false,
  }) async {
    /// 已在刷新中，或当前根本未登录时，不继续请求。
    if (_refreshing || !userInformation.isLoggedIn.value) return;

    /// 标记进入刷新状态。
    _refreshing = true;
    if (showLoading && mounted) {
      setState(() => _loading = true);
    }
    try {
      /// 调用逻辑层刷新用户资料。
      await logic.refreshUserInfo(showSuccessTip: showSuccessTip);

      /// 下拉刷新时更新随机头像。
      if (updateAvatar) {
        final userInfoTopState =
            _userInfoTopKey.currentState as dynamic;
        if (userInfoTopState != null) {
          userInfoTopState.refreshRandomAvatar();
        }
      }
    } finally {
      /// 无论成功失败都要关闭刷新标记。
      _refreshing = false;
      if (showLoading && mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // 顶部内容可以突破状态栏
      extendBody: true, // 底部内容可以突破导航栏
      body: Obx(() {
        /// 当前主题模式。
        final isDark = deviceInfo.dark.value;
        final isLoggedIn = userInformation.isLoggedIn.value;

        return AnimatedContainer(
          duration: Duration(milliseconds: ThemeConstants.animationTime),
          // 动画时长
          curve: Curves.easeInOut,
          // 动画曲线
          color: isDark
              ? ColorConstants.nightBackgroundColor
              : ColorConstants.whiteColor,
          child: Stack(
            children: [
              _buildScrollableContent(
                is_dark: isDark,
                is_logged_in: isLoggedIn,
                child: SingleChildScrollView(
                  key: const PageStorageKey<String>('user_info_scroll'),
                  /// 已登录时保持始终可下拉刷新；
                  /// 未登录时改为普通滚动，这样横屏内容超出视口时仍可上下滑动。
                  physics: isLoggedIn
                      ? const AlwaysScrollableScrollPhysics()
                      : const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      /// 顶部头像、昵称和登录态入口区域。
                      UserInfoTop(key: _userInfoTopKey),

                      Stack(
                        children: [
                          SafeArea(
                            top: false,
                            bottom: false,
                            child: Column(
                              children: [
                                /// 只有登录后才展示统计区。
                                if (isLoggedIn) Statistics(),

                                /// 常用操作入口列表。
                                OperationList(),

                                /// 操作区和客服区之间的间距。
                                SizedBox(height: Style.support_spacing),

                                /// 客服支持区。
                                Support(),

                                /// 页面底部留白，避免内容贴底。
                                SizedBox(
                                  height:
                                      Style.page_bottom_spacing +
                                      MediaQuery.paddingOf(context).bottom,
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: Style.content_decor_height,
                            child: IgnorePointer(
                              /// 顶部内容区下方的装饰层。
                              child: _UserInfoContentDecor(isDark: isDark),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              /// 主动刷新期间的全屏轻量遮罩。
              if (_loading)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(
                        alpha: Style.refresh_mask_opacity,
                      ),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  /// 根据登录态决定是否包裹下拉刷新。
  ///
  /// 未登录时不提供刷新能力，这样短内容页面也不会因为
  /// `RefreshIndicator` 的滚动物理效果产生额外位移。
  Widget _buildScrollableContent({
    required bool is_dark,
    required bool is_logged_in,
    required Widget child,
  }) {
    if (!is_logged_in) {
      return child;
    }

    return RefreshIndicator(
      /// 下拉时刷新用户资料，但不额外显示全屏 loading。
      onRefresh: () => _refreshUserInfo(showLoading: false, updateAvatar: true),
      color: ColorConstants.themeColor,
      backgroundColor: is_dark
          ? ColorConstants.nightHighlightColor
          : ColorConstants.whiteColor,
      child: child,
    );
  }
}

/// 用户中心内容装饰层。
///
/// 纯视觉组件，用于在资料区和操作区之间增加轻量氛围元素，
/// 不参与任何交互。
class _UserInfoContentDecor extends StatelessWidget {
  final bool isDark;

  const _UserInfoContentDecor({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: Style.decor_glow_one_top,
          right: Style.decor_glow_one_right,
          child: Container(
            /// 右上大光晕。
            width: Style.decor_glow_one_size,
            height: Style.decor_glow_one_size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark
                          ? Style.decor_glow_one_dark_color
                          : Style.decor_glow_one_light_color)
                      .withValues(
                        alpha: isDark
                            ? Style.decor_glow_one_dark_opacity
                            : Style.decor_glow_one_light_opacity,
                      ),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: Style.decor_glow_two_top,
          left: Style.decor_glow_two_left,
          child: Container(
            /// 左侧辅助光晕。
            width: Style.decor_glow_two_size,
            height: Style.decor_glow_two_size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark
                          ? Style.decor_glow_two_dark_color
                          : Style.decor_glow_two_light_color)
                      .withValues(
                        alpha: isDark
                            ? Style.decor_glow_two_dark_opacity
                            : Style.decor_glow_two_light_opacity,
                      ),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: Style.decor_outline_one_top,
          right: Style.decor_outline_one_right,
          child: Transform.rotate(
            angle: Style.decor_outline_one_angle,
            child: Container(
              /// 旋转描边方块，增加页面节奏感。
              width: Style.decor_outline_one_size,
              height: Style.decor_outline_one_size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Style.decor_outline_one_radius),
                border: Border.all(
                  color: (isDark ? Colors.white : ColorConstants.themeColor)
                      .withValues(
                        alpha: isDark
                            ? Style.decor_outline_one_dark_opacity
                            : Style.decor_outline_one_light_opacity,
                      ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: Style.decor_block_top,
          right: Style.decor_block_right,
          child: Transform.rotate(
            angle: Style.decor_block_angle,
            child: Container(
              /// 右侧渐变装饰块。
              width: Style.decor_block_size,
              height: Style.decor_block_size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Style.decor_block_radius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (isDark
                            ? Style.decor_block_dark_color
                            : Style.decor_block_light_color)
                        .withValues(
                          alpha: isDark
                              ? Style.decor_block_dark_opacity
                              : Style.decor_block_light_opacity,
                        ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: Style.decor_line_one_top,
          left: Style.decor_line_one_side,
          right: Style.decor_line_one_side,
          child: Container(
            /// 第一条横向渐变线。
            height: Style.decor_line_height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  (isDark ? Colors.white : ColorConstants.themeColor)
                      .withValues(
                        alpha: isDark
                            ? Style.decor_line_one_dark_opacity
                            : Style.decor_line_one_light_opacity,
                      ),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: Style.decor_line_two_top,
          left: Style.decor_line_two_side,
          right: Style.decor_line_two_side,
          child: Container(
            /// 第二条更短的横向渐变线。
            height: Style.decor_line_height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  (isDark
                          ? Style.decor_line_two_dark_color
                          : Style.decor_line_two_light_color)
                      .withValues(
                        alpha: isDark
                            ? Style.decor_line_two_dark_opacity
                            : Style.decor_line_two_light_opacity,
                      ),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
