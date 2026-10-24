import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/work_hero_stats/index.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/stores/project_config_store.dart';

/// 阅读页顶部统计区块组件。
///
/// 展示小说的评分、在读人数和总字数。
/// 采用三列等分数据条，长篇/漫画共用 [WorkHeroStatsRow] 视觉。
class ReadStatSection extends StatelessWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 详情数据。
  final ReadDetail detail;
  final bool hero;
  final VoidCallback? on_rating_tap;

  const ReadStatSection({
    super.key,
    required this.is_dark,
    required this.detail,
    this.hero = false,
    this.on_rating_tap,
  });

  @override
  Widget build(BuildContext context) {
    // iOS 审核模式下隐藏评分/评论列。
    final config = Get.find<ProjectConfigStore>().current;
    final score = double.tryParse(detail.score_major_text.trim());
    final bool show_review =
        config.is_rating_enabled &&
        !config.is_apple_review_mode &&
        score != null &&
        score.isFinite &&
        score > 0;

    return WorkHeroStatsRow(
      on_hero: hero,
      is_dark: is_dark,
      items: [
        if (show_review)
          WorkHeroStat(
            icon: Icons.star_rounded,
            value: detail.score_major_text,
            label: detail.review_count_text,
            on_tap: on_rating_tap,
          ),
        WorkHeroStat(
          icon: Icons.local_fire_department_rounded,
          value:
              detail.reading_value_text ??
              '${detail.reading_major_text}${detail.reading_minor_text}',
          label: detail.reading_label_text ?? detail.reading_subtitle_text,
        ),
        WorkHeroStat(
          icon: Icons.notes_rounded,
          value:
              detail.word_count_value_text ??
              '${detail.word_count_major_text}${detail.word_count_minor_text}',
          label:
              detail.word_count_label_text ?? detail.word_count_subtitle_text,
        ),
      ],
    );
  }
}
