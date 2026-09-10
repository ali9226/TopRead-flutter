// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/author_center/models/creator_backend_models.dart';
import 'package:app/pages/home/widgets/tab_contents/short_story_tab/style.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 创作者作品卡片 — 参照短篇小说列表卡片风格。
///
/// 纵向布局：标题 → 简介（封面在右侧）→ 底部标签 + 元信息。
/// 操作按钮改为长按弹出菜单。
class BackendWorkCard extends StatelessWidget {
  final CreatorWorkModel work;
  final bool is_dark;
  final bool is_cjk;
  final VoidCallback on_tap;
  final VoidCallback? on_long_press;

  const BackendWorkCard({
    super.key,
    required this.work,
    required this.is_dark,
    required this.is_cjk,
    required this.on_tap,
    this.on_long_press,
  });

  String get _title => work.title.trim().isEmpty
      ? easy.tr('creator_center.unnamed_work')
      : work.title.trim();

  /// 是否有封面图片。
  bool get _has_cover => work.cover_url?.trim().isNotEmpty == true;

  /// 是否有简介。
  bool get _has_intro => work.introduction?.trim().isNotEmpty == true;

  @override
  Widget build(BuildContext context) {
    /// 卡片背景色。
    final Color card_bg = is_dark
        ? ShortStoryTabStyle.card_dark_bg
        : ShortStoryTabStyle.card_light_bg;

    /// 波纹颜色。
    final Color ripple_color =
        ColorConstants.themeColor.withValues(alpha: 0.12);

    /// 高亮颜色。
    final Color highlight_color =
        ColorConstants.themeColor.withValues(alpha: 0.06);

    return Material(
      color: card_bg,
      borderRadius: BorderRadius.circular(ShortStoryTabStyle.card_border_radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: on_tap,
        onLongPress: on_long_press,
        splashFactory: InkRipple.splashFactory,
        splashColor: ripple_color,
        highlightColor: highlight_color,
        radius: 240,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ShortStoryTabStyle.card_horizontal_padding,
            vertical: is_cjk
                ? ShortStoryTabStyle.card_vertical_padding_cjk
                : ShortStoryTabStyle.card_vertical_padding_alphabetic,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// 标题（最多两行）。
              _build_title(),

              /// 标题与简介间距。
              SizedBox(
                height: is_cjk
                    ? ShortStoryTabStyle.card_title_desc_gap_cjk
                    : ShortStoryTabStyle.card_title_desc_gap_alphabetic,
              ),

              /// 简介行：有封面时左侧简介右侧封面，无封面时纯简介。
              if (_has_intro) _build_description_row(),

              /// 简介与底部标签栏间距。
              if (_has_intro)
                SizedBox(
                  height: is_cjk
                      ? ShortStoryTabStyle.card_desc_bottom_gap_cjk
                      : ShortStoryTabStyle.card_desc_bottom_gap_alphabetic,
                ),

              /// 底部：标签 + 元信息。
              _build_bottom_row(),

              /// 定时发布倒计时。
              if (_build_countdown() != null) ...[
                const SizedBox(height: 8),
                _build_countdown()!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 标题（最多两行）。
  Widget _build_title() {
    final Color title_color = is_dark
        ? ShortStoryTabStyle.card_title_dark_text
        : ShortStoryTabStyle.card_title_light_text;

    final double title_font_size = is_cjk
        ? ShortStoryTabStyle.card_title_font_size_cjk
        : ShortStoryTabStyle.card_title_font_size_alphabetic;
    final double title_height = is_cjk
        ? ShortStoryTabStyle.card_title_height_cjk
        : ShortStoryTabStyle.card_title_height_alphabetic;

    return Text(
      _title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: title_font_size,
        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
        color: title_color,
        height: title_height,
        letterSpacing:
            is_cjk ? null : ShortStoryTabStyle.card_title_letter_spacing_alphabetic,
      ),
    );
  }

  /// 简介行：有封面时左侧简介右侧封面，无封面时纯简介。
  Widget _build_description_row() {
    final Color desc_color = is_dark
        ? ShortStoryTabStyle.card_desc_dark_text
        : ShortStoryTabStyle.card_desc_light_text;

    final double desc_font_size = is_cjk
        ? ShortStoryTabStyle.card_description_font_size_cjk
        : ShortStoryTabStyle.card_description_font_size_alphabetic;
    final double desc_height = is_cjk
        ? ShortStoryTabStyle.card_desc_height_cjk
        : ShortStoryTabStyle.card_desc_height_alphabetic;

    /// 简介最大行数。
    const int desc_max_lines = 3;

    final TextStyle desc_style = TextStyle(
      fontSize: desc_font_size,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
      color: desc_color,
      height: desc_height,
      letterSpacing: is_cjk
          ? null
          : ShortStoryTabStyle.card_desc_letter_spacing_alphabetic,
    );

    final String description = work.introduction!.trim();

    /// 无封面时：纯简介文字。
    if (!_has_cover) {
      return Text(
        description,
        maxLines: desc_max_lines,
        overflow: TextOverflow.ellipsis,
        style: desc_style,
      );
    }

    /// 有封面时：左侧简介，右侧封面。
    final double cover_height = desc_font_size * desc_height * desc_max_lines;
    final double cover_width = cover_height * (100 / 75);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 左侧简介文字。
        Expanded(
          child: Text(
            description,
            maxLines: desc_max_lines,
            overflow: TextOverflow.ellipsis,
            style: desc_style,
          ),
        ),

        /// 间距。
        const SizedBox(width: 10),

        /// 右侧封面图片。
        ClipRRect(
          borderRadius: BorderRadius.circular(LayoutConfig.tag_radius),
          child: SizedBox(
            width: cover_width,
            height: cover_height,
            child: Image.network(
              work.cover_url!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _build_default_cover(
                width: cover_width,
                height: cover_height,
              ),
              loadingBuilder: (context, child, progress) =>
                  progress == null
                      ? child
                      : _build_default_cover(
                          width: cover_width,
                          height: cover_height,
                        ),
            ),
          ),
        ),
      ],
    );
  }

  /// 默认封面（渐变背景 + 标题前两字）。
  Widget _build_default_cover({required double width, required double height}) {
    const List<List<Color>> palettes = <List<Color>>[
      <Color>[Color(0xFF516889), Color(0xFF252D40)],
      <Color>[Color(0xFF9B7A58), Color(0xFF443124)],
      <Color>[Color(0xFF577D70), Color(0xFF213D35)],
      <Color>[Color(0xFF80688D), Color(0xFF382D43)],
    ];
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
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
              fontSize: 16,
              height: 1.3,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  /// 底部行：左侧标签列表，右侧元信息。
  Widget _build_bottom_row() {
    final Color meta_color = is_dark
        ? ShortStoryTabStyle.card_like_dark_text
        : ShortStoryTabStyle.card_like_light_text;

    final double meta_font_size = is_cjk ? 12.0 : 11.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        /// 左侧标签列表。
        Expanded(child: _build_badges()),

        /// 右侧元信息。
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            _build_meta_text(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: meta_font_size,
              height: 1.4,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              color: meta_color,
              letterSpacing: is_cjk ? null : 0.15,
            ),
          ),
        ),
      ],
    );
  }

  /// 标签列表。
  Widget _build_badges() {
    final List<Color> colors = ColorConstants.tagColorList;
    int color_index = work.id * 7;

    Color next_color() {
      final Color c = colors[color_index % colors.length];
      color_index += 3;
      return c;
    }

    final double tag_font_size = is_cjk
        ? ShortStoryTabStyle.card_tag_font_size_cjk
        : ShortStoryTabStyle.card_tag_font_size_alphabetic;
    final double tag_h_padding = is_cjk
        ? ShortStoryTabStyle.card_tag_horizontal_padding_cjk
        : ShortStoryTabStyle.card_tag_horizontal_padding_alphabetic;

    return Wrap(
      spacing: ShortStoryTabStyle.card_tag_spacing,
      runSpacing: ShortStoryTabStyle.card_tag_spacing,
      children: <Widget>[
        _build_pill(
          is_cjk
              ? work.work_type_text
              : (work.is_long_novel ? 'Novel' : 'Short story'),
          color: next_color(),
          font_size: tag_font_size,
          h_padding: tag_h_padding,
        ),
        _build_pill(
          _status_label,
          color: next_color(),
          font_size: tag_font_size,
          h_padding: tag_h_padding,
        ),
        if (work.draftChapterCount > 0 || work.workDraftCount > 0)
          _build_pill(
            '${easy.tr('creator_workspace.has_draft')} ${work.draftChapterCount > 0 ? work.draftChapterCount : ''}',
            color: next_color(),
            font_size: tag_font_size,
            h_padding: tag_h_padding,
          ),
        if (work.is_pending_publish)
          _build_pill(
            easy.tr('creator_workspace.scheduled'),
            color: next_color(),
            font_size: tag_font_size,
            h_padding: tag_h_padding,
          ),
        if (work.is_long_novel && work.is_published)
          _build_pill(
            is_cjk
                ? work.serialization_status_text
                : (work.serialization_status == 1 ? 'Ongoing' : 'Completed'),
            color: next_color(),
            font_size: tag_font_size,
            h_padding: tag_h_padding,
          ),
      ],
    );
  }

  /// 单个标签胶囊。
  Widget _build_pill(
    String label, {
    required Color color,
    required double font_size,
    required double h_padding,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: h_padding,
        vertical: ShortStoryTabStyle.card_tag_vertical_padding,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: is_dark ? 0.16 : 0.10),
        borderRadius:
            BorderRadius.circular(ShortStoryTabStyle.card_tag_border_radius),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: font_size,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
        ),
      ),
    );
  }

  /// 元信息文本：字数 · 章节数 · 更新时间。
  String _build_meta_text() {
    final int chapters = work.is_published
        ? work.chapter_count
        : (work.draftChapterCount > 0 ? work.draftChapterCount : work.chapter_count);

    final List<String> parts = <String>[
      easy.tr(
        'creator_center.chapter_editor_word_count',
        namedArgs: {'count': '${work.word_count}'},
      ),
      if (work.is_long_novel)
        easy.tr(
          'creator_center.work_detail_chapter_count',
          namedArgs: {'count': '$chapters'},
        ),
      _updated_time,
    ];
    return parts.join(' · ');
  }

  /// 定时发布倒计时组件。
  Widget? _build_countdown() {
    final countdown = _countdown_text;
    if (countdown == null) return null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AuthorStyle.gold.withValues(alpha: is_dark ? 0.15 : 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 14,
            color: is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold,
          ),
          const SizedBox(width: 6),
          Text(
            '${easy.tr("creator_center.publish_countdown")} $countdown',
            style: TextStyle(
              fontSize: is_cjk ? 12 : 11,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
              color: is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold,
            ),
          ),
        ],
      ),
    );
  }

  String get _status_label {
    return work.is_published
        ? easy.tr('creator_workspace.published')
        : work.status_text;
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
    if (time == null) return easy.tr('creator_center.status_unknown');
    return DateFormat('yyyy-MM-dd HH:mm').format(time.toLocal());
  }

  /// 倒计时文本。
  String? get _countdown_text {
    if (!work.is_pending_publish) return null;
    final publishTime = work.scheduled_publish_datetime;
    if (publishTime == null) return null;

    final now = DateTime.now();
    if (publishTime.isBefore(now)) return null;

    final diff = publishTime.difference(now);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    if (days > 0) {
      return easy.tr(
        'creator_center.publish_countdown_days',
        namedArgs: {'days': '$days', 'hours': '$hours', 'minutes': '$minutes'},
      );
    } else if (hours > 0) {
      return easy.tr(
        'creator_center.publish_countdown_hours',
        namedArgs: {'hours': '$hours', 'minutes': '$minutes'},
      );
    } else {
      return easy.tr(
        'creator_center.publish_countdown_minutes',
        namedArgs: {'minutes': '$minutes', 'seconds': '$seconds'},
      );
    }
  }
}
