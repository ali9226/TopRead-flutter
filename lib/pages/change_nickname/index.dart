import 'package:easy_localization/easy_localization.dart';
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/common_style/submit_button/index.dart';
import 'package:app/components/cute_mascot/index.dart';
import 'package:app/components/language_selection/index.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/router/router_util.dart';

import 'logic.dart';
import 'style.dart';

/// 更新昵称页面。
///
/// 展示当前昵称信息，提供新昵称输入和提交功能。
/// 整体布局：顶部导航栏 → 英雄区域（标题+小猫） → 表单卡片 → 提交按钮。
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

    final UserInformation userController = Get.put(UserInformation());
    final String currentName =
        userController.userInfo.value?.name.trim().isNotEmpty == true
            ? userController.userInfo.value!.name.trim()
            : '--';

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
                        height: MediaQuery.of(context).padding.top + 56,
                      ),
                      _HeroSection(
                        isDark: isDark,
                        title: context.tr('UserInfo.update_nickname_screen_title'),
                        subtitle: context
                            .tr('UserInfo.update_nickname_screen_subtitle'),
                      ),
                      const SizedBox(height: 24),
                      _FormCard(
                        isDark: isDark,
                        currentNickname: currentName,
                        controller: _nicknameController,
                        focusNode: _nicknameFocusNode,
                        maxLength: _maxLength,
                        onChanged: () => setState(() {}),
                        onClearTap: () {
                          _nicknameController.clear();
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: Style.submitTopSpacing),
                      CommonSubmitButton(
                        title: context.tr('UserInfo.confirm_update'),
                        isDark: isDark,
                        loading: _submitLoading,
                        onTap: _handleSubmit,
                        suffix: Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: const Color(0xFF3D2E1A).withValues(alpha: 0.6),
                        ),
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
                      title: '',
                      showLeftIcon: true,
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

/// 英雄区域：标题、副标题和小猫吉祥物。
///
/// 布局与修改密码页面一致：标题和副标题居左，猫咪居右。
/// 不使用卡片容器，直接展示在页面背景上。
class _HeroSection extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;

  const _HeroSection({
    required this.isDark,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    /// 根据当前语种判断是否为 CJK，用于调整副标题行高。
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );
    final double subtitle_height = is_cjk
        ? Style.heroSubtitleHeightCjk
        : Style.heroSubtitleHeightAlphabetic;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 左侧文字区域（标题 + 副标题）。
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// 页面主标题。
              Text(
                title,
                style: TextStyle(
                  fontSize: Style.heroTitleSize,
                  fontWeight: Style.heroTitleWeight,
                  color: Style.titleColor(isDark: isDark),
                ),
              ),
              const SizedBox(height: 8),

              /// 页面副标题。
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: Style.heroSubtitleSize,
                  height: subtitle_height,
                  fontWeight: Style.heroSubtitleWeight,
                  color: Style.subtitleColor(isDark: isDark),
                ),
              ),
            ],
          ),
        ),

        /// 右侧猫咪吉祥物。
        SizedBox(
          width: Style.heroDecorationWidth,
          height: Style.heroDecorationHeight,
          child: Center(
            child: CuteMascot(
              isCovering: false,
              isDark: isDark,
            ),
          ),
        ),
      ],
    );
  }
}

/// 表单卡片：当前昵称 + 分割线 + 新昵称输入。
class _FormCard extends StatelessWidget {
  final bool isDark;
  final String currentNickname;
  final TextEditingController controller;
  final FocusNode focusNode;
  final int maxLength;
  final VoidCallback onChanged;
  final VoidCallback onClearTap;

  const _FormCard({
    required this.isDark,
    required this.currentNickname,
    required this.controller,
    required this.focusNode,
    required this.maxLength,
    required this.onChanged,
    required this.onClearTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: Style.formCardHorizontalPadding,
        vertical: Style.formCardVerticalPadding,
      ),
      decoration: BoxDecoration(
        gradient: Style.formCardGradient(isDark: isDark),
        borderRadius: BorderRadius.circular(Style.formCardRadius),
        border: Border.all(color: Style.formCardBorderColor(isDark: isDark)),
        boxShadow: Style.formCardShadow(isDark: isDark),
      ),
      child: Column(
        children: <Widget>[
          _CurrentNicknameRow(
            isDark: isDark,
            nickname: currentNickname,
          ),
          const SizedBox(height: Style.dividerTopSpacing),
          _DividerWithArrow(isDark: isDark),
          const SizedBox(height: Style.dividerBottomSpacing),
          _NewNicknameInput(
            isDark: isDark,
            controller: controller,
            focusNode: focusNode,
            maxLength: maxLength,
            currentLength: controller.text.length,
            onChanged: onChanged,
            onClearTap: onClearTap,
          ),
        ],
      ),
    );
  }
}

