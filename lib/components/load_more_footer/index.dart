import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

import 'package:app/config/color_config.dart';
import 'package:app/components/load_more_footer/style.dart';

/// 统一加载更多底部组件。
///
/// 支持三种状态：
/// - [has_more] 为 true 且非加载中：显示"加载更多"按钮（圆角胶囊 + 箭头）
/// - [is_loading] 为 true：显示加载中（主题色旋转圈 + 文案）
/// - [has_more] 为 false 且非加载中：显示"没有更多了"（两侧装饰线）
///
/// 用法：
/// ```dart
/// LoadMoreFooter(
///   is_dark: is_dark,
///   is_loading: _is_loading_more,
///   has_more: _current_page < _max_page,
///   on_load_more: _load_more_data,
/// )
/// ```
class LoadMoreFooter extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 是否正在加载中。
  final bool is_loading;

  /// 是否还有更多数据。
  final bool has_more;

  /// 点击"加载更多"时的回调。
  final VoidCallback? on_load_more;

  const LoadMoreFooter({
    super.key,
    required this.is_dark,
    required this.is_loading,
    required this.has_more,
    this.on_load_more,
  });

  @override
  Widget build(BuildContext context) {
    if (is_loading) {
      return _build_loading();
    }
    if (has_more) {
      return _build_load_more();
    }
    return _build_no_more();
  }

  /// 加载中状态：主题色旋转圈 + 文案。
  Widget _build_loading() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: LoadMoreFooterStyle.vertical_spacing,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: LoadMoreFooterStyle.spinner_size,
            height: LoadMoreFooterStyle.spinner_size,
            child: CircularProgressIndicator(
              strokeWidth: LoadMoreFooterStyle.spinner_stroke_width,
              color: ColorConstants.themeColor,
            ),
          ),
          const SizedBox(width: LoadMoreFooterStyle.icon_spacing),
          Text(
            easy.tr('bookshelf.load_more.loading'),
            style: TextStyle(
              color: is_dark
                  ? ColorConstants.components_load_more_footer_index_tone
                  : ColorConstants.customer_service_sheet_style_time_color_light,
              fontSize: LoadMoreFooterStyle.font_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  /// 还有更多状态：圆角胶囊按钮。
  Widget _build_load_more() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: LoadMoreFooterStyle.vertical_spacing,
      ),
      child: Center(
        child: GestureDetector(
          onTap: on_load_more,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LoadMoreFooterStyle.button_horizontal_padding,
              vertical: LoadMoreFooterStyle.button_vertical_padding,
            ),
            decoration: BoxDecoration(
              color: is_dark
                  ? ColorConstants.util_dialog_show_upgrade_dialog_tone_14ffffff
                  : ColorConstants.components_load_more_footer_index_tone_fff2f3f5,
              borderRadius: BorderRadius.circular(
                LoadMoreFooterStyle.button_radius,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  easy.tr('bookshelf.load_more.button'),
                  style: TextStyle(
                    color: is_dark
                        ? ColorConstants.components_load_more_footer_index_tone_bfffffff
                        : ColorConstants.customer_service_sheet_style_time_color_dark,
                    fontSize: LoadMoreFooterStyle.font_size,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                  ),
                ),
                const SizedBox(width: LoadMoreFooterStyle.icon_spacing),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: LoadMoreFooterStyle.icon_size,
                  color: is_dark
                      ? ColorConstants.util_dialog_show_upgrade_dialog_tone_80ffffff
                      : ColorConstants.customer_service_sheet_style_time_color_light,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 没有更多状态：两侧装饰线 + 文案。
  Widget _build_no_more() {
    final Color line_color = is_dark
        ? ColorConstants.components_fixed_bottom_navigation_widgets_night_panel_decor_tone
        : ColorConstants.components_load_more_footer_index_tone_ffe5e6eb;
    final Color text_color = is_dark
        ? ColorConstants.components_load_more_footer_index_tone_59ffffff
        : ColorConstants.components_load_more_footer_index_tone_ffbbbbbb;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: LoadMoreFooterStyle.vertical_spacing,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: LoadMoreFooterStyle.divider_width,
            height: LoadMoreFooterStyle.divider_height,
            color: line_color,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LoadMoreFooterStyle.divider_text_spacing,
            ),
            child: Text(
              easy.tr('bookshelf.load_more.no_more'),
              style: TextStyle(
                color: text_color,
                fontSize: LoadMoreFooterStyle.small_font_size,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              ),
            ),
          ),
          Container(
            width: LoadMoreFooterStyle.divider_width,
            height: LoadMoreFooterStyle.divider_height,
            color: line_color,
          ),
        ],
      ),
    );
  }
}
