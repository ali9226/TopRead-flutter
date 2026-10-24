// ignore_for_file: constant_identifier_names, non_constant_identifier_names
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// [TileQuestTile] 的几何与材质常量，全部按组件宽高等比缩放。
///
/// 坐标约定：几何量以「牌体」为基准（组件内扣掉投影留白后的正方形），
/// 颜色分五层：投影、厚度、正面、倒角、高光。正面与倒角共享一条连续
/// 的暖奶油→暖棕曲面渐变，模拟陶瓷圆盘从上方看的凸起弧面。
class TileQuestTileStyle {
  const TileQuestTileStyle._();

  // ------------------------------------------------------------------ 几何 --
  /// 牌体边长 / 组件边长：正方形牌体，四周留出投影空间。
  static const double body_scale = 0.868;

  /// 牌体顶边 / 组件高度：略靠上，底部给投影留出更多空间。
  static const double body_top = 0.056;

  /// 正面圆角半径 / 牌体宽度。目标图角很圆，取 18%。
  static const double radius = 0.180;

  /// 立体厚度 / 牌体高度。目标图底缘约占 10%。
  static const double depth = 0.100;

  /// 倒角宽度 / 牌体宽度。目标图倒角很宽，约占 9%，与瓷面连成曲面。
  static const double bevel = 0.090;

  /// 图案（child）占正面宽度的比例：60%～65% 的中值。
  static const double icon_scale = 0.625;

  /// 选中态向上抬起的距离 / 组件边长。
  static const double selected_lift = 0.030;

  /// 选中态阴影额外加强系数。
  static const double selected_shadow_boost = 0.35;

  /// 按压态缩放比。
  static const double pressed_scale = 0.962;

  /// 按压 / 选中过渡时长。
  static const Duration motion_duration = Duration(milliseconds: 130);

  // ------------------------------------------------------------------ 配色 --
  // 第一层：底部投影——柔和深棕，不过黑。
  static const Color shadow_color = ColorConstants.shadow_color_382a1c14;
  static const Color contact_color = ColorConstants.contact_color_3d37271f;
  static const Offset shadow_offset = Offset(0.010, 0.030);
  static const double shadow_sigma = 0.018;
  static const Offset contact_offset = Offset(0.003, 0.010);
  static const double contact_sigma = 0.008;

  // 第二层：立体厚度——灰棕 / 藕棕，不是焦糖黄。
  /// 厚度顶缘受光的浅色台阶。
  static const Color wall_ledge = ColorConstants.wall_ledge_ffc0a898;

  /// 厚度上段：浅灰棕。
  static const Color wall_top = ColorConstants.wall_top_ffa89080;

  /// 厚度中段：藕棕。
  static const Color wall_mid = ColorConstants.wall_mid_ff907868;

  /// 厚度下段：深灰棕。
  static const Color wall_bottom = ColorConstants.wall_bottom_ff786058;

  /// 厚度底缘最暗处。
  static const Color wall_floor = ColorConstants.wall_floor_ff90776d;

  // 第三、四层：正面 + 倒角——同一条连续曲面渐变。
  /// 曲面最亮处（中心偏左上），暖奶油。
  static const Color face_center = ColorConstants.face_center_fffaf2e4;

  /// 曲面中段。
  static const Color face_main = ColorConstants.face_main_fff2e2cc;

  /// 曲面边缘 / 倒角最暗处，暖棕。
  static const Color face_bottom = ColorConstants.face_bottom_ffd8b898;

  // 第五层：漫画高光。
  /// 主高光中心强度。
  static const Color highlight_main = ColorConstants.pages_read_widgets_navigation_bars_bottom_index_tone_ccffffff;

  /// 辅助高光强度。
  static const Color highlight_aux = ColorConstants.components_load_more_footer_index_tone_59ffffff;

  /// 向量牌面与离屏图集共用相同的边缘阴影和高光渐变。
  static const Color transparent_white = ColorConstants.transparent_white;
  static const List<Color> wall_shade_colors = [
    ColorConstants.transparent,
    ColorConstants.pages_short_story_read_index_tone,
  ];
  static const List<Color> highlight_tail_colors = [
    ColorConstants.transparent_white_28ffffff,
    ColorConstants.transparent_white_0cffffff,
    transparent_white,
  ];
  static const List<Color> highlight_core_colors = [
    highlight_main,
    ColorConstants.transparent_white_50ffffff,
    transparent_white,
  ];
  static const List<Color> highlight_aux_colors = [
    highlight_aux,
    transparent_white,
  ];

  /// 主高光中心相对牌体的位置。
  static const Offset highlight_center = Offset(0.26, 0.20);

  /// 主高光椭圆的半长轴 / 牌体宽度、短轴 / 牌体宽度。
  /// 目标图高光很大，约占瓷面 1/3。
  static const double highlight_major = 0.310;
  static const double highlight_minor = 0.145;

  /// 主高光的旋转角（弧度）。
  static const double highlight_rotation = -0.48;

  /// 辅助高光的位置与半径（相对牌体）。
  static const Offset highlight_aux_center = Offset(0.155, 0.370);
  static const double highlight_aux_radius = 0.042;

  // ---------------------------------------------------------------- 遮挡态 --
  static const Color blocked_multiply = ColorConstants.blocked_multiply_ffc8beb2;
  static const Color blocked_veil = ColorConstants.blocked_veil_324a4038;

  // ------------------------------------------------------------------ 几何 --
  /// 牌体（含厚度的完整轮廓）在组件内的矩形。
  static Rect body_rect(Size size) {
    final side = size.shortestSide * body_scale;
    return Rect.fromLTWH(
      (size.width - side) / 2,
      size.height * body_top,
      side,
      side,
    );
  }

  /// 正面矩形：牌体去掉底部厚度。
  static Rect face_rect(Size size) {
    final body = body_rect(size);
    return Rect.fromLTRB(
      body.left,
      body.top,
      body.right,
      body.bottom - body.height * depth,
    );
  }

  /// 图案区域：正面中心、占正面宽度 [icon_scale] 的正方形。
  static Rect icon_rect(Size size) {
    final face = face_rect(size);
    final edge = face.width * icon_scale;
    return Rect.fromCenter(center: face.center, width: edge, height: edge);
  }

  /// 牌体的圆角。
  static Radius body_radius(Size size) =>
      Radius.circular(body_rect(size).width * radius);

  /// 正面的圆角。
  static Radius face_radius(Size size) => body_radius(size);

  /// 倒角内缩后的正面（最内层）矩形。
  static Rect face_inner_rect(Size size) {
    final face = face_rect(size);
    final inset = body_rect(size).width * bevel;
    return face.deflate(inset);
  }

  /// 倒角内缩后的圆角。
  static Radius face_inner_radius(Size size) {
    final inset = body_rect(size).width * bevel;
    final raw = body_radius(size).x - inset;
    return Radius.circular(math.max(raw, body_rect(size).width * 0.05));
  }

  /// 把 [fraction]（0..1 相对牌体）换算到组件坐标。
  static Offset body_point(Offset fraction, Size size) {
    final body = body_rect(size);
    return Offset(
      body.left + fraction.dx * body.width,
      body.top + fraction.dy * body.height,
    );
  }
}
