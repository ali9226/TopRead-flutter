import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';

import '../style.dart';

/// 单条账单记录卡片。
///
/// 父页面负责把原始接口数据整理成“可以直接展示”的文案，
/// 这个组件只负责最终视觉渲染和局部交互，例如复制流水号。
class BillRecordCard extends StatelessWidget {
  /// 当前主题是否为深色模式。
  final bool isDark;

  /// 账单标题，例如充值、提现、牌局结算等。
  final String title;

  /// 账单左侧图标名称。
  final String iconName;

  /// 金额展示文本。
  ///
  /// 这里传入的值已经在外层补好了正负号和千分位。
  final String amountText;

  /// 当前金额是否表示收入增加。
  ///
  /// 这个布尔值会同时影响：
  /// 1. 左侧图标底色
  /// 2. 金额颜色
  /// 3. 增减标签文案
  final bool isIncrease;

  /// 流水号原文。
  final String serialNumber;

  /// 已经格式化好的更新时间文本。
  final String updateTimeText;

  /// 点击复制流水号时的回调。
  final VoidCallback onCopySerialNumber;

  const BillRecordCard({
    super.key,
    required this.isDark,
    required this.title,
    required this.iconName,
    required this.amountText,
    required this.isIncrease,
    required this.serialNumber,
    required this.updateTimeText,
    required this.onCopySerialNumber,
  });

