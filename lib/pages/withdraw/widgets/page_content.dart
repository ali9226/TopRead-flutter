import 'package:flutter/material.dart';
import 'package:app/components/submit_button/index.dart';

import '../logic.dart';
import '../style.dart';
import 'amount_panel.dart';
import 'summary_card.dart';
import 'type_selector.dart';

/// 提现页主滚动内容层。
///
/// 这里只关心正文区的顺序和布局：
/// 1. 余额摘要卡。
/// 2. 提现网络与钱包地址。
/// 3. 提现金额区。
/// 4. 竖屏时的提交按钮。
///
/// 路由页只需要决定“放在哪里”和“什么时候显示横屏底部按钮”，
/// 不再直接堆业务表单细节。
class WithdrawPageContent extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 当前是否为横屏。
  final bool isLandscape;

  /// 页面逻辑对象。
  ///
  /// 正文区的大部分状态和交互都来自它。
  final WithdrawLogic logic;

  /// 左侧安全区。
  final double leftInset;

  /// 右侧安全区。
  final double rightInset;

  /// 底部安全区。
  final double bottomInset;

  /// 内容起始顶部内边距。
  ///
  /// 这个值已经把固定标题层和它的渐变过渡区算进去了。
  final double contentTopPadding;

  /// 点击“提现记录”后的跳转逻辑。
  final VoidCallback onTapRecords;

  /// 点击主提交按钮后的统一逻辑。
  final VoidCallback onSubmit;

  /// 下拉刷新：由路由页包装 [WithdrawLogic.refreshData] 并在成功后提示多语种文案。
  final Future<void> Function() onPullRefresh;

  const WithdrawPageContent({
    super.key,
    required this.isDark,
    required this.isLandscape,
    required this.logic,
    required this.leftInset,
    required this.rightInset,
    required this.bottomInset,
    required this.contentTopPadding,
    required this.onTapRecords,
    required this.onSubmit,
    required this.onPullRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      // 下拉刷新时重新拉取余额、提现网络和最小提现额度。
      onRefresh: onPullRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          WithdrawStyle.pageHorizontalPadding + leftInset,
          contentTopPadding,
          WithdrawStyle.pageHorizontalPadding + rightInset,
          WithdrawStyle.pageBottomPadding + bottomInset,
        ),
        children: <Widget>[
          // 摘要卡先展示“当前可提现余额”和“最小提现门槛”，
          // 让用户在输入金额前先有全局认知。
          WithdrawSummaryCard(
            isDark: isDark,
            balanceText: logic.displayAmount(logic.balance),
            minText: logic.displayAmount(logic.minWithdrawal),
          ),
          const SizedBox(height: WithdrawStyle.sectionSpacing),
          // 网络选择和钱包地址输入放在金额区前面，
          // 因为提交时这两项都属于比金额更基础的必填条件。
          WithdrawTypeSelector(
            isDark: isDark,
            items: logic.withdrawTypes,
            selectedId: logic.selectedTypeId,
            enabled: logic.canWithdraw,
            onTapType: logic.onTapType,
            addressController: logic.addressController,
            addressFocusNode: logic.addressFocusNode,
            onCommitAddressInput: logic.commitAddressInput,
            onSubmitAddressInput: logic.commitAddressInputAndFocusAmount,
            onTapPaste: logic.pasteWalletAddress,
            onTapClearAddress: logic.clearWalletAddress,
            onTapRecords: onTapRecords,
          ),
          const SizedBox(height: WithdrawStyle.sectionSpacing),
          // 金额区负责承接输入框、滑杆和快捷比例按钮，
          // 这些交互都围绕 `selectedAmount` 这一个核心状态同步。
          WithdrawAmountPanel(
            isDark: isDark,
            enabled: logic.canWithdraw,
            balanceText: logic.displayAmount(logic.balance),
            minText: logic.displayAmount(logic.minWithdrawal),
            maxText: logic.displayAmount(logic.balance),
            controller: logic.amountController,
            focusNode: logic.amountFocusNode,
            sliderValue: logic.canWithdraw
                ? logic.selectedAmount.clamp(logic.sliderMin, logic.sliderMax)
                : 0,
            sliderMin: logic.sliderMin,
            sliderMax: logic.sliderMax,
            onTapOneThird: () => logic.onTapShortcut(1 / 3),
            onTapHalf: () => logic.onTapShortcut(1 / 2),
            onTapAll: logic.onTapWithdrawAll,
            onSliderChanged: logic.onSliderChanged,
            oneThirdSelected: logic.isShortcutSelected(
              WithdrawShortcut.oneThird,
            ),
            halfSelected: logic.isShortcutSelected(WithdrawShortcut.half),
            allSelected: logic.isShortcutSelected(WithdrawShortcut.all),
            oneThirdEnabled: logic.canUseOneThirdShortcut,
            halfEnabled: logic.canUseHalfShortcut,
            onCommitInput: logic.commitAmountInput,
          ),
          if (!isLandscape) ...<Widget>[
            const SizedBox(height: WithdrawStyle.sectionSpacing),
            // 竖屏时把按钮留在滚动流里，避免遮住输入框和键盘动画。
            SubmitButton(
              loading: logic.loading,
              title: logic.submitTitle,
              onTap: onSubmit,
            ),
          ],
        ],
      ),
    );
  }
}
