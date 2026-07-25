import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/theme.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/layout/page_header_spacing.dart';
import 'package:app/util/router/router_util.dart';

import 'logic.dart';
import 'style.dart';
import 'widgets/confirm_dialog.dart';
import 'widgets/page_background.dart';
import 'widgets/page_bottom_action.dart';
import 'widgets/page_content.dart';
import 'widgets/page_header.dart';

/// 提现页面。
///
/// 这一页只负责把“余额概览 / 提现网络 / 提现金额 / 底部按钮”组织出来，
/// 所有数据请求、弹窗判断和金额同步逻辑都收口在 `logic.dart`。
class Withdraw extends StatefulWidget {
  const Withdraw({super.key});

  @override
  State<Withdraw> createState() => _WithdrawState();
}

class _WithdrawState extends State<Withdraw> {
  /// 设备主题仓库。
  final DeviceInfo deviceInfo = Get.find<DeviceInfo>();

  /// 提现页逻辑层。
  late final WithdrawLogic logic;

  @override
  void initState() {
    super.initState();

    /// 初始化逻辑层。
    logic = WithdrawLogic();

    /// 监听逻辑层状态变化。
    logic.addListener(handleLogicChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      /// 首帧后加载提现页所需数据。
      logic.init();
    });
  }

  @override
  void dispose() {
    /// 页面销毁前解除逻辑监听。
    logic.removeListener(handleLogicChanged);

    /// 释放逻辑层内部资源。
    logic.dispose();
    super.dispose();
  }

  void handleLogicChanged() {
    /// 页面已经销毁时不再刷新 UI。
    if (!mounted) return;

    /// 逻辑层状态变化后重建页面。
    setState(() {});
  }

  /// 下拉刷新成功后提示「刷新成功」（多语种 `constant.refresh_success`）。
  Future<void> _handlePullRefresh() async {
    final bool ok = await logic.refreshData();
    if (!mounted || !ok) return;
    showBottomTip(easy.tr('constant.refresh_success'));
  }

  Future<void> handleSubmit() async {
    /// 提交前先收起输入焦点。
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    /// 把地址输入框中的草稿值提交给逻辑层。
    logic.commitAddressInput();

    /// 当前不能提现时，直接走逻辑层已有的兜底处理。
    if (!logic.canWithdraw) {
      logic.onSubmit();
      return;
    }

    /// 钱包地址为空时直接拦截。
    if (logic.walletAddress.isEmpty) {
      showBottomTip(easy.tr('withdraw_page.address_required'));
      return;
    }

    /// 正式提交前先展示确认弹窗。
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return WithdrawConfirmDialog(
          isDark: deviceInfo.dark.value,
          networkValue: logic.currentTypeLabel(),
          walletLabel: easy.tr('withdraw_page.wallet_title'),
          walletValue: logic.walletAddress,
          amountValue: logic.displayAmount(logic.selectedAmount),
          onConfirm: logic.submitWithdrawRequest,
          onSuccess: (String successMessage) async {
            await logic.showWithdrawSuccessDialog(successMessage);
          },
        );
      },
    );

    /// 弹窗关闭后再次收起键盘，避免焦点残留。
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    /// 读取一次 locale，确保切换语言后当前页参与重建。
    Localizations.localeOf(context);
    return Obx(() {
      /// 当前主题模式。
      final bool isDark = deviceInfo.dark.value;

      /// 当前是否横屏。
      final bool isLandscape =
          MediaQuery.of(context).orientation == Orientation.landscape;

      /// 页面底色。
      final Color backgroundColor = isDark
          ? ColorConstants.nightBackgroundColor
          : ColorConstants.lightBackgroundColor;

      /// 当前媒体信息。
      final MediaQueryData mediaQuery = MediaQuery.of(context);
      final EdgeInsets safePadding = mediaQuery.padding;

      /// 主内容顶部起始位置。
      final double contentTopPadding = resolvePageHeaderContentTopPadding(
        mediaQuery: mediaQuery,
        headerBottomFadeSpacing: WithdrawStyle.headerBottomFadeSpacing,
      );

      return Scaffold(
        resizeToAvoidBottomInset: !isLandscape,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            /// 点击页面空白处时收起键盘。
            FocusScope.of(context).unfocus();
          },
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: ThemeConstants.animationTime,
            ),
            curve: Curves.easeInOut,
            color: backgroundColor,
            child: Stack(
              children: <Widget>[
                // 页面背景层单独封装，避免路由页里堆很多纯视觉 Positioned。
                WithdrawPageBackground(isDark: isDark),
                // 主内容层只关心正文顺序，不再让路由页直接拼网络、金额和摘要卡。
                WithdrawPageContent(
                  isDark: isDark,
                  isLandscape: isLandscape,
                  logic: logic,
                  leftInset: safePadding.left,
                  rightInset: safePadding.right,
                  bottomInset: safePadding.bottom,
                  contentTopPadding: contentTopPadding,
                  onTapRecords: () {
                    routerUtil(path: '/withdraw_record');
                  },
                  onSubmit: handleSubmit,
                  onPullRefresh: _handlePullRefresh,
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  // 顶部标题层也独立成组件，职责只剩“固定标题 + 顶部渐变”。
                  child: WithdrawPageHeader(
                    isDark: isDark,
                    backgroundColor: backgroundColor,
                  ),
                ),
                if (isLandscape)
                  WithdrawPageBottomAction(
                    leftInset: safePadding.left,
                    rightInset: safePadding.right,
                    bottomInset: safePadding.bottom,
                    loading: logic.loading,
                    title: logic.submitTitle,
                    onTap: handleSubmit,
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
