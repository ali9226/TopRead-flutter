import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/transaction_inquire_type.dart';
import 'package:app/config/font_config.dart';

import '../style.dart';

/// 提现网络与钱包地址区块。
///
/// 这个组件负责处理两类表单：
/// 1. 提现网络选择。
/// 2. 收款地址输入。
///
/// 之所以把这两块放在同一个组件里，是因为它们都属于“提现目标”信息，
/// 和金额区相比更接近同一层职责。
class WithdrawTypeSelector extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 可供选择的提现网络列表。
  final List<TransactionInquireTypeItem> items;

  /// 当前选中的提现网络 id。
  final int selectedId;

  /// 当前区块是否允许交互。
  final bool enabled;

  /// 点击切换提现网络后的回调。
  final ValueChanged<int> onTapType;

  /// 地址输入框控制器。
  final TextEditingController addressController;

  /// 地址输入框焦点节点。
  final FocusNode addressFocusNode;

  /// 失焦时提交地址草稿的回调。
  final VoidCallback onCommitAddressInput;

  /// 点击键盘下一项时提交地址并切到金额输入框的回调。
  final VoidCallback onSubmitAddressInput;

  /// 点击粘贴按钮后的回调。
  final VoidCallback onTapPaste;

  /// 点击清空地址按钮后的回调。
  final VoidCallback onTapClearAddress;

  /// 点击提现记录入口后的回调。
  final VoidCallback onTapRecords;

  const WithdrawTypeSelector({
    super.key,
    required this.isDark,
    required this.items,
    required this.selectedId,
    required this.enabled,
    required this.onTapType,
    required this.addressController,
    required this.addressFocusNode,
    required this.onCommitAddressInput,
    required this.onSubmitAddressInput,
    required this.onTapPaste,
    required this.onTapClearAddress,
    required this.onTapRecords,
  });

  @override
  Widget build(BuildContext context) {
    // 依赖 locale，保证切换语言后标题和占位文案同步刷新。
    Localizations.localeOf(context);

    // 标题和主要文字颜色。
    final titleColor = isDark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;

    // 次级说明文字和占位文字颜色。
    final hintColor = isDark
        ? ColorConstants.whiteColor.withValues(
            alpha: WithdrawStyle.subtitleDarkOpacity,
          )
        : ColorConstants.hintColor;

    return Container(
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
          // 右上角装饰光斑。
          Positioned(
            top: -18,
            right: -8,
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
          // 左下角辅助光斑。
          Positioned(
            left: -18,
            bottom: -24,
            child: IgnorePointer(
              child: Container(
                width: 90,
                height: 90,
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
                      easy.tr('withdraw_page.type_title'),
                      style: TextStyle(
                        color: titleColor,
                        fontSize: WithdrawStyle.titleSize,
                        fontWeight: WithdrawStyle.titleWeight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onTapRecords,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: WithdrawStyle.recordButtonHeight,
                      padding: WithdrawStyle.recordButtonPadding,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : ColorConstants.themeColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(
                          WithdrawStyle.recordButtonRadius,
                        ),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF8DB7FF).withValues(alpha: 0.12)
                              : ColorConstants.themeColor.withValues(
                                  alpha: 0.18,
                                ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgIcon(
                            name: 'withdraw',
                            width: 14,
                            height: 14,
                            color: isDark
                                ? ColorConstants.themeColor
                                : titleColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            easy.tr('withdraw_page.records'),
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 12,
                              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                easy.tr('withdraw_page.type_hint'),
                style: TextStyle(
                  color: hintColor,
                  fontSize: WithdrawStyle.subtitleSize,
                  fontWeight: WithdrawStyle.subtitleWeight,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                // 网络类型数量可能不固定，用 Wrap 而不是 Row，
                // 可以避免网络类型变多时直接溢出。
                spacing: WithdrawStyle.typeChipGap,
                runSpacing: WithdrawStyle.typeChipGap,
                children: items
                    .map(
                      (item) => _TypeChip(
                        isDark: isDark,
                        label: item.label,
                        selected: item.id == selectedId,
                        enabled: enabled,
                        onTap: () => onTapType(item.id),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: WithdrawStyle.addressSectionTopSpacing),
              Text(
                easy.tr('withdraw_page.address_title'),
                style: TextStyle(
                  color: titleColor,
                  fontSize: 14,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                ),
              ),
              const SizedBox(height: WithdrawStyle.addressTitleBottomSpacing),
              Container(
                // 地址输入框外壳同时包裹输入框、清空按钮和粘贴按钮。
                height: WithdrawStyle.addressFieldHeight,
                padding: WithdrawStyle.addressFieldPadding,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(
                          alpha: WithdrawStyle.addressFieldDarkOpacity,
                        )
                      : Colors.black.withValues(
                          alpha: WithdrawStyle.addressFieldLightOpacity,
                        ),
                  borderRadius: BorderRadius.circular(
                    WithdrawStyle.addressFieldRadius,
                  ),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF8DB7FF).withValues(alpha: 0.12)
                        : ColorConstants.themeColor.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: addressController,
                        focusNode: addressFocusNode,
                        textInputAction: TextInputAction.next,
                        // 用户点空白、按回车、编辑完成时都统一提交地址草稿，
                        // 防止逻辑层还停留在旧地址。
                        onTapOutside: (_) => onCommitAddressInput(),
                        onSubmitted: (_) => onSubmitAddressInput(),
                        onEditingComplete: onSubmitAddressInput,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: WithdrawStyle.addressInputSize,
                          fontWeight: WithdrawStyle.addressInputWeight,
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
                            'withdraw_page.address_placeholder',
                          ),
                          hintStyle: TextStyle(
                            color: hintColor,
                            fontSize: WithdrawStyle.addressInputSize,
                            fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    if (addressController.text.trim().isNotEmpty) ...[
                      const SizedBox(width: WithdrawStyle.addressActionGap),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          // 只有当前确实有输入内容时才显示清空按钮，
                          // 避免空输入框右侧堆无意义图标。
                          borderRadius: BorderRadius.circular(
                            WithdrawStyle.addressClearButtonSize / 2,
                          ),
                          onTap: onTapClearAddress,
                          child: Ink(
                            width: WithdrawStyle.addressClearButtonSize,
                            height: WithdrawStyle.addressClearButtonSize,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.close_rounded,
                                size: WithdrawStyle.addressClearIconSize,
                                color: hintColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: WithdrawStyle.addressActionGap),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        // 粘贴按钮单独做强调色渐变，目的是把“粘贴地址”这个高频动作提出来。
                        borderRadius: BorderRadius.circular(
                          WithdrawStyle.pasteButtonRadius,
                        ),
                        onTap: onTapPaste,
                        child: Ink(
                          height: WithdrawStyle.pasteButtonHeight,
                          padding: WithdrawStyle.pasteButtonPadding,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? const [Color(0xFF2C3444), Color(0xFF232A38)]
                                  : const [
                                      Color(0xFFFFF7D8),
                                      Color(0xFFFFEAA5),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(
                              WithdrawStyle.pasteButtonRadius,
                            ),
                            border: Border.all(
                              color: isDark
                                  ? const Color(
                                      0xFF8DB7FF,
                                    ).withValues(alpha: 0.14)
                                  : const Color(0xFFE7C866),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isDark
                                            ? const Color(0xFF8DB7FF)
                                            : const Color(0xFFF6C542))
                                        .withValues(
                                          alpha: isDark ? 0.10 : 0.16,
                                        ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              SvgIcon(
                                name: 'copy',
                                width: 16,
                                height: 16,
                                color: isDark
                                    ? const Color(0xFFFFE8A3)
                                    : const Color(0xFF7A5A00),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                easy.tr('withdraw_page.paste'),
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFFFE8A3)
                                      : const Color(0xFF7A5A00),
                                  fontSize: 12,
                                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 当前网络名称。
  final String label;

  /// 当前按钮是否已选中。
  final bool selected;

  /// 当前按钮是否允许点击。
  final bool enabled;

  /// 点击按钮后的回调。
  final VoidCallback onTap;

  const _TypeChip({
    required this.isDark,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 选中态使用主题色边框，未选中时退回到低对比边框。
    final borderColor = selected
        ? ColorConstants.themeColor
        : isDark
        ? const Color(
            0xFF8DB7FF,
          ).withValues(alpha: WithdrawStyle.typeChipBorderDarkOpacity)
        : ColorConstants.themeColor.withValues(
            alpha: WithdrawStyle.typeChipBorderLightOpacity,
          );

    return Opacity(
      // 不可提现时网络切换整体半透明，让视觉状态和真实可用性保持一致。
      opacity: enabled ? 1 : 0.48,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: WithdrawStyle.typeChipPadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(WithdrawStyle.typeChipRadius),
            color: selected
                ? ColorConstants.themeColor.withValues(
                    alpha: isDark ? 0.16 : 0.12,
                  )
                : isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isDark
                  ? ColorConstants.whiteColor
                  : ColorConstants.lightTextColor,
              fontSize: 13,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
