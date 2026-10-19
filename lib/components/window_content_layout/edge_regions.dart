// ignore_for_file: non_constant_identifier_names

import 'dart:ui' show DisplayFeature, DisplayFeatureType;
import 'package:flutter/widgets.dart';

/// 根据系统报告的局部边缘遮挡释放整列 SafeArea。
/// 不识别机型、屏幕常量或方向；只有与真实安全边距匹配、且未贯穿窗口的
/// 顶角 cutout 才启用。全高铰链、普通横屏安全区、屏外或过期区域均不适用。
class WindowEdgeRegions {
  const WindowEdgeRegions({
    this.left = 0,
    this.right = 0,
    this.features = const [],
  });
  final double left;
  final double right;
  final List<DisplayFeature> features;
  bool get is_active => left > 0 || right > 0;

  static WindowEdgeRegions from_media(MediaQueryData media) {
    final accepted = <DisplayFeature>[];
    var left = 0.0;
    var right = 0.0;
    for (final feature in media.displayFeatures) {
      final bounds = feature.bounds;
      if (feature.type != DisplayFeatureType.cutout ||
          bounds.isEmpty ||
          bounds.top > media.viewPadding.top ||
          bounds.height >= media.size.height - media.viewPadding.bottom ||
          bounds.left < 0 ||
          bounds.right > media.size.width ||
          bounds.bottom > media.size.height) {
        continue;
      }
      final right_matches =
          media.viewPadding.right > 0 &&
          bounds.right == media.size.width &&
          bounds.width >= media.viewPadding.right &&
          bounds.left >= media.size.width - media.viewPadding.right;
      final left_matches =
          media.viewPadding.left > 0 &&
          bounds.left == 0 &&
          bounds.width >= media.viewPadding.left &&
          bounds.right <= media.viewPadding.left;
      if (!right_matches && !left_matches) continue;
      if (right_matches) right = media.padding.right;
      if (left_matches) left = media.padding.left;
      accepted.add(feature);
    }
    return WindowEdgeRegions(left: left, right: right, features: accepted);
  }

  MediaQueryData content_media(MediaQueryData media) => media.copyWith(
    padding: media.padding.copyWith(
      left: left > 0 ? 0 : media.padding.left,
      right: right > 0 ? 0 : media.padding.right,
    ),
    viewPadding: media.viewPadding.copyWith(
      left: left > 0 ? 0 : media.viewPadding.left,
      right: right > 0 ? 0 : media.viewPadding.right,
    ),
  );

  static bool same_features(List<DisplayFeature> a, List<DisplayFeature> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index].bounds != b[index].bounds ||
          a[index].type != b[index].type ||
          a[index].state != b[index].state) {
        return false;
      }
    }
    return true;
  }
}
