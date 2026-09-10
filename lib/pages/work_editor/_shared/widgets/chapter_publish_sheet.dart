// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'steps/step_publish/step_publish.dart';
import 'steps/step_publish/widgets/schedule_time/picker.dart';

/// 新章节复用作品发布方式与日期组件，时间设置只属于当前章节。
Future<({CreatorReleaseMode mode, DateTime? time})?>
show_chapter_publish_sheet({
  required BuildContext context,
  required bool is_dark,
  CreatorReleaseMode initial_mode = CreatorReleaseMode.immediate,
  DateTime? initial_time,
}) {
  var mode = initial_mode;
  DateTime? time = initial_time;
  var rights = false;
  return showModalBottomSheet<({CreatorReleaseMode mode, DateTime? time})>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AuthorStyle.background(is_dark),
    builder: (context) => StatefulBuilder(
      builder: (context, update) => SafeArea(
        child: SizedBox(
          height:
              MediaQuery.sizeOf(context).height *
              WorkEditorStyle.publish_sheet_height_factor,
          child: Column(
            children: [
              Expanded(
                child: StepPublish(
                  is_dark: is_dark,
                  is_editing: false,
                  release_mode: mode,
                  scheduled_publish_time: time,
                  rights_confirmed: rights,
                  on_release_mode_changed: (value) =>
                      update(() => mode = value),
                  on_select_schedule_time: () async {
                    final selected = await show_schedule_time_picker(
                      context: context,
                      is_dark: is_dark,
                      initial_time: time,
                    );
                    if (selected != null && context.mounted) {
                      update(() => time = selected);
                    }
                  },
                  on_rights_confirmed_changed: (value) =>
                      update(() => rights = value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(WorkEditorStyle.section_padding),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        rights &&
                            (mode == CreatorReleaseMode.immediate ||
                                (time?.isAfter(DateTime.now()) ?? false))
                        ? () => Navigator.pop(context, (mode: mode, time: time))
                        : null,
                    child: Text(tr('creator_center.publish')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
