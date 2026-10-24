// ignore_for_file: non_constant_identifier_names

import 'package:app/components/reader_theme_options/style.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 长篇、短篇和漫画共用主题选项，切换动画由各阅读会话持有。
class ReaderThemeOptions extends StatelessWidget {
  const ReaderThemeOptions({
    super.key,
    required this.is_dark,
    required this.on_change,
    this.label_width,
  });

  final bool is_dark;
  final ValueChanged<bool> on_change;
  final double? label_width;

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final label = Text(
      tr('short_story_read.theme'),
      style: TextStyle(
        fontSize: cjk
            ? ReaderThemeOptionsStyle.label_cjk
            : ReaderThemeOptionsStyle.label_alphabetic,
        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
        color: is_dark ? ColorConstants.whiteColor : ReaderThemeOptionsStyle.day_ink,
      ),
    );
    return Row(
      children: [
        SizedBox(width: label_width, child: label),
        const SizedBox(width: ReaderThemeOptionsStyle.label_gap),
        for (final night in [false, true]) ...[
          if (night) const SizedBox(width: ReaderThemeOptionsStyle.option_gap),
          Expanded(
            child: Semantics(
              button: true,
              selected: is_dark == night,
              child: GestureDetector(
                onTap: is_dark == night ? null : () => on_change(night),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: ReaderThemeOptionsStyle.min_height,
                  ),
                  padding: const EdgeInsets.all(
                    ReaderThemeOptionsStyle.padding,
                  ),
                  decoration: BoxDecoration(
                    color: night
                        ? ReaderThemeOptionsStyle.night_surface
                        : ColorConstants.whiteColor,
                    borderRadius: BorderRadius.circular(
                      ReaderThemeOptionsStyle.radius,
                    ),
                    border: Border.all(
                      color: is_dark == night
                          ? ColorConstants.dangerColor
                          : ColorConstants.transparent,
                      width: ReaderThemeOptionsStyle.border_width,
                    ),
                  ),
                  child: Text(
                    tr(
                      night
                          ? 'short_story_read.theme_night'
                          : 'short_story_read.theme_day',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: cjk
                          ? ReaderThemeOptionsStyle.option_cjk
                          : ReaderThemeOptionsStyle.option_alphabetic,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                      color: night
                          ? ColorConstants.whiteColor
                          : ReaderThemeOptionsStyle.day_ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
