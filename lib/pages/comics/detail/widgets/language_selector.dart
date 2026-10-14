// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:flutter/material.dart';

import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/util/language_util/index.dart';

/// 语种选择区：横向换行的语言胶囊，选中项高亮。
class ComicDetailLanguageSelector extends StatelessWidget {
  /// 作品详情数据。
  final ComicDetail detail;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 选中回调，参数为语言 code。
  final ValueChanged<String> on_selected;

  const ComicDetailLanguageSelector({
    super.key,
    required this.detail,
    required this.is_dark,
    required this.on_selected,
  });

  @override
  Widget build(BuildContext context) {
    if (detail.languages.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: ComicDetailStyle.language_spacing,
      runSpacing: ComicDetailStyle.language_run_spacing,
      children: <Widget>[
        for (final language in detail.languages)
          _LanguageChip(
            label: LanguageUtil.get_language_name(language.language),
            selected: detail.selected_language_id == language.id,
            is_dark: is_dark,
            onTap: () => on_selected(language.language),
          ),
      ],
    );
  }
}

/// 单个语种胶囊。
class _LanguageChip extends StatelessWidget {
  /// 语言显示名。
  final String label;

  /// 是否为当前选中语种。
  final bool selected;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 点击回调。
  final VoidCallback onTap;

  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.is_dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 选中态：主题色背景 + 黑色文字，与全局按钮体系一致。
    final Color background = selected
        ? ColorConstants.themeColor
        : is_dark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFF161C28).withValues(alpha: 0.05);
    final Color foreground = selected
        ? ColorConstants.lightTextColor
        : is_dark
        ? Colors.white.withValues(alpha: 0.78)
        : const Color(0xFF3A4150);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(ComicDetailStyle.language_radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(ComicDetailStyle.language_radius),
        onTap: onTap,
        child: Padding(
          padding: ComicDetailStyle.language_padding,
          child: Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: ComicDetailStyle.language_font_size,
              fontWeight: selected
                  ? ComicDetailStyle.weight_medium
                  : ComicDetailStyle.weight_regular,
            ),
          ),
        ),
      ),
    );
  }
}
