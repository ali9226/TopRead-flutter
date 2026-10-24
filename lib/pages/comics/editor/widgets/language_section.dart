// ignore_for_file: non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/comics/editor/logic.dart';
import 'package:app/pages/comics/editor/models.dart';
import 'package:app/pages/comics/editor/style.dart';
import 'package:app/pages/comics/editor/widgets/basic_info_form.dart'
    show comic_editor_input_decoration;
import 'package:app/pages/comics/editor/widgets/chapter_section.dart';
import 'package:app/pages/comics/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 语种版本分区：语种切换芯片 + 当前语种标题/简介 + 章节列表。
class LanguageSection extends StatelessWidget {
  /// 编辑器逻辑层。
  final ComicEditorLogic logic;

  /// 是否允许编辑。
  final bool enabled;

  /// 添加图片回调，参数为章节下标。
  final void Function(int chapter_index) on_add_images;

  /// 删除章节回调。
  final void Function(int chapter_index) on_remove_chapter;

  /// 删除语种回调，参数为语种下标。
  final void Function(int language_index) on_remove_language;

  /// 为当前语种设置封面。
  final VoidCallback on_pick_language_cover;

  const LanguageSection({
    super.key,
    required this.logic,
    required this.enabled,
    required this.on_add_images,
    required this.on_remove_chapter,
    required this.on_remove_language,
    required this.on_pick_language_cover,
  });

  @override
  Widget build(BuildContext context) {
    final ComicEditorLanguage? language = logic.selected_language;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 分区标题 + 添加语种。
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                tr('comics.language_versions'),
                style: ComicEditorStyle.section_title(context),
              ),
            ),
            TextButton.icon(
              onPressed: enabled ? () => _show_add_language(context) : null,
              icon: const Icon(Icons.add, size: 18),
              label: Text(tr('comics.add_language')),
              style: ComicsStyle.text_button(context),
            ),
          ],
        ),
        const SizedBox(height: ComicEditorStyle.section_title_gap),

        /// 语种切换芯片。
        _LanguageChips(
          logic: logic,
          enabled: enabled,
          on_remove_language: on_remove_language,
        ),

        if (language == null) ...<Widget>[
          const SizedBox(height: ComicEditorStyle.field_spacing),
          _EmptyLanguages(
            enabled: enabled,
            on_add: () => _show_add_language(context),
          ),
        ] else ...<Widget>[
          const SizedBox(height: ComicEditorStyle.field_spacing),

          /// 版本标题。
          Text(
            tr('comics.version_title'),
            style: ComicEditorStyle.label(context),
          ),
          const SizedBox(height: ComicEditorStyle.label_bottom_spacing),
          TextFormField(
            enabled: enabled,
            key: ValueKey('language_title_${language.id}_${language.language}'),
            initialValue: language.title,
            onChanged: (String value) => logic.update_language(title: value),
            decoration: comic_editor_input_decoration(
              context,
              tr('comics.version_title'),
            ),
            style: ComicEditorStyle.input_text(context),
          ),
          const SizedBox(height: ComicEditorStyle.field_spacing),

          /// 版本简介。
          Text(
            tr('comics.description'),
            style: ComicEditorStyle.label(context),
          ),
          const SizedBox(height: ComicEditorStyle.label_bottom_spacing),
          TextFormField(
            enabled: enabled,
            key: ValueKey('language_desc_${language.id}_${language.language}'),
            initialValue: language.description,
            onChanged: (String value) =>
                logic.update_language(description: value),
            minLines: ComicEditorStyle.description_min_lines,
            maxLines: ComicEditorStyle.description_max_lines,
            decoration: comic_editor_input_decoration(
              context,
              tr('comics.description'),
            ),
            style: ComicEditorStyle.input_text(context),
          ),

          /// 章节分区。
          const SizedBox(height: ComicEditorStyle.section_spacing),
          ChapterSection(
            logic: logic,
            enabled: enabled,
            on_add_images: on_add_images,
            on_remove_chapter: on_remove_chapter,
          ),
        ],
      ],
    );
  }

  /// 弹出添加语种面板。
  Future<void> _show_add_language(BuildContext context) async {
    final String? code = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: ColorConstants.transparent,
      builder: (BuildContext sheet_context) => const _LanguagePickerSheet(),
    );
    if (code == null || code.isEmpty) return;
    logic.add_language(language: code);
  }
}

