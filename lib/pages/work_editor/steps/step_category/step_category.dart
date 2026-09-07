// ignore_for_file: non_constant_identifier_names

import 'package:app/common_style/selection_chip/index.dart';
import 'package:app/common_style/selection_chip/style.dart';
import 'package:app/models/preference.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/interest_preference/style.dart';
import 'package:app/pages/work_editor/widgets/editor_section_card.dart';
import 'package:app/pages/work_editor/widgets/step_utils.dart';
import 'package:app/stores/preference_store.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';

/// TODO 步骤2：偏好选择。
///
/// 布局结构（与兴趣偏好页面一致）：
/// 1. 标题 + 副标题
/// 2. 性别偏好（单选）
/// 3. 状态（单选，原「完结偏好」）
/// 4. 篇幅（单选，原「篇幅偏好」）
/// 5. 分类（多选，最多5个，原「内容偏好」）
class StepCategory extends StatelessWidget {
  /// TODO 是否夜间主题。
  final bool is_dark;

  /// TODO 各偏好分类的选中项（key 为偏好类别 id，value 为已选选项 id 集合）。
  final Map<int, Set<int>> selected_preference_map;

  /// TODO 偏好切换回调（参数：偏好类别 id、选项 id）。
  final void Function(int preference_id, int item_id) on_toggle_preference;

  const StepCategory({
    super.key,
    required this.is_dark,
    required this.selected_preference_map,
    required this.on_toggle_preference,
  });

