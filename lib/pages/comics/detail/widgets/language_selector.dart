// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:flutter/material.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/util/language_util/index.dart';

/// TODO 作品版本独立切换，不改变App界面语言；视觉标签与透明触控区域分开布局。
class ComicDetailLanguageSelector extends StatelessWidget {
  final ComicDetail detail;
  final bool is_dark;
  final bool enabled;
  final ValueChanged<String> on_selected;
  const ComicDetailLanguageSelector({
    super.key,
    required this.detail,
    required this.is_dark,
    this.enabled = true,
    required this.on_selected,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: ComicDetailStyle.language_spacing,
    runSpacing: ComicDetailStyle.language_run_spacing,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: <Widget>[
      for (final language in detail.languages)
        _LanguageChip(
          id: language.id,
          label: LanguageUtil.get_language_name(language.language),
          selected: detail.selected_language_id == language.id,
          is_dark: is_dark,
          on_tap: enabled ? () => on_selected(language.language) : null,
        ),
    ],
  );
}

/// TODO 文字在32像素以上的色块内居中；48像素最小高度仅用于透明点击区。
class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.id,
    required this.label,
    required this.selected,
    required this.is_dark,
    required this.on_tap,
  });
  final int id;
  final String label;
  final bool selected;
  final bool is_dark;
  final VoidCallback? on_tap;

  @override
  Widget build(BuildContext context) {
    final is_cjk = ComicsStyle.is_cjk(context);
    final foreground = selected && is_dark
        ? ColorConstants.themeColor
        : ComicDetailStyle.ink(context);
    final background = selected
        ? ColorConstants.themeColor.withValues(
            alpha: ComicDetailStyle.language_selected_alpha,
          )
        : is_dark
        ? ColorConstants.sheetInputBackground(true)
        : ColorConstants.sheetInputBackground(false);
    return Semantics(
      selected: selected,
      button: true,
      enabled: on_tap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: on_tap,
          borderRadius: BorderRadius.circular(ComicDetailStyle.language_radius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: ComicDetailStyle.touch_target,
              minWidth: ComicDetailStyle.touch_target,
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: DecoratedBox(
                key: ValueKey('comic_language_visual_$id'),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(
                    ComicDetailStyle.language_radius,
                  ),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: ComicDetailStyle.language_visual_height,
                  ),
                  child: Padding(
                    padding: ComicDetailStyle.language_padding,
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        // TODO 共用行框，中文与拉丁文字的字体升降部不会改变标签高度。
                        strutStyle: StrutStyle(
                          fontFamily: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.fontFamily,
                          fontSize: is_cjk
                              ? ComicDetailStyle.label_size_cjk
                              : ComicDetailStyle.label_size_alphabetic,
                          height: ComicDetailStyle.language_line_height,
                          forceStrutHeight: true,
                        ),
                        textHeightBehavior: const TextHeightBehavior(
                          leadingDistribution: TextLeadingDistribution.even,
                        ),
                        style:
                            ComicDetailStyle.label_style(
                              context,
                              is_cjk,
                              color: foreground,
                              strong: selected,
                            ).copyWith(
                              height: ComicDetailStyle.language_line_height,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
