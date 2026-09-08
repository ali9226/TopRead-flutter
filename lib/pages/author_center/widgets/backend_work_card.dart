// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/author_center/models/creator_backend_models.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

/// 创作者作品卡片 — 参照短篇小说列表卡片风格。
class BackendWorkCard extends StatelessWidget {
  final CreatorWorkModel work;
  final bool is_dark;
  final bool is_cjk;
  final VoidCallback on_tap;
  final VoidCallback? on_primary_action;
  final VoidCallback? on_delete;
  final VoidCallback? on_withdraw;

  const BackendWorkCard({
    super.key,
    required this.work,
    required this.is_dark,
    required this.is_cjk,
    required this.on_tap,
    this.on_primary_action,
    this.on_delete,
    this.on_withdraw,
  });

  String get _title => work.title.trim().isEmpty
      ? (is_cjk ? '未命名作品' : 'Untitled work')
      : work.title.trim();

  @override
  Widget build(BuildContext context) {
    final Color card_bg = is_dark ? const Color(0xFF1E2130) : Colors.white;
    final Color ripple_color = AuthorStyle.gold.withValues(
      alpha: is_dark ? 0.10 : 0.08,
    );
    final Color highlight_color = AuthorStyle.gold.withValues(alpha: 0.04);

    return Material(
      color: card_bg,
      borderRadius: BorderRadius.circular(LayoutConfig.card_radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: on_tap,
        splashFactory: InkRipple.splashFactory,
        splashColor: ripple_color,
        highlightColor: highlight_color,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: is_cjk ? 14 : 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _build_cover(),
              const SizedBox(width: 12),
              Expanded(child: _build_content()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _build_cover() {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LayoutConfig.card_radius),
        child: SizedBox(
          width: 60,
          height: 80,
          child: work.cover_url?.trim().isNotEmpty == true
              ? Image.network(
                  work.cover_url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _build_default_cover(),
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : _build_default_cover(),
                )
              : _build_default_cover(),
        ),
      ),
    );
  }

  Widget _build_default_cover() {
    const List<List<Color>> palettes = <List<Color>>[
      <Color>[Color(0xFF516889), Color(0xFF252D40)],
      <Color>[Color(0xFF9B7A58), Color(0xFF443124)],
      <Color>[Color(0xFF577D70), Color(0xFF213D35)],
      <Color>[Color(0xFF80688D), Color(0xFF382D43)],
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palettes[work.id.abs() % palettes.length],
        ),
      ),
      child: Center(
        child: Text(
          _title.characters.take(2).toString(),
          textScaler: TextScaler.noScaling,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFFFF5DB),
            fontSize: 18,
            height: 1.3,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _build_content() {
    final Color title_color = is_dark
        ? const Color(0xFFE8E8EA)
        : const Color(0xFF1A1A1A);
    final Color meta_color = is_dark
        ? const Color(0xFF777788)
        : const Color(0xFF888888);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 标题
        Text(
          _title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: is_cjk ? 17 : 15,
            height: is_cjk ? 1.4 : 1.35,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
            color: title_color,
            letterSpacing: is_cjk ? null : 0.2,
          ),
        ),

        const SizedBox(height: 8),

        /// 标签行
        _build_badges(),

        const SizedBox(height: 10),

        /// 元信息行：时间 + 删除按钮
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _build_meta_text(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: is_cjk ? 12 : 11,
                  height: 1.4,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                  color: meta_color,
                  letterSpacing: is_cjk ? null : 0.15,
                ),
              ),
            ),
            if (work.is_reviewing && on_withdraw != null)
              GestureDetector(
                onTap: on_withdraw,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    easy.tr('creator_center.withdraw_work'),
                    style: TextStyle(
                      fontSize: is_cjk ? 12 : 11,
                      height: 1.4,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                      color: ColorConstants.dangerColor,
                    ),
                  ),
                ),
              )
            else if (!work.is_reviewing && on_delete != null)
              GestureDetector(
                onTap: on_delete,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: SvgPicture.asset(
                    'assets/svg/delete.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      ColorConstants.dangerColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (work.is_published) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              TextButton.icon(
                onPressed: on_tap,
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: Text(
                  work.pending_submission != null
                      ? easy.tr('creator_center.view_update_review')
                      : easy.tr('creator_center.edit_update'),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: is_dark
                      ? AuthorStyle.gold
                      : AuthorStyle.deep_gold,
                ),
              ),
              TextButton(
                onPressed: on_primary_action,
                child: Text(easy.tr('creator_center.read_published')),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _build_badges() {
    final List<Color> colors = ColorConstants.tagColorList;
    int color_index = work.id * 7;

    Color next_color() {
      final Color c = colors[color_index % colors.length];
      color_index += 3;
      return c;
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: <Widget>[
        _build_pill(
          is_cjk
              ? work.work_type_text
              : (work.is_long_novel ? 'Novel' : 'Short story'),
          color: next_color(),
        ),
        _build_pill(_status_label, color: next_color()),
        if (work.is_long_novel && work.is_published)
          _build_pill(
            is_cjk
                ? work.serialization_status_text
                : (work.serialization_status == 1 ? 'Ongoing' : 'Completed'),
            color: next_color(),
          ),
      ],
    );
  }

  Widget _build_pill(String label, {required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: is_cjk ? 6 : 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: is_dark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(LayoutConfig.card_radius),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: is_cjk ? 11 : 10,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
        ),
      ),
    );
  }

  String _build_meta_text() {
    final List<String> parts = <String>[
      is_cjk ? '${work.word_count}字' : '${work.word_count} words',
      if (work.is_long_novel)
        is_cjk ? '${work.chapter_count}章' : '${work.chapter_count} ch',
      _updated_time,
    ];
    return parts.join(' · ');
  }

  String get _status_label {
    if (is_cjk) return work.is_reviewing ? '待审核' : work.status_text;
    if (work.is_draft) return 'Draft';
    if (work.is_reviewing) return 'In review';
    if (work.is_rejected) return 'Rejected';
    if (work.is_off_shelf) return 'Unlisted';
    if (work.is_published) return 'Published';
    return 'Unpublished';
  }

  String get _updated_time {
    final String value =
        <String?>[
          work.creator_update_time,
          work.latest_update_time,
          work.create_time,
        ].whereType<String>().firstWhere(
          (String time) => time.trim().isNotEmpty,
          orElse: () => '',
        );
    final DateTime? time = DateTime.tryParse(value);
    if (time == null) return is_cjk ? '暂无记录' : 'Unknown';
    return DateFormat('yyyy-MM-dd HH:mm').format(time.toLocal());
  }
}
