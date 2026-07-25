import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/style.dart';
import 'package:app/util/language_util/index.dart';

/// 榜单 Tab 栏组件。
///
/// 展示子 Tab 标签列表和"完整榜单"按钮，
/// 支持选中缩放动画和左右两侧渐变遮罩。
///
/// 根据当前语种自动适配字号、间距和缩放比例：
/// - CJK 语系使用较大的字号和宽松的间距。
/// - 非 CJK 语系使用较小的字号和紧凑的间距。
class RankingTabBar extends StatelessWidget {
  /// 子 Tab 标签列表。
  final List<String> sub_tab_list;

  /// 当前选中的 Tab 索引。
  final int selected_index;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 面板背景色（用于渐变遮罩）。
  final Color panel_bg;

  /// Tab 切换回调，参数为选中的索引。
  final ValueChanged<int>? on_tab_changed;

  /// "完整榜单"点击回调。
  final VoidCallback? on_full_ranking_tap;

  /// 当前语种代码，用于判断是否为 CJK 语系。
  final String language_code;

  const RankingTabBar({
    super.key,
    required this.sub_tab_list,
    required this.selected_index,
    required this.is_dark,
    required this.panel_bg,
    required this.language_code,
    this.on_tab_changed,
    this.on_full_ranking_tap,
  });

  @override
  Widget build(BuildContext context) {
    /// 根据语种判断是否为 CJK，选择对应的字号、间距和缩放比例。
    final bool is_cjk = LanguageUtil.is_cjk_language(language_code);
    final double font_size = is_cjk
        ? RankingSectionStyle.tab_font_size_cjk
        : RankingSectionStyle.tab_font_size_alphabetic;
    final double selected_scale = is_cjk
        ? RankingSectionStyle.tab_selected_scale_cjk
        : RankingSectionStyle.tab_selected_scale_alphabetic;
    final double separator_width = is_cjk
        ? RankingSectionStyle.tab_separator_width_cjk
        : RankingSectionStyle.tab_separator_width_alphabetic;

    /// 选中文字颜色。
    final Color selected_color = is_dark ? Colors.white : Colors.black;

    /// 未选中文字颜色。
    final Color unselected_color = is_dark
        ? Colors.white.withValues(alpha: 0.54)
        : RankingSectionStyle.unselected_color_light;

    return SizedBox(
      height: RankingSectionStyle.tab_bar_height,
      child: Row(
        children: <Widget>[
          // 子 Tab 横向滚动列表
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // Tab 列表主体
                ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(
                    RankingSectionStyle.tab_left_padding,
                    0,
                    RankingSectionStyle.tab_right_padding,
                    0,
                  ),
                  itemCount: sub_tab_list.length,
                  separatorBuilder: (BuildContext context, int index) {
                    return SizedBox(
                      width: separator_width,
                    );
                  },
                  itemBuilder: (BuildContext context, int index) {
                    final bool is_selected = index == selected_index;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => on_tab_changed?.call(index),
                      child: Center(
                        child: AnimatedScale(
                          scale: is_selected ? selected_scale : 1.0,
                          duration: const Duration(
                            milliseconds: RankingSectionStyle.tab_animation_duration_ms,
                          ),
                          curve: Curves.easeOut,
                          child: Text(
                            sub_tab_list[index],
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              fontSize: font_size,
                              fontWeight: is_selected
                                  ? FontConfig.adjustedWeight(FontWeight.w500)
                                  : FontConfig.adjustedWeight(FontWeight.w400),
                              color: is_selected
                                  ? selected_color
                                  : unselected_color,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // 左侧渐变遮罩，用于隐藏滚动边缘
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: RankingSectionStyle.tab_left_gradient_width,
                  child: IgnorePointer(
                    child: _build_gradient_mask(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                // 右侧渐变遮罩，用于隐藏滚动边缘
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: RankingSectionStyle.tab_right_gradient_width,
                  child: IgnorePointer(
                    child: _build_gradient_mask(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 右侧间距
          const SizedBox(width: RankingSectionStyle.full_ranking_gap),
          // "完整榜单"按钮
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: on_full_ranking_tap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  easy.tr('home.full_ranking_link'),
                  style: TextStyle(
                    fontSize: font_size,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                    color: selected_color,
                  ),
                ),
                const SizedBox(width: RankingSectionStyle.full_ranking_icon_gap),
                Icon(
                  Icons.chevron_right,
                  size: RankingSectionStyle.full_ranking_icon_size,
                  color: selected_color,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建渐变遮罩容器。
  ///
  /// [begin] 渐变起始方向。
  /// [end] 渐变结束方向。
  Widget _build_gradient_mask({
    required Alignment begin,
    required Alignment end,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: <Color>[
            panel_bg,
            panel_bg.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
