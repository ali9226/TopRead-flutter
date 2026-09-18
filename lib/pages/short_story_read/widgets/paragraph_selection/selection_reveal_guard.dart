// ignore_for_file: non_constant_identifier_names, avoid_renaming_method_parameters

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'style.dart';

/// 初次全选时保留当前阅读位置，避免 EditableText 自动把段尾滚进屏幕。
///
/// 手柄拖拽期间恢复默认的 showOnScreen，仍可跟随手柄滚动正文。
class ParagraphSelectionRevealGuard extends SingleChildRenderObjectWidget {
  const ParagraphSelectionRevealGuard({
    super.key,
    required this.should_suppress,
    required this.active_selection_position,
    required super.child,
  });

  final bool Function() should_suppress;
  final TextPosition? Function() active_selection_position;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _ParagraphSelectionRevealRenderBox(
        should_suppress,
        active_selection_position,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderProxyBox render_object,
  ) {
    render_object as _ParagraphSelectionRevealRenderBox;
    render_object.should_suppress = should_suppress;
    render_object.active_selection_position = active_selection_position;
  }
}

class _ParagraphSelectionRevealRenderBox extends RenderProxyBox {
  _ParagraphSelectionRevealRenderBox(
    this.should_suppress,
    this.active_selection_position,
  );

  bool Function() should_suppress;
  TextPosition? Function() active_selection_position;

  @override
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    if (should_suppress()) return;
    // Android 拖动起始手柄时 base 会改变，但 EditableText 默认仍显示 extent。
    // 使用实际移动的边界，防止长段落拖动起点时突然滚到段落末尾。
    final TextPosition? active_position = active_selection_position();
    if (active_position != null && descendant is RenderEditable) {
      rect = descendant
          .getLocalRectForCaret(active_position)
          .inflate(ParagraphSelectionStyle.drag_reveal_padding);
    }
    super.showOnScreen(
      descendant: descendant,
      rect: rect,
      duration: duration,
      curve: curve,
    );
  }
}
