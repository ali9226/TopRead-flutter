// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

/// 游戏的视觉尺度、文字适配与配色集中在此，避免布局中分散调整。
class TileQuestStyle {
  const TileQuestStyle._();

  static const double max_width = 680;

  /// 横屏使用真实的安全区域宽度；竖屏上限会把手机横屏强制挤回窄画布。
  static const double landscape_max_width = 1280;
  static const double landscape_ratio = 1.3;
  static const double landscape_header_height = 44;
  static const double landscape_controls_fraction = .26;
  static const double landscape_controls_min_width = 204;
  static const double landscape_controls_max_width = 280;

  /// 可用空间足够时，七格保留完整触摸尺度；不能把七张牌压入窄工具栏。
  static const double wide_controls_fraction = .40;
  static const double readable_tray_tile_width = 44;
  static const double fold_pane_min_width = 300;
  static const double fold_pane_min_height = 400;
  static const double landscape_controls_gap = 12;
  static const double landscape_board_gap = 8;
  static const double landscape_bottom_spacing = 8;
  static const double landscape_tools_height = 80;

  /// 主阵和辅助岛横向排列，区域之间保留四分之三格的明确间隔。
  static const double landscape_main_columns = 6;
  static const double landscape_island_gap = .75;
  static const double landscape_auxiliary_rows_gap = 1;
  static const double landscape_reference_rows = 6;

  /// 按安全区域内的实际窗口高度启用短高布局，与设备型号无关。
  static const double compact_window_height = 720;
  static const double compact_header_height = 44;
  static const double compact_board_top = 60;
  static const double compact_island_gap = .18;
  static const double compact_bottom_gap = 8;
  static const double compact_reserve_fraction = .37;
  static const double compact_reserve_min_width = 112;
  static const double compact_reserve_max_width = 160;
  static const double compact_reserve_max_edge = 36;
  static const double narrow_tool_width = 80;
  static const double narrow_tool_icon_size = 24;
  static const double narrow_tool_content_inset = 4;
  static const double page_inset = 16;
  static const double board_side_margin = 4;

  /// 七格槽按父容器宽度均分，宽屏/平板达到此宽度后停止长大并整体居中。
  static const double tray_tile_max_width = 60;

  /// 备用牌保持紧凑而独立的尺度，避免放宽七格槽后挤小主牌阵。
  static const double reserve_tile_width_scale = .86;
  static const double reserve_tile_max_width = 52;
  static const double portrait_tools_height = 56;
  static const int tool_icon_cache_width = 128;
  static const double tool_icon_compact_size = 34;
  static const double tool_icon_size = 36;
  static const double tool_tall_threshold = 78;
  static const double tool_content_inset = 6;
  static const double tool_content_gap = 4;
  static const double compact_title_size_cjk = 18;
  static const double compact_title_size_alphabetic = 18;
  static const double portrait_bottom_spacing = 6;
  static const double portrait_controls_gap = 4;
  static const double board_bottom_spacing = 2;
  static const double toolbar_height = 44;
  static const double header_height = 96;
  static const double tutorial_top = 106;
  static const double board_top = 108;
  static const double corner = 22;
  static const double tile_corner_radius_fraction = .107;

