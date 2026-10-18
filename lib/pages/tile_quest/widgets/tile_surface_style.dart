// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';

/// 参考主界面实体陶瓷牌：圆弧侧壁、宽软倒角、左上光源和接触投影。
/// 归一化参数独立于棋盘逻辑格，所有材质都预烘焙进共享图集。
class QuestTileSurfaceStyle {
  const QuestTileSurfaceStyle._();
  static const double edge = 192;
  static const double radius_fraction = .147;
  static const Rect body = Rect.fromLTWH(.046, .085, .908, .849);
  static const Rect face = Rect.fromLTWH(.040, .035, .920, .800);
  static const Rect face_inset = Rect.fromLTWH(.095, .070, .810, .700);

  /// PNG自身约有10–20%透明留白，实际图案占牌宽约68–74%，与参考牌一致。
  static const Rect icon = Rect.fromLTWH(.100, .035, .800, .800);
  static const double pressed_scale = .965;

  /// 只对露出的前侧着色；不能把整张牌的渐变压缩成一条棕色底带。
  static const double side_start = .810;
  static const List<Color> body_colors = [
    Color(0xFFE5D0BB),
    Color(0xFFCCB19A),
    Color(0xFFB09582),
    Color(0xFF8D7668),
  ];
  static const List<double> body_stops = [0, .24, .66, 1];
  static const List<Color> side_light_colors = [
    Color(0x44FFF6E4),
    Color(0x00FFF6E4),
    Color(0x242D1D15),
  ];
  static const List<double> side_light_stops = [0, .46, 1];

  /// 倒角外沿自左上亮边过渡至右下暖灰，内面保持干净的象牙白。
  static const List<Color> bevel_colors = [
    Color(0xFFFFFEFB),
    Color(0xFFF8EBDD),
    Color(0xFFE3C9AE),
  ];
  static const List<double> bevel_stops = [0, .55, 1];
  static const int bevel_steps = 12;
  static const List<Color> face_colors = [
    Color(0xFFFFF9EE),
    Color(0xFFFFF3E4),
    Color(0xFFF1DDC7),
  ];
  static const List<double> face_stops = [0, .68, 1];
  static const List<Color> sheen_colors = [
    Color(0x62FFFFFF),
    Color(0x00FFFFFF),
  ];
  static const Alignment sheen_center = Alignment(-.62, -.82);
  static const double sheen_radius = 1.24;

  /// 真正的高斯柔影仅在一次材质烘焙中计算，交互帧没有模糊滤镜。
  static const Offset ambient_offset = Offset(.008, .023);
  static const double ambient_sigma = .026;
  static const Color ambient_color = Color(0x59111925);
  static const Offset contact_offset = Offset(.002, .012);
  static const double contact_sigma = .008;
  static const Color contact_color = Color(0x701C1A1C);

  /// 被压住的牌保留瓷面与图标的颜色，避免统一涂成灰色平板。
  static const List<Color> occlusion_colors = [
    Color(0x14304A59),
    Color(0x2E2B3F49),
  ];
  static const List<Color> side_occlusion_colors = [
    Color(0x45435A60),
    Color(0xC0284951),
  ];

  /// 按1254px原底板的实物内沿取样，去掉自动抠图留下的游离亮点。
  /// 左右侧壁有轻微弧度，不能用独立RRect裁切出不属于原物体的直边。
  /// 烘焙、遮罩与点击检测共用此路径，坐标只在全局材质创建时换算。
  static Path create_outline() {
    const source_edge = 1254.0;
    const unit = edge / source_edge;
    return Path()
      ..moveTo(252 * unit, 50 * unit)
      ..lineTo(1000 * unit, 50 * unit)
      ..cubicTo(
        1115 * unit,
        50 * unit,
        1192 * unit,
        130 * unit,
        1196 * unit,
        270 * unit,
      )
      ..lineTo(1205 * unit, 850 * unit)
      ..cubicTo(
        1207 * unit,
        938 * unit,
        1205 * unit,
        1008 * unit,
        1198 * unit,
        1040 * unit,
      )
      ..cubicTo(
        1185 * unit,
        1133 * unit,
        1122 * unit,
        1161 * unit,
        1000 * unit,
        1161 * unit,
      )
      ..lineTo(250 * unit, 1162 * unit)
      ..cubicTo(
        136 * unit,
        1162 * unit,
        66 * unit,
        1139 * unit,
        49 * unit,
        1046 * unit,
      )
      ..cubicTo(
        41 * unit,
        992 * unit,
        44 * unit,
        898 * unit,
        44 * unit,
        850 * unit,
      )
      ..lineTo(58 * unit, 300 * unit)
      ..cubicTo(
        62 * unit,
        143 * unit,
        133 * unit,
        50 * unit,
        252 * unit,
        50 * unit,
      )
      ..close();
  }
}
