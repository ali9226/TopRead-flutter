import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/hero/index.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/tag_section/index.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/intro_summary_section/index.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/comment_section/index.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/content_panel/index.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/content_panel/overlap_layout.dart';
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
  final VoidCallback? on_author_tap;
  final VoidCallback? on_rating_tap;
  final VoidCallback? on_back;
  final VoidCallback? on_share;
  final VoidCallback? on_read;
  final VoidCallback? on_favorite;
  final bool favorited;
  final bool favorite_loading;

  /// 替换封面成功回调，携带新的封面信息。
  final void Function(String cover_url, int cover_width, int cover_height)?
  on_cover_replaced;

  const ReadIntroductionSection({
    super.key,
    required this.is_dark,
    required this.detail,
    this.on_focus_changed,
    this.on_author_tap,
    this.on_rating_tap,
    this.on_back,
    this.on_share,
    this.on_read,
    this.on_favorite,
    this.favorited = false,
    this.favorite_loading = false,
    this.on_cover_replaced,
  });

  @override
  Widget build(BuildContext context) {
    // iOS 审核模式下隐藏评论区。
    final bool show_comment =
        !Get.find<ProjectConfigStore>().current.is_apple_review_mode;

    return ReadIntroductionLayout(
      key: const ValueKey('novel_introduction_layout'),
      overlap: IntroductionStyle.content_panel_overlap,
      hero: ReadIntroductionHero(
        is_dark: is_dark,
        detail: detail,
        on_back: on_back,
        on_share: on_share,
        on_read: on_read,
        on_favorite: on_favorite,
        favorited: favorited,
        favorite_loading: favorite_loading,
        on_author_tap: on_author_tap,
        on_rating_tap: on_rating_tap,
        on_focus_changed: on_focus_changed,
        on_cover_replaced: on_cover_replaced,
        bottom_overlap: IntroductionStyle.content_panel_overlap,
      ),
      panel: ReadIntroductionPanel(
        is_dark: is_dark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标签子组件，展示小说标签列表。
            ReadTagSection(is_dark: is_dark, tag_list: detail.tag_list),
            // 标签区与简介区之间的间距。
            const SizedBox(height: IntroductionStyle.intro_top_spacing),
            // 所有作品类型共用卡片与完整正文裁切动画。
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
        ),
      ),
    );
  }
}
