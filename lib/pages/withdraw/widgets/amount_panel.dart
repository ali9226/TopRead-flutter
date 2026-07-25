import 'dart:ui';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';

import '../style.dart';

/// 提现金额区块。
///
/// 这个组件负责把所有和“金额”有关的交互集中到一起：
/// 1. 当前余额和最小/最大金额展示。
/// 2. 金额输入框。
/// 3. 滑杆调节。
/// 4. 1/3、1/2、全部提现快捷入口。
///
/// 这样网络选择、钱包地址和金额交互就能保持职责分离。
class WithdrawAmountPanel extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 当前金额区是否允许交互。
  ///
  /// 当余额不足最低提现金额时，这里会整体降透明并禁用点击。
  final bool enabled;

  /// 已格式化的余额文本。
  final String balanceText;

  /// 已格式化的最小提现金额文本。
  final String minText;

  /// 已格式化的最大提现金额文本。
  final String maxText;

  /// 金额输入框控制器。
  final TextEditingController controller;

  /// 金额输入框焦点节点。
  final FocusNode focusNode;

  /// 当前滑杆值。
  final double sliderValue;

  /// 滑杆允许的最小值。
  final double sliderMin;

  /// 滑杆允许的最大值。
  final double sliderMax;

  /// 点击 1/3 快捷按钮后的回调。
  final VoidCallback onTapOneThird;

  /// 点击 1/2 快捷按钮后的回调。
  final VoidCallback onTapHalf;

  /// 点击“全部提现”后的回调。
  final VoidCallback onTapAll;

  /// 滑杆拖动后的统一回调。
  final ValueChanged<double> onSliderChanged;

  /// 当前 1/3 快捷按钮是否处于选中态。
  final bool oneThirdSelected;

  /// 当前 1/2 快捷按钮是否处于选中态。
  final bool halfSelected;

  /// 当前“全部提现”按钮是否处于选中态。
  final bool allSelected;

  /// 当前 1/3 快捷按钮是否可用。
  final bool oneThirdEnabled;

  /// 当前 1/2 快捷按钮是否可用。
  final bool halfEnabled;

  /// 输入框失焦或键盘提交时，统一提交输入值的回调。
  final VoidCallback onCommitInput;

  const WithdrawAmountPanel({
    super.key,
    required this.isDark,
    required this.enabled,
    required this.balanceText,
    required this.minText,
    required this.maxText,
    required this.controller,
    required this.focusNode,
    required this.sliderValue,
    required this.sliderMin,
    required this.sliderMax,
    required this.onTapOneThird,
    required this.onTapHalf,
    required this.onTapAll,
    required this.onSliderChanged,
    required this.oneThirdSelected,
    required this.halfSelected,
    required this.allSelected,
    required this.oneThirdEnabled,
    required this.halfEnabled,
    required this.onCommitInput,
  });

  @override
  Widget build(BuildContext context) {
    // 主动依赖 locale，确保语言切换后标题、提示文案和快捷按钮能即时刷新。
    Localizations.localeOf(context);

    // 标题和主数值颜色。
    final titleColor = isDark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;

    // 次级说明文字颜色。
    final hintColor = isDark
        ? ColorConstants.whiteColor.withValues(
            alpha: WithdrawStyle.subtitleDarkOpacity,
          )
        : ColorConstants.hintColor;

    return Opacity(
      // 不可提现时整块半透明，先从视觉上告诉用户“当前不可操作”。
      opacity: enabled ? 1 : 0.5,
      child: IgnorePointer(
        // 同时从交互层彻底禁用点击和输入，避免用户操作后没有反馈。
        ignoring: !enabled,
        child: Container(
          padding: WithdrawStyle.cardPadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(WithdrawStyle.cardRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? WithdrawStyle.darkCardGradient
                  : WithdrawStyle.lightCardGradient,
            ),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF8DB7FF).withValues(alpha: 0.14)
                  : ColorConstants.themeColor.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.14)
                    : ColorConstants.themeColor.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 右上角光斑只是做视觉层次，不参与任何交互。
              Positioned(
                top: -20,
                right: -12,
                child: IgnorePointer(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (isDark
                                  ? const Color(0xFF8DB7FF)
                                  : ColorConstants.themeColor)
                              .withValues(alpha: isDark ? 0.12 : 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 左下角辅助光斑和右上角形成呼应，避免卡片中部显得太平。
              Positioned(
                left: -16,
                bottom: -26,
                child: IgnorePointer(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(
                            0xFF8DB7FF,
                          ).withValues(alpha: isDark ? 0.08 : 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          easy.tr('withdraw_page.amount_title'),
                          style: TextStyle(
                            color: titleColor,
                            fontSize: WithdrawStyle.titleSize,
                            fontWeight: WithdrawStyle.titleWeight,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ConstrainedBox(
                            // 余额文案可能因不同语言变长，限制最大宽度并允许自适应缩放。
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "${easy.tr('constant.balance')}: $balanceText",
                                  maxLines: 1,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: titleColor,
                                    fontSize: WithdrawStyle.inlineBalanceSize,
                                    fontWeight:
                                        WithdrawStyle.inlineBalanceWeight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    easy.tr('withdraw_page.amount_hint'),
                    style: TextStyle(
                      color: hintColor,
                      fontSize: WithdrawStyle.subtitleSize,
                      fontWeight: WithdrawStyle.subtitleWeight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    // 金额输入框外壳只负责包裹币种前缀、输入框本体和后缀单位。
                    height: WithdrawStyle.amountFieldHeight,
                    padding: WithdrawStyle.amountFieldPadding,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(
                              alpha: WithdrawStyle.amountFieldDarkOpacity,
                            )
                          : Colors.black.withValues(
                              alpha: WithdrawStyle.amountFieldLightOpacity,
                            ),
                      borderRadius: BorderRadius.circular(
                        WithdrawStyle.amountFieldRadius,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '\$',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: WithdrawStyle.amountInputSize,
                            fontWeight: WithdrawStyle.amountInputWeight,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.done,
                            // 用户点空白、按完成、编辑完成时都统一走一套提交逻辑，
                            // 这样逻辑层能把草稿值纠正到合法提现区间。
                            onTapOutside: (_) => onCommitInput(),
                            onSubmitted: (_) => onCommitInput(),
                            onEditingComplete: onCommitInput,
                            inputFormatters: [
                              // 只允许输入数字和两位小数，避免脏值提前进入逻辑层。
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            style: TextStyle(
                              color: titleColor,
                              fontSize: WithdrawStyle.amountInputSize,
                              fontWeight: WithdrawStyle.amountInputWeight,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              isCollapsed: true,
                              hintText: easy.tr(
                                'withdraw_page.amount_placeholder',
                              ),
                              hintStyle: TextStyle(
                                color: hintColor,
                                fontSize: 16,
                                fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'USDT',
                          style: TextStyle(
                            color: hintColor,
                            fontSize: WithdrawStyle.amountInputSuffixSize,
                            fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: WithdrawStyle.sliderTopSpacing),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      inactiveTrackColor: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.black.withValues(alpha: 0.08),
                      activeTrackColor: ColorConstants.themeColor,
                      thumbColor: ColorConstants.themeColor,
                      overlayColor: ColorConstants.themeColor.withValues(
                        alpha: 0.12,
                      ),
                    ),
                    child: Slider(
                      // 这里再次 clamp 一次，是为了防止外部状态切换时旧值短暂落在边界外。
                      value: sliderValue.clamp(sliderMin, sliderMax),
                      min: sliderMin,
                      max: sliderMax <= sliderMin
                          ? sliderMin + 0.01
                          : sliderMax,
                      onChanged: onSliderChanged,
                    ),
                  ),
                  const SizedBox(height: WithdrawStyle.sliderLabelTopSpacing),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${easy.tr('withdraw_page.min_short')}: $minText",
                          style: TextStyle(
                            color: hintColor,
                            fontSize: WithdrawStyle.sliderLabelSize,
                            fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "${easy.tr('withdraw_page.max_short')}: $maxText",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: hintColor,
                            fontSize: WithdrawStyle.sliderLabelSize,
                            fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: WithdrawStyle.shortcutTopSpacing),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ShortcutChip(
                            label: '1/3',
                            active: oneThirdSelected,
                            enabled: oneThirdEnabled,
                            dark: isDark,
                            onTap: onTapOneThird,
                          ),
                        ),
                        const SizedBox(width: WithdrawStyle.shortcutGap),
                        Expanded(
                          child: _ShortcutChip(
                            label: '1/2',
                            active: halfSelected,
                            enabled: halfEnabled,
                            dark: isDark,
                            onTap: onTapHalf,
                          ),
                        ),
                        const SizedBox(width: WithdrawStyle.shortcutGap),
                        Expanded(
                          child: _ShortcutChip(
                            label: easy.tr('withdraw_page.withdraw_all'),
                            active: allSelected,
                            enabled: true,
                            dark: isDark,
                            onTap: onTapAll,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  /// 当前按钮文案。
  final String label;

  /// 是否为当前选中的快捷比例。
  final bool active;

  /// 当前按钮是否允许点击。
  final bool enabled;

  /// 当前是否深色主题。
  final bool dark;

  /// 点击按钮后的回调。
  final VoidCallback onTap;

  const _ShortcutChip({
    required this.label,
    required this.active,
    required this.enabled,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 非选中态的基础背景色。
    final baseColor = dark ? const Color(0xFF1A2634) : const Color(0xFFF5F7FB);

    // 选中后偏暖的高亮背景，用来强化“已应用快捷比例”的状态。
    final activeBg = dark ? const Color(0xFF3A3220) : const Color(0xFFFFF3CC);

    // 普通状态边框色。
    final normalBorder = dark
        ? const Color(0xFF334559)
        : const Color(0xFFE2E8F0);

    // 不可点击时的降级背景。
    final disabledBg = dark ? const Color(0xFF141C27) : const Color(0xFFF1F5F9);

    // 不可点击时的边框色。
    final disabledBorder = dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    // 不可点击时的文字色。
    final disabledText = dark
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: enabled ? onTap : null,
        child: TweenAnimationBuilder<double>(
          // 用一个 0 到 1 的补间值统一驱动背景、边框、文字和阴影变化，
          // 比分别写多套 AnimatedContainer/AnimatedDefaultTextStyle 更容易维护。
          tween: Tween<double>(begin: 0, end: active ? 1 : 0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) {
            // 根据动画进度计算按钮的实时背景色。
            final bgColor = enabled
                ? Color.lerp(baseColor, activeBg, t)!
                : disabledBg;
            // 根据动画进度计算边框从普通态到高亮态的过渡。
            final borderColor = enabled
                ? Color.lerp(normalBorder, const Color(0xFFF8D02D), t)!
                : disabledBorder;
            // 根据动画进度计算文字色，选中态会更偏金色。
            final textColor = enabled
                ? Color.lerp(
                    dark ? const Color(0xFFA9B5C6) : const Color(0xFF5B6472),
                    dark ? const Color(0xFFFFE8A3) : const Color(0xFF6A4D00),
                    t,
                  )!
                : disabledText;
            // 阴影位移和模糊半径也跟随选中态一起抬起。
            final y = lerpDouble(0, 3, t) ?? 0;
            final blur = lerpDouble(0, 10, t) ?? 0;

            return Container(
              height: WithdrawStyle.shortcutHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: bgColor,
                border: Border.all(color: borderColor),
                boxShadow: [
                  if (enabled && t > 0)
                    BoxShadow(
                      color: const Color(
                        0xFFF8D02D,
                      ).withValues(alpha: 0.28 * t),
                      blurRadius: blur,
                      offset: Offset(0, y),
                    ),
                ],
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
                  color: textColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
