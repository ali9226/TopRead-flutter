import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/auth_form_widgets/auth_top_bar.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/stores/authorized_login_store.dart';
import 'package:app/stores/device_info.dart';

import 'style.dart';
import 'package:app/config/font_config.dart';

/// 认证页通用外壳。
class AuthPageScaffold extends StatelessWidget {
  final List<AuthBackgroundBubble> backgroundBubbles;
  final List<Widget> children;

  const AuthPageScaffold({
    super.key,
    required this.backgroundBubbles,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final deviceInfo = Get.find<DeviceInfo>();

    return Obx(() {
      final bool isDark = deviceInfo.dark.value;
      final List<Color> backgroundColors = AuthPageStyle.backgroundGradient(
        isDark,
      );
      final double safeTop = MediaQuery.paddingOf(context).top;

      return Scaffold(
        backgroundColor: backgroundColors.last,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _dismissKeyboard,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: backgroundColors,
                    ),
                  ),
                ),
              ),
              ...backgroundBubbles.map(
                (AuthBackgroundBubble bubble) =>
                    _AuthBackgroundBubble(bubble: bubble, isDark: isDark),
              ),
              SingleChildScrollView(
                padding: AuthPageStyle.contentPadding.add(
                  EdgeInsets.only(
                    top:
                        safeTop +
                        AuthPageStyle.topHeaderHeight +
                        AuthPageStyle.brandTranslateY,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
              const AuthTopBar(),
            ],
          ),
        ),
      );
    });
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}

/// 认证页字段标题。
class AuthFieldLabel extends StatelessWidget {
  final String iconName;
  final String title;

  const AuthFieldLabel({
    super.key,
    required this.iconName,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final deviceInfo = Get.find<DeviceInfo>();

    return Obx(() {
      final bool isDark = deviceInfo.dark.value;
      final Color textColor = AuthPageStyle.primaryTextColor(isDark);

      return Row(
        children: [
          const SizedBox(width: AuthPageStyle.fieldHorizontalPadding),
          SvgIcon(
            name: iconName,
            color: textColor,
            width: AuthPageStyle.fieldIconSize,
            height: AuthPageStyle.fieldIconSize,
          ),
          const SizedBox(width: 7),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            ),
          ),
        ],
      );
    });
  }
}

/// 认证页复用输入框。
class AuthTextField extends StatefulWidget {
  final bool password;
  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;

  const AuthTextField({
    super.key,
    this.password = false,
    this.hintText = '',
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  final DeviceInfo _deviceInfo = Get.find<DeviceInfo>();
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isDark = _deviceInfo.dark.value;

      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AuthPageStyle.fieldHorizontalPadding,
        ),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, child) {
            return TextField(
              controller: _controller,
              focusNode: _focusNode,
              obscureText: widget.password && _obscureText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              ),
              cursorColor: ColorConstants.themeColor,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: AuthPageStyle.hintColor(isDark),
                  fontSize: 15,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AuthPageStyle.inputBorderColor(isDark),
                    width: 1,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: ColorConstants.themeColor,
                    width: 1,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                suffixIcon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: value.text.isEmpty
                      ? const SizedBox.shrink(key: ValueKey('empty'))
                      : Row(
                          key: ValueKey('icons_${value.text}_$_obscureText'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _clearText,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: SvgIcon(
                                  name: 'clear_02',
                                  color: AuthPageStyle.passwordIconColor,
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                            ),
                            if (widget.password)
                              GestureDetector(
                                onTap: _toggleObscureText,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: SvgIcon(
                                    key: ValueKey(
                                      _obscureText ? 'show' : 'hide',
                                    ),
                                    name: _obscureText
                                        ? 'show_password'
                                        : 'hide_password',
                                    color: AuthPageStyle.passwordIconColor,
                                    width: AuthPageStyle.passwordIconSize,
                                    height: AuthPageStyle.passwordIconSize,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted != null
                  ? (_) => widget.onSubmitted!()
                  : null,
            );
          },
        ),
      );
    });
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
    _focusNode.requestFocus();
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }
}

/// 登录页“记住密码 / 忘记密码”区。
class AuthRememberRow extends StatelessWidget {
  final bool remember;
  final VoidCallback onToggleRemember;
  final VoidCallback onTapForgotPassword;

  const AuthRememberRow({
    super.key,
    required this.remember,
    required this.onToggleRemember,
    required this.onTapForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    final deviceInfo = Get.find<DeviceInfo>();

    return Obx(() {
      final bool isDark = deviceInfo.dark.value;
      final Color textColor = AuthPageStyle.primaryTextColor(isDark);

      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onToggleRemember,
              behavior: HitTestBehavior.translucent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: AuthPageStyle.fieldHorizontalPadding),
                  Container(
                    width: AuthPageStyle.rememberSize,
                    height: AuthPageStyle.rememberSize,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: remember ? ColorConstants.themeColor : textColor,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      color: remember
                          ? ColorConstants.themeColor
                          : Colors.transparent,
                    ),
                    child: remember
                        ? Icon(
                            Icons.check,
                            size: 14,
                            color: isDark
                                ? ColorConstants.nightBackgroundColor
                                : ColorConstants.whiteColor,
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      easy.tr('login.remember_password'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: onTapForgotPassword,
              behavior: HitTestBehavior.translucent,
              child: Text(
                easy.tr('login.forgot_password'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  decoration: TextDecoration.underline,
                  decorationColor: textColor,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// 认证页底部跳转区。
class AuthFooterAction extends StatelessWidget {
  final String promptText;
  final String actionText;
  final VoidCallback onTap;

  const AuthFooterAction({
    super.key,
    required this.promptText,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final DeviceInfo deviceInfo = Get.find<DeviceInfo>();
    final AuthorizedLoginStore authorizedLoginStore =
        Get.find<AuthorizedLoginStore>();

    return Obx(() {
      final bool isDark = deviceInfo.dark.value;
      final bool enabled = !authorizedLoginStore.loading.value;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            promptText,
            style: TextStyle(
              fontSize: AuthPageStyle.footerPromptFontSize,
              color: isDark
                  ? ColorConstants.nightTextColor
                  : ColorConstants.lightTextColor,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            enabled: enabled,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: enabled ? 1 : 0.38,
              child: GestureDetector(
                onTap: enabled ? onTap : null,
                child: Text(
                  actionText,
                  style: TextStyle(
                    fontSize: AuthPageStyle.footerPromptFontSize,
                    color: ColorConstants.dangerColor,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                    decoration: TextDecoration.underline,
                    decorationColor: ColorConstants.dangerColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _AuthBackgroundBubble extends StatelessWidget {
  final AuthBackgroundBubble bubble;
  final bool isDark;

  const _AuthBackgroundBubble({required this.bubble, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: bubble.top,
      right: bubble.right,
      bottom: bubble.bottom,
      left: bubble.left,
      child: IgnorePointer(
        child: Container(
          width: bubble.width,
          height: bubble.height,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bubble.color.withValues(
              alpha: isDark ? bubble.darkOpacity : bubble.lightOpacity,
            ),
          ),
        ),
      ),
    );
  }
}
