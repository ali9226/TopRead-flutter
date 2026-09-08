import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/util/router/run_navigation_action_once.dart';
import 'package:app/util/withdraw/withdraw_entry.dart';
import 'package:get/get.dart';
import '../style.dart';

/* TODO
 * 个人中心右下角的快捷操作区域。
 *
 * 这个组件专门负责“充值 / 提现”两个按钮：
 * 1. 统一管理按钮样式。
 * 2. 统一处理 SVG 图标渲染。
 * 3. 统一维护路由跳转。
 *
 * 把这部分从 userInfoTop 拆出来后，顶部组件只需要负责布局，
 * 而按钮区域的展示和交互可以独立维护，后续扩展会更容易。
 */
class AccountActionButtons extends StatelessWidget {
  const AccountActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final userInformation = Get.find<UserInformation>();
    final localeCode = context.locale.languageCode;
    final buttonWidth = _calculateSharedButtonWidth(context);

    return Obx(() {
      /* TODO
       * 用户没有登录时，不展示充值 / 提现按钮。
       *
       * 这里直接在组件内部判断，而不是交给父组件处理，
       * 这样父组件不用额外关心登录态，职责会更单一。
       */
      if (!userInformation.isLoggedIn.value) {
        return const SizedBox.shrink();
      }

      return SafeArea(
        key: ValueKey(localeCode),
        left: true,
        top: false,
        right: true,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _AccountActionButton(
              width: buttonWidth,
              iconName: 'recharge',
              labelKey: 'UserInfo.recharge',
              backgroundColor: ColorConstants.themeColor,
              foregroundColor: Style.rechargeForegroundColor,
              routePath: '/top_up',
            ),
            const SizedBox(height: Style.actionButtonSpacing),
            _AccountActionButton(
              width: buttonWidth,
              iconName: 'withdraw_02',
              labelKey: 'UserInfo.withdraw',
              backgroundColor: Style.withdrawBackgroundColor,
              foregroundColor: Style.withdrawForegroundColor,
              routePath: '/withdraw',
              hasBorder: true,
              onTapOverride: () {
                unawaited(openWithdrawIfBalanceAllows());
              },
            ),
          ],
        ),
      );
    });
  }

  /* TODO
   * 计算两个按钮共享的宽度。
   *
   * 规则是取当前语言下“充值 / 提现”两条文案里更长的那一条，
   * 再加上图标、间距和左右内边距，得到一个共同宽度。
   * 这样两个按钮始终等宽，同时又能适配不同语言长度。
   */
  double _calculateSharedButtonWidth(BuildContext context) {
    final localeCode = context.locale.languageCode.toLowerCase();
    final isCompactLocale = LanguageUtil.is_cjk_language(localeCode);
    final textStyle = TextStyle(
      fontSize: Style.actionButtonTextSize,
      fontWeight: Style.actionButtonFontWeight,
    );

    final labels = [easy.tr('UserInfo.recharge'), easy.tr('UserInfo.withdraw')];

    double maxTextWidth = 0;
    for (final label in labels) {
      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        maxLines: 1,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();

      if (textPainter.width > maxTextWidth) {
        maxTextWidth = textPainter.width;
      }
    }

    final width =
        Style.actionButtonPadding.horizontal +
        Style.actionButtonIconAreaWidth +
        Style.actionButtonIconGap +
        maxTextWidth;

    final minWidth = isCompactLocale
        ? Style.actionButtonCompactMinWidth
        : Style.actionButtonExpandedMinWidth;

    if (width < minWidth) {
      return minWidth;
    }

    if (width > Style.actionButtonMaxWidth) {
      return Style.actionButtonMaxWidth;
    }

    return width;
  }
}

/* TODO
 * 单个快捷按钮。
 *
 * 这里把“按钮结构”固定住，把下面这些变化点作为参数传入：
 * - 图标名
 * - 多语种 key
 * - 前景色 / 背景色
 * - 点击跳转目标
 *
 * 这样可以最大限度复用同一套布局和视觉规范。
 */
class _AccountActionButton extends StatelessWidget {
  final double width;
  final String iconName;
  final String labelKey;
  final Color backgroundColor;
  final Color foregroundColor;
  final String routePath;
  final bool hasBorder;

  /// 非空时优先执行，用于提现等需先校验再跳转的场景。
  final VoidCallback? onTapOverride;

  const _AccountActionButton({
    required this.width,
    required this.iconName,
    required this.labelKey,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.routePath,
    this.hasBorder = false,
    this.onTapOverride,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        run_navigation_action_once(
          actionKey: 'account_action_$routePath',
          action: () async {
            if (onTapOverride != null) {
              onTapOverride!();
              return;
            }
            routerUtil(path: routePath);
          },
        );
      },
      child: Container(
        width: width,
        height: Style.actionButtonHeight,
        padding: Style.actionButtonPadding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(Style.actionButtonRadius),
          border: hasBorder
              ? Border.all(
                  color: Style.withdrawForegroundColor.withValues(
                    alpha: Style.withdrawBorderOpacity,
                  ),
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Style.actionButtonShadowOpacity,
              ),
              blurRadius: Style.actionButtonShadowBlur,
              offset: Style.actionButtonShadowOffset,
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: Style.actionButtonIconAreaWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SvgIcon(
                  name: iconName,
                  width: Style.actionButtonIconSize,
                  height: Style.actionButtonIconSize,
                  color: foregroundColor,
                ),
              ),
            ),
            const SizedBox(width: Style.actionButtonIconGap),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    easy.tr(labelKey),
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: Style.actionButtonTextSize,
                      fontWeight: Style.actionButtonFontWeight,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
