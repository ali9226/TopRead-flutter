import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/color_config.dart';

import 'package:app/components/svg_icon/index.dart';
import 'package:app/models/preference.dart';
import 'package:app/components/category_filter/style.dart';
import 'package:app/util/language_util/index.dart';

/// 分类筛选栏组件。
///
/// 顶部固定不动，包含：
/// - 左侧可左右滑动的分类标签列表（带左右渐变遮罩）
/// - 右侧向下箭头图标（点击弹出筛选弹窗）
///
/// 支持单选模式：点击已选中的分类会取消选中，点击其他分类会替换选中。
/// 通过外部传入 [scroll_controller] 控制横向滚动位置。
class CategoryFilterBar extends StatefulWidget {
  /// 当前选中的分类项 id（单选，null 表示未选中）。
  final int? selected_id;

  /// 所有分类项列表（来源于 preference_list id=2 的 data_list）。
  final List<PreferenceItem> category_list;

  /// 标签点击回调，参数为分类项的 id。
  final ValueChanged<int> on_tag_tap;

  /// 右侧箭头点击回调。
  final VoidCallback on_arrow_tap;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 横向标签列表的滚动控制器，由外部传入以支持自动滚动到选中项。
  final ScrollController scroll_controller;

  /// 当前语言代码，用于 CJK/非 CJK 样式适配。
  final String language_code;

  /// 每个分类标签的 GlobalKey，由外部传入，用于读取实际渲染位置和尺寸。
  final Map<int, GlobalKey> tag_keys;

  const CategoryFilterBar({
    super.key,
    required this.selected_id,
    required this.category_list,
    required this.on_tag_tap,
    required this.on_arrow_tap,
    required this.is_dark,
    required this.scroll_controller,
    required this.language_code,
    required this.tag_keys,
  });

  @override
  State<CategoryFilterBar> createState() => _CategoryFilterBarState();
}

class _CategoryFilterBarState extends State<CategoryFilterBar> {
  @override
  Widget build(BuildContext context) {
    /// 根据语种判断是否为 CJK，选择对应的字号、间距和高度。
    final bool is_cjk = LanguageUtil.is_cjk_language(widget.language_code);
    final double font_size = is_cjk
        ? CategoryFilterStyle.tag_font_size_cjk
        : CategoryFilterStyle.tag_font_size_alphabetic;
    final double horizontal_padding = is_cjk
        ? CategoryFilterStyle.tag_horizontal_padding_cjk
        : CategoryFilterStyle.tag_horizontal_padding_alphabetic;
    final double vertical_padding = is_cjk
        ? CategoryFilterStyle.tag_vertical_padding_cjk
        : CategoryFilterStyle.tag_vertical_padding_alphabetic;
    final double filter_bar_height = is_cjk
        ? CategoryFilterStyle.filter_bar_height_cjk
        : CategoryFilterStyle.filter_bar_height_alphabetic;

    /// 右侧箭头图标的颜色。
    final Color arrow_color = widget.is_dark
        ? const Color(0xFFBBBBC0)
        : const Color(0xFF666666);

    /// 未选中标签背景色。
    final Color unselected_bg = widget.is_dark
        ? CategoryFilterStyle.tag_unselected_dark_bg
        : CategoryFilterStyle.tag_unselected_light_bg;

    /// 未选中标签文字色。
    final Color unselected_text = widget.is_dark
        ? CategoryFilterStyle.tag_unselected_dark_text
        : CategoryFilterStyle.tag_unselected_light_text;

    /// 选中标签背景色（区分日夜模式）。
    final Color selected_bg = widget.is_dark
        ? CategoryFilterStyle.tag_selected_dark_bg
        : CategoryFilterStyle.tag_selected_light_bg;

    /// 选中标签文字色（区分日夜模式）。
    final Color selected_text = widget.is_dark
        ? CategoryFilterStyle.tag_selected_dark_text
        : CategoryFilterStyle.tag_selected_light_text;

    /// 渐变遮罩颜色（与页面背景一致）。
    final Color gradient_color = widget.is_dark
        ? const Color(0xFF12121C)
        : const Color(0xFFF6F7FB);

    return Padding(
      padding: const EdgeInsets.only(bottom: CategoryFilterStyle.filter_bar_bottom_padding),
      child: SizedBox(
        height: filter_bar_height,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            /// 标签横向滚动列表。
            Positioned(
              left: 0,
              right: 44,
              top: 0,
              bottom: 0,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  ListView.builder(
                    controller: widget.scroll_controller,
                    scrollDirection: Axis.horizontal,
                    cacheExtent: double.infinity,
                    padding: const EdgeInsets.only(
                      left: CategoryFilterStyle.arrow_right_margin,
                      right: CategoryFilterStyle.arrow_right_margin + 10,
                    ),
                    itemCount: widget.category_list.length,
                    itemBuilder: (BuildContext context, int index) {
                      final PreferenceItem item = widget.category_list[index];
                      final bool is_selected = widget.selected_id == item.id;
                      return Padding(
                        key: widget.tag_keys[item.id],
                        padding: const EdgeInsets.only(
                          right: CategoryFilterStyle.tag_spacing,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => widget.on_tag_tap(item.id),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontal_padding,
                                  vertical: vertical_padding,
                                ),
                                decoration: BoxDecoration(
                                  color: is_selected ? selected_bg : unselected_bg,
                                  borderRadius: BorderRadius.circular(
                                    CategoryFilterStyle.tag_border_radius,
                                  ),
                                  border: Border.all(
                                    color: is_selected
                                        ? ColorConstants.themeColor
                                        : unselected_bg,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: font_size,
                                    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                                    color: is_selected ? selected_text : unselected_text,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  /// 左侧渐变遮罩。
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: CategoryFilterStyle.left_gradient_width,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: <Color>[
                              gradient_color,
                              gradient_color.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  /// 右侧渐变遮罩。
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: CategoryFilterStyle.right_gradient_width,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: <Color>[
                              gradient_color,
                              gradient_color.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// 右侧向下箭头图标（上移 2px）。
            Positioned(
              right: 0,
              top: 0,
              bottom: 4,
              width: 44,
              child: GestureDetector(
                onTap: widget.on_arrow_tap,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Transform.rotate(
                    angle: 90 * 3.141592653589793 / 180,
                    child: SvgIcon(
                      name: 'right',
                      width: CategoryFilterStyle.arrow_icon_size,
                      height: CategoryFilterStyle.arrow_icon_size,
                      color: arrow_color,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
