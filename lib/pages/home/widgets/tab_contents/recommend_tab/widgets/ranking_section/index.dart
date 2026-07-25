import 'package:flutter/material.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/models/story_item.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/style.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/widgets/ranking_tab_bar.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/widgets/ranking_content.dart';
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

    // Tab 标题列表为空时才展示 Tab 栏骨架屏，
    // 切换榜单内容时 Tab 标题不变，无需骨架屏。
    final bool is_tab_bar_loading = widget.sub_tab_list.isEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // 顶部 Tab 栏
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
          child: is_tab_bar_loading
              ? _build_tab_bar_skeleton()
              : RankingTabBar(
                  sub_tab_list: widget.sub_tab_list,
                  selected_index: selected_sub_tab_index,
                  is_dark: widget.is_dark,
                  panel_bg: widget.panel_bg,
                  language_code: widget.language_code,
                  on_tab_changed: _handle_tab_tap,
                  on_full_ranking_tap: widget.on_full_ranking_tap != null
                      ? () => _handle_full_ranking_tap()
                      : null,
                ),
        ),
        // 榜单内容区域
        widget.is_loading
            ? _build_content_skeleton()
            : Transform.translate(
                offset: const Offset(
                  0,
                  RankingSectionStyle.content_padding_top,
                ),
                child: RankingContent(
                  key: ValueKey<int>(selected_sub_tab_index),
                  books:
                      widget.all_ranking_data.isNotEmpty &&
                          selected_sub_tab_index <
                              widget.all_ranking_data.length
                      ? widget.all_ranking_data[selected_sub_tab_index]
                      : [],
                  is_dark: widget.is_dark,
                  panel_bg: widget.panel_bg,
                  initial_column_index:
                      _column_index_by_sub_tab_index[selected_sub_tab_index] ??
                      0,
                  on_column_index_changed: (int column_index) {
                    _column_index_by_sub_tab_index[selected_sub_tab_index] =
                        column_index;
                  },
                  on_reload: widget.on_reload,
                ),
              ),
        // "查看更多"按钮及其加载骨架。
        if (widget.is_loading)
          _build_view_more_skeleton()
        else if (_has_current_tab_data)
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

  /// 构建 Tab 栏骨架屏。
  Widget _build_tab_bar_skeleton() {
    final Color skeleton_color = widget.is_dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.withValues(alpha: 0.15);

    return SizedBox(
      height: RankingSectionStyle.tab_bar_height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          RankingSectionStyle.tab_left_padding,
          0,
          RankingSectionStyle.tab_right_padding,
          0,
        ),
        itemCount: 5,
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(
            width: RankingSectionStyle.tab_separator_width_cjk,
          );
        },
        itemBuilder: (BuildContext context, int index) {
          return Center(
            child: Container(
              width: 40 + (index % 3) * 8.0,
              height: 12,
              decoration: BoxDecoration(
                color: skeleton_color,
                borderRadius: BorderRadius.circular(LayoutConfig.tag_radius),
              ),
              child: _ShimmerWidget(is_dark: widget.is_dark),
            ),
          );
        },
      ),
    );
  }

  /// 构建内容区域骨架屏。
  ///
  /// 双列四行布局，每列包含封面、排名序号和书籍信息骨架。
  Widget _build_content_skeleton() {
    final Color skeleton_color = widget.is_dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.withValues(alpha: 0.15);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: RankingSectionStyle.content_padding_horizontal,
      ),
      child: Column(
        children: List<Widget>.generate(RankingSectionStyle.rows_per_column, (
          int row_index,
        ) {
          return Padding(
            padding: const EdgeInsets.only(
              bottom:
                  RankingSectionStyle.item_height -
                  RankingSectionStyle.cover_height,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _build_single_skeleton_item(
                    skeleton_color: skeleton_color,
                    index: row_index * 2,
                  ),
                ),
                const SizedBox(width: RankingSectionStyle.column_gap),
                Expanded(
                  child: _build_single_skeleton_item(
                    skeleton_color: skeleton_color,
                    index: row_index * 2 + 1,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// 构建与“查看更多”文字位置一致的居中骨架。
  Widget _build_view_more_skeleton() {
    final Color skeleton_color = widget.is_dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.withValues(alpha: 0.15);

    return Padding(
      padding: const EdgeInsets.only(
        top: RankingSectionStyle.view_more_top_spacing,
        bottom: RankingSectionStyle.view_more_bottom_spacing,
      ),
      child: SizedBox(
        height: RankingSectionStyle.view_more_content_height,
        child: Center(
          child: Container(
            width: RankingSectionStyle.view_more_skeleton_width,
            height: RankingSectionStyle.view_more_skeleton_height,
            decoration: BoxDecoration(
              color: skeleton_color,
              borderRadius: BorderRadius.circular(LayoutConfig.tag_radius),
            ),
            child: _ShimmerWidget(is_dark: widget.is_dark),
          ),
        ),
      ),
    );
  }

  /// 构建单个骨架屏条目。
  ///
  /// 包含封面骨架、排名序号骨架、书名骨架和分类/热度骨架。
  Widget _build_single_skeleton_item({
    required Color skeleton_color,
    required int index,
  }) {
    return Row(
      children: <Widget>[
        Container(
          width: RankingSectionStyle.cover_width,
          height: RankingSectionStyle.cover_height,
          decoration: BoxDecoration(
            color: skeleton_color,
            borderRadius: BorderRadius.circular(
              RankingSectionStyle.cover_border_radius,
            ),
          ),
        ),
        const SizedBox(width: RankingSectionStyle.cover_to_rank_gap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 100 + (index % 3) * 20.0,
                height: 12,
                decoration: BoxDecoration(
                  color: skeleton_color,
                  borderRadius: BorderRadius.circular(LayoutConfig.tag_radius),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 60 + (index % 2) * 15.0,
                height: 10,
                decoration: BoxDecoration(
                  color: skeleton_color,
                  borderRadius: BorderRadius.circular(LayoutConfig.tag_radius),
                ),
              ),
            ],
          ),
        ),
      ],
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

/// 简单的骨架屏闪烁动画组件。
class _ShimmerWidget extends StatefulWidget {
  final bool is_dark;

  const _ShimmerWidget({required this.is_dark});

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final Color base_color = widget.is_dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.1);
        final Color highlight_color = widget.is_dark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.25);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[base_color, highlight_color, base_color],
              stops: <double>[
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
            borderRadius: BorderRadius.circular(LayoutConfig.tag_radius),
          ),
        );
      },
    );
  }
}
