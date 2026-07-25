import 'package:flutter/material.dart';

import 'package:app/components/bottom_sheet_drag_handle/style.dart';

/// 底部弹窗顶部的统一拖拽把手。
///
/// 把手负责向用户表达“当前面板可以上下拖动”；实际拖拽、回弹和下滑关闭由
/// [showModalBottomSheet] 创建的系统 BottomSheet 统一处理，保证目录、设置和评论
/// 三类面板拥有完全一致的手势反馈。
class BottomSheetDragHandle extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  const BottomSheetDragHandle({super.key, required this.is_dark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: BottomSheetDragHandleStyle.touch_height,
      child: Center(
        child: Container(
          width: BottomSheetDragHandleStyle.bar_width,
          height: BottomSheetDragHandleStyle.bar_height,
          decoration: BoxDecoration(
            color: is_dark
                ? BottomSheetDragHandleStyle.dark_color
                : BottomSheetDragHandleStyle.light_color,
            borderRadius: BorderRadius.circular(
              BottomSheetDragHandleStyle.bar_radius,
            ),
          ),
        ),
      ),
    );
  }
}
