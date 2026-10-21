// ignore_for_file: avoid_renaming_method_parameters

import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 面板以真实布局覆盖头图；总高度扣除重叠量，后续章节锚点紧接内容末尾。
class ReadIntroductionLayout extends MultiChildRenderObjectWidget {
  ReadIntroductionLayout({
    super.key,
    required Widget hero,
    required Widget panel,
    required this.overlap,
  }) : assert(overlap >= 0),
       super(children: [hero, panel]);

  final double overlap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _ReadIntroductionRenderBox(overlap);

  @override
  void updateRenderObject(BuildContext context, RenderObject render_object) =>
      (render_object as _ReadIntroductionRenderBox).overlap = overlap;
}

class _ReadIntroductionParentData extends ContainerBoxParentData<RenderBox> {}

class _ReadIntroductionRenderBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ReadIntroductionParentData>,
        RenderBoxContainerDefaultsMixin<
          RenderBox,
          _ReadIntroductionParentData
        > {
  _ReadIntroductionRenderBox(this._overlap);
  double _overlap;

  set overlap(double value) {
    if (_overlap == value) return;
    _overlap = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ReadIntroductionParentData) {
      child.parentData = _ReadIntroductionParentData();
    }
  }

  @override
  void performLayout() {
    assert(childCount == 2 && constraints.hasBoundedWidth);
    final hero = firstChild!;
    final panel = lastChild!;
    final child_constraints = BoxConstraints.tightFor(
      width: constraints.maxWidth,
    );
    hero.layout(child_constraints, parentUsesSize: true);
    panel.layout(child_constraints, parentUsesSize: true);
    final panel_top = math.max(0.0, hero.size.height - _overlap);
    (hero.parentData! as _ReadIntroductionParentData).offset = Offset.zero;
    (panel.parentData! as _ReadIntroductionParentData).offset = Offset(
      0,
      panel_top,
    );
    size = constraints.constrain(
      Size(constraints.maxWidth, panel_top + panel.size.height),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
