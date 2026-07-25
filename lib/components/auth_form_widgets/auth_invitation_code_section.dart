// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/components/auth_page/index.dart';
import 'package:app/pages/register/style.dart';

/// 邀请码输入模块组件。
///
/// 在登录页账号未注册时显示，用于收集邀请码。
/// 使用过渡动画平滑显示/隐藏。
class AuthInvitationCodeSection extends StatelessWidget {
  /// 是否显示邀请码模块。
  final bool show;

  /// 邀请码输入框控制器。
  final TextEditingController controller;

  /// 邀请码变化回调。
  final ValueChanged<String>? onChanged;

  const AuthInvitationCodeSection({
    super.key,
    required this.show,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: show
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Style.sectionSpacing),
                AuthFieldLabel(
                  iconName: 'invitation_code',
                  title: context.tr('register.invitation_code'),
                ),
                AuthTextField(
                  controller: controller,
                  hintText: context.tr('register.invitation_code_input_tips'),
                  onChanged: onChanged,
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}
