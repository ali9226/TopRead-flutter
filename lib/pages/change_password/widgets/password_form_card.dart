import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import 'package:app/pages/change_password/widgets/password_field.dart';
import 'package:app/pages/change_password/widgets/password_strength_bar.dart';

/// 修改密码页面表单组件。
///
/// 包含新密码输入框、密码强度条和确认密码输入框。
/// 参考登录页样式，不使用卡片包裹。
class PasswordFormCard extends StatelessWidget {
    final TextEditingController newPasswordController;
    final TextEditingController confirmPasswordController;
    final FocusNode newPasswordFocusNode;
    final FocusNode confirmPasswordFocusNode;
    final bool newPasswordObscured;
    final bool confirmPasswordObscured;
    final bool isDark;
    final ValueChanged<String>? onChanged;
    final ValueChanged<String>? onNewPasswordSubmitted;
    final ValueChanged<String>? onConfirmPasswordSubmitted;
    final VoidCallback? onNewPasswordVisibilityTap;
    final VoidCallback? onConfirmPasswordVisibilityTap;

    const PasswordFormCard({
        super.key,
        required this.newPasswordController,
        required this.confirmPasswordController,
        required this.newPasswordFocusNode,
        required this.confirmPasswordFocusNode,
        required this.newPasswordObscured,
        required this.confirmPasswordObscured,
        required this.isDark,
        this.onChanged,
        this.onNewPasswordSubmitted,
        this.onConfirmPasswordSubmitted,
        this.onNewPasswordVisibilityTap,
        this.onConfirmPasswordVisibilityTap,
    });

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                    // TODO 新密码输入框
                    PasswordField(
                        label: easy.tr('UserInfo.new_password_label'),
                        hintText: easy.tr('UserInfo.tips_02'),
                        controller: newPasswordController,
                        focusNode: newPasswordFocusNode,
                        obscureText: newPasswordObscured,
                        isDark: isDark,
                        textAction: TextInputAction.next,
                        onChanged: onChanged,
                        onSubmitted: onNewPasswordSubmitted,
                        onVisibilityTap: onNewPasswordVisibilityTap,
                    ),

                    // TODO 密码强度条
                    const SizedBox(height: 10),
                    PasswordStrengthBar(
                        password: newPasswordController.text,
                        isDark: isDark,
                    ),

                    // TODO 间距
                    const SizedBox(height: 20),

                    // TODO 确认密码输入框
                    PasswordField(
                        label: easy.tr('UserInfo.confirm_password_label'),
                        hintText: easy.tr('UserInfo.tips_06'),
                        controller: confirmPasswordController,
                        focusNode: confirmPasswordFocusNode,
                        obscureText: confirmPasswordObscured,
                        isDark: isDark,
                        textAction: TextInputAction.done,
                        onChanged: onChanged,
                        onSubmitted: onConfirmPasswordSubmitted,
                        onVisibilityTap: onConfirmPasswordVisibilityTap,
                    ),
                ],
            ),
        );
    }
}