/// 无语种时的引导。
class _EmptyLanguages extends StatelessWidget {
  final bool enabled;
  final VoidCallback on_add;

  const _EmptyLanguages({required this.enabled, required this.on_add});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ComicEditorStyle.card_padding_v),
      decoration: BoxDecoration(
        color: ComicEditorStyle.input_fill(context),
        borderRadius: BorderRadius.circular(ComicEditorStyle.chapter_radius),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.translate,
            size: 36,
            color: ComicEditorStyle.input_hint(context),
          ),
          const SizedBox(height: LayoutConfig.space_12),
          Text(
            tr('comics.add_first_language'),
            textAlign: TextAlign.center,
            style: ComicsStyle.text(context, color: ComicsStyle.muted(context)),
          ),
          const SizedBox(height: LayoutConfig.space_14),
          ElevatedButton(
            onPressed: enabled ? on_add : null,
            style: ComicEditorStyle.primary_button(context),
            child: Text(tr('comics.add_language')),
          ),
        ],
      ),
    );
  }
}

/// 语种切换芯片行，支持左右滑动浏览更多语种。
class _LanguageChips extends StatelessWidget {
  final ComicEditorLogic logic;
  final bool enabled;
  final void Function(int language_index) on_remove_language;

  const _LanguageChips({
    required this.logic,
    required this.enabled,
    required this.on_remove_language,
  });

  @override
  Widget build(BuildContext context) {
    if (logic.data.languages.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List<Widget>.generate(logic.data.languages.length, (
          int index,
        ) {
          final ComicEditorLanguage language = logic.data.languages[index];
          final bool selected = index == logic.selected_language_index;
          return Padding(
            padding: const EdgeInsets.only(
              right: ComicEditorStyle.chip_spacing,
            ),
            child: _LanguageChip(
              label: language.language.toUpperCase(),
              selected: selected,
              enabled: enabled,
              onTap: () => logic.select_language(index),
              on_remove: () => on_remove_language(index),
            ),
          );
        }),
      ),
    );
  }
}

/// 单个语种芯片：选中态高亮 + 删除入口。
class _LanguageChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback on_remove;

  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.on_remove,
  });

  @override
  Widget build(BuildContext context) {
    final Color background = selected
        ? ColorConstants.themeColor.withValues(alpha: 0.22)
        : ComicEditorStyle.tag_unselected(context);
    final Color ink = selected
        ? ColorConstants.lightTextColor
        : ComicEditorStyle.tag_unselected_ink(context);
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(ComicEditorStyle.chip_radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ComicEditorStyle.chip_radius),
        child: Padding(
          padding: ComicEditorStyle.chip_padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontSize: ComicEditorStyle.chip_font_size,
                  color: ink,
                ),
              ),
              if (enabled) ...<Widget>[
                const SizedBox(width: LayoutConfig.space_6),
                GestureDetector(
                  onTap: on_remove,
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: ink.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 语种选择面板：常用语种代码一键添加。
class _LanguagePickerSheet extends StatelessWidget {
  const _LanguagePickerSheet();

  /// 常用语种代码，覆盖应用当前四语种与若干扩展语种。
  static const List<String> _codes = <String>[
    'en',
    'zh',
    'fr',
    'sw',
    'es',
    'pt',
    'ar',
    'hi',
    'ja',
    'ko',
    'ru',
    'de',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          LayoutConfig.space_16,
          LayoutConfig.space_12,
          LayoutConfig.space_16,
          LayoutConfig.space_20,
        ),
        decoration: BoxDecoration(
          color: ComicsStyle.surface(context),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(LayoutConfig.radius_24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: ComicsStyle.outline(context),
                  borderRadius: BorderRadius.circular(LayoutConfig.radius_pill),
                ),
              ),
            ),
            const SizedBox(height: LayoutConfig.space_16),
            Text(
              tr('comics.select_language'),
              style: ComicEditorStyle.section_title(context),
            ),
            const SizedBox(height: LayoutConfig.space_14),
            Wrap(
              spacing: ComicEditorStyle.chip_spacing,
              runSpacing: ComicEditorStyle.chip_spacing,
              children: _codes
                  .map(
                    (String code) => ActionChip(
                      label: Text(code.toUpperCase()),
                      onPressed: () => Navigator.of(context).pop(code),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ComicEditorStyle.chip_radius,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
