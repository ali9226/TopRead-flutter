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
    /// 从偏好数据中提取标签文案列表和 id 列表。
    final List<String> labels = preference.data_list
        .map((PreferenceItem item) => item.title)
        .toList();
    final List<int> item_ids = preference.data_list
        .map((PreferenceItem item) => item.id)
        .toList();

    /// 根据 single_select 字段选择单选或多选提示文案。
    final bool is_single = preference.is_single_select;
    final String hint_key = is_single
        ? 'interest_preference.single_select_hint'
        : 'interest_preference.multi_select_hint';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 分组标题行：左侧标题 + 右侧单选/多选提示。
        Row(
          children: <Widget>[
            /// 分类标题文字。
            Text(
              preference.title,
              style: TextStyle(
                fontSize: InterestPreferenceStyle.sectionTitleSize,
                fontWeight: InterestPreferenceStyle.sectionTitleWeight,
                color: InterestPreferenceStyle.sectionTitleColor(isDark: isDark),
              ),
            ),
            const SizedBox(width: 8),

            /// 单选/多选提示文字。
            Text(
              easy.tr(hint_key),
              style: TextStyle(
                fontSize: InterestPreferenceStyle.sectionHintSize,
                color: InterestPreferenceStyle.sectionHintColor(isDark: isDark),
              ),
            ),
          ],
        ),

        /// 标题与标签网格之间的间距。
        const SizedBox(height: InterestPreferenceStyle.sectionTitleBottomSpacing),

        /// 标签网格：根据屏幕宽度自适应列数，固定宽度等分。
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
  /// 根据可用宽度计算列数和每个标签的固定宽度，
  /// 使用 Wrap 布局实现自动换行。
  /// 文字长度差异由标签自身的 minFontSize 缩放机制处理，
  /// 列数在 CJK 和非 CJK 语种间保持一致。
  Widget _build_chip_grid({
    required BuildContext context,
    required List<String> labels,
    required List<int> itemIds,
    required bool isDark,
  }) {
    /// 根据当前语种判断是否为 CJK，用于调整标签字号和内边距。
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );

    /// 根据语种选择标签字号和内边距。
    final double chip_font_size = is_cjk
        ? InterestPreferenceStyle.chipFontSizeCjk
        : InterestPreferenceStyle.chipFontSizeAlphabetic;
    final double chip_h_padding = is_cjk
        ? InterestPreferenceStyle.chipHorizontalPaddingCjk
        : InterestPreferenceStyle.chipHorizontalPaddingAlphabetic;

    /// 计算可用宽度（屏幕宽度 - 左右内边距）。
    final double availableWidth = MediaQuery.of(context).size.width
        - InterestPreferenceStyle.pageHorizontalPadding * 2;

    /// 根据可用宽度计算每行列数（与语种无关，保持一致的网格布局）。
    final int columns = InterestPreferenceStyle.columnsByWidth(availableWidth);

    /// 根据列数计算每个标签的固定宽度。
    final double chipWidth =
        InterestPreferenceStyle.chipWidthByColumns(availableWidth, columns);

    return Wrap(
      spacing: InterestPreferenceStyle.chipSpacing,
      runSpacing: InterestPreferenceStyle.chipRunSpacing,
      children: List<Widget>.generate(labels.length, (int index) {
        return SelectionChip(
          label: labels[index],
          selected: selectedSet.contains(itemIds[index]),
          isDark: isDark,
          fixedWidth: chipWidth,
          horizontalPadding: chip_h_padding,
          fontSize: chip_font_size,
          minFontSize: InterestPreferenceStyle.chipMinFontSize,
          borderRadius: InterestPreferenceStyle.chipBorderRadius,
          fixedHeight: SelectionChipStyle.chipHeight,
          onTap: () => onToggle(index),
        );
      }),
    );
  }
}
