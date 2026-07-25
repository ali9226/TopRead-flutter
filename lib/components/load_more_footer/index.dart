import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

import 'package:app/config/color_config.dart';
import 'package:app/components/load_more_footer/style.dart';

/// 统一加载更多底部组件。
///
/// 支持三种状态：
/// - [hasMore] 为 true 且非加载中：显示"加载更多"按钮（圆角胶囊 + 箭头）
/// - [isLoading] 为 true：显示加载中（主题色旋转圈 + 文案）
/// - [hasMore] 为 false 且非加载中：显示"没有更多了"（两侧装饰线）
///
/// 用法：
/// ```dart
/// LoadMoreFooter(
///   is_dark: is_dark,
///   isLoading: _is_loading_more,
///   hasMore: _current_page < _max_page,
///   onLoadMore: _load_more_data,
/// )
/// ```
class LoadMoreFooter extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 是否正在加载中。
  final bool isLoading;

  /// 是否还有更多数据。
  final bool hasMore;

  /// 点击"加载更多"时的回调。
  final VoidCallback? onLoadMore;

  const LoadMoreFooter({
    super.key,
    required this.is_dark,
    required this.isLoading,
    required this.hasMore,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _build_loading();
    }
    if (hasMore) {
      return _build_load_more();
    }
    return _build_no_more();
  }

  /// 加载中状态：主题色旋转圈 + 文案。
  Widget _build_loading() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: LoadMoreFooterStyle.verticalSpacing,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: LoadMoreFooterStyle.spinnerSize,
            height: LoadMoreFooterStyle.spinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: ColorConstants.themeColor,
            ),
          ),
          const SizedBox(width: LoadMoreFooterStyle.iconSpacing),
          Text(
            easy.tr('bookshelf.load_more.loading'),
            style: TextStyle(
              color: is_dark
                  ? Colors.white.withValues(alpha: 0.6)
                  : const Color(0xFF999999),
              fontSize: LoadMoreFooterStyle.fontSize,
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
        vertical: LoadMoreFooterStyle.verticalSpacing,
      ),
      child: Center(
        child: GestureDetector(
          onTap: onLoadMore,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LoadMoreFooterStyle.buttonHorizontalPadding,
              vertical: LoadMoreFooterStyle.buttonVerticalPadding,
            ),
            decoration: BoxDecoration(
              color: is_dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFF2F3F5),
              borderRadius: BorderRadius.circular(
                LoadMoreFooterStyle.buttonRadius,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  easy.tr('bookshelf.load_more.button'),
                  style: TextStyle(
                    color: is_dark
                        ? Colors.white.withValues(alpha: 0.75)
                        : const Color(0xFF666666),
                    fontSize: LoadMoreFooterStyle.fontSize,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                  ),
                ),
                const SizedBox(width: LoadMoreFooterStyle.iconSpacing),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: LoadMoreFooterStyle.iconSize,
                  color: is_dark
                      ? Colors.white.withValues(alpha: 0.5)
                      : const Color(0xFF999999),
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
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE5E6EB);
    final Color text_color = is_dark
        ? Colors.white.withValues(alpha: 0.35)
        : const Color(0xFFBBBBBB);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: LoadMoreFooterStyle.verticalSpacing,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: LoadMoreFooterStyle.dividerWidth,
            height: 1,
            color: line_color,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LoadMoreFooterStyle.dividerTextSpacing,
            ),
            child: Text(
              easy.tr('bookshelf.load_more.no_more'),
              style: TextStyle(
                color: text_color,
                fontSize: LoadMoreFooterStyle.smallFontSize,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              ),
            ),
          ),
          Container(
            width: LoadMoreFooterStyle.dividerWidth,
            height: 1,
            color: line_color,
          ),
        ],
      ),
    );
  }
}
