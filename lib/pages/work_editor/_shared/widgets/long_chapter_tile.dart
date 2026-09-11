// ignore_for_file: non_constant_identifier_names
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

/// 新建长篇目录与已发布目录共用的圆角章节卡片。
class LongChapterTile extends StatelessWidget {
  const LongChapterTile({
    super.key,
    required this.title,
    required this.number,
    required this.subtitle,
    required this.dark,
    required this.index,
    required this.on_open,
    this.active = false,
    this.ordering = false,
    this.scheduled = false,
    this.schedule_time,
  });
  final String title, number, subtitle;
  final bool dark, active, ordering, scheduled;
  final int index;
  final VoidCallback? on_open;
  final String? schedule_time;
  @override
  Widget build(BuildContext context) {
    final accent = dark
        ? ColorConstants.themeColor
        : ColorConstants.lightTextColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: active
            ? accent.withValues(alpha: dark ? .10 : .11)
            : AuthorStyle.surface(dark),
        borderRadius: BorderRadius.circular(LayoutConfig.section_radius),
        child: InkWell(
          onTap: ordering ? null : on_open,
          borderRadius: BorderRadius.circular(LayoutConfig.section_radius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LayoutConfig.section_radius),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: scheduled
                      ? Icon(Icons.schedule_rounded, color: accent, size: 18)
                      : Text(
                          number.padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 15,
                            color: active
                                ? accent
                                : AuthorStyle.secondary_text(dark),
                            fontWeight: FontConfig.adjustedWeight(
                              FontWeight.w500,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty
                            ? easy.tr('creator_center.untitled_work')
                            : title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: AuthorStyle.primary_text(dark),
                          fontWeight: FontConfig.adjustedWeight(
                            FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: active
                              ? accent
                              : AuthorStyle.secondary_text(dark),
                          fontSize: 11,
                        ),
                      ),
                      if (schedule_time != null)
                        Text(
                          schedule_time!,
                          style: TextStyle(
                            color: AuthorStyle.secondary_text(dark),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                if (ordering)
                  ReorderableDragStartListener(
                    index: index,
                    enabled: on_open != null,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: AuthorStyle.secondary_text(dark),
                      ),
                    ),
                  )
                else
                  Icon(
                    active
                        ? Icons.edit_note_rounded
                        : Icons.chevron_right_rounded,
                    color: active ? accent : AuthorStyle.secondary_text(dark),
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
