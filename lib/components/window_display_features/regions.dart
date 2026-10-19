// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// 原生区域坐标是当前 Flutter view 的逻辑坐标，frame 已包含系统 margins。
/// 将姿态区域与窗口尺寸绑定，防止旋转时把上一张窗口的坐标用于新布局。
class WindowReservedRegions {
  const WindowReservedRegions({
    required this.view_size,
    required this.features,
  });

  final Size view_size;
  final List<ui.DisplayFeature> features;

  static WindowReservedRegions? from_platform(Object? value) {
    if (value is! Map) return null;
    final width = _number(value['view_width']);
    final height = _number(value['view_height']);
    final regions = value['regions'];
    if (width == null ||
        height == null ||
        width <= 0 ||
        height <= 0 ||
        regions is! List) {
      return null;
    }
    final features = <ui.DisplayFeature>[];
    for (final region in regions) {
      if (region is! Map || region['active'] != true) continue;
      final kind = region['kind'];
      if (kind != 'division' && kind != 'occlusion') continue;
      final x = _number(region['x']);
      final y = _number(region['y']);
      final region_width = _number(region['width']);
      final region_height = _number(region['height']);
      if (x == null ||
          y == null ||
          region_width == null ||
          region_height == null ||
          region_width < 0 ||
          region_height < 0 ||
          x > width ||
          y > height ||
          x + region_width < 0 ||
          y + region_height < 0) {
        continue;
      }
      final bounds = Rect.fromLTRB(
        x.clamp(0, width),
        y.clamp(0, height),
        (x + region_width).clamp(0, width),
        (y + region_height).clamp(0, height),
      );
      // Active division 即使是零宽度，也要保留 halfOpened 状态供框架拆屏。
      // 摄像头仅为局部遮挡，不能伪装成贯穿整张窗口的铰链。
      if (kind == 'occlusion' && bounds.isEmpty) continue;
      if (bounds.width == 0 && bounds.height == 0) continue;
      features.add(
        ui.DisplayFeature(
          bounds: bounds,
          type: kind == 'division'
              ? ui.DisplayFeatureType.hinge
              : ui.DisplayFeatureType.cutout,
          state: kind == 'division'
              ? ui.DisplayFeatureState.postureHalfOpened
              : ui.DisplayFeatureState.unknown,
        ),
      );
    }
    return WindowReservedRegions(
      view_size: Size(width, height),
      features: List.unmodifiable(features),
    );
  }

  /// 尺寸过期时只保留 Flutter 自带信息，下一次 metrics/layout 会补齐新区域。
  List<ui.DisplayFeature> merge_with(MediaQueryData media_query) {
    const size_tolerance = .5;
    if ((view_size.width - media_query.size.width).abs() > size_tolerance ||
        (view_size.height - media_query.size.height).abs() > size_tolerance) {
      return media_query.displayFeatures;
    }
    final merged = List<ui.DisplayFeature>.of(media_query.displayFeatures);
    for (final feature in features) {
      if (!merged.any(
        (existing) =>
            existing.bounds == feature.bounds &&
            existing.type == feature.type &&
            existing.state == feature.state,
      )) {
        merged.add(feature);
      }
    }
    return merged;
  }

  static double? _number(Object? value) {
    if (value is! num || !value.isFinite) return null;
    return value.toDouble();
  }

  /// 比较窗口与实际区域，避免相同原生事件触发整棵导航树重建。
  bool has_same_geometry(WindowReservedRegions? other) {
    if (other == null || other.view_size != view_size) return false;
    if (features.length != other.features.length) return false;
    for (var index = 0; index < features.length; index++) {
      final feature = features[index];
      final previous = other.features[index];
      if (feature.bounds != previous.bounds ||
          feature.type != previous.type ||
          feature.state != previous.state) {
        return false;
      }
    }
    return true;
  }
}
