import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/common_style/submit_button/index.dart';

/// 修改密码页面确认修改按钮组件。
///
/// 复用全局统一提交按钮样式，保证与登录、注册等页面一致。
///
/// 参数说明：
/// [isLoading] - 是否处于提交加载状态。
/// [isDark] - 当前是否为夜间模式。
/// [onPressed] - 点击提交回调。
class SubmitButton extends StatelessWidget {
  /// 是否处于提交加载状态。
  final bool isLoading;

  /// 当前是否为夜间模式。
  final bool isDark;

  /// 点击提交回调。
  final VoidCallback? onPressed;

  const SubmitButton({
    super.key,
    required this.isLoading,
    required this.isDark,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CommonSubmitButton(
      title: easy.tr('UserInfo.confirm_change'),
      isDark: isDark,
      loading: isLoading,
      onTap: onPressed,
    );
  }
}