  /// 在48逻辑像素的参考牌宽上加宽2px；修改此值可同步调整牌体与网格。
  /// 高度不变，位图图集与所有静态/飞行矩形始终读取同一个宽高比。
  static const int board_tile_width_extra = 2;
  static const int tile_reference_width = 48;
  static const int tile_texture_scale = 4;
  static const int tile_cache_width =
      (tile_reference_width + board_tile_width_extra) * tile_texture_scale;
  static const double tile_press_depth_fraction = .016;
  static const int shuffle_atlas_columns = 8;
  static const int shuffle_atlas_padding = 2;
  static const double title_size_cjk = 25;
  static const double title_size_alphabetic = 27;
  static const double body_size_cjk = 14;
  static const double body_size_alphabetic = 13;
  static const double caption_size_cjk = 12;
  static const double caption_size_alphabetic = 10;
  static const double line_height_cjk = 1.25;
  static const double line_height_alphabetic = 1.4;
  static const double button_min_width_cjk = 92;
  static const double button_min_width_alphabetic = 112;
  static const Duration flight_duration = Duration(milliseconds: 340);
  static const double flight_lift_max = 18;
  static const double flight_lift_distance_fraction = .06;
  static const double match_hold_ms = 28;
  static const double match_fade_ms = 480;
  static const double tray_compact_ms = 140;
  static const double tool_motion_ms = 240;
  static const double entry_duration_ms = 900;
  static const double entry_fall_ms = 560;
  static const double entry_source_height_fraction = .12;
  static const double entry_rotation = .08;
  // 聚拢、搅动与散开共用连续角速度；中段完整绕行三圈以上。
  static const double shuffle_duration_ms = 2100;
  static const double shuffle_gather_fraction = .18;
  static const double shuffle_scatter_fraction = .84;
  static const double shuffle_turns = 3.8;
  static const double shuffle_radius_fraction = .32;
  static const double shuffle_safe_radius_fraction = .92;
  static const double shuffle_rotation = .18;
  static const double shuffle_flip_center = .5;
  static const double shuffle_flip_fraction = .14;
  static const double shuffle_flip_stagger = .06;
  static const double feedback_frame_window_ms = 80;
  static const Duration quick_duration = Duration(milliseconds: 180);
  static const Duration reveal_duration = Duration(milliseconds: 280);
  static const Color cream = Color(0xFFFFF2CF);
  static const Color gold = Color(0xFFFFD879);
  static const Color ink = Color(0xFF14213E);
  static const Color pale = Color(0xFFCFDFF7);
  static const Color mint = Color(0xFF9FE9CC);
  static const List<Color> undo_colors = [Color(0xFF60BBFF), Color(0xFF2775D8)];
  static const List<Color> shuffle_colors = [
    Color(0xFF70DDA0),
    Color(0xFF269373),
  ];
  static const List<Color> remove_colors = [
    Color(0xFFDE91EE),
    Color(0xFF9960C6),
  ];

  static List<Color> sky(bool dark) => dark
      ? [
          const Color(0xFF0B1430),
          const Color(0xFF172C52),
          const Color(0xFF174653),
        ]
      : [
          const Color(0xFF172A59),
          const Color(0xFF355B88),
          const Color(0xFF477C83),
        ];

  static List<Color> background_scrim(bool dark) => dark
      ? const [Color(0x2907142D), Color(0x0D07142D), Color(0x4207142D)]
      : const [Color(0x1A07142D), Color(0x0007142D), Color(0x2907142D)];

  static TextStyle title(bool cjk) => TextStyle(
    color: cream,
    fontSize: cjk ? title_size_cjk : title_size_alphabetic,
    height: cjk ? line_height_cjk : line_height_alphabetic,
    letterSpacing: -0.8,
    fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
  );

  static TextStyle body(
    bool cjk, {
    Color color = cream,
    bool emphasis = false,
  }) => TextStyle(
    color: color,
    fontSize: cjk ? body_size_cjk : body_size_alphabetic,
    height: cjk ? line_height_cjk : line_height_alphabetic,
    fontWeight: FontConfig.adjustedWeight(
      emphasis ? FontWeight.w600 : FontWeight.w400,
    ),
  );

  static TextStyle caption(bool cjk, {Color color = pale}) => TextStyle(
    color: color,
    fontSize: cjk ? caption_size_cjk : caption_size_alphabetic,
    height: cjk ? line_height_cjk : line_height_alphabetic,
    letterSpacing: cjk ? 0.5 : 1.2,
    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
  );

  static BoxDecoration glass({bool dark = true, double radius = corner}) =>
      BoxDecoration(
        color: (dark ? const Color(0xFF142544) : const Color(0xFF264972))
            .withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: const Color(0xFFACCAE5).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      );
}
