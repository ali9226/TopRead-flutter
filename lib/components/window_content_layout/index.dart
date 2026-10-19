// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;
import 'dart:ui' show DisplayFeature;

import 'edge_regions.dart';
import 'reserved_region_padding.dart';
export 'reserved_region_padding.dart' show WindowReservedRegionPadding;
export 'window_app_bar.dart' show WindowAppBar;

import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';

/// 根据当前窗口重新布局内容，不依赖设备型号、启动方向或物理屏幕尺寸。
///
/// 页面背景保持铺满窗口。普通横向安全区仍整列避让；局部顶角状态区
/// 只由实际相交的导航控件避让，正文和底栏使用完整宽度。上下安全区由页面
/// 自己的顶栏、底栏处理。始终保留组件树，折叠不会重建路由或编辑会话。
class WindowContentLayout extends StatelessWidget {
  const WindowContentLayout({
    super.key,
    required this.child,
    this.max_width,
    this.expand_height = true,
  });

  final Widget child;
  final double? max_width;

  /// 顶栏/底栏只包自身高度；正文画布默认占满可用高度。
  final bool expand_height;

  @override
  Widget build(BuildContext context) {
    // SafeArea会把横向padding清零，先记录它实际消耗的左右窗口空间。
    final source_media = MediaQuery.of(context);
    final edge_regions = WindowEdgeRegions.from_media(source_media);
    final outer_media = edge_regions.content_media(source_media);
    final has_local_edge =
        edge_regions.is_active || WindowLayoutScope.has_local_edge_of(context);
    return MediaQuery(
      data: outer_media,
      child: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final media_query = MediaQuery.of(context);
            final available_width = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : media_query.size.width;
            final content_width = math.min(
              available_width,
              has_local_edge
                  ? double.infinity
                  : max_width ?? WindowLayoutScope.max_width_of(context),
            );
            final content_rect = Rect.fromLTWH(
              outer_media.padding.left + (available_width - content_width) / 2,
              0,
              content_width,
              constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : media_query.size.height,
            );
            return Align(
              alignment: Alignment.topCenter,
              heightFactor: expand_height ? null : 1,
              child: SizedBox(
                width: content_width,
                height: expand_height && constraints.hasBoundedHeight
                    ? constraints.maxHeight
                    : null,
                child: MediaQuery(
                  // 弹窗和旧页面中基于MediaQuery的计算，也必须看到真实内容宽度。
                  // 保留键盘、安全区、无障碍缩放和系统动画偏好。
                  data: media_query.copyWith(
                    size: Size(content_width, media_query.size.height),
                    displayFeatures: _content_display_features(
                      outer_media.displayFeatures,
                      content_rect,
                    ),
                  ),
                  child: WindowReservedRegionPadding(
                    // 仅导航栏等自身高度的前景局部避让。正文、底栏不会损失整列空间。
                    enabled: !expand_height,
                    child: child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 原生保留区域使用整个Flutter窗口坐标。居中、限宽和SafeArea之后，
  /// 同步转换到内容坐标，避免路由内的弹窗把屏外保留区域当成自己的遮挡。
  List<DisplayFeature> _content_display_features(
    List<DisplayFeature> features,
    Rect content_rect,
  ) => [
    for (final feature in features)
      if (_intersects_content(feature.bounds, content_rect))
        DisplayFeature(
          bounds: feature.bounds
              .intersect(content_rect)
              .shift(-content_rect.topLeft),
          type: feature.type,
          state: feature.state,
        ),
  ];

  /// 零宽/零高折线仍然有效，但只在内容边界之外相切的区域无需保留。
  bool _intersects_content(Rect bounds, Rect content_rect) {
    final intersects_x = bounds.width == 0
        ? bounds.left > content_rect.left && bounds.left < content_rect.right
        : bounds.right > content_rect.left && bounds.left < content_rect.right;
    final intersects_y = bounds.height == 0
        ? bounds.top > content_rect.top && bounds.top < content_rect.bottom
        : bounds.bottom > content_rect.top && bounds.top < content_rect.bottom;
    return intersects_x && intersects_y;
  }
}

/// 非游戏路由的窗口策略。局部侧边状态区只影响与它相交的控件，
/// 不再把整张页面压窄；普通设备原有的刘海、安全区和可读宽度继续生效。
class WindowLayoutScope extends StatelessWidget {
  const WindowLayoutScope({
    super.key,
    required this.child,
    this.max_width = LayoutConfig.page_max_width,
  });

  final Widget child;
  final double max_width;

  static double max_width_of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<WindowLayoutData>();
    return scope?.has_local_edge == true
        ? double.infinity
        : scope?.max_width ?? LayoutConfig.page_max_width;
  }

  static bool has_local_edge_of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<WindowLayoutData>()
          ?.has_local_edge ??
      false;

  /// 页面内部还有独立的阅读/编辑限宽时，同样遵守当前窗口的满宽策略。
  static double resolve_max_width(
    BuildContext context,
    double normal_max_width,
  ) => has_local_edge_of(context) ? double.infinity : normal_max_width;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final regions = WindowEdgeRegions.from_media(media);
    // 内层 scope 的 MediaQuery 可能已经由外层释放过边距，继续继承原生
    // 窗口区域，不能重新启用居中限宽或丢失导航栏局部避让。
    final parent = context
        .dependOnInheritedWidgetOfExactType<WindowLayoutData>();
    final has_local_edge = regions.is_active || parent?.has_local_edge == true;
    return WindowLayoutData(
      max_width: max_width,
      has_local_edge: has_local_edge,
      regions: regions.is_active
          ? regions.features
          : parent?.regions ?? const [],
      edge_insets: regions.is_active
          ? EdgeInsets.only(left: regions.left, right: regions.right)
          : parent?.edge_insets ?? EdgeInsets.zero,
      child: MediaQuery(data: regions.content_media(media), child: child),
    );
  }
}

/// 保留原生窗口坐标，局部导航栏依据自己的真实位置处理交集。
class WindowLayoutData extends InheritedWidget {
  const WindowLayoutData({
    super.key,
    required super.child,
    required this.max_width,
    required this.has_local_edge,
    required this.regions,
    required this.edge_insets,
  });

  final double max_width;
  final bool has_local_edge;
  final List<DisplayFeature> regions;
  final EdgeInsets edge_insets;

  @override
  bool updateShouldNotify(WindowLayoutData old_widget) =>
      max_width != old_widget.max_width ||
      has_local_edge != old_widget.has_local_edge ||
      edge_insets != old_widget.edge_insets ||
      !WindowEdgeRegions.same_features(regions, old_widget.regions);
}
