import 'package:app/components/window_content_layout/index.dart';
import 'package:app/components/work_about_section/style.dart';
import 'package:app/components/work_section_card/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';

import 'style.dart';
import 'widgets/genre_tag.dart';

/// 标题下方完整宽度展示分类；独立区域与简介内嵌区域共用同一彩色胶囊。
class WorkGenresSection extends StatelessWidget {
  const WorkGenresSection({
    super.key,
    required this.title,
    required this.tags,
    required this.is_dark,
    this.content_id = 0,
    this.embedded = false,
  });

  final String title;
  final List<String> tags;
  final bool is_dark;

  /// 保留现有调用接口；标签颜色按展示顺序循环全局数组，不依赖作品编号。
  final int content_id;

  /// 连续详情区域不增加第二张卡片，分类颜色与独立模式保持一致。
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    if (embedded) return _embedded_content(context);
    return WorkSectionCard(
      is_dark: is_dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorkSectionHeading(title: title, is_dark: is_dark),
          const SizedBox(height: WorkSectionCardStyle.title_gap),
          _tags(context),
        ],
      ),
    );
  }

  Widget _embedded_content(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final has_title = title.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (has_title) ...[
          WindowReservedRegionPadding(
            mode: WindowReservedRegionPaddingMode.heading,
            retain_when_above_viewport: true,
            child: Text(
              title,
              key: const ValueKey('work_genres_heading'),
              style: TextStyle(
                color: WorkAboutSectionStyle.foreground(is_dark),
                fontSize: cjk
                    ? WorkAboutSectionStyle.heading_size_cjk
                    : WorkAboutSectionStyle.heading_size_alphabetic,
                height: WorkAboutSectionStyle.heading_height,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: WorkAboutSectionStyle.heading_gap),
        ],
        WindowReservedRegionPadding(
          mode: WindowReservedRegionPaddingMode.heading,
          retain_when_above_viewport: true,
          child: _tags(context),
        ),
      ],
    );
  }

  /// 使用既有tagColorList的顺序及取模规则，超出数组长度后从首色继续循环。
  Widget _tags(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    return Wrap(
      key: const ValueKey('work_genres_tags'),
      spacing: embedded
          ? WorkGenresSectionStyle.hero_tag_spacing
          : WorkGenresSectionStyle.tag_spacing,
      runSpacing: embedded
          ? WorkGenresSectionStyle.hero_tag_run_spacing
          : WorkGenresSectionStyle.tag_run_spacing,
      children: List.generate(
        tags.length,
        (index) => WorkGenreTag(
          label: tags[index],
          color: ColorConstants.resolveTagColor(index),
          is_dark: is_dark,
          is_cjk: cjk,
          compact: embedded,
        ),
      ),
    );
  }
}
