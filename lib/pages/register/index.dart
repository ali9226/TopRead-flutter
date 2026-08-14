// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:app/components/auth_page/index.dart';
import 'package:app/components/auth_page/style.dart';
import 'package:app/components/auth_form_widgets/index.dart';
import 'package:app/components/authorized_login/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/stores/authorized_login_store.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/util/router/web_history.dart';
import 'package:get/get.dart';

import 'logic.dart';
import 'style.dart';

/// 路由：`/register`
///
/// 注册页组合 UI，由 `logic.dart` 处理具体的接口交互。
class Register extends StatefulWidget {
  final String? c;
  const Register({super.key, this.c});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  /// 提交按钮 loading 状态。
  bool loading = false;

  /// 用户协议勾选状态。
  bool _isAgreed = false;

  /// 登录、注册及第三方授权共用的认证互斥状态。
  final AuthorizedLoginStore authorized_login_store =
      Get.find<AuthorizedLoginStore>();

  /// 注册页逻辑层。
  late final Logic logic;

  /// 账号输入框控制器。
  late final TextEditingController accountController;

  /// 密码输入框控制器。
  late final TextEditingController passwordController;

  /// 邀请码输入框控制器。
  late final TextEditingController invitationController;

  /// 账号输入框焦点节点。
  late final FocusNode accountFocusNode;

  /// 密码输入框焦点节点。
  late final FocusNode passwordFocusNode;

  @override
  void initState() {
    super.initState();
    logic = Logic();

    /// 如果路由带了邀请码（c），自动填入逻辑层。
    if (widget.c != null) {
      logic.invitationCode = widget.c!;
    }

    accountController = TextEditingController();
    passwordController = TextEditingController();
    invitationController = TextEditingController(text: logic.invitationCode);
    accountFocusNode = FocusNode();
    passwordFocusNode = FocusNode();

    /// 监听账号输入框焦点变化，失去焦点时验证账号。
    accountFocusNode.addListener(_onAccountFocusChange);
  }

