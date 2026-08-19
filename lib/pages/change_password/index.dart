import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app/api/post_request.dart';
import 'package:app/config/constant.dart';
import 'package:app/models/login.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/encryption/index.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:app/util/string/to_string.dart';
import 'package:app/components/language_selection/index.dart';

import 'style.dart';
import 'widgets/background_decorations.dart';
import 'widgets/hero_section.dart';
import 'widgets/password_form_card.dart';
import 'widgets/password_tips_card.dart';
import 'widgets/submit_button.dart';

/// 修改密码页面。
///
/// 页面结构：
/// 1. 背景装饰层（渐变 + 光斑 + 边缘淡出）。
/// 2. 顶部语言选择导航栏。
/// 3. 英雄区域（标题 + 副标题 + 猫咪吉祥物）。
/// 4. 表单卡片（新密码 + 密码强度条 + 确认密码）。
/// 5. 确认修改按钮。
/// 6. 密码小贴士卡片。
///
/// 支持日间/夜间主题切换，所有文案支持多语种。
class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  // ==================== 控制器 ====================

  /// 新密码文本控制器，管理新密码输入框的文本内容。
  final TextEditingController _newPasswordController = TextEditingController();

  /// 确认密码文本控制器，管理确认密码输入框的文本内容。
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  /// 新密码焦点节点，用于控制键盘焦点流转。
  final FocusNode _newPasswordFocusNode = FocusNode();

  /// 确认密码焦点节点，用于控制键盘焦点流转。
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  // ==================== 状态 ====================

  /// 新密码是否处于隐藏状态（密码模式）。
  bool _newPasswordObscured = true;

  /// 确认密码是否处于隐藏状态（密码模式）。
  bool _confirmPasswordObscured = true;

  /// 提交按钮是否处于 loading 状态（防止重复提交）。
  bool _isSubmitting = false;

  /// 登录态校验是否完成（校验完成前不渲染表单，避免闪屏）。
  bool _isAuthChecking = true;

  /// 全局设备主题仓库，用于读取日间/夜间模式状态。
  final DeviceInfo _deviceInfo = Get.find<DeviceInfo>();

  // ==================== 计算属性 ====================

  /// 吉祥物是否应该遮眼。
  /// 当任一密码输入框有内容且处于隐藏状态时，猫咪遮住眼睛表示"不偷看"。
  bool get _shouldMascotCover =>
      (_newPasswordController.text.isNotEmpty && _newPasswordObscured) ||
      (_confirmPasswordController.text.isNotEmpty && _confirmPasswordObscured);

  // ==================== 生命周期 ====================

  @override
  void initState() {
    super.initState();

    /// 监听两个密码输入框的文本变化，驱动密码强度条和吉祥物动画刷新。
    _newPasswordController.addListener(_onTextChange);
    _confirmPasswordController.addListener(_onTextChange);

    /// 检查本地登录态，未登录时重定向到首页。
    _verifyLoginStatus();
  }

  @override
  void dispose() {
    /// 移除文本监听并释放所有控制器和焦点节点，避免内存泄漏。
    _newPasswordController.removeListener(_onTextChange);
    _confirmPasswordController.removeListener(_onTextChange);
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  // ==================== 回调方法 ====================

  /// 输入变化回调。
  /// 每次文本变化时触发 UI 刷新，更新密码强度条和吉祥物遮眼状态。
  void _onTextChange() {
    if (mounted) setState(() {});
  }

  /// 检查本地登录态。
  /// 读取本地 token，为空则重定向到首页；否则完成校验并自动聚焦新密码输入框。
  Future<void> _verifyLoginStatus() async {
    final String token =
        (await StorageUtil.getData(Constant.tokenKey) ?? '').trim();
    if (!mounted) return;

    /// 没有 token 时，直接替换到首页，不继续展示表单。
    if (token.isEmpty) {
      routerUtil(path: '/', type: 'replace');
      return;
    }

    setState(() {
      _isAuthChecking = false;
    });
  }

  /// 收起键盘。
  /// 点击空白区域或提交前调用，避免键盘遮挡内容。
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  /// 处理表单提交。
  /// 校验输入合法性 → 调用修改密码接口 → 刷新 token 和用户信息 → 返回上一页。
  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    _dismissKeyboard();

    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    /// 校验新密码非空。
    if (newPassword.isEmpty) {
      showBottomTip(easy.tr('UserInfo.error_02'));
      return;
    }

    /// 校验确认密码非空。
    if (confirmPassword.isEmpty) {
      showBottomTip(easy.tr('UserInfo.error_07'));
      return;
    }

    /// 校验两次密码是否一致。
    if (newPassword != confirmPassword) {
      showBottomTip(easy.tr('UserInfo.error_08'));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      /// 调用修改密码接口，密码经过加密处理后传输。
      final Map<String, dynamic> parameter = <String, dynamic>{
        'password': passwordEncryption(removeSpaces(newPassword)),
      };
      final results = await postRequest<Login>(
        path: 'user/update_password',
        parameter: parameter,
        fromJson: (json) => Login.fromJson(json),
      );
      if (!results.status) return;
      if (results.content == null) return;

      /// 接口返回新 token，保存到本地以刷新登录态。
      final String token = results.content?.token.toString() ?? '';
      if (token.isEmpty) return;
      await StorageUtil.saveData(Constant.tokenKey, token);

      /// 刷新全局用户信息缓存。
      final userController = Get.put(UserInformation());
      if (results.content?.userInfo != null) {
        userController.saveUserInfo(results.content!.userInfo);
      }

      showBottomTip(easy.tr('UserInfo.success_03'));

      /// 提交成功后返回个人中心页面。
      if (mounted) {
        routerUtil(path: '/user_info', type: 'replace');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ==================== 构建方法 ====================

  @override
  Widget build(BuildContext context) {
    /// 读取当前是否为夜间模式。
    final bool isDark = _deviceInfo.theme.value == ThemeMode.dark;

    /// 读取媒体信息，用于计算安全区高度。
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final EdgeInsets safePadding = mediaQuery.padding;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,

      /// 点击空白区域收起键盘。
      onTap: _dismissKeyboard,
      child: Scaffold(
        backgroundColor: Style.backgroundColor(isDark: isDark),
        body: _isAuthChecking

            /// 登录态校验完成前不渲染内容，避免闪屏。
            ? const SizedBox.shrink()
            : Stack(
                children: <Widget>[
                  /// 背景装饰层（渐变 + 光斑 + 边缘淡出）。
                  BackgroundDecorations(
                    isDark: isDark,
                    safePaddingTop: safePadding.top,
                  ),

                  /// 主滚动内容区域。
                  ListView(
                    padding: EdgeInsets.fromLTRB(
                      Style.pageHorizontalPadding,
                      0,
                      Style.pageHorizontalPadding,
                      Style.pageBottomPadding + safePadding.bottom,
                    ),
                    children: <Widget>[
                      /// 顶部留白（为固定导航栏腾出空间）。
                      SizedBox(height: safePadding.top + 36),

                      /// 导航栏占位（由 Positioned 的 LanguageSelection 处理）。
                      const SizedBox.shrink(),
                      const SizedBox(height: 8),

                      /// 英雄区域（标题 + 副标题 + 猫咪吉祥物）。
                      HeroSection(
                        isCovering: _shouldMascotCover,
                        isDark: isDark,
                      ),

                      /// 表单卡片（新密码 + 强度条 + 确认密码）。
                      const SizedBox(height: 4),
                      PasswordFormCard(
                        newPasswordController: _newPasswordController,
                        confirmPasswordController: _confirmPasswordController,
                        newPasswordFocusNode: _newPasswordFocusNode,
                        confirmPasswordFocusNode: _confirmPasswordFocusNode,
                        newPasswordObscured: _newPasswordObscured,
                        confirmPasswordObscured: _confirmPasswordObscured,
                        isDark: isDark,
                        onChanged: (_) {
                          if (mounted) setState(() {});
                        },
                        onNewPasswordSubmitted: (_) {
                          _confirmPasswordFocusNode.requestFocus();
                        },
                        onConfirmPasswordSubmitted: (_) => _handleSubmit(),
                        onNewPasswordVisibilityTap: () {
                          setState(() {
                            _newPasswordObscured = !_newPasswordObscured;
                          });
                        },
                        onConfirmPasswordVisibilityTap: () {
                          setState(() {
                            _confirmPasswordObscured =
                                !_confirmPasswordObscured;
                          });
                        },
                      ),

                      /// 确认修改按钮。
                      SizedBox(height: Style.submitTopSpacing),
                      SubmitButton(
                        isLoading: _isSubmitting,
                        isDark: isDark,
                        onPressed: _handleSubmit,
                      ),

                      /// 密码小贴士卡片（位于按钮下方）。
                      SizedBox(height: Style.formCardSpacing),
                      PasswordTipsCard(isDark: isDark),
                    ],
                  ),

                  /// 顶部固定语言选择导航栏（返回按钮 + 语言切换）。
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LanguageSelection(
                      title: '',
                      showLeftIcon: true,
                      showRightLanguageEntry: false,
                      useSafeAreaTop: true,
                      topOffset: 0,
                      horizontalPadding: Style.pageHorizontalPadding,
                      darkBackground: isDark,
                      onLeftTapOverride: () {
                        _dismissKeyboard();
                        routerUtil(path: '/user_info', type: 'replace');
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
