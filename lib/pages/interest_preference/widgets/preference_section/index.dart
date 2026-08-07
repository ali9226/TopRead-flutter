import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as easy;

import 'package:app/pages/interest_preference/style.dart';
import 'package:app/common_style/selection_chip/index.dart';
import 'package:app/common_style/selection_chip/style.dart';
import 'package:app/models/preference.dart';
import 'package:app/util/language_util/index.dart';

/// 单个偏好分类区块组件。
///
/// 包含分类标题、选择提示（单选/多选）和标签网格。
/// 每个标签对应一个 [PreferenceItem]，点击后通过回调通知父组件。
/// 支持日间/夜间主题切换。
///
/// 标签网格布局策略：
/// 1. 用 TextPainter 计算每个标签在固定宽度下的文字高度；
/// 2. 按列数分行，取每行最大高度；
/// 3. 用 Wrap 布局渲染，矮标签通过 SizedBox 撑高到行高，保证同行等高。
///    Wrap 自动换行，不会溢出。
class PreferenceSection extends StatelessWidget {
  /// 偏好类别数据模型。
  final Preference preference;

  /// 该分类下已选中的选项 id 集合。
  final Set<int> selectedSet;

  /// 是否为夜间模式。
  final bool isDark;

  /// 标签点击回调，参数为被点击标签在 data_list 中的索引。
  final ValueChanged<int> onToggle;

  const PreferenceSection({
    super.key,
    required this.preference,
    required this.selectedSet,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> labels = preference.data_list
        .map((PreferenceItem item) => item.title)
        .toList();
    final List<int> item_ids = preference.data_list
        .map((PreferenceItem item) => item.id)
        .toList();
    final bool is_single = preference.is_single_select;
    final String hint_key = is_single
        ? 'interest_preference.single_select_hint'
        : 'interest_preference.multi_select_hint';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 分组标题行。
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Text(
                preference.title,
                style: TextStyle(
                  fontSize: InterestPreferenceStyle.sectionTitleSize,
                  fontWeight: InterestPreferenceStyle.sectionTitleWeight,
                  color: InterestPreferenceStyle.sectionTitleColor(isDark: isDark),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              easy.tr(hint_key),
              style: TextStyle(
                fontSize: InterestPreferenceStyle.sectionHintSize,
                color: InterestPreferenceStyle.sectionHintColor(isDark: isDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: InterestPreferenceStyle.sectionTitleBottomSpacing),

        /// 标签网格。
        _build_chip_grid(
          context: context,
          labels: labels,
          itemIds: item_ids,
          isDark: isDark,
        ),
      ],
    );
  }

  /// 构建标签网格。
  ///
  /// 用 TextPainter 预计算每行最大高度，Wrap 布局渲染，
  /// 矮标签通过 SizedBox 撑高到行高。
  Widget _build_chip_grid({
    required BuildContext context,
    required List<String> labels,
    required List<int> itemIds,
    required bool isDark,
  }) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );
    final double chip_font_size = is_cjk
        ? InterestPreferenceStyle.chipFontSizeCjk
        : InterestPreferenceStyle.chipFontSizeAlphabetic;
    final double chip_h_padding = is_cjk
        ? InterestPreferenceStyle.chipHorizontalPaddingCjk
        : InterestPreferenceStyle.chipHorizontalPaddingAlphabetic;

    /// 用 LayoutBuilder 获取真实约束宽度。
    return LayoutBuilder(
      builder: (BuildContext ctx, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth;
        final int columns =
            InterestPreferenceStyle.columnsByWidth(availableWidth);
        final double chipWidth =
            InterestPreferenceStyle.chipWidthByColumns(availableWidth, columns);
        final double textAreaWidth = chipWidth - chip_h_padding * 2;

        /// TextPainter 计算每个标签的文字高度。
        final List<double> textHeights = _measure_text_heights(
          labels: labels,
          fontSize: chip_font_size,
          maxWidth: textAreaWidth,
        );

        /// 按列数分行，计算每行最大标签高度。
        final Map<int, double> rowHeights = _compute_row_heights(
          textHeights: textHeights,
          columns: columns,
          verticalPadding: SelectionChipStyle.verticalPadding,
        );

        /// 构建 Wrap 子组件，每个标签用 SizedBox 撑到行高。
        final List<Widget> children = [];
        int rowIndex = 0;
        int chipInRow = 0;

        for (int i = 0; i < labels.length; i++) {
          final double rowHeight = rowHeights[rowIndex] ?? 0;

          children.add(SizedBox(
            height: rowHeight > 0 ? rowHeight : null,
            child: SelectionChip(
              label: labels[i],
              selected: selectedSet.contains(itemIds[i]),
              isDark: isDark,
              fixedWidth: chipWidth,
              horizontalPadding: chip_h_padding,
              fontSize: chip_font_size,
              maxLines: 2,
              borderRadius: InterestPreferenceStyle.chipBorderRadius,
              onTap: () => onToggle(i),
            ),
          ));

          chipInRow++;
          if (chipInRow >= columns && i < labels.length - 1) {
            rowIndex++;
            chipInRow = 0;
          }
        }

        return Wrap(
          spacing: InterestPreferenceStyle.chipSpacing,
          runSpacing: InterestPreferenceStyle.chipRunSpacing,
          children: children,
        );
      },
    );
  }

  /// 用 TextPainter 计算每个标签文案在给定宽度下的文字实际高度。
  List<double> _measure_text_heights({
    required List<String> labels,
    required double fontSize,
    required double maxWidth,
  }) {
    return labels.map((String label) {
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(fontSize: fontSize, height: 1.3),
        ),
        maxLines: 2,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);
      return painter.size.height;
    }).toList();
  }

  /// 按列数分行，计算每行的最大标签高度（文字高度 + 垂直内边距）。
  Map<int, double> _compute_row_heights({
    required List<double> textHeights,
    required int columns,
    required double verticalPadding,
  }) {
    final Map<int, double> heights = {};
    int rowIndex = 0;

    for (int i = 0; i < textHeights.length; i += columns) {
      double maxHeight = 0;
      final int end =
          (i + columns > textHeights.length) ? textHeights.length : i + columns;

      for (int j = i; j < end; j++) {
        final double chipHeight = textHeights[j] + verticalPadding * 2;
        if (chipHeight > maxHeight) {
          maxHeight = chipHeight;
        }
      }

      heights[rowIndex] = maxHeight;
      rowIndex++;
    }

    return heights;
  }
}
