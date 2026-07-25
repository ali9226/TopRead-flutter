// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';

/// 账号状态提示组件。
///
/// 在登录页显示"账号未注册"提示，在注册页显示"账号已注册"提示。
/// 使用过渡动画平滑显示/隐藏。
class AuthAccountStatusHint extends StatelessWidget {
  /// 是否显示提示。
  final bool show;

  /// 提示文案。
  final String message;

  /// 提示类型：true 表示警告（未注册），false 表示信息（已注册）。
  final bool isWarning;

  const AuthAccountStatusHint({
    super.key,
    required this.show,
    required this.message,
    this.isWarning = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: show
          ? Padding(
              padding: const EdgeInsets.only(top: 8, left: 20, right: 20),
              child: Row(
                children: [
                  Icon(
                    isWarning
                        ? Icons.info_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 14,
                    color: isWarning
                        ? ColorConstants.dangerColor
                        : ColorConstants.successColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: isWarning
                            ? ColorConstants.dangerColor
                            : ColorConstants.successColor,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
