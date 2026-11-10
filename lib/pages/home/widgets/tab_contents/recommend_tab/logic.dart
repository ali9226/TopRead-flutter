import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import 'package:app/pages/home/widgets/tab_contents/recommend_tab/style.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/style.dart';

/// TODO 推荐页双向磁吸：前往瀑布流，或在回滑露出榜单后返回顶部。
class RecommendScrollController extends ScrollController {
  /// TODO [disable_animations] 读取系统减少动态效果设置，保留无障碍偏好。
  RecommendScrollController({required this.disable_animations});

  /// TODO 每次松手读取当前设置，适配页面存活期间的系统偏好变化。
  final bool Function() disable_animations;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _RecommendScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      debugLabel: debugLabel,
      disable_animations: disable_animations,
    );
  }
}

/// TODO 在拖动结束、原生惯性开始之前决定是否吸附，保留其他滚动行为。
class _RecommendScrollPosition extends ScrollPositionWithSingleContext {
  _RecommendScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    super.initialPixels,
    super.keepScrollOffset,
    super.debugLabel,
    required this.disable_animations,
  });

  /// TODO 当前系统是否要求减少动态效果。
  final bool Function() disable_animations;

  /// TODO 仅允许真实回滑产生的惯性在榜单重新露出后继续回顶。
  bool _is_user_return_ballistic = false;

  @override
  void absorb(ScrollPosition other) {
    super.absorb(other);
    if (other is _RecommendScrollPosition) {
      _is_user_return_ballistic = other._is_user_return_ballistic;
    }
  }

  @override
  void beginActivity(ScrollActivity? newActivity) {
    // TODO 新触摸、程序定位或进入空闲时清除旧来源，避免误吸程序滚动。
    if (newActivity is! DragScrollActivity &&
        newActivity is! BallisticScrollActivity) {
      _is_user_return_ballistic = false;
    }
    super.beginActivity(newActivity);
  }

  @override
  void goBallistic(double velocity) {
    final bool is_drag_release = activity is DragScrollActivity;
    final bool is_user_return_end =
        _is_user_return_ballistic &&
        activity is BallisticScrollActivity &&
        velocity == 0;
    if (is_drag_release) {
      _is_user_return_ballistic =
          userScrollDirection == ScrollDirection.forward;
    }
    final double ranking_end =
        RecommendTabStyle.ranking_margin.vertical +
        RankingSectionStyle.section_fixed_height;
    final double snap_threshold =
        RecommendTabStyle.ranking_margin.top +
        RankingSectionStyle.tab_bar_height;
    final double snap_target =
        ranking_end + RecommendTabStyle.recommend_top_spacing;

    // TODO 手动回滑露出榜单即回顶；正向仍沿用越过标题栏后的瀑布流停靠。
    if ((is_drag_release || is_user_return_end) &&
        axisDirection == AxisDirection.down &&
        hasContentDimensions &&
        !outOfRange) {
      final bool should_return_to_top =
          userScrollDirection == ScrollDirection.forward &&
          pixels > minScrollExtent &&
          pixels < ranking_end;
      final bool should_snap_to_feed =
          is_drag_release &&
          userScrollDirection == ScrollDirection.reverse &&
          pixels > snap_threshold &&
          pixels <= ranking_end &&
          maxScrollExtent >= snap_target;
      if (should_return_to_top || should_snap_to_feed) {
        final double target = should_return_to_top
            ? minScrollExtent
            : snap_target;
        if (disable_animations()) {
          jumpTo(target);
        } else {
          animateTo(
            target,
            duration: RecommendTabStyle.snap_duration,
            curve: RecommendTabStyle.snap_curve,
          );
        }
        return;
      }
    }

    super.goBallistic(velocity);
  }
}
