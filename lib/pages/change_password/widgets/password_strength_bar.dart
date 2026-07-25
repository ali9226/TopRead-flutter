import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/pages/change_password/style.dart';

/// 密码强度等级枚举。
enum PasswordStrengthLevel {
  /// 无输入。
  none,

  /// 弱（< 6位）。
  weak,

  /// 一般（6-8位，仅字母或数字）。
  fair,

  /// 良好（8-12位，含字母+数字）。
  good,

  /// 强（12位以上，含字母+数字+符号）。
  strong,
}

/// 密码强度条组件。
///
/// 根据输入密码的长度和复杂度，动态显示强度条和强度标签。
///
/// 参数说明：
/// [password] - 当前输入的密码文本。
/// [isDark] - 当前是否为夜间模式。
class PasswordStrengthBar extends StatelessWidget {
  /// 当前输入的密码文本。
  final String password;

  /// 当前是否为夜间模式。
  final bool isDark;

  const PasswordStrengthBar({
    super.key,
    required this.password,
    required this.isDark,
  });

  /// 计算密码强度等级。
  ///
  /// 判断逻辑：
  /// 1. 空密码 → none
  /// 2. < 6位 → weak
  /// 3. 6-8位，仅字母或数字 → fair
  /// 4. 8-12位，含字母+数字 → good
  /// 5. 12位以上，含字母+数字+符号 → strong
  PasswordStrengthLevel _calculateStrength() {
    if (password.isEmpty) return PasswordStrengthLevel.none;
    if (password.length < 6) return PasswordStrengthLevel.weak;

    final bool hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final bool hasDigit = RegExp(r'[0-9]').hasMatch(password);
    final bool hasSpecial = RegExp(r'[^a-zA-Z0-9]').hasMatch(password);

    if (password.length >= 12 && hasLetter && hasDigit && hasSpecial) {
      return PasswordStrengthLevel.strong;
    }
    if (password.length >= 8 && hasLetter && hasDigit) {
      return PasswordStrengthLevel.good;
    }
    return PasswordStrengthLevel.fair;
  }

  /// 获取强度等级对应的激活段数。
  int _getActiveSegments(PasswordStrengthLevel level) {
    switch (level) {
      case PasswordStrengthLevel.none:
        return 0;
      case PasswordStrengthLevel.weak:
        return 1;
      case PasswordStrengthLevel.fair:
        return 2;
      case PasswordStrengthLevel.good:
        return 3;
      case PasswordStrengthLevel.strong:
        return 4;
    }
  }

  /// 获取强度等级对应的颜色。
  Color _getStrengthColor(PasswordStrengthLevel level) {
    switch (level) {
      case PasswordStrengthLevel.none:
        return Style.strengthBarInactive(isDark: isDark);
      case PasswordStrengthLevel.weak:
        return Style.strengthWeak;
      case PasswordStrengthLevel.fair:
        return Style.strengthFair;
      case PasswordStrengthLevel.good:
        return Style.strengthGood;
      case PasswordStrengthLevel.strong:
        return Style.strengthStrong;
    }
  }

  /// 获取强度等级对应的标签文本。
  String _getStrengthLabel(PasswordStrengthLevel level) {
    switch (level) {
      case PasswordStrengthLevel.none:
        return '';
      case PasswordStrengthLevel.weak:
        return easy.tr('UserInfo.strength_weak');
      case PasswordStrengthLevel.fair:
        return easy.tr('UserInfo.strength_fair');
      case PasswordStrengthLevel.good:
        return easy.tr('UserInfo.strength_good');
      case PasswordStrengthLevel.strong:
        return easy.tr('UserInfo.strength_strong');
    }
  }

  @override
  Widget build(BuildContext context) {
    final PasswordStrengthLevel level = _calculateStrength();
    final int activeSegments = _getActiveSegments(level);
    final Color activeColor = _getStrengthColor(level);
    final String label = _getStrengthLabel(level);

    return Row(
      children: <Widget>[
        /// "密码强度："标签。
        Text(
          easy.tr('UserInfo.password_strength'),
          style: TextStyle(
            fontSize: Style.strengthLabelSize,
            fontWeight: Style.strengthLabelWeight,
            color: Style.strengthLabelColor(isDark: isDark),
          ),
        ),

        /// 标签与色块间距。
        SizedBox(width: Style.strengthLabelBarGap),

        /// 强度条。
        Expanded(
          child: Row(
            children: List<Widget>.generate(
              Style.strengthBarSegments,
              (int index) {
                final bool isActive = index < activeSegments;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index < Style.strengthBarSegments - 1
                          ? Style.strengthBarSegmentGap
                          : 0,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      height: Style.strengthBarHeight,
                      decoration: BoxDecoration(
                        color: isActive
                            ? activeColor
                            : Style.strengthBarInactive(isDark: isDark),
                        borderRadius: BorderRadius.circular(
                          Style.strengthBarRadius,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        /// 强度等级标签。
        if (label.isNotEmpty) ...<Widget>[
          SizedBox(width: Style.strengthLabelGap),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              label,
              key: ValueKey<String>(label),
              style: TextStyle(
                fontSize: Style.strengthLabelSize,
                fontWeight: Style.strengthLabelWeight,
                color: activeColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
