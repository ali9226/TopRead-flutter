import 'package:easy_localization/easy_localization.dart';
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/common_style/submit_button/index.dart';
import 'package:app/components/auth_form_widgets/auth_brand_section.dart';
import 'package:app/components/language_selection/index.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/router/router_util.dart';

import 'logic.dart';
import 'style.dart';

/// 更新昵称页面。
///
/// 整体布局：顶部导航栏 → 英雄区域（标题+小猫） → 当前昵称展示 → 新昵称输入 → 提交按钮。
class ChangeNickname extends StatefulWidget {
  const ChangeNickname({super.key});

  @override
  State<ChangeNickname> createState() => _ChangeNicknameState();
}

class _ChangeNicknameState extends State<ChangeNickname> {
  /// 页面逻辑对象。
  late final Logic logic;

  /// 新昵称输入控制器。
  final TextEditingController _nicknameController = TextEditingController();

  /// 输入框焦点节点。
  final FocusNode _nicknameFocusNode = FocusNode();

  /// 提交按钮 loading 状态。
  bool _submitLoading = false;

  /// 登录态校验中。
  bool _authChecking = true;

  /// 昵称最大长度限制。
  final int _maxLength = 12;

  @override
  void initState() {
    super.initState();
    logic = Logic(context);
    _verifyLoginStatus();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _nicknameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DeviceInfo deviceInfo = Get.find<DeviceInfo>();
    final bool isDark = deviceInfo.theme.value == ThemeMode.dark;

    final UserInformation userController = Get.find<UserInformation>();
    final String currentName =
        userController.userInfo.value?.name.trim().isNotEmpty == true
            ? userController.userInfo.value!.name.trim()
            : '--';

    /// 输入框下划线颜色。
    final Color borderColor = isDark
        ? ColorConstants.nightTextColor
        : Colors.black.withValues(alpha: 0.2);

    /// 提示文字颜色。
    final Color hintColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade600;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Style.backgroundColor(isDark: isDark),
        body: _authChecking
            ? const SizedBox.shrink()
            : Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? Style.darkBackgroundGradient
                              : Style.lightBackgroundGradient,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: Style.decorCircleOneTop,
                    right: Style.decorCircleOneRight,
                    child: IgnorePointer(
                      child: Container(
                        width: Style.decorCircleOneSize,
                        height: Style.decorCircleOneSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF8D02D).withValues(
                            alpha: isDark
                                ? Style.decorCircleOneDarkOpacity
                                : Style.decorCircleOneLightOpacity,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: Style.decorCircleTwoTop,
                    left: Style.decorCircleTwoLeft,
                    child: IgnorePointer(
                      child: Container(
                        width: Style.decorCircleTwoSize,
                        height: Style.decorCircleTwoSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF67C23A).withValues(
                            alpha: Style.decorCircleTwoOpacity,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ListView(
                    padding: EdgeInsets.fromLTRB(
                      Style.pageHorizontalPadding,
                      0,
                      Style.pageHorizontalPadding,
                      Style.pageBottomPadding,
                    ),
                    children: <Widget>[
                      SizedBox(
                        height: MediaQuery.of(context).padding.top + 16,
                      ),

                      /// Logo + 口号。
                      const AuthBrandSection(),

                      /// 当前昵称展示。
                      _CurrentNicknameSection(
                        isDark: isDark,
                        nickname: currentName,
                      ),
                      const SizedBox(height: 30),

                      /// 新昵称输入。
                      _NewNicknameSection(
                        isDark: isDark,
                        controller: _nicknameController,
                        focusNode: _nicknameFocusNode,
                        maxLength: _maxLength,
                        onChanged: () => setState(() {}),
                        borderColor: borderColor,
                        hintColor: hintColor,
                      ),

                      /// 提交按钮。
                      const SizedBox(height: Style.submitTopSpacing),
                      CommonSubmitButton(
                        title: context.tr('UserInfo.confirm_update'),
                        isDark: isDark,
                        loading: _submitLoading,
                        onTap: _handleSubmit,
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: MediaQuery.of(context).padding.top + 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Colors.white.withValues(
                                alpha: isDark ? 0.18 : 0.92,
                              ),
                              Colors.white.withValues(
                                alpha: isDark ? 0.06 : 0.48,
                              ),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LanguageSelection(
                      showLeftIcon: true,
                      showRightLanguageEntry: false,
                      useSafeAreaTop: true,
                      topOffset: 0,
                      horizontalPadding: Style.pageHorizontalPadding,
                      darkBackground: isDark,
                      onLeftTapOverride: _handleClose,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// 检查本地登录态。
  Future<void> _verifyLoginStatus() async {
    await logic.checkLoginStatus();
    if (!mounted) return;
    setState(() {
      _authChecking = false;
    });
  }

  /// 处理提交。
  Future<void> _handleSubmit() async {
    if (_submitLoading) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _submitLoading = true;
    });

    try {
      final bool success = await logic.submitNewNickname(
        <String, String>{'nickname': _nicknameController.text},
      );
      if (!mounted) return;
      if (success) {
        routerUtil(path: '/user_info', type: 'replace');
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitLoading = false;
        });
      }
    }
  }

  /// 处理顶部关闭动作。
  void _handleClose() {
    FocusScope.of(context).unfocus();
    routerUtil(path: '/user_info', type: 'replace');
  }
}

/// 当前昵称展示区域（标签 + 下划线样式的只读展示）。
class _CurrentNicknameSection extends StatelessWidget {
  final bool isDark;
  final String nickname;

  const _CurrentNicknameSection({
    required this.isDark,
    required this.nickname,
  });

  @override
  Widget build(BuildContext context) {
    final Color labelColor = isDark
        ? ColorConstants.whiteColor
        : ColorConstants.nightBackgroundColor;

    final Color valueColor = isDark
        ? ColorConstants.whiteColor.withValues(alpha: 0.85)
        : ColorConstants.lightTextColor;

    final Color borderColor = isDark
        ? ColorConstants.nightTextColor
        : Colors.black.withValues(alpha: 0.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 标签行。
        Row(
          children: <Widget>[
            SvgIcon(
              name: 'account',
              color: labelColor,
              width: 22,
              height: 22,
            ),
            const SizedBox(width: 7),
            Text(
              context.tr('UserInfo.current_nickname_label'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                color: labelColor,
              ),
            ),
          ],
        ),

        /// 昵称值（下划线样式）。
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 14),
          child: Text(
            nickname,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              color: valueColor,
            ),
          ),
        ),

        /// 下划线。
        Container(
          height: 1,
          color: borderColor,
        ),
      ],
    );
  }
}

/// 新昵称输入区域（标签 + 下划线输入框）。
class _NewNicknameSection extends StatelessWidget {
  final bool isDark;
  final TextEditingController controller;
  final FocusNode focusNode;
  final int maxLength;
  final VoidCallback onChanged;
  final Color borderColor;
  final Color hintColor;

