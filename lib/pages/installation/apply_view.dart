import 'dart:async';

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/common_style/auth_text/style.dart';
import 'package:app/common_style/submit_button/index.dart';
import 'package:app/components/auth_page/index.dart';
import 'package:app/components/auth_page/style.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/router/router_util.dart';

import 'logic.dart';
import 'style.dart';

/// 申请成为作家表单。
///
/// [onSuccess] 提交成功后的回调。
/// [initialEmail] 预填邮箱地址。
class ApplyView extends StatefulWidget {
  final VoidCallback? onSuccess;
  final String initialEmail;

  const ApplyView({super.key, this.onSuccess, this.initialEmail = ''});

  @override
  State<ApplyView> createState() => _ApplyViewState();
}

class _ApplyViewState extends State<ApplyView> {
  // ==================== 控制器 ====================

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _introductionController =
      TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _codeFocusNode = FocusNode();
  final FocusNode _introductionFocusNode = FocusNode();

  // ==================== 状态 ====================

  bool _isSubmitting = false;
  bool _isSendingCode = false;
  int _countdownSeconds = 0;
  Timer? _countdownTimer;
  final DeviceInfo _deviceInfo = Get.find<DeviceInfo>();
  late Logic _logic;

  // ==================== 生命周期 ====================

  @override
  void initState() {
    super.initState();
    _logic = Logic(context);
    if (widget.initialEmail.isNotEmpty) {
      _emailController.text = widget.initialEmail;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _introductionController.dispose();
    _emailFocusNode.dispose();
    _codeFocusNode.dispose();
    _introductionFocusNode.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ==================== 回调方法 ====================

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _startCountdown() {
    setState(() => _countdownSeconds = 120);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _countdownSeconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _countdownSeconds--);
    });
  }

  Future<void> _handleSendCode() async {
    if (_isSendingCode) return;
    _dismissKeyboard();
    final emailError = _logic.validate_email(_emailController.text);
    if (emailError != null) {
      showBottomTip(emailError);
      return;
    }
    setState(() => _isSendingCode = true);
    try {
      final success = await _logic.send_verification_code(_emailController.text);
      if (success) _startCountdown();
    } finally {
      if (mounted) setState(() => _isSendingCode = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    _dismissKeyboard();

    final emailError = _logic.validate_email(_emailController.text);
    if (emailError != null) {
      showBottomTip(emailError);
      return;
    }
    final codeError = _logic.validate_code(_codeController.text);
    if (codeError != null) {
      showBottomTip(codeError);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await _logic.submit_application(
        email: _emailController.text,
        code: _codeController.text,
        introduction: _introductionController.text,
      );
      final bool success = result['success'] ?? false;
      final String message = result['message'] ?? '';
      if (mounted && message.isNotEmpty) {
        showBottomTip(message);
      }
      if (success && mounted) {
        widget.onSuccess?.call();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ==================== 构建方法 ====================

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// 品牌区域（Logo + 标题 + 副标题）。
        _buildBrandSection(),

        /// 联系邮箱。
        AuthFieldLabel(
          iconName: 'account',
          title: easy.tr('installation.email'),
        ),
        _buildEmailField(),
        const SizedBox(height: Style.sectionSpacing),

        /// 验证码。
        const SizedBox(height: 10),
        AuthFieldLabel(
          iconName: 'password',
          title: easy.tr('installation.verify_code'),
        ),
        _buildCodeField(),
        const SizedBox(height: Style.sectionSpacing),

        /// 自我介绍。
        const SizedBox(height: 10),
        AuthFieldLabel(
          iconName: 'account',
          title: easy.tr('installation.introduction'),
        ),
        _buildIntroductionField(),
        const SizedBox(height: Style.largeSpacing),

        /// 提交按钮。
        CommonSubmitButton(
          title: easy.tr('installation.submit'),
          isDark: _deviceInfo.dark.value,
          loading: _isSubmitting,
          horizontalMargin: Style.buttonHorizontalMargin,
          onTap: _handleSubmit,
        ),

        /// 协议文字。
        const SizedBox(height: 16),
        _buildAgreementText(),

        /// 底部留白。
        const SizedBox(height: 40),
      ],
    );
  }

  /// 构建品牌区域。
  Widget _buildBrandSection() {
    return Obx(() {
      final bool isDark = _deviceInfo.dark.value;
      final Color logoColor = AuthPageStyle.primaryTextColor(isDark);
      final Color textColor = AuthPageStyle.primaryTextColor(isDark);

      return Column(
        children: [
          const SizedBox(height: AuthPageStyle.brandTopSpacing),
          const SizedBox(height: 30),

          /// Logo。
          Center(
            child: SvgIcon(
              name: 'logo',
              color: logoColor,
              width: AuthPageStyle.logoSize,
              height: AuthPageStyle.logoHeightSize,
            ),
          ),

          /// 副标题（带装饰线）。
          const SizedBox(height: 12),
          _buildSloganRow(isDark, textColor),

          const SizedBox(height: 30),
        ],
      );
    });
  }

  /// 构建副标题装饰行（左右渐变线 + 中间文字）。
  Widget _buildSloganRow(bool isDark, Color textColor) {
    final String localeCode = context.locale.languageCode;
    final bool isCjk = LanguageUtil.is_cjk_language(localeCode);

    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// 左侧渐变装饰线。
          Container(
            width: AuthPageStyle.sloganWidth,
            height: AuthPageStyle.sloganHeight,
            decoration: AuthPageStyle.sloganGradientBar(
              isDark: isDark,
              reverse: false,
            ),
          ),

          /// 中间副标题文字。
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              easy.tr('installation.subtitle'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                height: isCjk ? 1.5 : 1.65,
              ),
            ),
          ),

          /// 右侧渐变装饰线。
          const SizedBox(width: 12),
          Container(
            width: AuthPageStyle.sloganWidth,
            height: AuthPageStyle.sloganHeight,
            decoration: AuthPageStyle.sloganGradientBar(
              isDark: isDark,
              reverse: true,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建邮箱输入框。
  Widget _buildEmailField() {
    return Obx(() {
      final bool isDark = _deviceInfo.dark.value;
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AuthPageStyle.fieldHorizontalPadding,
        ),
        child: TextField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _codeFocusNode.requestFocus(),
          cursorColor: ColorConstants.themeColor,
          style: TextStyle(
            fontSize: Style.inputFontSize,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
          ),
          decoration: InputDecoration(
            hintText: easy.tr('installation.email_hint'),
            hintStyle: TextStyle(
              color: AuthPageStyle.hintColor(isDark),
              fontSize: Style.inputFontSize,
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
          ),
        ),
      );
    });
  }

  /// 构建验证码输入框（输入框 + 发送按钮）。
  Widget _buildCodeField() {
    return Obx(() {
      final bool isDark = _deviceInfo.dark.value;
      final bool canSend = _countdownSeconds == 0;

      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AuthPageStyle.fieldHorizontalPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            /// 验证码输入框。
            Expanded(
              child: TextField(
                controller: _codeController,
                focusNode: _codeFocusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _introductionFocusNode.requestFocus(),
                cursorColor: ColorConstants.themeColor,
                style: TextStyle(
                  fontSize: Style.inputFontSize,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                  letterSpacing: 6,
                ),
                decoration: InputDecoration(
                  hintText: easy.tr('installation.verify_code_hint'),
                  hintStyle: TextStyle(
                    color: AuthPageStyle.hintColor(isDark),
                    fontSize: Style.inputFontSize,
                    letterSpacing: 0,
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
                ),
              ),
            ),

            /// 发送验证码按钮。
            const SizedBox(width: 16),
            GestureDetector(
              onTap: (canSend && !_isSendingCode) ? _handleSendCode : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: ColorConstants.themeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _isSendingCode
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColorConstants.lightTextColor,
                        ),
                      )
                    : Text(
                        canSend
                            ? easy.tr('installation.send_code')
                            : '${_countdownSeconds}s',
                        style: TextStyle(
                          fontSize: Style.sendCodeFontSize,
                          fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                          color: ColorConstants.lightTextColor,
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 构建自我介绍输入框（多行）。
  Widget _buildIntroductionField() {
    return Obx(() {
      final bool isDark = _deviceInfo.dark.value;
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AuthPageStyle.fieldHorizontalPadding,
        ),
        child: TextField(
          controller: _introductionController,
          focusNode: _introductionFocusNode,
          maxLines: 4,
          minLines: 3,
          cursorColor: ColorConstants.themeColor,
          style: TextStyle(
            fontSize: Style.inputFontSize,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
          ),
          decoration: InputDecoration(
            hintText: easy.tr('installation.introduction_hint'),
            hintStyle: TextStyle(
              color: AuthPageStyle.hintColor(isDark),
              fontSize: Style.inputFontSize,
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
          ),
        ),
      );
    });
  }

  /// 构建协议文字。
  Widget _buildAgreementText() {
    return Obx(() {
      final bool isDark = _deviceInfo.dark.value;
      final Color textColor = AuthTextStyle.textColor(isDark: isDark);
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: AuthTextStyle.fontSize,
                height: Style.agreementHeight,
                color: textColor,
                fontWeight: AuthTextStyle.fontWeight,
              ),
              children: [
                TextSpan(text: easy.tr('installation.agreement_prefix')),
                TextSpan(
                  text: easy.tr('installation.agreement_link'),
                  style: TextStyle(
                    color: ColorConstants.dangerColor,
                    fontWeight: AuthTextStyle.actionFontWeight,
                    decoration: TextDecoration.underline,
                    decorationColor: ColorConstants.dangerColor,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      routerUtil(path: '/image_text?type=62');
                    },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
