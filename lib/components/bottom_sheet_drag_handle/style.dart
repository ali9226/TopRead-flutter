import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 底部弹窗拖拽把手统一视觉常量。
class BottomSheetDragHandleStyle {
  /// 把手的完整触达高度；真实拖拽手势由 ModalBottomSheet 路由承接。
  static const double touch_height = 20;

  /// 中间显色横条尺寸。
  static const double bar_width = 36;
  static const double bar_height = 4;
  static const double bar_radius = LayoutConfig.radius_2;

  /// 日间与夜间模式颜色，保持 iOS 底部面板把手的中性层级。
  static const Color light_color = ColorConstants.light_color_ffb8b8bd;
  static const Color dark_color = ColorConstants.dark_color_ff65656a;
}
