// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/author_center/author_style.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'style.dart';

/// 页面中的时间入口：日期和时刻分层呈现，整张卡片可点击修改。
class ScheduleTimeField extends StatelessWidget {
  const ScheduleTimeField({
    super.key,
    required this.is_dark,
    required this.selected_time,
    required this.on_tap,
  });

  final bool is_dark;
  final DateTime? selected_time;
  final VoidCallback on_tap;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    final is_cjk = LanguageUtil.is_cjk_language(context.locale.languageCode);
    final time = selected_time?.toLocal();
    final primary = AuthorStyle.primary_text(is_dark);
    final secondary = AuthorStyle.secondary_text(is_dark);
    return Material(
      color: AuthorStyle.surface(is_dark),
      borderRadius: BorderRadius.circular(ScheduleTimeStyle.card_radius),
      child: InkWell(
        key: const ValueKey('schedule_time_field'),
        onTap: on_tap,
        borderRadius: BorderRadius.circular(ScheduleTimeStyle.card_radius),
        child: Container(
          padding: const EdgeInsets.all(ScheduleTimeStyle.card_padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ScheduleTimeStyle.card_radius),
            border: Border.all(color: AuthorStyle.border(is_dark)),
          ),
          child: Row(
            children: [
              Container(
                width: ScheduleTimeStyle.badge_size,
                height: ScheduleTimeStyle.badge_size,
                decoration: BoxDecoration(
                  color: AuthorStyle.selected_tab_surface(is_dark),
                  borderRadius: BorderRadius.circular(ScheduleTimeStyle.card_radius),
                ),
                child: Icon(Icons.calendar_today_rounded,
                  size: ScheduleTimeStyle.icon_size,
                  color: AuthorStyle.selected_tab_text(is_dark)),
              ),
              const SizedBox(width: ScheduleTimeStyle.card_padding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('creator_center.select_schedule_time'),
                      style: TextStyle(
                        color: time == null ? primary : secondary,
                        fontSize: is_cjk ? ScheduleTimeStyle.label_size_cjk : ScheduleTimeStyle.label_size_alphabetic,
                        fontWeight: ScheduleTimeStyle.title_weight,
                      )),
                    const SizedBox(height: ScheduleTimeStyle.small_gap),
                    if (time != null) ...[
                      Text(DateFormat.Hm(locale).format(time),
                        style: TextStyle(color: primary,
                          fontSize: is_cjk ? ScheduleTimeStyle.time_size_cjk : ScheduleTimeStyle.time_size_alphabetic,
                          fontWeight: ScheduleTimeStyle.title_weight,
                          height: 1.1)),
                      const SizedBox(height: ScheduleTimeStyle.small_gap),
                    ],
                    Text(time == null
                        ? tr('creator_center.schedule_picker_hint')
                        : DateFormat.yMMMEd(locale).format(time),
                      style: TextStyle(color: secondary,
                        fontSize: is_cjk ? ScheduleTimeStyle.hint_size_cjk : ScheduleTimeStyle.hint_size_alphabetic,
                        height: 1.4,
                        fontWeight: ScheduleTimeStyle.body_weight)),
                  ],
                ),
              ),
              const SizedBox(width: ScheduleTimeStyle.small_gap),
              Icon(Icons.chevron_right_rounded, color: secondary,
                size: ScheduleTimeStyle.icon_size),
            ],
          ),
        ),
      ),
    );
  }
}
