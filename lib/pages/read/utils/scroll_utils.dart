import 'package:flutter/material.dart';
import 'package:app/pages/read/style.dart';

/// 阅读页滚动相关工具方法集合。
class ScrollUtils {
  /// 判断正文区域是否已经滚动到屏幕顶部附近。
  ///
  /// 使用容差阈值：正文区块顶部距离状态栏 [threshold] 像素以内即视为已到达顶部，
  /// 避免用户刚看到正文内容时还需要再滑动一点点才能触发翻页点击。
  static bool is_reading_section_at_top({
    required GlobalKey? reading_section_key,
    required BuildContext context,
  }) {
    final BuildContext? reading_context = reading_section_key?.currentContext;
    if (reading_context == null) {
      return false;
    }

    final RenderObject? render_object = reading_context.findRenderObject();
    if (render_object is! RenderBox || !render_object.hasSize) {
      return false;
    }

    final double reading_section_top = render_object
        .localToGlobal(Offset.zero)
        .dy;
    final double screen_top_inset = MediaQuery.viewPaddingOf(context).top;
    return reading_section_top <=
        screen_top_inset + Style.reading_section_at_top_threshold;
  }

  /// 向上滚动接近一屏，预留底部 50 像素。
  static Future<void> scroll_page_up({
    required ScrollController scroll_controller,
    required BuildContext context,
  }) async {
    // 未绑定滚动视图时直接返回，防止访问 position 报错。
    if (!scroll_controller.hasClients) {
      return;
    }

    // 计算单次上翻距离，按“一屏高度 - 预留偏移”处理，避免翻页后贴底。
    final double scroll_distance =
        scroll_controller.position.viewportDimension -
        Style.page_scroll_step_offset;
    // 目标偏移量向上移动，并限制在合法滚动区间内。
    final double target_offset = (scroll_controller.offset - scroll_distance)
        .clamp(0.0, scroll_controller.position.maxScrollExtent);
    // 执行平滑滚动，提升翻页过渡体验。
    await scroll_controller.animateTo(
      target_offset,
      duration: Duration(milliseconds: Style.page_scroll_animation_duration_ms),
      curve: Curves.easeInOut,
    );
  }

  /// 向下滚动接近一屏，预留底部 50 像素。
  static Future<void> scroll_page_down({
    required ScrollController scroll_controller,
    required BuildContext context,
  }) async {
    // 未绑定滚动视图时直接返回，防止访问 position 报错。
    if (!scroll_controller.hasClients) {
      return;
    }

    // 计算单次下翻距离，按“一屏高度 - 预留偏移”处理，便于连续阅读。
    final double scroll_distance =
        scroll_controller.position.viewportDimension -
        Style.page_scroll_step_offset;
    // 目标偏移量向下移动，并限制在合法滚动区间内。
    final double target_offset = (scroll_controller.offset + scroll_distance)
        .clamp(0.0, scroll_controller.position.maxScrollExtent);
    // 执行平滑滚动，提升翻页过渡体验。
    await scroll_controller.animateTo(
      target_offset,
      duration: Duration(milliseconds: Style.page_scroll_animation_duration_ms),
      curve: Curves.easeInOut,
    );
  }
}
