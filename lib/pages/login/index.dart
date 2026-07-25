// ignore_for_file: non_constant_identifier_names

import 'package:app/stores/authorized_login_store.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:app/components/auth_page/index.dart';
import 'package:app/components/auth_page/style.dart';
import 'package:app/components/auth_form_widgets/index.dart';
import 'package:app/components/authorized_login/index.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/util/router/web_history.dart';
import 'package:get/get.dart';

import 'logic.dart';
import 'style.dart';

/// 路由：`/login`
///
/// 登录页只负责组合 UI，账号恢复、请求发送、缓存写入都集中在 `logic.dart`。
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  /// 提交按钮 loading 状态。
  bool loading = false;

  /// 登录页逻辑层。
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

    /// 初始化逻辑层与输入控制器。
    logic = Logic();
    accountController = TextEditingController();
    passwordController = TextEditingController();
    invitationController = TextEditingController();
    accountFocusNode = FocusNode();
    passwordFocusNode = FocusNode();

    /// 把控制器交给逻辑层，便于逻辑层恢复缓存数据。
    logic.accountController = accountController;
    logic.passwordController = passwordController;

    /// 监听账号输入框焦点变化，失去焦点时验证账号。
    accountFocusNode.addListener(_onAccountFocusChange);

    logic.init().then((_) {
      /// 初始化完成后刷新 UI，展示恢复出的账号密码。
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    /// 释放输入框控制器。
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
    /// 根据账号注册状态决定显示登录还是注册模式。
    final bool isLoginMode = logic.isAccountRegistered != false;

    return AuthPageScaffold(
      backgroundBubbles: AuthPageStyle.loginBubbles,
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
          show: logic.isAccountRegistered == false,
          message: context.tr('login.account_not_registered'),
          isWarning: true,
        ),
        const SizedBox(height: Style.sectionSpacing),

        /// 密码输入区。
        AuthFieldLabel(iconName: 'password', title: context.tr('login.password')),
        AuthTextField(
          controller: passwordController,
          focusNode: passwordFocusNode,
          hintText: context.tr('login.password_tips'),
          password: true,
          onChanged: (String value) => logic.password = value,
          onSubmitted: () {
            /// 点击回车时收起键盘并触发登录。
            passwordFocusNode.unfocus();
            _handleLogin();
          },
        ),

        /// 邀请码输入区（账号未注册时显示）。
        AuthInvitationCodeSection(
          show: logic.isAccountRegistered == false,
          controller: invitationController,
          onChanged: (String value) => logic.invitationCode = value,
        ),
        const SizedBox(height: Style.rememberSectionSpacing),

        /// 记住密码与忘记密码区。
        AuthRememberRow(
          remember: logic.remember,
          onToggleRemember: _toggleRemember,
          onTapForgotPassword: _handleForgotPassword,
        ),
        const SizedBox(height: Style.footerSpacing),

        /// 主提交按钮（根据模式切换文案）。
        AuthSubmitButton(
          isLoginMode: isLoginMode,
          loading: loading,
          onTap: isLoginMode ? _handleLogin : _handleRegister,
        ),
        const SizedBox(height: Style.footerSpacing),

        /// 底部跳转入口（根据模式切换文案）。
        AuthFooterAction(
          promptText: isLoginMode
              ? context.tr('login.no_account_tips')
              : context.tr('register.account_tips'),
          actionText: isLoginMode
              ? context.tr('login.register_now')
              : context.tr('register.login_now'),
          onTap: isLoginMode ? _goToRegister : _switchToLoginMode,
        ),
        const SizedBox(height: Style.supportSpacing),
        const AuthorizedLoginView(),
        const SizedBox(height: 30),
      ],
    );
  }

  /// 切换"记住密码"状态。
  void _toggleRemember() {
    setState(() {
      logic.remember = !logic.remember;
    });
  }

  /// 当前版本忘记密码尚未接入真实流程，先保留日志入口。
  void _handleForgotPassword() {
    logUtil(msg: '点击了忘记密码');
  }

  /// 提交登录请求并在成功后跳到首页。
  Future<void> _handleLogin() async {
    /// 提交前先收起键盘。
    FocusScope.of(context).unfocus();

    /// loading 中时不允许重复提交。
    if (loading) return;

    setState(() {
      /// 打开 loading。
      loading = true;
    });

    /// 让 loading 先渲染一帧，再执行异步登录。
    await Future<void>.delayed(Duration.zero);
    final bool loginStatus = await logic.login();

    if (!mounted) return;
    setState(() {
      /// 结束后关闭 loading。
      loading = false;
    });

    /// 登录失败时逻辑层内部已提示，此处只需在成功时跳转。
    if (!loginStatus) return;

    routerUtil(path: '/', type: 'replace');
  }

  /// 提交注册请求（账号未注册时使用）。
  Future<void> _handleRegister() async {
    /// 提交前先收起键盘。
    FocusScope.of(context).unfocus();

    /// loading 中时不允许重复提交。
    if (loading) return;

    setState(() {
      /// 打开 loading。
      loading = true;
    });

    /// 让 loading 先渲染一帧，再执行异步注册。
    await Future<void>.delayed(Duration.zero);
    final bool registerStatus = await logic.register();

    if (!mounted) return;
    setState(() {
      /// 结束后关闭 loading。
      loading = false;
    });

    /// 注册失败时逻辑层内部已提示，此处只需在成功时跳转。
    if (!registerStatus) return;

    routerUtil(path: '/', type: 'replace');
  }

  /// 登录页底部跳转到注册页。
  void _goToRegister() {
    if (kIsWeb) {
      /// Web 端直接替换浏览器地址。
      browserReplaceState('/register');
      return;
    }

    /// 非 Web 端替换到注册页。
    routerUtil(path: '/register', type: 'replace');
  }

  /// 切换回登录模式（清空账号、重置状态、关闭输入法）。
  void _switchToLoginMode() {
    /// 关闭输入法，取消所有输入框焦点。
    FocusScope.of(context).unfocus();

    setState(() {
      accountController.clear();
      invitationController.clear();
      logic.account = '';
      logic.invitationCode = '';
      logic.isAccountRegistered = null;
    });
  }
}