  @override
  Widget build(BuildContext context) {
    final List<Preference> preferences =
        Get.find<PreferenceStore>().preference_list;

    return StepUtils.build_step_scroll_view(
      context: context,
      children: <Widget>[
        EditorSectionCard(
          title: easy.tr('creator_center.category_step_title'),
          subtitle: easy.tr('creator_center.category_step_subtitle'),
          is_dark: is_dark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _build_preference_sections(preferences),
          ),
        ),
      ],
    );
  }

  /// TODO 构建所有偏好分类区块。
  List<Widget> _build_preference_sections(List<Preference> preferences) {
    if (preferences.isEmpty) return <Widget>[];

    final List<Widget> sections = <Widget>[];
    for (int i = 0; i < preferences.length; i++) {
      final Preference pref = preferences[i];
      final String display_title = _get_display_title(pref);
      final bool force_single = _is_force_single(pref);

      /// 第一个区块间距10px，其余20px。
      sections.add(SizedBox(height: i == 0 ? 10 : 20));

      sections.add(
        _build_preference_section(
          preference: pref,
          display_title: display_title,
          force_single: force_single,
        ),
      );
    }
    return sections;
  }

  /// TODO 判断是否强制单选（状态、篇幅）。
  bool _is_force_single(Preference preference) {
    final String original = preference.title;
    /// 状态（完结偏好）强制单选。
    if (original.contains('完结') || original.toLowerCase().contains('complet')) {
      return true;
    }
    /// 篇幅强制单选。
    return original.contains('篇幅') || original.toLowerCase().contains('length');
  }

  /// TODO 获取显示标题（覆盖特定偏好标题）。
  String _get_display_title(Preference preference) {
    final String original = preference.title;

    if (original.contains('完结') || original.toLowerCase().contains('complet')) {
      return easy.tr('creator_center.preference_status');
    }

    if (original.contains('篇幅') || original.toLowerCase().contains('length')) {
      return easy.tr('creator_center.preference_length');
    }

    if (original.contains('内容') || original.toLowerCase().contains('content')) {
      return easy.tr('creator_center.preference_category');
    }

    return original;
  }

  /// TODO 构建单个偏好分类区块。
  Widget _build_preference_section({
    required Preference preference,
    required String display_title,
    required bool force_single,
  }) {
    final Set<int> selected_set =
        selected_preference_map[preference.id] ?? <int>{};
    final bool is_single = preference.is_single_select || force_single;
    final bool is_category = !is_single;
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
                display_title,
                style: TextStyle(
                  fontSize: InterestPreferenceStyle.sectionTitleSize,
                  fontWeight: InterestPreferenceStyle.sectionTitleWeight,
                  color: AuthorStyle.primary_text(is_dark),
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
                color: AuthorStyle.secondary_text(is_dark),
              ),
            ),
            if (is_category) ...<Widget>[
              const SizedBox(width: 8),
              Text(
                easy
                    .tr('creator_center.category_selected_count')
                    .replaceAll('{selected}', '${selected_set.length}')
                    .replaceAll('{max}', '5'),
                style: TextStyle(
                  fontSize: InterestPreferenceStyle.sectionHintSize,
                  color: AuthorStyle.secondary_text(is_dark),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(
            height: InterestPreferenceStyle.sectionTitleBottomSpacing),

        /// 标签网格（左对齐）。
        _build_chip_grid(
          preference: preference,
          selected_set: selected_set,
          is_single: is_single,
        ),
      ],
    );
  }

  /// TODO 构建标签网格（左对齐）。
  Widget _build_chip_grid({
    required Preference preference,
    required Set<int> selected_set,
    required bool is_single,
  }) {
    final List<String> labels = preference.data_list
        .map((PreferenceItem item) => item.title)
        .toList();
    final List<int> item_ids = preference.data_list
        .map((PreferenceItem item) => item.id)
        .toList();

    return LayoutBuilder(
      builder: (BuildContext ctx, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth;
        final int columns =
            InterestPreferenceStyle.columnsByWidth(availableWidth);
        final double chipWidth =
            InterestPreferenceStyle.chipWidthByColumns(availableWidth, columns);

        final bool is_cjk = LanguageUtil.is_cjk_language(
          ctx.locale.languageCode,
        );
        final double chip_font_size = is_cjk
            ? InterestPreferenceStyle.chipFontSizeCjk
            : InterestPreferenceStyle.chipFontSizeAlphabetic;
        final double chip_h_padding = is_cjk
            ? InterestPreferenceStyle.chipHorizontalPaddingCjk
            : InterestPreferenceStyle.chipHorizontalPaddingAlphabetic;
        final double textAreaWidth = chipWidth - chip_h_padding * 2;

        final List<double> textHeights = _measure_text_heights(
          labels: labels,
          fontSize: chip_font_size,
          maxWidth: textAreaWidth,
        );

        final Map<int, double> rowHeights = _compute_row_heights(
          textHeights: textHeights,
          columns: columns,
          verticalPadding: SelectionChipStyle.verticalPadding,
        );

        final List<Widget> children = [];
        int rowIndex = 0;
        int chipInRow = 0;

        for (int i = 0; i < labels.length; i++) {
          final double rowHeight = rowHeights[rowIndex] ?? 0;

          children.add(SizedBox(
            height: rowHeight > 0 ? rowHeight : null,
            child: SelectionChip(
              label: labels[i],
              selected: selected_set.contains(item_ids[i]),
              isDark: is_dark,
              fixedWidth: chipWidth,
              horizontalPadding: chip_h_padding,
              fontSize: chip_font_size,
              maxLines: 2,
              borderRadius: InterestPreferenceStyle.chipBorderRadius,
              onTap: () => _handle_toggle(
                preference: preference,
                item_id: item_ids[i],
                is_single: is_single,
              ),
            ),
          ));

          chipInRow++;
          if (chipInRow >= columns && i < labels.length - 1) {
            rowIndex++;
            chipInRow = 0;
          }
        }

        /// 左对齐：使用 Align 包裹 Wrap。
        return Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: InterestPreferenceStyle.chipSpacing,
            runSpacing: InterestPreferenceStyle.chipRunSpacing,
            children: children,
          ),
        );
      },
    );
  }

  /// TODO 处理标签切换。
  void _handle_toggle({
    required Preference preference,
    required int item_id,
    required bool is_single,
  }) {
    final Set<int> current =
        selected_preference_map[preference.id] ?? <int>{};

    /// 多选时检查上限。
    if (!is_single && !current.contains(item_id) && current.length >= 5) {
      showBottomTip(easy.tr('creator_center.category_limit'));
      return;
    }

    on_toggle_preference(preference.id, item_id);
  }

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
