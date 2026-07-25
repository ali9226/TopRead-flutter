// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// `FixedBottomNavigation` 的样式常量集中定义。
///
/// 这个文件只负责统一维护尺寸、动画时长和颜色：
/// 1. 避免在 UI 代码里散落魔法数字；
/// 2. 后续微调视觉时只需要改这里；
/// 3. 让 `index.dart` 只关注结构和状态。
class Style {
  /// 底部导航主体高度。
  static const double bar_height = 60;

  /// 单个导航按钮点击热区的最小高度。
  static const double navigation_item_height = bar_height;

  /// 单个导航按钮点击半径。
  static const double navigation_item_radius = 32;

  /// 图标统一承载槽位宽度。
  static const double icon_slot_width = 48;

  /// 图标统一承载槽位高度。
  ///
  /// 使用固定槽位后，不同素材的实际尺寸即使不一样，
  /// 视觉中心也会基于同一条中线对齐。
  static const double icon_slot_height = 38;

  /// “我的”页面图标在选中态时向上微调的距离。
  static const double user_active_icon_offset_y = -2;

  /// 图标切换动画时长。
  static const Duration icon_anim_duration = Duration(milliseconds: 420);

  /// 图标缩放反馈动画时长。
  static const Duration icon_scale_duration = Duration(milliseconds: 560);

  /// 点击波纹扩散动画时长。
  static const Duration ripple_duration = Duration(milliseconds: 420);

  /// 图标透明度动画时长。
  static const Duration icon_opacity_duration = Duration(milliseconds: 220);

  /// 底部导航阴影模糊值。
  static const double shadow_blur_radius = 14;

  /// 底部导航阴影纵向偏移。
  static const Offset shadow_offset = Offset(0, -2);

  /// 波纹半径计算时，高度方向占比。
  static const double ripple_height_radius_factor = 0.45;

  /// 波纹半径计算时，宽度方向占比。
  static const double ripple_width_radius_factor = 0.38;

  /// 波纹半径宽高混合权重。
  static const double ripple_radius_blend = 0.5;

  /// 夜间模式顶部高光高度。
  static const double night_highlight_height = 108;

  /// 夜间模式顶部高光顶部偏移。
  static const double night_highlight_top = 10;

  /// 夜间模式顶部高光左偏移。
  static const double night_highlight_left = -26;

  /// 夜间模式底部环境光尺寸。
  static const double night_ambient_glow_size = 140;

  /// 夜间模式底部环境光左偏移。
  static const double night_ambient_glow_left = -18;

  /// 夜间模式底部环境光底部偏移。
  static const double night_ambient_glow_bottom = -26;

  /// 夜间模式右上角光束宽度。
  static const double night_sunbeam_width = 220;

  /// 夜间模式右上角光束高度。
  static const double night_sunbeam_height = 92;

  /// 夜间模式右上角光束圆角。
  static const double night_sunbeam_radius = 999;

  /// 夜间模式右上角光束顶部偏移。
  static const double night_sunbeam_top = -12;

  /// 夜间模式右上角光束右偏移。
  static const double night_sunbeam_right = -56;

  /// 夜间模式右上角光束旋转角度。
  static const double night_sunbeam_angle_degrees = -30;

  /// 亮色模式阴影颜色。
  static Color light_shadow_color() {
    return Colors.black.withValues(alpha: 0.08);
  }

  /// 夜间模式阴影颜色。
  static Color dark_shadow_color() {
    return Colors.black.withValues(alpha: 0.22);
  }

  /// 当前主题下的底部导航背景色。
  static Color panel_background_color({required bool is_dark}) {
    return is_dark
        ? ColorConstants.nightHighlightColor
        : ColorConstants.whiteColor;
  }

  /// 夜间模式底部导航背景渐变。
  static LinearGradient night_panel_gradient() {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [const Color(0xFF20283A), ColorConstants.nightHighlightColor],
    );
  }

  /// 点击波纹的主题色。
  static Color ripple_color() {
    return ColorConstants.themeColor.withValues(alpha: 0.22);
  }

  /// 夜间模式选中态图标颜色。
  static Color night_active_icon_color() {
    return const Color(0xFFD0D4DB).withValues(alpha: 0.82);
  }

  /// 夜间模式未选中态图标颜色。
  ///
  /// 当前单独抽成变量，方便后续直接在这里调整夜间模式图标颜色。
  static Color night_inactive_icon_color() {
    return const Color(0xFF888888);
  }

  /// 根据路径和状态返回图标尺寸。
  static double icon_size({required String tab_path, required bool is_active}) {
    if (tab_path == '/' && is_active) {
      return 34;
    }
    if (tab_path == '/bookshelf' && is_active) {
      return 26;
    }
    if (tab_path == '/bookshelf' && !is_active) {
      return 27;
    }
    if (tab_path == '/message' && is_active) {
      return 28;
    }
    if (tab_path == '/message' && !is_active) {
      return 30;
    }
    return 28;
  }

  /// 根据路径和状态返回缩放倍率。
  static double icon_scale({
    required String tab_path,
    required bool is_active,
  }) {
    if (is_active) {
      if (tab_path == '/bookshelf') {
        return 1.14;
      }
      return 1.26;
    }
    if (tab_path == '/bookshelf') {
      return 0.92;
    }
    if (tab_path == '/message') {
      return 0.94;
    }
    return 0.82;
  }

  /// 根据路径和状态返回图标纵向偏移。
  static double icon_offset_y({
    required String tab_path,
    required bool is_active,
  }) {
    if (!is_active) {
      return -5;
    }
    if (tab_path == '/user_info' && is_active) {
      return user_active_icon_offset_y;
    }
    return 0;
  }

  /// 计算左右安全区需要补偿的水平内边距。
  static double horizontal_inset(EdgeInsets view_padding) {
    return math.max(view_padding.left, view_padding.right);
  }
}
