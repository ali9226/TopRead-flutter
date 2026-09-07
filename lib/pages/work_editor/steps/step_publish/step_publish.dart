// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/style.dart';
import 'package:app/pages/work_editor/widgets/editor_section_card.dart';
import 'package:app/pages/work_editor/widgets/step_utils.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StepPublish extends StatelessWidget {
  final bool is_dark;
  final bool is_editing;
  final CreatorReleaseMode release_mode;
  final DateTime? scheduled_publish_time;
  final bool rights_confirmed;
  final ValueChanged<CreatorReleaseMode> on_release_mode_changed;
  final VoidCallback on_select_schedule_time;
  final ValueChanged<bool> on_rights_confirmed_changed;

  const StepPublish({
    super.key,
    required this.is_dark,
    required this.is_editing,
    required this.release_mode,
    required this.scheduled_publish_time,
    required this.rights_confirmed,
    required this.on_release_mode_changed,
    required this.on_select_schedule_time,
    required this.on_rights_confirmed_changed,
  });

  @override
  Widget build(BuildContext context) {
    return StepUtils.build_step_scroll_view(
      context: context,
      children: <Widget>[
        EditorSectionCard(
          title: easy.tr('creator_center.publish_title'),
          subtitle: easy.tr('creator_center.publish_subtitle'),
          iconSvgName: 'user_selected',
          iconColor: is_dark ? Colors.white : null,
          is_dark: is_dark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              StepUtils.build_field_label(
                easy.tr('creator_center.release_mode'),
                is_dark,
              ),
              const SizedBox(height: 10),
              _build_release_option(
                mode: CreatorReleaseMode.immediate,
                icon: Icons.rocket_launch_outlined,
                title: easy.tr('creator_center.release_immediate_title'),
                subtitle: easy.tr('creator_center.release_immediate_subtitle'),
              ),
              const SizedBox(height: 10),
              _build_release_option(
                mode: CreatorReleaseMode.scheduled,
                icon: Icons.schedule_outlined,
                title: easy.tr('creator_center.release_scheduled_title'),
                subtitle: easy.tr('creator_center.release_scheduled_subtitle'),
              ),
              if (release_mode == CreatorReleaseMode.scheduled) ...<Widget>[
                const SizedBox(height: 12),
                _build_schedule_picker(context),
              ],
              const SizedBox(height: WorkEditorStyle.field_spacing),
              _build_rights_confirmation(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _build_release_option({
    required CreatorReleaseMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final bool is_selected = release_mode == mode;
    final Color red = ColorConstants.dangerColor;

    return GestureDetector(
      onTap: () => on_release_mode_changed(mode),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: is_selected
              ? red.withValues(alpha: is_dark ? 0.12 : 0.08)
              : AuthorStyle.secondary_surface(is_dark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: is_selected
                ? red.withValues(alpha: is_dark ? 0.40 : 0.50)
                : AuthorStyle.border(is_dark),
            width: is_selected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: is_selected
                    ? red.withValues(alpha: is_dark ? 0.20 : 0.16)
                    : AuthorStyle.secondary_surface(is_dark),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: is_selected
                    ? red
                    : AuthorStyle.secondary_text(is_dark),
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      color: AuthorStyle.primary_text(is_dark),
                      fontSize: 14,
                      fontWeight: is_selected
                          ? WorkEditorStyle.field_label_weight
                          : AuthorStyle.body_weight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AuthorStyle.secondary_text(is_dark),
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: AuthorStyle.body_weight,
                    ),
                  ),
                ],
              ),
            ),
            Radio<CreatorReleaseMode>(
              value: mode,
              groupValue: release_mode,
              onChanged: (CreatorReleaseMode? v) {
                if (v != null) on_release_mode_changed(v);
              },
              activeColor: red,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _build_schedule_picker(BuildContext context) {
    final String formatted_time = scheduled_publish_time != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(scheduled_publish_time!)
        : easy.tr('creator_center.select_schedule_time');

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: on_select_schedule_time,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AuthorStyle.secondary_surface(is_dark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AuthorStyle.border(is_dark)),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.event_outlined,
              color: scheduled_publish_time != null
                  ? ColorConstants.dangerColor
                  : AuthorStyle.secondary_text(is_dark),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                formatted_time,
                style: TextStyle(
                  color: scheduled_publish_time != null
                      ? AuthorStyle.primary_text(is_dark)
                      : AuthorStyle.secondary_text(is_dark),
                  fontSize: 14,
                  fontWeight: AuthorStyle.body_weight,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AuthorStyle.secondary_text(is_dark),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _build_rights_confirmation() {
    final Color red = ColorConstants.dangerColor;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => on_rights_confirmed_changed(!rights_confirmed),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Checkbox(
              value: rights_confirmed,
              onChanged: (bool? v) {
                if (v != null) on_rights_confirmed_changed(v);
              },
              activeColor: red,
              checkColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: BorderSide(
                color: red,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  easy.tr('creator_center.rights_confirm'),
                  style: TextStyle(
                    color: AuthorStyle.secondary_text(is_dark),
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: AuthorStyle.body_weight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