/// 当前昵称展示行。
class _CurrentNicknameRow extends StatelessWidget {
  final bool isDark;
  final String nickname;

  const _CurrentNicknameRow({
    required this.isDark,
    required this.nickname,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: Style.sceneIconContainerSize,
          height: Style.sceneIconContainerSize,
          decoration: BoxDecoration(
            color: Style.sceneIconBackground(isDark: isDark),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_outline_rounded,
            size: Style.sceneIconSize,
            color: Style.sceneIconColor(isDark: isDark),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          context.tr('UserInfo.current_nickname_label'),
          style: TextStyle(
            fontSize: Style.currentNicknameLabelSize,
            color: Style.currentNicknameLabelColor(isDark: isDark),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            nickname,
            style: TextStyle(
              fontSize: Style.currentNicknameValueSize,
              fontWeight: Style.currentNicknameValueWeight,
              color: Style.currentNicknameValueColor(isDark: isDark),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// 带箭头的虚线分割线。
class _DividerWithArrow extends StatelessWidget {
  final bool isDark;

  const _DividerWithArrow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: CustomPaint(
            painter: _DashedLinePainter(
              color: Style.dividerColor(isDark: isDark),
            ),
            size: const Size(double.infinity, 1),
          ),
        ),
        Container(
          width: Style.dividerCircleSize,
          height: Style.dividerCircleSize,
          decoration: BoxDecoration(
            color: Style.dividerCircleColor(isDark: isDark),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_downward_rounded,
            size: Style.dividerIconSize,
            color: Style.dividerIconColor(isDark: isDark),
          ),
        ),
        Expanded(
          child: CustomPaint(
            painter: _DashedLinePainter(
              color: Style.dividerColor(isDark: isDark),
            ),
            size: const Size(double.infinity, 1),
          ),
        ),
      ],
    );
  }
}

/// 虚线绘制器。
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const double dashWidth = 6.0;
    const double dashSpace = 4.0;
    double currentX = 0;

    while (currentX < size.width) {
      canvas.drawLine(
        Offset(currentX, size.height / 2),
        Offset(currentX + dashWidth, size.height / 2),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 新昵称输入区域。
class _NewNicknameInput extends StatelessWidget {
  final bool isDark;
  final TextEditingController controller;
  final FocusNode focusNode;
  final int maxLength;
  final int currentLength;
  final VoidCallback onChanged;
  final VoidCallback onClearTap;

  const _NewNicknameInput({
    required this.isDark,
    required this.controller,
    required this.focusNode,
    required this.maxLength,
    required this.currentLength,
    required this.onChanged,
    required this.onClearTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: Style.sceneIconContainerSize,
              height: Style.sceneIconContainerSize,
              decoration: BoxDecoration(
                color: Style.sceneIconBackground(isDark: isDark),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_outlined,
                size: Style.sceneIconSize,
                color: Style.sceneIconColor(isDark: isDark),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              context.tr('UserInfo.new_nickname_label'),
              style: TextStyle(
                fontSize: Style.inputLabelSize,
                color: Style.inputLabelColor(isDark: isDark),
              ),
            ),
            const Spacer(),
            Text(
              '$currentLength/$maxLength',
              style: TextStyle(
                fontSize: Style.counterSize,
                color: Style.counterColor(isDark: isDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: Style.inputPadding,
          decoration: BoxDecoration(
            color: Style.inputBackgroundColor(isDark: isDark),
            borderRadius: BorderRadius.circular(Style.inputRadius),
            border: Border.all(
              color: focusNode.hasFocus
                  ? Style.inputFocusBorderColor(isDark: isDark)
                  : Style.inputBorderColor(isDark: isDark),
              width: focusNode.hasFocus ? 1.5 : 1.0,
            ),
          ),
          height: Style.inputHeight,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            maxLength: maxLength,
            textAlignVertical: TextAlignVertical.center,
            onChanged: (_) => onChanged(),
            style: TextStyle(
              fontSize: Style.inputTextSize,
              color: Style.inputTextColor(isDark: isDark),
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            ),
            decoration: InputDecoration(
              hintText: context.tr('UserInfo.tips_03'),
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              hintStyle: TextStyle(
                fontSize: Style.inputHintSize,
                color: Style.inputHintColor(isDark: isDark),
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              ),
              contentPadding: const EdgeInsets.only(top: 0, bottom: 2, left: 0, right: 0),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 24,
              ),
              suffixIcon: Align(
                widthFactor: 1.0,
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: currentLength > 0 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedScale(
                    scale: currentLength > 0 ? 1.0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: GestureDetector(
                      onTap: currentLength > 0 ? onClearTap : null,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Style.inputHintColor(isDark: isDark),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
