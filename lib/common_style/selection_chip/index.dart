import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';

import 'style.dart';

/// 通用选择标签组件。
///
/// 复用于「兴趣偏好」页面各分类选择、「短篇分类筛选栏」和「短篇筛选弹窗」，
/// 通过参数控制尺寸和布局，保持选中/未选中视觉样式统一。
///
/// 参数说明：
/// [label] - 标签展示文案。
/// [selected] - 当前是否为选中状态。
/// [isDark] - 当前是否为夜间模式。
/// [onTap] - 点击回调。
/// [horizontalPadding] - 水平内边距，覆盖默认值。
/// [fontSize] - 字号，覆盖默认值。
/// [borderRadius] - 圆角，覆盖默认值。
/// [fixedWidth] - 固定宽度，为 null 时自适应内容（筛选栏/弹窗场景）。
/// [fixedHeight] - 固定高度，为 null 时自适应内容。
class SelectionChip extends StatelessWidget {
  /// 标签展示文案。
  final String label;

  /// 当前是否为选中状态。
  final bool selected;

  /// 当前是否为夜间模式。
  final bool isDark;

  /// 点击回调。
  final VoidCallback? onTap;

  /// 水平内边距，为 null 时使用默认值。
  final double? horizontalPadding;

  /// 字号，为 null 时使用默认值。
  final double? fontSize;

  /// 圆角，为 null 时使用默认值。
  final double? borderRadius;

  /// 固定宽度，为 null 时根据文字内容自适应。
  final double? fixedWidth;

  /// 固定高度，为 null 时根据字号和内边距自适应。
  final double? fixedHeight;

  /// 文字最小缩放字号，仅在 fixedWidth 不为 null 时生效。
  /// 文字超长时自动缩小至此字号，为 null 时不缩放。
  final double? minFontSize;

  const SelectionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.isDark,
    this.onTap,
    this.horizontalPadding,
    this.fontSize,
    this.borderRadius,
    this.fixedWidth,
    this.fixedHeight,
    this.minFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final double hPad = horizontalPadding ?? SelectionChipStyle.horizontalPadding;
    final double fSize = fontSize ?? SelectionChipStyle.fontSize;
    final double bRadius = borderRadius ?? SelectionChipStyle.borderRadius;

    /// 使用固定高度时，垂直内边距为 0，由 alignment 负责居中；
    /// 自适应高度时，使用默认垂直内边距。
    final bool hasFixedHeight = fixedHeight != null;
    final double vPad = hasFixedHeight ? 0 : SelectionChipStyle.verticalPadding;

    final Widget chip = AnimatedContainer(
      duration: SelectionChipStyle.animationDuration,
      curve: Curves.easeInOut,
      width: fixedWidth,
      height: fixedHeight,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: selected
            ? SelectionChipStyle.selectedBg(isDark: isDark)
            : SelectionChipStyle.unselectedBg(isDark: isDark),
        borderRadius: BorderRadius.circular(bRadius),
        border: Border.all(
          color: selected
              ? SelectionChipStyle.selectedBorder(isDark: isDark)
              : SelectionChipStyle.unselectedBg(isDark: isDark),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: minFontSize != null
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fSize,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                  color: selected
                      ? SelectionChipStyle.selectedText(isDark: isDark)
                      : SelectionChipStyle.unselectedText(isDark: isDark),
                ),
              ),
            )
          : Text(
              label,
              style: TextStyle(
                fontSize: fSize,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                color: selected
                    ? SelectionChipStyle.selectedText(isDark: isDark)
                    : SelectionChipStyle.unselectedText(isDark: isDark),
              ),
            ),
    );

    /// 有固定宽度时（弹窗场景），直接渲染；
    /// 无固定宽度时（兴趣偏好场景），用 IntrinsicWidth 让 Wrap 能正确测量宽度。
    if (fixedWidth != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(bRadius),
          child: chip,
        ),
      );
    }

    return IntrinsicWidth(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(bRadius),
          child: chip,
        ),
      ),
    );
  }
}
