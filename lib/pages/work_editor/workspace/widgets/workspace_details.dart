// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/work_editor/_shared/style.dart';
import 'package:app/pages/work_editor/_shared/widgets/editor_section_card.dart';
import 'package:app/pages/work_editor/_shared/widgets/step_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../style.dart';

/// 作品资料预览；编辑按钮由页面固定在底部，长简介不会遮住入口。
class WorkspaceDetails extends StatelessWidget {
  const WorkspaceDetails({
    super.key,
    required this.novel,
    required this.is_dark,
    required this.is_cjk,
    required this.is_published,
    this.on_read,
    this.on_delete,
    this.draft_title,
  });

  final Map<String, dynamic> novel;
  final bool is_dark;
  final bool is_cjk;
  final bool is_published;
  final VoidCallback? on_read;
  final VoidCallback? on_delete;
  final String? draft_title;

  @override
  Widget build(BuildContext context) {
    final cover = '${novel['cover_url'] ?? ''}';
    final placeholder = Center(
      child: Icon(
        Icons.menu_book_rounded,
        color: AuthorStyle.secondary_text(is_dark),
      ),
    );
    return StepUtils.build_step_scroll_view(
      context: context,
      children: [
        EditorSectionCard(
          title: tr('creator_center.basic_title'),
          subtitle: tr(
            is_published
                ? 'creator_center.editing_published_hint'
                : 'creator_center.basic_subtitle',
          ),
          is_dark: is_dark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(WorkspaceStyle.radius),
                    child: ColoredBox(
                      color: AuthorStyle.secondary_surface(is_dark),
                      child: SizedBox(
                        width: WorkspaceStyle.cover_width,
                        height: WorkspaceStyle.cover_height,
                        child: cover.isEmpty
                            ? placeholder
                            : CachedNetworkImage(
                                imageUrl: cover,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => placeholder,
                                errorWidget: (_, _, _) => placeholder,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: WorkEditorStyle.section_spacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${novel['language_title'] ?? novel['title'] ?? ''}',
                          style: WorkspaceStyle.title(is_dark, is_cjk),
                        ),
                        const SizedBox(height: WorkspaceStyle.gap),
                        Text(
                          tr(
                            is_published
                                ? 'creator_workspace.published'
                                : 'creator_workspace.unpublished',
                          ),
                          style: WorkspaceStyle.caption(is_dark, is_cjk)
                              .copyWith(
                                color: is_dark
                                    ? AuthorStyle.gold
                                    : AuthorStyle.deep_gold,
                              ),
                        ),
                        if (on_read != null)
                          TextButton.icon(
                            onPressed: on_read,
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: WorkspaceStyle.icon_size,
                            ),
                            label: Text(tr('creator_workspace.read_public')),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WorkEditorStyle.field_spacing),
              StepUtils.build_field_label(
                tr('creator_center.intro_label'),
                is_dark,
              ),
              const SizedBox(height: WorkspaceStyle.gap),
              Container(
                width: double.infinity,
                padding: WorkspaceStyle.padding,
                decoration: BoxDecoration(
                  color: AuthorStyle.secondary_surface(is_dark),
                  borderRadius: BorderRadius.circular(WorkspaceStyle.radius),
                ),
                child: Text(
                  '${novel['introduction'] ?? ''}',
                  style: WorkspaceStyle.body(is_dark, is_cjk),
                ),
              ),
              if (draft_title != null) ...[
                const SizedBox(height: WorkEditorStyle.field_spacing),
                Text(
                  tr('creator_workspace.has_work_draft'),
                  style: WorkspaceStyle.caption(is_dark, is_cjk),
                ),
                Text(draft_title!, style: WorkspaceStyle.body(is_dark, is_cjk)),
              ],
              if (on_delete != null)
                TextButton(
                  onPressed: on_delete,
                  child: Text(tr('creator_workspace.delete_work')),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
