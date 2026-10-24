import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 根据正文起点的真实布局定位，简介展开、标题重排和折叠后无需估算头部高度。
/// 正文很短时钳制到可滚动边界，不把下一篇预览或底部安全区当成正文起点。
double? reading_start_scroll_offset({
  required ScrollController scroll_controller,
  required GlobalKey body_start_key,
}) {
  if (!scroll_controller.hasClients ||
      !scroll_controller.position.hasContentDimensions) {
    return null;
  }
  final render_object = body_start_key.currentContext?.findRenderObject();
  if (render_object is! RenderBox || !render_object.hasSize) return null;
  final viewport = RenderAbstractViewport.of(render_object);
  return viewport
      .getOffsetToReveal(render_object, 0)
      .offset
      .clamp(
        scroll_controller.position.minScrollExtent,
        scroll_controller.position.maxScrollExtent,
      )
      .toDouble();
}