  const _NewNicknameSection({
    required this.isDark,
    required this.controller,
    required this.focusNode,
    required this.maxLength,
    required this.onChanged,
    required this.borderColor,
    required this.hintColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color labelColor = isDark
        ? ColorConstants.whiteColor
        : ColorConstants.nightBackgroundColor;

    final Color counterColor = isDark
        ? ColorConstants.whiteColor.withValues(alpha: 0.45)
        : ColorConstants.hintColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 标签行（图标 + 标签 + 计数器）。
        Row(
          children: <Widget>[
            SvgIcon(
              name: 'account',
              color: labelColor,
              width: 22,
              height: 22,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                context.tr('UserInfo.new_nickname_label'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                  color: labelColor,
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, __) {
                return Text(
                  '${value.text.length}/$maxLength',
                  style: TextStyle(
                    fontSize: 13,
                    color: counterColor,
                  ),
                );
              },
            ),
          ],
        ),

        /// 输入框（下划线样式）。
        TextField(
          controller: controller,
          focusNode: focusNode,
          maxLength: maxLength,
          onChanged: (_) => onChanged(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
          ),
          cursorColor: ColorConstants.themeColor,
          decoration: InputDecoration(
            hintText: context.tr('UserInfo.tips_03'),
            counterText: '',
            hintStyle: TextStyle(
              color: hintColor,
              fontSize: 15,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: borderColor, width: 1),
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
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, __) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: hintColor,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
