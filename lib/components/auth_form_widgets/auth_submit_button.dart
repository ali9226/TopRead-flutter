// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/common_style/submit_button/index.dart';
import 'package:app/stores/authorized_login_store.dart';

/// 认证页提交按钮组件。
///
/// 根据 [isLoginMode] 动态切换按钮文案：
/// - 登录模式：显示"登录"
/// - 注册模式：显示"立即注册"
class AuthSubmitButton extends StatelessWidget {
  /// 是否为登录模式。
  final bool isLoginMode;

  /// 按钮点击回调。
  final VoidCallback onTap;

  /// 是否正在加载。
  final bool loading;

  const AuthSubmitButton({
    super.key,
    required this.isLoginMode,
    required this.onTap,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final AuthorizedLoginStore authorized_login_store =
        Get.find<AuthorizedLoginStore>();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final bool is_authentication_loading =
          authorized_login_store.loading.value;

      return CommonSubmitButton(
        title: isLoginMode
            ? context.tr('UserInfo.login')
            : context.tr('login.register_now'),
        isDark: isDark,
        loading: loading || is_authentication_loading,
        horizontalMargin: 20,
        onTap: is_authentication_loading ? null : onTap,
      );
    });
  }
}
