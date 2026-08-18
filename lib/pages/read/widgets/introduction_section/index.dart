import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/network_cover_image/index.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/author_section/index.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/stat_section/index.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/tag_section/index.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/intro_summary_section/index.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/comment_section/index.dart';
import 'package:app/config/font_config.dart';
import 'package:app/stores/project_config_store.dart';
import './style.dart';

/// 阅读页介绍组件。
///
/// 负责在页面顶部展示小说的完整介绍信息，包括：
/// 封面、标题、作者信息、数据统计、标签、内容简介以及评论区。
/// 将原本分散的多个子组件整合为一个统一的介绍区块，便于管理和维护。
class ReadIntroductionSection extends StatelessWidget {
  /// 当前是否为夜间主题，用于控制整块内容的文字与装饰颜色。
  final bool is_dark;

  /// 详情数据，包含封面、标题、作者、统计、简介、评论等内容。
  final ReadDetail detail;

  /// 关注状态变更回调。
  final ValueChanged<bool>? on_focus_changed;

  const ReadIntroductionSection({
    super.key,
    required this.is_dark,
    required this.detail,
    this.on_focus_changed,
  });

  @override
  Widget build(BuildContext context) {
    // 标题文字颜色
    final Color title_color = is_dark
        ? IntroductionStyle.title_color_dark
        : IntroductionStyle.title_color_light;

    // iOS 审核模式下隐藏评论区。
    final bool show_comment =
        !Get.find<ProjectConfigStore>().current.is_apple_review_mode;

    // 该区块按"封面 -> 标题 -> 作者 -> 统计 -> 标签 -> 简介 -> 评论"的顺序组织。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // 封面图居中显示，加载失败时回退到 story_id 文案占位。
        Align(
          child: NetworkCoverImage(
            image_url: detail.cover_url,
            width: IntroductionStyle.cover_width,
            height: IntroductionStyle.cover_height,
            border_radius: IntroductionStyle.cover_radius,
            is_dark: is_dark,
            error_text: '${detail.story_id}',
          ),
        ),
        // 封面与标题之间保持固定垂直节奏。
        const SizedBox(height: IntroductionStyle.title_top_spacing),
        // 书名在头图区居中展示，保证视觉焦点明确。
        Center(
          child: Text(
            detail.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: title_color,
              fontSize: IntroductionStyle.title_font_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
            ),
          ),
        ),
        // 标题与作者区之间的间距。
        const SizedBox(height: IntroductionStyle.author_top_spacing),
        // 作者信息子组件，负责头像、名称和关注标签。
        ReadAuthorSection(
          is_dark: is_dark,
          detail: detail,
          on_focus_changed: on_focus_changed,
        ),
        // 作者信息与统计区之间的间距。
        const SizedBox(height: IntroductionStyle.stat_panel_top_spacing),
        // 统计子组件，展示评分、在读人数、字数三个指标。
        ReadStatSection(is_dark: is_dark, detail: detail),
        // 统计区与标签区之间的间距。
        const SizedBox(height: IntroductionStyle.tag_section_top_spacing),
        // 标签子组件，展示小说标签列表。
        ReadTagSection(is_dark: is_dark, tag_list: detail.tag_list),
        // 标签区与简介区之间的间距。
        const SizedBox(height: IntroductionStyle.intro_top_spacing),
        // 简介子组件，展示单行摘要与"更多"入口文案。
        ReadIntroSummarySection(
          is_dark: is_dark,
          intro_text: detail.intro_text,
        ),
        if (show_comment) ...[
          // 简介区与评论区之间的间距。
          const SizedBox(height: IntroductionStyle.comment_top_spacing),
          // 评论子组件，展示热门书评列表。
          ReadCommentSection(
            is_dark: is_dark,
            comment_list: detail.comment_list,
          ),
        ],
      ],
    );
  }
}
