// ignore_for_file: non_constant_identifier_names
import 'dart:math' as math;
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;
import 'package:flutter/material.dart';
import '../style.dart';

/// 游戏保持一个稳定的场景坐标系：可用的双屏分别放牌阵及操作区，
/// 狭窄或上下分屏则选择较大的完整区域，背景始终由页面铺满全窗。
class QuestPlayfield extends StatelessWidget {
  const QuestPlayfield({super.key, required this.child});
  final Widget child;

  /// 弹窗仍放在单个完整子屏，避免按钮横跨折痕。
  static Offset anchor_for(MediaQueryData media) => pane_for(media).center;

  /// 暂停、结果和错误提示共用实际子屏，不把交互面板放在折痕中央。
  static Rect pane_for(MediaQueryData media) {
    final panes = DisplayFeatureSubScreen.subScreensInBounds(
      Offset.zero & media.size,
      DisplayFeatureSubScreen.avoidBounds(media),
    );
    var largest = Offset.zero & media.size;
    var largest_area = -1.0;
    for (final pane in panes) {
      final area = pane.width * pane.height;
      if (area > largest_area) {
        largest = pane;
        largest_area = area;
      }
    }
    return largest;
  }

  /// 只约束弹层里的交互面板，不能用该矩形裁切全屏遮罩。
  /// 先选择完整子屏再与窗口安全区域取交集，避免把右侧系统边距
  /// 错加到左子屏的内侧，同时保留底部手势区和普通手机刘海避让。
  static Rect safe_pane_for(MediaQueryData media) => pane_for(media).intersect(
    Rect.fromLTRB(
      media.padding.left,
      media.padding.top,
      math.max(media.padding.left, media.size.width - media.padding.right),
      math.max(media.padding.top, media.size.height - media.padding.bottom),
    ),
  );

  /// 返回能够分别容纳主牌阵和七槽操作区的真实左右区域。
  static List<Rect>? split_columns(Size size, List<DisplayFeature> features) {
    for (final feature in features) {
      final hinge = feature.bounds;
      if ((feature.type != DisplayFeatureType.hinge &&
              feature.type != DisplayFeatureType.fold) ||
          (feature.type == DisplayFeatureType.fold &&
              feature.state != DisplayFeatureState.postureHalfOpened) ||
          hinge.top > 0 ||
          hinge.bottom < size.height ||
          (hinge.width <= 0 &&
              feature.state != DisplayFeatureState.postureHalfOpened)) {
        continue;
      }
      final left = Rect.fromLTWH(0, 0, hinge.left, size.height);
      final right = Rect.fromLTRB(hinge.right, 0, size.width, size.height);
      if (left.width >= TileQuestStyle.fold_pane_min_width &&
          right.width >= TileQuestStyle.fold_pane_min_width &&
          size.height >= TileQuestStyle.fold_pane_min_height) {
        return [left, right];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final media = MediaQuery.of(context);
      final window = Offset.zero & constraints.biggest;
      final safe = Rect.fromLTRB(
        media.padding.left,
        media.padding.top,
        math.max(media.padding.left, window.width - media.padding.right),
        math.max(media.padding.top, window.height - media.padding.bottom),
      );
      final local_features = _features_in(media.displayFeatures, safe);
      var content = safe;
      if (split_columns(safe.size, local_features) == null) {
        final panes = DisplayFeatureSubScreen.subScreensInBounds(
          window,
          DisplayFeatureSubScreen.avoidBounds(media),
        );
        var largest_area = -1.0;
        for (final pane in panes) {
          final available = pane.intersect(safe);
          final area = available.width * available.height;
          if (area > largest_area) {
            content = available;
            largest_area = area;
          }
        }
      }
      final max_width =
          content.width > content.height * TileQuestStyle.landscape_ratio
          ? TileQuestStyle.landscape_max_width
          : TileQuestStyle.max_width;
      if (content.width > max_width) {
        content = Rect.fromCenter(
          center: content.center,
          width: max_width,
          height: content.height,
        );
      }
      // 组件结构不随姿态切换，进行中的连点、洗牌和飞牌不会重新初始化。
      return Padding(
        padding: EdgeInsets.fromLTRB(
          content.left,
          content.top,
          window.width - content.right,
          window.height - content.bottom,
        ),
        child: MediaQuery(
          data: media.copyWith(
            size: content.size,
            padding: EdgeInsets.zero,
            viewPadding: EdgeInsets.zero,
            displayFeatures: _features_in(media.displayFeatures, content),
          ),
          child: child,
        ),
      );
    },
  );

  /// display feature 始终转为场景局部坐标，不能沿用整屏坐标计算折痕。
  static List<DisplayFeature> _features_in(
    List<DisplayFeature> features,
    Rect content,
  ) => [
    for (final feature in features)
      if (feature.bounds.right >= content.left &&
          feature.bounds.left <= content.right &&
          feature.bounds.bottom >= content.top &&
          feature.bounds.top <= content.bottom)
        DisplayFeature(
          bounds: feature.bounds.intersect(content).shift(-content.topLeft),
          type: feature.type,
          state: feature.state,
        ),
  ];
}

/// 弹层面板保持同一组件树，仅随安全区域平移。
/// 遮罩必须在该组件外绘制，才会覆盖底部和右侧的完整窗口。
class QuestPlayfieldOverlay extends StatelessWidget {
  const QuestPlayfieldOverlay({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final media = MediaQuery.of(context).copyWith(size: constraints.biggest);
      final pane = QuestPlayfield.safe_pane_for(media);
      return Padding(
        padding: EdgeInsets.fromLTRB(
          pane.left,
          pane.top,
          constraints.maxWidth - pane.right,
          constraints.maxHeight - pane.bottom,
        ),
        child: child,
      );
    },
  );
}