  @override
  Widget build(BuildContext context) {
    /// 标题文字颜色。
    final Color titleColor = isDark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;

    /// 根据金额方向切换成功色或危险色。
    final Color amountColor = isIncrease
        ? ColorConstants.successColor
        : ColorConstants.dangerColor;

    /// 深色模式下用偏冷的浅蓝色做局部高光，
    /// 让卡片边界在暗背景里更清楚。
    const Color coldBlueAccent = Color(0xFF8DB7FF);

    /// 深色模式下第二层装饰光斑使用的淡蓝色。
    const Color nightGlowColor = Color(0xFFB8CCFF);

    return Container(
      /// 卡片与卡片之间的底部间距。
      margin: const EdgeInsets.only(bottom: Style.billCardBottomMargin),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          /// 外层渐变主要负责整体轮廓和氛围。
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? <Color>[
                  ColorConstants.nightHighlightColor,
                  const Color(0xFF1C2230),
                ]
              : <Color>[
                  ColorConstants.themeColor.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.88),
                ],
        ),
        borderRadius: BorderRadius.circular(Style.billCardRadius),
        border: Border.all(
          /// 外层描边帮助卡片从背景里浮起来。
          width: Style.billCardOuterBorderWidth,
          color: isDark
              ? coldBlueAccent.withValues(alpha: 0.16)
              : ColorConstants.themeColor.withValues(alpha: 0.14),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            /// 阴影负责建立卡片悬浮感。
            color: Colors.black.withValues(
              alpha: isDark
                  ? Style.billCardShadowDarkOpacity
                  : Style.billCardShadowLightOpacity,
            ),
            blurRadius: Style.billCardShadowBlur,
            offset: const Offset(0, Style.billCardShadowOffsetY),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          /// 内层圆角略小一圈，
          /// 让外层描边和内层内容形成双层卡片结构。
          borderRadius: BorderRadius.circular(Style.billCardInnerRadius),
          border: Border.all(
            /// 内层描边只做极轻微的玻璃高光感。
            color: isDark
                ? Colors.white.withValues(
                    alpha: Style.billCardInnerBorderDarkOpacity,
                  )
                : Colors.white.withValues(
                    alpha: Style.billCardInnerBorderLightOpacity,
                  ),
          ),
          gradient: LinearGradient(
            /// 内层渐变让卡片内容区更有体积，不至于显得平。
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? <Color>[
                    Colors.white.withValues(alpha: 0.04),
                    Colors.white.withValues(alpha: 0.015),
                  ]
                : <Color>[Colors.white, const Color(0xFFFFFBF0)],
          ),
        ),
        child: ClipRRect(
          /// 裁切掉内部装饰光斑超出的部分，保证所有视觉元素都被限制在卡片圆角内。
          borderRadius: BorderRadius.circular(Style.billCardInnerRadius),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: Style.billCardGlowOneTop,
                right: Style.billCardGlowOneRight,
                child: IgnorePointer(
                  child: Container(
                    /// 右上角大光斑，跟随金额方向变色，
                    /// 让用户一眼感知当前账单偏“收入”还是“支出”。
                    width: Style.billCardGlowOneSize,
                    height: Style.billCardGlowOneSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: amountColor.withValues(
                        alpha: isDark ? 0.12 : Style.billCardGlowLightOpacity,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: Style.billCardGlowTwoLeft,
                bottom: Style.billCardGlowTwoBottom,
                child: IgnorePointer(
                  child: Container(
                    /// 左下角辅助光斑。
                    /// 它的作用不是传达业务，而是平衡视觉重心，避免整个卡片亮点都堆在右上。
                    width: Style.billCardGlowTwoSize,
                    height: Style.billCardGlowTwoSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          (isDark ? nightGlowColor : ColorConstants.themeColor)
                              .withValues(
                                alpha: isDark
                                    ? 0.16
                                    : Style.billCardGlowLightOpacity,
                              ),
                    ),
                  ),
                ),
              ),
              Padding(
                /// 真正可读内容的统一内边距。
                padding: Style.billCardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          /// 左侧圆形图标承载区。
                          width: Style.billTypeOrbSize,
                          height: Style.billTypeOrbSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: amountColor.withValues(
                              alpha: isDark ? 0.18 : 0.14,
                            ),
                          ),
                          child: Center(
                            child: SvgIcon(
                              /// 使用父级已经算好的图标名称。
                              name: iconName,
                              width: Style.billTypeOrbIconSize,
                              height: Style.billTypeOrbIconSize,
                              color: amountColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: Style.billHeaderSpacing),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                /// 账单类型主标题。
                                title,
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: Style.billCardTitleSize,
                                  fontWeight: Style.billCardTitleWeight,
                                ),
                              ),
                              const SizedBox(
                                height: Style.billTypeValueBottomSpacing,
                              ),

                              /// 增加 / 减少方向标签。
                              _BillAmountDirectionBadge(
                                isIncrease: isIncrease,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            /// 金额胶囊保持最小宽度，
                            /// 避免不同位数的金额导致右侧区域宽度剧烈跳动。
                            minWidth: Style.amountBadgeMinWidth,
                          ),
                          child: Container(
                            /// 金额区域内边距。
                            padding: Style.amountBadgePadding,
                            decoration: BoxDecoration(
                              /// 用金额方向色做淡色背景，强化涨跌语义。
                              color: amountColor.withValues(
                                alpha: isDark
                                    ? Style.amountBadgeDarkOpacity
                                    : Style.amountBadgeLightOpacity,
                              ),
                              borderRadius: BorderRadius.circular(
                                Style.amountBadgeRadius,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  /// 金额标签小标题。
                                  easy.tr('bill.amount'),
                                  style: TextStyle(
                                    color: amountColor.withValues(
                                      alpha: isDark
                                          ? Style.amountBadgeLabelDarkOpacity
                                          : Style.amountBadgeLabelLightOpacity,
                                    ),
                                    fontSize: Style.amountBadgeLabelSize,
                                    fontWeight: Style.amountBadgeLabelWeight,
                                  ),
                                ),
                                const SizedBox(
                                  height: Style.amountBadgeInnerSpacing,
                                ),
                                Text(
                                  /// 实际金额值。
                                  amountText,
                                  style: TextStyle(
                                    color: amountColor,
                                    fontSize: Style.amountTextSize,
                                    fontWeight: Style.amountTextWeight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Style.billDividerSpacing),
                    Container(
                      /// 头部信息和底部详情之间的分隔线。
                      height: 1,
                      color: isDark
                          ? coldBlueAccent.withValues(alpha: 0.16)
                          : Colors.black.withValues(
                              alpha: Style.billDividerLightOpacity,
                            ),
                    ),
                    const SizedBox(height: Style.billDividerSpacing),
                    _BillInfoRow(
                      /// 流水号行。
                      label: easy.tr('bill.serial_number'),
                      value: serialNumber,
                      isDark: isDark,
                      copyValue: serialNumber,
                      onCopy: onCopySerialNumber,
                    ),
                    const SizedBox(height: Style.infoRowSpacing),
                    _BillInfoRow(
                      /// 时间行。
                      label: easy.tr('bill.time'),
                      value: updateTimeText,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 底部信息行。
///
/// 同一套结构同时服务“流水号”和“时间”两行，
/// 这样左标签右内容的对齐方式能完全保持一致。
class _BillInfoRow extends StatelessWidget {
  /// 左侧字段名。
  final String label;

  /// 右侧字段值。
  final String value;

  /// 当前主题是否为深色模式。
  final bool isDark;

  /// 如果有值，则表示这行支持复制。
  final String? copyValue;

  /// 点击复制时执行的回调。
  final VoidCallback? onCopy;

  const _BillInfoRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.copyValue,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      /// 信息值可能换行，所以整体顶部对齐比垂直居中更稳妥。
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          /// 固定左侧标签宽度，让所有行的右侧内容从同一列开始。
          width: Style.infoLabelWidth,
          child: Text(
            label,
            style: TextStyle(
              /// 标签文字故意弱化，让阅读重点落在右侧真实值上。
              color: isDark
                  ? ColorConstants.whiteColor.withValues(
                      alpha: Style.infoLabelDarkOpacity,
                    )
                  : ColorConstants.hintColor,
              fontSize: Style.infoLabelSize,
              fontWeight: Style.infoLabelWeight,
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            /// 只有可复制时才挂点击事件。
            onTap: copyValue != null && copyValue!.isNotEmpty ? onCopy : null,

            /// 扩大点击热区，让复制流水号更容易点中。
            behavior: HitTestBehavior.translucent,
            child: Row(
              /// 右侧内容整体右对齐，更符合“标签-值”信息表的阅读习惯。
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Flexible(
                  child: Text(
                    value,

                    /// 值文本右对齐，和复制图标一起靠右收口。
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: isDark
                          ? ColorConstants.whiteColor.withValues(
                              alpha: Style.infoValueDarkOpacity,
                            )
                          : ColorConstants.lightTextColor,
                      fontSize: Style.infoValueSize,
                      fontWeight: Style.infoValueWeight,
                    ),
                  ),
                ),
                if (copyValue != null && copyValue!.isNotEmpty) ...<Widget>[
                  /// 只有支持复制时才展示复制图标，
                  /// 避免时间行这种纯展示字段产生误导。
                  const SizedBox(width: Style.infoCopySpacing),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: Style.infoCopyTopPadding,
                    ),
                    child: SvgIcon(
                      /// 复制图标。
                      name: 'copy',
                      width: Style.infoCopyIconSize,
                      height: Style.infoCopyIconSize,
                      color: isDark
                          ? ColorConstants.whiteColor.withValues(
                              alpha: Style.infoCopyDarkOpacity,
                            )
                          : ColorConstants.hintColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 金额方向徽标。
///
/// 通过一小块“增加 / 减少”标签，进一步强化金额正负的语义，
/// 避免用户只靠颜色判断，尤其是色觉不敏感用户。
class _BillAmountDirectionBadge extends StatelessWidget {
  /// 是否为增加。
  final bool isIncrease;

  /// 当前主题是否为深色模式。
  final bool isDark;

  const _BillAmountDirectionBadge({
    required this.isIncrease,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    /// 根据金额方向切换徽标主色。
    final Color badgeColor = isIncrease
        ? ColorConstants.successColor
        : ColorConstants.dangerColor;

    return Container(
      /// 徽标内边距让文字拥有胶囊感。
      padding: Style.billDirectionBadgePadding,
      decoration: BoxDecoration(
        /// 使用半透明底色，而不是纯色整块，
        /// 这样能传达方向信息，但不会和右侧金额胶囊抢主次。
        color: badgeColor.withValues(
          alpha: isDark
              ? Style.billDirectionBadgeDarkOpacity
              : Style.billDirectionBadgeLightOpacity,
        ),
        borderRadius: BorderRadius.circular(Style.billDirectionBadgeRadius),
      ),
      child: Text(
        /// 多语种方向文案。
        easy.tr(isIncrease ? 'bill.increase' : 'bill.decrease'),
        style: TextStyle(
          color: badgeColor,
          fontSize: Style.billDirectionBadgeTextSize,
          fontWeight: Style.billDirectionBadgeTextWeight,
        ),
      ),
    );
  }
}
