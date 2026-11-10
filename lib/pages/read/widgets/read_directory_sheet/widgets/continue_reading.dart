import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../style.dart';

/// TODO 继续阅读只关闭目录并恢复原阅读位置，不把当前章进度重置为开头。
class DirectoryContinueReading extends StatelessWidget {
  const DirectoryContinueReading({
    super.key,
    required this.on_pressed,
    required this.chapter_no,
    required this.progress,
  });
  final VoidCallback? on_pressed;
  final int chapter_no;
  final double progress;
  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(context.locale.languageCode);
    final compact =
        MediaQuery.sizeOf(context).height <
        ReadDirectorySheetStyle.footer_compact_height;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          ReadDirectorySheetStyle.footer_padding,
          compact
              ? ReadDirectorySheetStyle.footer_compact_vertical_padding
              : ReadDirectorySheetStyle.footer_vertical_padding,
          ReadDirectorySheetStyle.footer_padding,
          compact
              ? ReadDirectorySheetStyle.footer_compact_vertical_padding
              : ReadDirectorySheetStyle.footer_vertical_padding,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ReadDirectorySheetStyle.footer_radius,
            ),
            gradient: LinearGradient(
              colors: [
                Color.lerp(
                  ColorConstants.themeColor,
                  ColorConstants.whiteColor,
                  .26,
                )!,
                ColorConstants.themeColor,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: ColorConstants.themeColor.withValues(alpha: .20),
                blurRadius: ReadDirectorySheetStyle.footer_shadow_blur_radius,
                offset: ReadDirectorySheetStyle.footer_shadow_offset,
              ),
            ],
          ),
          child: Material(
            color: ColorConstants.transparent,
            child: InkWell(
              key: const ValueKey('read_directory_continue'),
              onTap: on_pressed,
              borderRadius: BorderRadius.circular(
                ReadDirectorySheetStyle.footer_radius,
              ),
              child: Opacity(
                opacity: on_pressed == null ? .45 : 1,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: compact
                        ? ReadDirectorySheetStyle.footer_compact_min_height
                        : ReadDirectorySheetStyle.footer_min_height,
                  ),
                  child: Padding(
                    padding: ReadDirectorySheetStyle.footer_content_padding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          size: ReadDirectorySheetStyle.footer_icon_size,
                          color: ColorConstants.lightTextColor,
                        ),
                        const SizedBox(
                          width: ReadDirectorySheetStyle.footer_gap,
                        ),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('read.directory_continue'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ColorConstants.lightTextColor,
                                  fontSize: cjk
                                      ? ReadDirectorySheetStyle
                                            .footer_font_size_cjk
                                      : ReadDirectorySheetStyle
                                            .footer_font_size_alphabetic,
                                  fontWeight: FontConfig.adjustedWeight(
                                    FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (!compact && chapter_no > 0)
                                Text(
                                  '${tr('read.chapter_label', args: [chapter_no.toString()])} · ${progress.clamp(0, 100).round()}%',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: ColorConstants.lightTextColor
                                        .withValues(alpha: .66),
                                    fontSize: cjk
                                        ? ReadDirectorySheetStyle
                                              .footer_meta_size_cjk
                                        : ReadDirectorySheetStyle
                                              .footer_meta_size_alphabetic,
                                    fontWeight: FontConfig.adjustedWeight(
                                      FontWeight.w400,
                                    ),
                                  ),
                                ),
                            ],
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
    );
  }
}
