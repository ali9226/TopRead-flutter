import 'package:flutter/material.dart';
import 'package:app/models/story_item.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/style.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/widgets/ranking_tab_bar.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/widgets/ranking_content.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/widgets/ranking_section_skeleton.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/widgets/view_more_button.dart';

/// 榜单区域组件。
///
/// 展示带有分类 Tab 的横向滚动榜单列表，
/// 支持自定义子 Tab 标签、榜单数据和主题色。
/// 底部包含"查看更多"按钮，点击跳转到完整榜单页面。
class RankingSection extends StatefulWidget {
  /// 子 Tab 标签列表。
  final List<String> sub_tab_list;

  /// 子 Tab 对应的 id 列表，索引与 [sub_tab_list] 一一对应。
  final List<int> sub_tab_id_list;

  /// 所有分类对应的榜单数据，索引与 [sub_tab_list] 一一对应。
  final List<List<StoryItem>> all_ranking_data;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 面板背景色。
  final Color panel_bg;

  /// Tab 切换时的回调，参数为选中的索引。
  final ValueChanged<int>? on_tab_changed;

  /// "完整榜单"点击回调，参数为当前选中 Tab 的 id。
  final ValueChanged<int>? on_full_ranking_tap;

  /// 是否正在加载中（用于骨架屏）。
  final bool is_loading;

  /// 当前语种代码，用于判断是否为 CJK 语系。
  final String language_code;

  /// 空数据时点击重新加载回调。
  final VoidCallback? on_reload;

  const RankingSection({
    super.key,
    required this.sub_tab_list,
    required this.sub_tab_id_list,
    required this.all_ranking_data,
    required this.is_dark,
    required this.panel_bg,
    required this.language_code,
    this.on_tab_changed,
    this.on_full_ranking_tap,
    this.is_loading = false,
    this.on_reload,
  });

  @override
  State<RankingSection> createState() => _RankingSectionState();
}

class _RankingSectionState extends State<RankingSection> {
  /// 当前选中的子 Tab 索引。
  int _selected_sub_tab_index = 0;

  /// 每个子 Tab 独立记录自己的榜单横向吸附列。
  ///
  /// 例如：第一个榜单滑到第 3 列，切换到第二个榜单时，
  /// 第二个榜单应该使用自己的位置，而不是复用第一个榜单的位置。
  final Map<int, int> _column_index_by_sub_tab_index = <int, int>{};

  /// 当前选中 Tab 是否有数据。
  bool get _has_current_tab_data {
    final List<List<StoryItem>> data = widget.all_ranking_data;
    if (data.isEmpty) return false;
    final int index = _selected_sub_tab_index;
    if (index >= data.length) return false;
    return data[index].isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final int selected_sub_tab_index = _selected_sub_tab_index;

    /// Tab 标题为空时展示完整榜单骨架；
    /// 切换已有 Tab 时保留真实 Tab，只替换内容区域。
    final bool is_tab_bar_loading = widget.sub_tab_list.isEmpty;

    if (widget.is_loading || is_tab_bar_loading) {
      return RankingSectionSkeleton(
        is_dark: widget.is_dark,
        tab_bar: is_tab_bar_loading
            ? null
            : _build_ranking_tab_bar(selected_sub_tab_index),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
          child: _build_ranking_tab_bar(selected_sub_tab_index),
        ),
        Transform.translate(
          offset: const Offset(0, RankingSectionStyle.content_padding_top),
          child: RankingContent(
            key: ValueKey<int>(selected_sub_tab_index),
            books:
                widget.all_ranking_data.isNotEmpty &&
                    selected_sub_tab_index < widget.all_ranking_data.length
                ? widget.all_ranking_data[selected_sub_tab_index]
                : [],
            is_dark: widget.is_dark,
            panel_bg: widget.panel_bg,
            initial_column_index:
                _column_index_by_sub_tab_index[selected_sub_tab_index] ?? 0,
            on_column_index_changed: (int column_index) {
              _column_index_by_sub_tab_index[selected_sub_tab_index] =
                  column_index;
            },
            on_reload: widget.on_reload,
          ),
        ),
        if (_has_current_tab_data)
          ViewMoreButton(
            is_dark: widget.is_dark,
            language_code: widget.language_code,
            on_tap: widget.on_full_ranking_tap != null
                ? () => _handle_full_ranking_tap()
                : null,
          ),
        const SizedBox(height: RankingSectionStyle.ranking_bottom_spacing),
      ],
    );
  }

  /// 构建真实榜单 Tab。
  Widget _build_ranking_tab_bar(int selected_sub_tab_index) {
    return RankingTabBar(
      sub_tab_list: widget.sub_tab_list,
      selected_index: selected_sub_tab_index,
      is_dark: widget.is_dark,
      panel_bg: widget.panel_bg,
      language_code: widget.language_code,
      on_tab_changed: _handle_tab_tap,
      on_full_ranking_tap: widget.on_full_ranking_tap != null
          ? _handle_full_ranking_tap
          : null,
    );
  }

  /// 处理子 Tab 点击事件。
  ///
  /// [index] - 被点击的 Tab 索引。
  void _handle_tab_tap(int index) {
    if (index == _selected_sub_tab_index) return;
    setState(() {
      _selected_sub_tab_index = index;
    });
    widget.on_tab_changed?.call(index);
  }

  /// 处理"完整榜单"按钮点击事件。
  ///
  /// 获取当前选中 Tab 的 id，传递给回调。
  void _handle_full_ranking_tap() {
    /// 当前选中 Tab 的 id。
    final int current_tab_id =
        widget.sub_tab_id_list.isNotEmpty &&
            _selected_sub_tab_index < widget.sub_tab_id_list.length
        ? widget.sub_tab_id_list[_selected_sub_tab_index]
        : 0;
    widget.on_full_ranking_tap?.call(current_tab_id);
  }
}
