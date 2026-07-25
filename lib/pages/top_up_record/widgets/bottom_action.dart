import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

import '../style.dart';

/// 列表底部状态区。
///
/// 根据分页状态展示三种结果：
/// 1. 正在加载更多
/// 2. 已经没有更多
/// 3. 仍有更多，但当前不显示额外文案
class TopUpRecordBottomAction extends StatelessWidget {
  final bool isDark;
  final bool loadingMore;
  final bool hasMore;

  const TopUpRecordBottomAction({
    super.key,
    required this.isDark,
    required this.loadingMore,
    required this.hasMore,
  });

  @override
  Widget build(BuildContext context) {
    // 深色模式下稍微提高文字亮度，避免在深背景里显得太弱。
    final textColor = isDark
        ? ColorConstants.whiteColor.withValues(
            alpha: TopUpRecordStyle.bottomActionDarkOpacity,
          )
        : ColorConstants.hintColor;

    if (loadingMore) {
      // 分页加载时，用轻量文案提示即可，不需要全屏遮罩。
      return Padding(
        padding: const EdgeInsets.only(
          top: TopUpRecordStyle.bottomActionTopSpacing,
          bottom: TopUpRecordStyle.bottomActionVertical,
        ),
        child: Center(
          child: Text(
            easy.tr('top_up_record_page.loading_more'),
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
      // 已经确认没有更多数据后，在底部给用户一个明确终点提示。
      return Padding(
        padding: const EdgeInsets.only(
          top: TopUpRecordStyle.bottomActionTopSpacing,
          bottom: TopUpRecordStyle.bottomActionVertical,
        ),
        child: Center(
          child: Text(
            easy.tr('top_up_record_page.no_more'),
            style: TextStyle(
              color: textColor,
              fontSize: TopUpRecordStyle.bottomActionTextSize,
              fontWeight: TopUpRecordStyle.bottomActionTextWeight,
            ),
          ),
        ),
      );
    }

    // 还有更多数据但当前未加载时，留一段呼吸空间即可。
    return const SizedBox(height: TopUpRecordStyle.bottomActionVertical);
  }
}
