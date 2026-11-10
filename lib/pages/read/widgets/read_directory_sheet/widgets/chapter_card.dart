import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/models/novel_info.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../style.dart';

/// TODO 纯文字章节卡片；当前章仅以红色描边强调，文字保持正常阅读颜色。
class DirectoryChapterCard extends StatelessWidget {
  const DirectoryChapterCard({
    super.key,
    required this.chapter,
    required this.is_current,
    required this.is_dark,
    required this.progress_percent,
    required this.on_tap,
    required this.on_continue,
  });
  final NovelChapterInfo chapter;
  final bool is_current;
  final bool is_dark;
  final double progress_percent;
  final VoidCallback on_tap;
  final VoidCallback on_continue;

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(context.locale.languageCode);
    final accent = ColorConstants.dangerColor;
    final ink = ReadDirectorySheetStyle.getPrimaryTextColor(is_dark);
    final muted = ReadDirectorySheetStyle.getSubTextColor(is_dark);
    final label = tr(
      'read.chapter_label',
      args: [chapter.chapter_no.toString()],
    );
    final title = chapter.title.trim();
    final has_distinct_title =
        title.isNotEmpty && title.toLowerCase() != label.toLowerCase();
    final progress = progress_percent.clamp(0.0, 100.0);
    final radius = BorderRadius.circular(
      ReadDirectorySheetStyle.chapter_radius,
    );
    final title_style = TextStyle(
      fontSize: cjk
          ? ReadDirectorySheetStyle.chapter_title_size_cjk
          : ReadDirectorySheetStyle.chapter_title_size_alphabetic,
      height: ReadDirectorySheetStyle.chapter_title_height,
      color: ink,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
    );
    return Semantics(
      selected: is_current,
      button: true,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: ReadDirectorySheetStyle.card_shadow(is_dark),
              blurRadius: ReadDirectorySheetStyle.chapter_shadow_blur_radius,
              offset: ReadDirectorySheetStyle.chapter_shadow_offset,
            ),
          ],
        ),
        child: Material(
          color: is_current
              ? ReadDirectorySheetStyle.getCurrentCardColor(is_dark)
              : ReadDirectorySheetStyle.getCardColor(is_dark),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: is_current
                  ? accent.withValues(alpha: .52)
                  : ink.withValues(alpha: .035),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: on_tap,
            splashColor: accent.withValues(alpha: .08),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: ReadDirectorySheetStyle.chapter_min_height,
              ),
              child: Padding(
                padding: const EdgeInsets.all(
                  ReadDirectorySheetStyle.chapter_padding,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: ReadDirectorySheetStyle.chapter_number_width,
                      padding: const EdgeInsets.symmetric(
                        vertical:
                            ReadDirectorySheetStyle.chapter_number_padding_v,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ReadDirectorySheetStyle.getChapterNumberColor(
                          is_dark,
                        ),
                        borderRadius: BorderRadius.circular(
                          ReadDirectorySheetStyle.chapter_number_radius,
                        ),
                      ),
                      child: Text(
                        chapter.chapter_no.toString().padLeft(2, '0'),
                        style: title_style.copyWith(
                          fontSize: cjk
                              ? ReadDirectorySheetStyle.chapter_number_size_cjk
                              : ReadDirectorySheetStyle
                                    .chapter_number_size_alphabetic,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width:
                          ReadDirectorySheetStyle.chapter_number_title_spacing,
                    ),
                    Expanded(
                      child: !is_current
                          ? Wrap(
                              spacing: ReadDirectorySheetStyle
                                  .chapter_number_title_spacing,
                              runSpacing:
                                  ReadDirectorySheetStyle.chapter_label_gap,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  has_distinct_title
                                      ? label
                                      : (title.isEmpty ? label : title),
                                  style: title_style,
                                ),
                                if (has_distinct_title)
                                  Text(
                                    title,
                                    style: title_style.copyWith(
                                      color: muted,
                                      fontWeight: FontConfig.adjustedWeight(
                                        FontWeight.w400,
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  has_distinct_title
                                      ? label
                                      : (title.isEmpty ? label : title),
                                  style: title_style,
                                ),
                                if (has_distinct_title) ...[
                                  const SizedBox(
                                    height: ReadDirectorySheetStyle
                                        .chapter_label_gap,
                                  ),
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: cjk
                                          ? ReadDirectorySheetStyle
                                                .chapter_title_size_cjk
                                          : ReadDirectorySheetStyle
                                                .chapter_title_size_alphabetic,
                                      height: ReadDirectorySheetStyle
                                          .chapter_title_height,
                                      color: muted,
                                      fontWeight: FontConfig.adjustedWeight(
                                        FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                                if (is_current) ...[
                                  const SizedBox(
                                    height:
                                        ReadDirectorySheetStyle.progress_gap,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            ReadDirectorySheetStyle
                                                .progress_height,
                                          ),
                                          child: LinearProgressIndicator(
                                            key: const ValueKey(
                                              'read_directory_current_progress',
                                            ),
                                            value: progress / 100,
                                            minHeight: ReadDirectorySheetStyle
                                                .progress_height,
                                            color: ColorConstants.themeColor,
                                            backgroundColor:
                                                ReadDirectorySheetStyle.getProgressTrackColor(
                                                  is_dark,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: ReadDirectorySheetStyle
                                            .progress_gap,
                                      ),
                                      Text(
                                        '${progress.round()}%',
                                        style: title_style.copyWith(
                                          fontSize: cjk
                                              ? ReadDirectorySheetStyle
                                                    .progress_label_size_cjk
                                              : ReadDirectorySheetStyle
                                                    .progress_label_size_alphabetic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                    ),
                    if (is_current) ...[
                      const SizedBox(
                        width: ReadDirectorySheetStyle.chapter_label_gap,
                      ),
                      IconButton.filled(
                        onPressed: on_continue,
                        tooltip: tr('read.directory_continue'),
                        style: IconButton.styleFrom(
                          backgroundColor: ColorConstants.themeColor,
                          foregroundColor: ColorConstants.lightTextColor,
                          minimumSize: const Size.square(
                            ReadDirectorySheetStyle.chapter_action_target,
                          ),
                        ),
                        icon: const Icon(
                          Icons.play_arrow_rounded,
                          size: ReadDirectorySheetStyle.chapter_action_icon,
                        ),
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: ReadDirectorySheetStyle.chapter_chevron_gap,
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: ReadDirectorySheetStyle.chapter_action_icon,
                          color: muted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
