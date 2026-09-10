// ignore_for_file: non_constant_identifier_names

import 'package:app/common_style/selection_chip/index.dart';
import 'package:app/common_style/selection_chip/style.dart';
import 'package:app/models/preference.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/interest_preference/style.dart';
import 'package:app/pages/work_editor/_shared/widgets/editor_section_card.dart';
import 'package:app/pages/work_editor/_shared/widgets/step_utils.dart';
import 'package:app/stores/preference_store.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';

/// 步骤2：偏好选择。
///
/// 布局结构（与兴趣偏好页面一致）：
/// 1. 标题 + 副标题
/// 2. 性别偏好（单选）
/// 3. 状态（单选，原「完结偏好」）
/// 4. 篇幅（单选，原「篇幅偏好」）- 可选显示
/// 5. 分类（多选，最多5个，原「内容偏好」）
class StepCategory extends StatelessWidget {
  /// 是否夜间主题。
  final bool is_dark;

  /// 各偏好分类的选中项（key 为偏好类别 id，value 为已选选项 id 集合）。
  final Map<int, Set<int>> selected_preference_map;

  /// 偏好切换回调（参数：偏好类别 id、选项 id）。
  final void Function(int preference_id, int item_id) on_toggle_preference;

  /// 是否显示篇幅选择（默认 true，独立编辑器中设为 false）。
  final bool showLength;

  const StepCategory({
    super.key,
    required this.is_dark,
    required this.selected_preference_map,
    required this.on_toggle_preference,
    this.showLength = true,
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

  /// 构建所有偏好分类区块。
  List<Widget> _build_preference_sections(List<Preference> preferences) {
    if (preferences.isEmpty) return <Widget>[];

    final List<Widget> sections = <Widget>[];
    int displayIndex = 0;
    for (int i = 0; i < preferences.length; i++) {
      final Preference pref = preferences[i];

      // 如果不显示篇幅，跳过篇幅偏好
      if (!showLength && _isLengthPreference(pref)) {
        continue;
      }

      final String display_title = _get_display_title(pref);
      final bool force_single = _is_force_single(pref);

      /// 第一个区块间距10px，其余20px。
      sections.add(SizedBox(height: displayIndex == 0 ? 10 : 20));

      sections.add(
        _build_preference_section(
          preference: pref,
          display_title: display_title,
          force_single: force_single,
        ),
      );
      displayIndex++;
    }
    return sections;
  }

  /// 判断是否是篇幅偏好。
  bool _isLengthPreference(Preference preference) {
    final String original = preference.title;
    return original.contains('篇幅') || original.toLowerCase().contains('length');
  }

  /// 判断是否强制单选（状态、篇幅）。
  bool _is_force_single(Preference preference) {
    final String original = preference.title;
    /// 状态（完结偏好）强制单选。
    if (original.contains('完结') || original.toLowerCase().contains('complet')) {
      return true;
    }
    /// 篇幅强制单选。
    return original.contains('篇幅') || original.toLowerCase().contains('length');
  }

  /// 获取显示标题（覆盖特定偏好标题）。
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

  /// 构建单个偏好分类区块。
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

  /// 构建标签网格（左对齐）。
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
      builder: (BuildContext context, BoxConstraints constraints) {
        final double available_width = constraints.maxWidth;
        final int columns = InterestPreferenceStyle.columnsByWidth(
          available_width,
        );
        final double chip_width = InterestPreferenceStyle.chipWidthByColumns(
          available_width,
          columns,
        );

        return Wrap(
          spacing: InterestPreferenceStyle.chipSpacing,
          runSpacing: InterestPreferenceStyle.chipRunSpacing,
          children: List<Widget>.generate(labels.length, (int index) {
            final int item_id = item_ids[index];
            final bool is_selected = selected_set.contains(item_id);

            return SelectionChip(
              label: labels[index],
              selected: is_selected,
              isDark: is_dark,
              fixedWidth: chip_width,
              onTap: () => on_toggle_preference(preference.id, item_id),
            );
          }),
        );
      },
    );
  }
}
