import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/withdraw_record/style.dart';

/// 提现记录页底部状态提示。
///
/// 这个组件专门负责列表末尾那一行文案：
/// 1. 正在加载更多。
/// 2. 已经没有更多。
/// 3. 还有更多但暂时不展示额外文案。
///
/// 单独拆出来后，路由页不需要在主列表里反复写这些 if/else 结构。
class WithdrawRecordBottomAction extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 是否处于“加载下一页”状态。
  final bool loadingMore;

  /// 是否还存在下一页数据。
  final bool hasMore;

  const WithdrawRecordBottomAction({
    super.key,
    required this.isDark,
    required this.loadingMore,
    required this.hasMore,
  });

  @override
  Widget build(BuildContext context) {
    // 底部状态提示文字的颜色。
    final textColor = isDark
        ? ColorConstants.whiteColor.withValues(
            alpha: TopUpRecordStyle.bottomActionDarkOpacity,
          )
        : ColorConstants.hintColor;

    if (loadingMore) {
      // 分页请求进行中时，优先告诉用户“正在继续加载”。
      return Padding(
        padding: const EdgeInsets.only(
          top: TopUpRecordStyle.bottomActionTopSpacing,
          bottom: TopUpRecordStyle.bottomActionVertical,
        ),
        child: Center(
          child: Text(
            context.tr('withdraw_record_page.loading_more'),
            style: TextStyle(
              color: textColor,
              fontSize: TopUpRecordStyle.bottomActionTextSize,
              fontWeight: TopUpRecordStyle.bottomActionTextWeight,
            ),
          ),
        ),
      );
    }

    if (!hasMore) {
      // 没有更多数据时，给出明确结束提示，避免用户误以为加载失败。
      return Padding(
        padding: const EdgeInsets.only(
          top: TopUpRecordStyle.bottomActionTopSpacing,
          bottom: TopUpRecordStyle.bottomActionVertical,
        ),
        child: Center(
          child: Text(
            context.tr('withdraw_record_page.no_more'),
            style: TextStyle(
              color: textColor,
              fontSize: TopUpRecordStyle.bottomActionTextSize,
              fontWeight: TopUpRecordStyle.bottomActionTextWeight,
            ),
          ),
        ),
      );
    }

    // 还有更多数据、但当前也没有主动加载时，只保留一段底部留白即可。
    return const SizedBox(height: TopUpRecordStyle.bottomActionVertical);
  }
}
