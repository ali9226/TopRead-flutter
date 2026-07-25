import 'package:flutter/material.dart';
import 'package:app/components/submit_button/index.dart';

import '../style.dart';

/// 提现页横屏底部操作条。
///
/// 横屏时可视高度更紧，主按钮固定在底部会比塞进滚动流里更稳定，
/// 用户也不用滚到最下方才能点击提交。
class WithdrawPageBottomAction extends StatelessWidget {
  /// 左侧安全区，用于横屏异形屏适配。
  final double leftInset;

  /// 右侧安全区，用于横屏异形屏适配。
  final double rightInset;

  /// 底部安全区，用于 Home Indicator / 手势区域适配。
  final double bottomInset;

  /// 当前提交按钮是否处于 loading。
  final bool loading;

  /// 按钮标题。
  final String title;

  /// 点击按钮后的统一提交逻辑。
  final VoidCallback onTap;

  const WithdrawPageBottomAction({
    super.key,
    required this.leftInset,
    required this.rightInset,
    required this.bottomInset,
    required this.loading,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: WithdrawStyle.pageHorizontalPadding + leftInset,
      right: WithdrawStyle.pageHorizontalPadding + rightInset,
      bottom: WithdrawStyle.bottomButtonBottom + bottomInset,
      child: SubmitButton(loading: loading, title: title, onTap: onTap),
    );
  }
}
