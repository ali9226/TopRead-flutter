// ignore_for_file: non_constant_identifier_names

import 'package:app/config/font_config.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/comics/detail/widgets/reading_action_bar_style.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// TODO 章节页共用底栏。章节编号来自可读目录，不从章节 ID 推断；父级负责贴底与安全区。
class ComicReadingActionBar extends StatelessWidget {
  const ComicReadingActionBar({
    super.key,
    required this.on_collect,
    required this.on_read,
    required this.collected,
    this.collecting = false,
    this.can_read = true,
    this.continuing = false,
    this.chapter_number,
  });

  final VoidCallback on_collect;
  final VoidCallback on_read;
  final bool collected;
  final bool collecting;
  final bool can_read;
  final bool continuing;
  final int? chapter_number;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final scaler = MediaQuery.textScalerOf(context);
    final surface = dark
        ? ComicReadingActionBarStyle.night_surface
        : ColorConstants.whiteColor;
    final ink = dark ? ColorConstants.whiteColor : ComicReadingActionBarStyle.ink;
    final library_label = tr(
      collected ? 'comics.collected' : 'comics.add_to_library',
    );
    final reading_label = tr(
      !can_read
          ? 'comics.unavailable'
          : continuing
          ? 'comics.continue_reading_action'
          : 'comics.start_reading',
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < ComicReadingActionBarStyle.compact_width;
        final show_book =
            constraints.maxWidth >=
                ComicReadingActionBarStyle.book_icon_min_width &&
            scaler.scale(1) < 1.4;
        final font_size = compact
            ? (cjk
                  ? ComicReadingActionBarStyle.compact_font_size_cjk
                  : ComicReadingActionBarStyle.compact_font_size_alphabetic)
            : (cjk
                  ? ComicReadingActionBarStyle.font_size_cjk
                  : ComicReadingActionBarStyle.font_size_alphabetic);
        final text_style = TextStyle(
          fontSize: font_size,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
          height: cjk
              ? ComicReadingActionBarStyle.text_height_cjk
              : ComicReadingActionBarStyle.text_height_alphabetic,
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(
              ComicReadingActionBarStyle.radius,
            ),
            border: Border.all(
              color: dark ? ColorConstants.util_dialog_show_upgrade_dialog_tone_14ffffff : ColorConstants.whiteColor,
            ),
            boxShadow: [
              BoxShadow(
                color: ColorConstants.pages_comics_detail_widgets_reading_action_bar_tone.withValues(alpha: dark ? 0.08 : 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(ComicReadingActionBarStyle.padding),
            child: Row(
              children: [
                Expanded(
                  flex: 38,
                  child: Semantics(
                    button: true,
                    toggled: collected,
                    enabled: !collecting,
                    label: library_label,
                    child: Material(
                      color: ColorConstants.transparent,
                      child: InkWell(
                        key: const ValueKey('comic_library_action'),
                        onTap: collecting ? null : on_collect,
                        borderRadius: BorderRadius.circular(
                          ComicReadingActionBarStyle.radius,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight:
                                ComicReadingActionBarStyle.button_min_height,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: ComicReadingActionBarStyle.gap,
                            ),
                            child: Row(
                              children: [
                                AnimatedSwitcher(
                                  duration:
                                      ComicReadingActionBarStyle.transition,
                                  child: Icon(
                                    collected
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    key: ValueKey(collected),
                                    size: ComicReadingActionBarStyle.icon_size,
                                    color: ColorConstants.dangerColor,
                                  ),
                                ),
                                const SizedBox(
                                  width: ComicReadingActionBarStyle.gap,
                                ),
                                Expanded(
                                  child: Text(
                                    library_label,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: text_style.copyWith(color: ink),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 0.5,
                  height: ComicReadingActionBarStyle.divider_height,
                  color: ink.withValues(alpha: 0.12),
                ),
                const SizedBox(width: ComicReadingActionBarStyle.gap),
                Expanded(
                  flex: 62,
                  child: Semantics(
                    button: true,
                    enabled: can_read,
                    child: AnimatedOpacity(
                      duration: ComicReadingActionBarStyle.transition,
                      opacity: can_read ? 1 : 0.55,
                      child: Material(
                        color: ColorConstants.transparent,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: ComicReadingActionBarStyle.gradient,
                            ),
                            borderRadius: BorderRadius.circular(
                              ComicReadingActionBarStyle.radius,
                            ),
                          ),
                          child: InkWell(
                            key: const ValueKey('comic_reading_action'),
                            onTap: can_read ? on_read : null,
                            borderRadius: BorderRadius.circular(
                              ComicReadingActionBarStyle.radius,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: ComicReadingActionBarStyle
                                    .button_min_height,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: ComicReadingActionBarStyle
                                      .button_padding_h,
                                  vertical: ComicReadingActionBarStyle
                                      .button_padding_v,
                                ),
                                child: Row(
                                  children: [
                                    if (show_book) ...[
                                      const Icon(
                                        Icons.menu_book_rounded,
                                        size: ComicReadingActionBarStyle
                                            .icon_size,
                                        color: ComicReadingActionBarStyle.ink,
                                      ),
                                      const SizedBox(
                                        width: ComicReadingActionBarStyle.gap,
                                      ),
                                    ],
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reading_label,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: text_style.copyWith(
                                              color: ComicReadingActionBarStyle
                                                  .ink,
                                            ),
                                          ),
                                          if (can_read &&
                                              chapter_number != null &&
                                              chapter_number! > 0)
                                            Text(
                                              tr(
                                                'comics.chapter_position',
                                                namedArgs: {
                                                  'index': '$chapter_number',
                                                },
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: cjk
                                                    ? ComicReadingActionBarStyle
                                                          .chapter_font_size_cjk
                                                    : ComicReadingActionBarStyle
                                                          .chapter_font_size_alphabetic,
                                                fontWeight:
                                                    FontConfig.adjustedWeight(FontWeight.w400),
                                                color:
                                                    ComicReadingActionBarStyle
                                                        .ink
                                                        .withValues(
                                                          alpha: 0.65,
                                                        ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      width: ComicReadingActionBarStyle.gap,
                                    ),
                                    const DecoratedBox(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: ComicReadingActionBarStyle
                                            .arrow_background,
                                      ),
                                      child: SizedBox.square(
                                        dimension: ComicReadingActionBarStyle
                                            .arrow_size,
                                        child: Icon(
                                          Icons.chevron_right_rounded,
                                          color: ColorConstants.pages_comics_detail_widgets_reading_action_bar_tone_ffffdf42,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
