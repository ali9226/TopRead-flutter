import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/color_config.dart';

/// 密码输入框组件。
///
/// 参考登录页 AuthTextField 样式：下划线边框、右侧清除和眼睛图标。
///
/// 参数说明：
/// [label] - 字段标签文本。
/// [hintText] - 输入框占位提示文本。
/// [controller] - 文本控制器。
/// [focusNode] - 焦点节点。
/// [obscureText] - 是否隐藏输入内容。
/// [isDark] - 当前是否为夜间模式。
/// [textAction] - 键盘动作类型。
/// [onChanged] - 输入变化回调。
/// [onSubmitted] - 键盘提交回调。
/// [onVisibilityTap] - 点击眼睛图标切换显隐的回调。
class PasswordField extends StatelessWidget {
    final String label;
    final String hintText;
    final TextEditingController controller;
    final FocusNode focusNode;
    final bool obscureText;
    final bool isDark;
    final TextInputAction textAction;
    final ValueChanged<String>? onChanged;
    final ValueChanged<String>? onSubmitted;
    final VoidCallback? onVisibilityTap;

    const PasswordField({
        super.key,
        required this.label,
        required this.hintText,
        required this.controller,
        required this.focusNode,
        required this.obscureText,
        required this.isDark,
        this.textAction = TextInputAction.next,
        this.onChanged,
        this.onSubmitted,
        this.onVisibilityTap,
    });

    @override
    Widget build(BuildContext context) {
        final bool hasText = controller.text.isNotEmpty;

        // TODO 下划线边框颜色（参考登录页）
        final Color border_color = isDark
            ? ColorConstants.nightTextColor
            : Colors.black.withOpacity(0.2);

        // TODO 提示文字颜色（参考登录页）
        final Color hint_color = isDark
            ? Colors.grey.shade400
            : Colors.grey.shade600;

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
                // TODO 字段标签
                Text(
                    label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                        color: isDark
                            ? ColorConstants.whiteColor.withOpacity(0.85)
                            : ColorConstants.lightTextColor.withOpacity(0.88),
                    ),
                ),
                // TODO 输入框（下划线样式，参考登录页）
                TextField(
                    controller: controller,
                    focusNode: focusNode,
                    obscureText: obscureText,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: textAction,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    cursorColor: ColorConstants.themeColor,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                    ),
                    decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: TextStyle(
                            color: hint_color,
                            fontSize: 15,
                        ),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: border_color, width: 1),
                        ),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: ColorConstants.themeColor, width: 1),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                                // TODO 一键清除图标
                                if (hasText)
                                    GestureDetector(
                                        onTap: () {
                                            controller.clear();
                                            onChanged?.call('');
                                        },
                                        child: Padding(
                                            padding: const EdgeInsets.only(right: 4),
                                            child: Icon(
                                                Icons.close_rounded,
                                                size: 18,
                                                color: isDark
                                                    ? Colors.white.withOpacity(0.6)
                                                    : ColorConstants.hintColor,
                                            ),
                                        ),
                                    ),
                                // TODO 密码显隐切换图标
                                Padding(
                                    padding: const EdgeInsets.only(right: 18),
                                    child: GestureDetector(
                                        onTap: onVisibilityTap,
                                        child: Icon(
                                            obscureText
                                                ? Icons.visibility_off_rounded
                                                : Icons.visibility_rounded,
                                            size: 20,
                                            color: isDark
                                                ? Colors.white.withOpacity(0.6)
                                                : ColorConstants.hintColor,
                                        ),
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
            ],
        );
    }
}
