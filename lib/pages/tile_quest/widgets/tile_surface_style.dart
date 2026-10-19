// ignore_for_file: constant_identifier_names, non_constant_identifier_names
import 'package:flutter/material.dart';
import '../style.dart';

/// 参考设计图的实体陶瓷牌：宽倒角瓷面、厚实暖棕侧壁、右下柔性接触影。
///
/// 坐标约定：
/// * 牌体几何使用「逻辑牌」归一化坐标，横向0..1为牌宽，纵向为牌高。
/// * 牌体外扩由 [body_overhang] 控制，目前为零，保留模板的格间隙。
///   没有间隙的旧牌阵仍可使用棋盘侧的四角接缝填色。
/// * 渲染时向四边各外扩牌宽的 [bleed]，得到矩形「绘制格」；
///   上层牌把自己的投影画在外扩区域里，落在下层牌上，形成真实层间阴影。
/// * 牌面直接借用用户lattice.png，图标透明切图与投影只合成一次图集。
class QuestTileSurfaceStyle {
  const QuestTileSurfaceStyle._();

  /// 逻辑牌（不含外扩阴影）在图集中的像素宽度。
  static const int edge = TileQuestStyle.tile_cache_width;

  /// 保留底部厚度后，让可见瓷面接近正方形的整牌高度。
  static const int height = 216;

  /// 棋盘、槽位与移动牌共用同一长宽比，动画只需一次等比缩放。
  static const double tile_aspect_ratio = height / edge;

  /// 每侧投影外扩比例（相对逻辑牌宽度，横纵留白厚度一致）。
  static const int shadow_padding = 20;
  static const double bleed = shadow_padding / edge;

  /// 图集宽度由可调牌宽和两侧投影留白推导，保持纹理与坐标比例一致。
  static const int cell_edge = edge + shadow_padding * 2;

  /// 高度与宽度共用20px投影留白，矩形图集无需非等比RSXform。
  static const int cell_height = height + (cell_edge - edge);

  /// 绘制格宽度相对逻辑牌宽度的倍数，纵向使用相同像素留白。
  static const double cell_scale = cell_edge / edge;

  // ---------------------------------------------------------------- 牌体几何 --
  /// 牌体不侵占模板预留的格间隙，视觉边缘和实际碰撞矩形保持一致。
  static const double body_overhang = 0;

  /// 牌体轮廓（含前方侧壁），相对逻辑牌边长归一化。
  static const Rect body = Rect.fromLTWH(
    -body_overhang,
    -body_overhang,
    1 + body_overhang * 2,
    1 + body_overhang * 2,
  );

  /// 前方侧壁高度，相对牌体高度。
  static const double side_depth = .150;

  /// 顶面区域（牌体轮廓减去前方侧壁），图标与高光都限定在这里。
  static const Rect face = Rect.fromLTWH(
    -body_overhang,
    -body_overhang,
    1 + body_overhang * 2,
    1 + body_overhang * 2 - side_depth * (1 + body_overhang * 2),
  );

  /// 圆角半径，相对逻辑牌边长。
  static const double radius = .180;

  /// 顶面倒角宽度，相对逻辑牌边长。
  static const double bevel = .090;

  /// 按比例放大的按压反馈。
  static const double pressed_scale = .965;

  // ------------------------------------------------------------------ 图标 --
  /// 图案的归一化中心及尺寸；实际宽高均按牌宽计算，保持图案比例。
  /// 透明切图主体占源图82%，最终可见图案约占牌宽66%，居中于瓷面。
  static const Rect icon = Rect.fromLTWH(.100, .025, .800, .800);

  /// 图案在牌面上的柔和投影：紧贴图案的高密度接触影 + 向外扩散的环境影。
  static const Offset icon_contact_offset = Offset(0, .014);
  static const double icon_contact_sigma = .012;
  static const Color icon_contact_color = Color(0x6650392A);
  static const Offset icon_shadow_offset = Offset(.012, .025);
  static const double icon_shadow_sigma = .024;
  static const Color icon_shadow_color = Color(0x4D563D2D);

  /// 原始底板的深棕底边提升到暖灰棕；保持奶油高光接近原值。
  /// 此曲线只用于底板，不影响图案饱和度、透明通道与完整厚度轮廓。
  /// 与图标投影一样只在共享图集里合成一次，不添加交互帧滤镜。
  static const double body_red_scale = .78;
  static const double body_green_scale = .75;
  static const double body_blue_scale = .77;
  static const double body_red_lift = 55;
  static const double body_green_lift = 58;
  static const double body_blue_lift = 50;
  static const List<double> body_filter = [
    body_red_scale,
    0,
    0,
    0,
    body_red_lift,
    0,
    body_green_scale,
    0,
    0,
    body_green_lift,
    0,
    0,
    body_blue_scale,
    0,
    body_blue_lift,
    0,
    0,
    0,
    1,
    0,
  ];

  /// 先提亮底板，再应用统一遮挡曲线；两次颜色变换合并成一次采样。
  static List<double> get blocked_body_filter => [
    body_red_scale * blocked_filter[0],
    0,
    0,
    0,
    body_red_lift * blocked_filter[0] + blocked_filter[4],
    0,
    body_green_scale * blocked_filter[6],
    0,
    0,
    body_green_lift * blocked_filter[6] + blocked_filter[9],
    0,
    0,
    body_blue_scale * blocked_filter[12],
    0,
    body_blue_lift * blocked_filter[12] + blocked_filter[14],
    0,
    0,
    0,
    1,
    0,
  ];

  // ---------------------------------------------------------------- 遮挡态 --
  /// 被上层牌压住时的整体压暗参数；直接用色滤镜处理像素，避免裁剪路径
  /// 在抗锯齿边缘留下亮圈。数值包含轻微暖色偏移，保持奶油质感。
  static const List<double> blocked_filter = <double>[
    .82,
    0,
    0,
    0,
    9,
    0,
    .80,
    0,
    0,
    7,
    0,
    0,
    .77,
    0,
    5,
    0,
    0,
    0,
    1,
    0,
  ];

  /// 被压住的牌沿轮廓叠加一圈径向环境影：中心几乎不变暗，越靠边越暗，
  /// 压掉倒角亮边，避免看起来像“牌外还有一圈原来的底色”。
  static const List<Color> blocked_edge_colors = [
    Color(0x00120D0A),
    Color(0x00120D0A),
    Color(0x42120D0A),
  ];
  static const List<double> blocked_edge_stops = [0, .42, .74];
  static const double blocked_edge_grow = .006;

  // ---------------------------------------------------------------- 向量材质 --
  /// 倒角截面级数；视觉配色统一取 [TileQuestTileStyle]。
  static const int bevel_steps = 14;

  /// 命中检测只看牌体轮廓，模糊投影不能拦截落在下层牌上的点击。
  static Path create_silhouette() => Path()
    ..addRRect(RRect.fromRectAndRadius(body, const Radius.circular(radius)));

  /// 把归一化矩形换算成指定牌格内的绝对矩形。
  static Rect resolve(Rect fraction, Rect tile) => Rect.fromLTWH(
    tile.left + fraction.left * tile.width,
    tile.top + fraction.top * tile.height,
    fraction.width * tile.width,
    fraction.height * tile.height,
  );
}
