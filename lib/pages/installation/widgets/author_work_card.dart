// ignore_for_file: non_constant_identifier_names

import 'package:app/config/font_config.dart';
import 'package:app/pages/installation/author_style.dart';
import 'package:app/pages/installation/models/creator_work.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// TODO 创作者作品列表卡片。
class AuthorWorkCard extends StatelessWidget {
  /// TODO 作品数据。
  final CreatorWorkDraft work;

  /// TODO 当前是否夜间主题。
  final bool is_dark;

  /// TODO 当前是否 CJK 语种。
  final bool is_cjk;

  /// TODO 点击整张卡片的行为。
  final VoidCallback on_tap;

  /// TODO 主操作按钮行为。
  final VoidCallback on_primary_action;

  const AuthorWorkCard({
    super.key,
    required this.work,
    required this.is_dark,
    required this.is_cjk,
    required this.on_tap,
    required this.on_primary_action,
  });

  @override
  Widget build(BuildContext context) {
    final Color status_color = _status_color(work.status);
    final String title = work.title.trim().isEmpty
        ? easy.tr('creator_center.untitled_work')
        : work.title.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: on_tap,
        borderRadius: BorderRadius.circular(AuthorStyle.section_radius),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AuthorStyle.surface(is_dark),
            borderRadius: BorderRadius.circular(AuthorStyle.section_radius),
            border: Border.all(color: AuthorStyle.border(is_dark)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: is_dark ? 0.14 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _build_cover(title),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            _build_status_badge(status_color),
                            if (work.is_demo) ...<Widget>[
                              const SizedBox(width: 6),
                              _build_demo_badge(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 9),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AuthorStyle.primary_text(is_dark),
                            fontSize: 17,
                            height: 1.25,
                            fontWeight: AuthorStyle.title_weight,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          children: <Widget>[
                            _build_meta_pill(
                              work.work_type == CreatorWorkType.long
                                  ? easy.tr('creator_center.long_work')
                                  : easy.tr('creator_center.short_work'),
                            ),
                            _build_meta_pill(
                              work.is_completed
                                  ? easy.tr('creator_center.completed')
                                  : easy.tr('creator_center.serializing'),
                            ),
                            ...work.categories.take(1).map(_build_meta_pill),
                          ],
                        ),
                        const SizedBox(height: 11),
                        Text(
                          _build_content_summary(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AuthorStyle.secondary_text(is_dark),
                            fontSize: 12,
                            fontWeight: AuthorStyle.body_weight,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          easy.tr(
                            'creator_center.updated_at',
                            namedArgs: <String, String>{
                              'time': DateFormat(
                                'MM-dd HH:mm',
                              ).format(work.update_time),
                            },
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AuthorStyle.secondary_text(is_dark),
                            fontSize: 11,
                            fontWeight: AuthorStyle.body_weight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Divider(height: 1, color: AuthorStyle.border(is_dark)),
              const SizedBox(height: 11),
              Row(
                children: <Widget>[
                  if (work.release_mode == CreatorReleaseMode.scheduled &&
                      work.scheduled_publish_time != null)
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.schedule_rounded,
                            color: AuthorStyle.purple,
                            size: 17,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              easy.tr(
                                'creator_center.scheduled_for',
                                namedArgs: <String, String>{
                                  'time': DateFormat(
                                    'MM-dd HH:mm',
                                  ).format(work.scheduled_publish_time!),
                                },
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AuthorStyle.purple,
                                fontSize: 11,
                                fontWeight: AuthorStyle.emphasis_weight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: on_tap,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(72, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      foregroundColor: AuthorStyle.primary_text(is_dark),
                      side: BorderSide(color: AuthorStyle.border(is_dark)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: Text(
                      easy.tr('creator_center.edit_work'),
                      style: TextStyle(
                        fontSize: is_cjk ? 12 : 10.5,
                        fontWeight: AuthorStyle.emphasis_weight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: on_primary_action,
                    icon: Icon(
                      work.work_type == CreatorWorkType.long
                          ? Icons.edit_note_rounded
                          : Icons.subject_rounded,
                      size: 17,
                    ),
                    label: Text(
                      work.work_type == CreatorWorkType.long
                          ? easy.tr('creator_center.write_chapter')
                          : easy.tr('creator_center.edit_content'),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(96, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      backgroundColor: AuthorStyle.gold,
                      foregroundColor: const Color(0xFF1A1A18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                      textStyle: TextStyle(
                        fontSize: is_cjk ? 12 : 10.5,
                        fontWeight: AuthorStyle.emphasis_weight,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// TODO 构建无网络依赖的渐变封面占位图。
  Widget _build_cover(String title) {
    final int palette_index = work.local_id.hashCode.abs() % 4;
    const List<List<Color>> palettes = <List<Color>>[
      <Color>[Color(0xFF4D5F80), Color(0xFF202636)],
      <Color>[Color(0xFF926F5A), Color(0xFF382A27)],
      <Color>[Color(0xFF4A7A70), Color(0xFF1F3633)],
      <Color>[Color(0xFF725B8B), Color(0xFF2D253B)],
    ];
    final List<Color> colors = palettes[palette_index];
    final String cover_text = title.characters.take(2).toString();

    return Container(
      width: 92,
      height: 124,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.last.withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -15,
            top: -12,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                cover_text,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.2,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// TODO 构建作品状态标签。
  Widget _build_status_badge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AuthorStyle.pill_radius),
      ),
      child: Text(
        _status_title(work.status),
        style: TextStyle(
          color: color,
          fontSize: is_cjk
              ? AuthorStyle.status_font_size_cjk
              : AuthorStyle.status_font_size_alphabetic,
          fontWeight: AuthorStyle.emphasis_weight,
        ),
      ),
    );
  }

  /// TODO 构建开发阶段示例标识，防止用户误认成真实后端数据。
  Widget _build_demo_badge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AuthorStyle.blue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AuthorStyle.pill_radius),
      ),
      child: Text(
        easy.tr('creator_center.demo_badge'),
        style: TextStyle(
          color: AuthorStyle.blue,
          fontSize: is_cjk ? 11 : 9.5,
          fontWeight: AuthorStyle.emphasis_weight,
        ),
      ),
    );
  }

  /// TODO 构建作品元信息胶囊。
  Widget _build_meta_pill(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AuthorStyle.secondary_surface(is_dark),
        borderRadius: BorderRadius.circular(AuthorStyle.pill_radius),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: AuthorStyle.secondary_text(is_dark),
          fontSize: 10.5,
          fontWeight: AuthorStyle.body_weight,
        ),
      ),
    );
  }

  /// TODO 构建章节数和字数摘要。
  String _build_content_summary() {
    final String words = NumberFormat.compact().format(work.word_count);

    if (work.work_type == CreatorWorkType.long) {
      return easy.tr(
        'creator_center.chapter_word_summary',
        namedArgs: <String, String>{
          'chapters': work.chapters.length.toString(),
          'words': words,
        },
      );
    }

    return easy.tr(
      'creator_center.word_count',
      namedArgs: <String, String>{'count': words},
    );
  }

  /// TODO 返回状态文案。
  String _status_title(CreatorWorkStatus status) {
    switch (status) {
      case CreatorWorkStatus.draft:
        return easy.tr('creator_center.status_draft');
      case CreatorWorkStatus.reviewing:
        return easy.tr('creator_center.status_reviewing');
      case CreatorWorkStatus.scheduled:
        return easy.tr('creator_center.status_scheduled');
      case CreatorWorkStatus.published:
        return easy.tr('creator_center.status_published');
      case CreatorWorkStatus.rejected:
        return easy.tr('creator_center.status_rejected');
    }
  }

  /// TODO 返回状态强调色。
  Color _status_color(CreatorWorkStatus status) {
    switch (status) {
      case CreatorWorkStatus.draft:
        return AuthorStyle.blue;
      case CreatorWorkStatus.reviewing:
        return AuthorStyle.coral;
      case CreatorWorkStatus.scheduled:
        return AuthorStyle.purple;
      case CreatorWorkStatus.published:
        return AuthorStyle.green;
      case CreatorWorkStatus.rejected:
        return const Color(0xFFE45D68);
    }
  }
}
