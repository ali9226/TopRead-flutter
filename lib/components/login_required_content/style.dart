import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';

/// 未登录提示公共组件样式常量。
class LoginRequiredContentStyle {
  /// 插图尺寸。
  static const double icon_size = 180;

  /// 组件顶部间距。
  static const double top_spacing = LayoutConfig.space_36;

  /// 插图底部间距。
  static const double icon_bottom_spacing = LayoutConfig.space_20;

  /// 标题底部间距。
  static const double title_bottom_spacing = LayoutConfig.space_10;

  /// 描述文案底部间距。
  static const double desc_bottom_spacing = LayoutConfig.space_24;

  /// 客服模块顶部间距。
  static const double customer_service_top_spacing = LayoutConfig.space_28;

  /// 标题字号。
  static const double title_font_size = 20;

  /// 描述字号。
  static const double desc_font_size = 13;

  /// 组件左右内边距。
  static const EdgeInsets content_padding = EdgeInsets.symmetric(
    horizontal: LayoutConfig.space_12,
  );
}
