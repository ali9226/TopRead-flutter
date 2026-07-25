import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/components/svg_icon/index.dart';
import 'package:app/components/home/style.dart';
import 'package:app/components/ranking_tab_content/story_rank_card.dart';
import 'package:app/components/empty_state/index.dart';
import 'package:app/models/story_item.dart';

/// 榜单内容区域子组件。
///
/// 该组件负责渲染每个榜单 Tab 下的小说列表内容，
/// 避免首页 `index.dart` 文件承担过多 UI 细节。
class RankingTabContent extends StatelessWidget {
  /// 小说列表数据源。
  final List<StoryItem> story_item_list;

  /// 当前是否为深色主题。
  final bool is_dark;

  /// 点击小说卡片时触发的回调。
  final ValueChanged<StoryItem>? on_story_tap;

  /// 空数据时点击重新加载回调。
  final VoidCallback? on_reload;

  const RankingTabContent({
    super.key,
    required this.story_item_list,
    required this.is_dark,
    this.on_story_tap,
    this.on_reload,
  });

  @override
  Widget build(BuildContext context) {
    final List<StoryItem> visible_story_item_list = story_item_list
        .take(Style.ranking_cross_axis_count * Style.ranking_row_count)
        .toList();

    /// 是否为空数据状态。
    final bool is_empty = visible_story_item_list.isEmpty;

    /// "查看更多"基础颜色。
    final Color ranking_more_base_color = is_dark ? Colors.white : Colors.black;

    /// "查看更多"显示颜色。
    final Color ranking_more_color = ranking_more_base_color.withValues(
      alpha: Style.ranking_more_opacity,
    );

    return Padding(
      padding: Style.story_list_padding,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: Style.ranking_grid_height,
            child: is_empty
                ? EmptyState(
                    is_dark: is_dark,
                    on_reload: on_reload,
                  )
                : GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: visible_story_item_list.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Style.ranking_cross_axis_count,
                      crossAxisSpacing: Style.ranking_column_spacing,
                      mainAxisSpacing: Style.ranking_row_spacing,
                      mainAxisExtent: Style.ranking_item_height,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      /// 当前索引对应的小说数据。
                      final StoryItem current_story_item =
                          visible_story_item_list[index];

                      return StoryRankCard(
                        ranking_index: index + 1,
                        title: current_story_item.title,
                        popularity_count: current_story_item.popularity_count,
                        cover_url: current_story_item.cover_url,
                        is_dark: is_dark,
                        on_tap: () => on_story_tap?.call(current_story_item),
                      );
                    },
                  ),
          ),
          const SizedBox(height: Style.ranking_more_top_spacing),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: ranking_more_color, width: 1.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: Style.ranking_more_underline_gap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      easy.tr('home.view_more'),
                      style: TextStyle(
                        color: ranking_more_color,
                        fontSize: Style.ranking_more_font_size,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                      ),
                    ),
                  ),
                  const SizedBox(width: Style.ranking_more_icon_gap),
                  SvgIcon(
                    name: 'right',
                    width: Style.ranking_more_icon_size,
                    height: Style.ranking_more_icon_size,
                    color: ranking_more_color,
                    opacity: Style.ranking_more_opacity,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Style.ranking_more_bottom_spacing),
        ],
      ),
    );
  }
}