  @override
  void dispose() {
    accountController.dispose();
    passwordController.dispose();
    invitationController.dispose();
    accountFocusNode.removeListener(_onAccountFocusChange);
    accountFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  /// 账号输入框焦点变化回调。
  void _onAccountFocusChange() {
    /// 焦点失去时验证账号。
    if (!accountFocusNode.hasFocus && logic.account.isNotEmpty) {
      _verifyAccount();
    }
  }

  /// 验证账号是否已注册。
  Future<void> _verifyAccount() async {
    await logic.verifyAccount();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    /// 根据账号注册状态决定显示注册还是登录模式。
    final bool isRegisterMode = logic.isAccountRegistered != true;

    return AuthPageScaffold(
      backgroundBubbles: AuthPageStyle.registerBubbles,
      children: [
        const AuthBrandSection(),

        /// 账号输入区。
        AuthFieldLabel(iconName: 'account', title: context.tr('login.account')),
        AuthTextField(
          controller: accountController,
          focusNode: accountFocusNode,
          hintText: context.tr('login.account_tips'),
          onChanged: (String value) {
            logic.account = value;

            /// 输入变化时重置验证状态。
            if (logic.isAccountRegistered != null) {
              setState(() {
                logic.isAccountRegistered = null;
              });
            }
          },
          onSubmitted: () {
            /// 点击回车时切换到密码输入框。
            passwordFocusNode.requestFocus();
          },
        ),

        /// 账号状态提示。
        AuthAccountStatusHint(
          show: logic.isAccountRegistered == true,
          message: context.tr('login.account_already_registered'),
          isWarning: false,
        ),
        const SizedBox(height: Style.sectionSpacing),

        /// 密码输入区。
        AuthFieldLabel(
          iconName: 'password',
          title: context.tr('login.password'),
        ),
        AuthTextField(
          controller: passwordController,
          focusNode: passwordFocusNode,
          hintText: context.tr('login.password_tips'),
          password: true,
          onChanged: (String value) => logic.password = value,
          onSubmitted: () {
            /// 点击回车时收起键盘并触发注册/登录。
            passwordFocusNode.unfocus();
            if (logic.isAccountRegistered == true) {
              _handleLogin();
            } else {
              _handleRegister();
            }
          },
        ),

        /// 邀请码输入区（账号未注册时显示）。
        AuthInvitationCodeSection(
          show: isRegisterMode,
          controller: invitationController,
          onChanged: (String value) => logic.invitationCode = value,
        ),
        const SizedBox(height: Style.footerSpacing),

        /// 主提交按钮（根据模式切换文案）。
        AuthSubmitButton(
          isLoginMode: !isRegisterMode,
          loading: loading,
          onTap: isRegisterMode ? _handleRegister : _handleLogin,
        ),

        /// 用户协议勾选框（仅注册模式显示）。
        if (isRegisterMode) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AuthPageStyle.fieldHorizontalPadding,
            ),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isAgreed = !_isAgreed;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// 勾选框。
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isAgreed
                            ? ColorConstants.themeColor
                            : ColorConstants.lightTextColor.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(3),
                      color: _isAgreed
                          ? ColorConstants.themeColor
                          : Colors.transparent,
                    ),
                    child: _isAgreed
                        ? const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),

                  /// 协议文字。
                  Flexible(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: ColorConstants.lightTextColor,
                          fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                        ),
                        children: [
                          TextSpan(
                            text: context.tr('register.agreement_prefix'),
                          ),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {
                                routerUtil(path: '/image_text?type=60');
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: Text(
                                  context.tr('register.user_agreement'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ColorConstants.dangerColor,
                                    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                                    decoration: TextDecoration.underline,
                                    decorationColor: ColorConstants.dangerColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        /// 底部跳转入口（根据模式切换文案）。
        AuthFooterAction(
          promptText: isRegisterMode
              ? context.tr('register.account_tips')
              : context.tr('login.no_account_tips'),
          actionText: isRegisterMode
              ? context.tr('register.login_now')
              : context.tr('login.register_now'),
          onTap: isRegisterMode ? _goToLogin : _switchToRegisterMode,
        ),
        const SizedBox(height: Style.supportSpacing),
        AuthorizedLoginView(),
        const SizedBox(height: 30),
      ],
    );
  }

  /// 提交注册请求并在成功后跳转首页。
  Future<void> _handleRegister() async {
    /// 未勾选用户协议时提示。
    if (!_isAgreed) {
      showBottomTip(context.tr('register.agreement_required'));
      return;
    }

    /// 提交前收起键盘。
    FocusScope.of(context).unfocus();

    /// 占用全局认证锁，阻止第三方授权与账号注册并发执行。
    if (!authorized_login_store.try_start_authentication('register')) return;

    setState(() {
      /// 打开 loading。
      loading = true;
    });

    bool registerStatus = false;
    try {
      /// 让 loading 先渲染，再执行异步注册。
      await Future<void>.delayed(Duration.zero);
      registerStatus = await logic.registerFun();
    } finally {
      authorized_login_store.finish_authentication('register');
      if (mounted) {
        setState(() {
          /// 请求结束后关闭 loading。
          loading = false;
        });
      }
    }

    /// 注册失败时逻辑层内部已提示。
    if (!mounted || !registerStatus) return;

    /// 注册成功后进入独立的兴趣偏好引导，并清理注册页路由历史。
    routerUtil(path: '/registration_interest_preference', type: 'go');
  }

  /// 提交登录请求（账号已注册时使用）。
  Future<void> _handleLogin() async {
    /// 提交前收起键盘。
    FocusScope.of(context).unfocus();

    /// 占用全局认证锁，阻止第三方授权与账号登录并发执行。
    if (!authorized_login_store.try_start_authentication('login')) return;

    setState(() {
      /// 打开 loading。
      loading = true;
    });

    bool loginStatus = false;
    try {
      /// 让 loading 先渲染，再执行异步登录。
      await Future<void>.delayed(Duration.zero);
      loginStatus = await logic.login();
    } finally {
      authorized_login_store.finish_authentication('login');
      if (mounted) {
        setState(() {
          /// 请求结束后关闭 loading。
          loading = false;
        });
      }
    }

    /// 登录失败时逻辑层内部已提示。
    if (!mounted || !loginStatus) return;

    /// 登录成功后跳转首页。
    routerUtil(path: '/', type: 'replace');
  }

  /// 注册页底部跳转回登录页。
  void _goToLogin() {
    if (authorized_login_store.loading.value) return;

    if (kIsWeb) {
      /// Web 端直接替换浏览器地址。
      browserReplaceState('/login');
      return;
    }

    /// 非 Web 端替换到登录页。
    routerUtil(path: '/login', type: 'replace');
  }

  /// 切换回注册模式（清空账号、重置状态、关闭输入法）。
  void _switchToRegisterMode() {
    if (authorized_login_store.loading.value) return;

    /// 关闭输入法，取消所有输入框焦点。
    FocusScope.of(context).unfocus();

    setState(() {
      accountController.clear();
      logic.account = '';
      logic.isAccountRegistered = null;
    });
  }
}
