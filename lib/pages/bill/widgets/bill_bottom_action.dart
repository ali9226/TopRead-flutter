import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

import '../style.dart';

/// 账单页底部操作区。
///
/// 这个组件只负责处理列表底部那一小块“继续加载 / 已经到底”的交互区，
/// 把它独立出来后，父级列表组件就不需要再关心按钮样式和文案切换细节。
class BillBottomAction extends StatelessWidget {
  /// 当前主题是否为深色模式。
  final bool isDark;

  /// 当前列表后面是否还可能存在更多账单数据。
  ///
  /// 这个值由父页面根据接口返回条数推导出来，
  /// 用来决定底部是显示“加载更多按钮”还是“已经到底提示”。
  final bool hasMore;

  /// 当前是否有分页请求正在进行中。
  ///
  /// 为 true 时按钮会进入禁用态，避免用户重复点击造成并发请求。
  final bool loading;

  /// 点击“加载更多”后的回调。
  final VoidCallback onTapLoadMore;

  const BillBottomAction({
    super.key,
    required this.isDark,
    required this.hasMore,
    required this.loading,
    required this.onTapLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    /// 当后面可能还有数据时，底部展示一个可点击按钮。
    if (hasMore) {
      return SizedBox(
        /// 让按钮撑满列表内容宽度，和上方卡片的横向节奏保持一致。
        width: double.infinity,
        child: ElevatedButton(
          /// 请求中时禁用按钮，防止重复分页。
          onPressed: loading ? null : onTapLoadMore,
          style: ElevatedButton.styleFrom(
            /// 扁平按钮，不额外叠加系统默认阴影。
            elevation: 0,

            /// 根据深浅色模式切换按钮底色。
            backgroundColor: isDark ? const Color(0xFF171926) : Colors.white,

            /// 正常状态下的前景色，主要影响文字颜色。
            foregroundColor: isDark
                ? ColorConstants.whiteColor
                : ColorConstants.lightTextColor,

            /// 禁用态背景使用同一底色降透明处理，
            /// 保持层级还在，但让用户明显感知当前不可点击。
            disabledBackgroundColor:
                (isDark ? const Color(0xFF171926) : Colors.white).withValues(
                  alpha: Style.actionButtonDisabledBackgroundOpacity,
                ),

            /// 禁用态文字也同步降透明，形成完整的不可用反馈。
            disabledForegroundColor:
                (isDark
                        ? ColorConstants.whiteColor
                        : ColorConstants.lightTextColor)
                    .withValues(
                      alpha: Style.actionButtonDisabledForegroundOpacity,
                    ),

            /// 统一按钮高度，避免因系统字体或内容差异导致高度跳动。
            minimumSize: const Size.fromHeight(Style.actionButtonHeight),
            shape: RoundedRectangleBorder(
              /// 统一按钮圆角，和页面整体卡片风格保持一致。
              borderRadius: BorderRadius.circular(Style.actionButtonRadius),
              side: BorderSide(
                /// 使用轻量描边把按钮从页面背景里提出来，
                /// 但又不能太重，避免抢过账单卡片本身的视觉重点。
                color: isDark
                    ? Colors.white.withValues(
                        alpha: Style.actionButtonBorderDarkOpacity,
                      )
                    : Colors.black.withValues(
                        alpha: Style.actionButtonBorderLightOpacity,
                      ),
              ),
            ),
          ),
          child: Text(
            /// 多语种“加载更多”文案。
            easy.tr('bill.load_more'),
            style: TextStyle(
              fontSize: Style.actionButtonTextSize,
              fontWeight: Style.actionButtonTextWeight,
            ),
          ),
        ),
      );
    }

    /// 当 `hasMore` 为 false 时，说明前端判断后面大概率没有更多数据了，
    /// 这里不再显示按钮，而是直接给出“已经到底”的静态提示。
    return Padding(
      padding: const EdgeInsets.only(
        /// 顶部留一点呼吸空间，让提示和上一条账单卡片不要贴得太近。
        top: Style.noMoreTopPadding,

        /// 底部补一点间距，让列表结束位置更自然。
        bottom: Style.noMoreBottomPadding,
      ),
      child: Center(
        child: Text(
          /// 多语种“没有更多”提示文案。
          easy.tr('bill.no_more'),
          style: TextStyle(
            /// 结束提示不应该比账单主内容更抢眼，所以使用更弱的颜色透明度。
            color: isDark
                ? ColorConstants.whiteColor.withValues(
                    alpha: Style.noMoreDarkOpacity,
                  )
                : ColorConstants.hintColor,
            fontSize: Style.noMoreTextSize,
            fontWeight: Style.noMoreTextWeight,
          ),
        ),
      ),
    );
  }
}
