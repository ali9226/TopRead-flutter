import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 计算当前篇末尾对齐阅读视口底部时的滚动偏移。
///
/// [scroll_controller] 是正文的滚动控制器。
/// [story_end_key] 指向当前篇结束标记，后面的下一篇预览不计入阅读进度。
double calculate_current_story_scroll_extent({
  required ScrollController scroll_controller,
  required GlobalKey story_end_key,
}) {
  if (!scroll_controller.hasClients ||
      !scroll_controller.position.hasContentDimensions) {
    return 0;
  }

  final ScrollPosition position = scroll_controller.position;
  final RenderObject? marker = story_end_key.currentContext?.findRenderObject();
  if (marker == null || !marker.attached) return position.maxScrollExtent;

  final RenderAbstractViewport? viewport = RenderAbstractViewport.maybeOf(
    marker,
  );
  if (viewport == null) return position.maxScrollExtent;

  final double reveal_offset = viewport.getOffsetToReveal(marker, 1).offset;
  return reveal_offset.clamp(
    position.minScrollExtent,
    position.maxScrollExtent,
  );
}
