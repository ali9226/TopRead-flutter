// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'package:app/config/font_config.dart';
import 'package:app/config/color_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/layout_config.dart';

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
  static const double wide_controls_fraction = .34;
  static const double readable_tray_tile_width = 37;
  static const double fold_pane_min_width = 300;
  static const double fold_pane_min_height = 400;
  static const double landscape_controls_gap = LayoutConfig.space_12;

  /// 横屏牌面单元目标上限：宽屏放大牌面，而不是把余量全给操作区。
  static const double landscape_board_unit_cap = 72;
  static const double landscape_board_gap = LayoutConfig.space_8;
  static const double landscape_bottom_spacing = LayoutConfig.space_8;
  static const double landscape_tools_height = 68;

  /// 主阵和辅助岛横向排列，区域之间保留四分之三格的明确间隔。
  static const double landscape_main_columns = 6;
  static const double landscape_island_gap = .75;
  static const double landscape_auxiliary_rows_gap = LayoutConfig.space_1;
  static const double landscape_reference_rows = 6;

  /// 按安全区域内的实际窗口高度启用短高布局，与设备型号无关。
  static const double compact_window_height = 720;
  static const double compact_header_height = 44;
  static const double compact_board_top = 60;
  static const double compact_island_gap = .18;
  static const double compact_bottom_gap = LayoutConfig.space_8;
  static const double compact_reserve_fraction = .37;
  static const double compact_reserve_min_width = 112;
  static const double compact_reserve_max_width = 160;
  static const double compact_reserve_max_edge = 36;
  static const double narrow_tool_width = 80;
  static const double narrow_tool_icon_size = LayoutConfig.icon_regular;
  static const double narrow_tool_content_inset = LayoutConfig.space_4;

  /// 与首页等页面共用同一左右边距变量，统一调整只改 LayoutConfig。
  static const double page_inset = LayoutConfig.page_horizontal_padding;
  static const double board_side_margin = LayoutConfig.space_4;

  /// 七格槽按父容器宽度均分，宽屏/平板达到此宽度后停止长大并整体居中。
  static const double tray_tile_max_width = 60;

  /// 备用牌保持紧凑而独立的尺度，避免放宽七格槽后挤小主牌阵。
  static const double reserve_tile_width_scale = .86;
  static const double reserve_tile_max_width = 52;
  static const double portrait_tools_height = 48;
  static const int tool_icon_cache_width = 128;
  static const double tool_icon_compact_size = 34;
  static const double tool_icon_size = 36;
  static const double tool_tall_threshold = 56;
  static const double tool_content_inset = LayoutConfig.space_6;
  static const double tool_content_gap = LayoutConfig.space_4;

  /// 道具剩余次数角标：主题色圆点 + 外发光 + 白字，无描边。
  static const double tool_badge_min_size = 20;
  static const double tool_badge_font = 13;

  /// 角标向外挂出的偏移：避开按钮内文字。
  static const double tool_badge_top = -6;
  static const double tool_badge_right = -4;

  /// 加号图标在数字角标基础上再右移，避免盖住文字。
  static const double tool_badge_add_right = -11;
  static const double tool_badge_add_size = 30;

  /// 数字 ↔ 加号 切换动画。
  static const int tool_badge_switch_ms = 240;

  /// 按压回弹：顶栏图标与道具按钮共用。
  static const double press_scale = 0.88;
  static const int press_down_ms = 90;
  static const int press_up_ms = 280;
  static const double compact_title_size_cjk = 18;
  static const double compact_title_size_alphabetic = 18;
  static const double portrait_bottom_spacing = LayoutConfig.space_6;
  static const double portrait_controls_gap = LayoutConfig.space_4;
  static const double board_bottom_spacing = LayoutConfig.space_2;
  static const double toolbar_height = 44;
  static const double header_height = 52;

  /// 结果、重开确认与会话暂停共用的卡片边距及圆角。
  static const double panel_inset = LayoutConfig.space_24;
  static const double panel_radius = LayoutConfig.radius_26;
  static const double panel_max_width = 350;
  static const double session_panel_max_width = 330;
  static const double result_panel_radius = LayoutConfig.radius_30;
  static const double result_window_inset = LayoutConfig.space_16;
  static const double restart_title_size_cjk = 22;
  static const double restart_title_size_alphabetic = 22;
  static const Color modal_barrier = ColorConstants.modal_barrier_ff07152d;
  static const Color session_scrim = ColorConstants.session_scrim_e807152d;
  static const Color result_scrim = ColorConstants.test_pages_tile_quest_modal_full_window_test_tone_ff061126;
  static const double result_scrim_opacity = .72;
  static const Duration result_duration = Duration(milliseconds: 1000);
  static const List<Color> result_panel_colors = [
    ColorConstants.result_scrim_ff29476d,
    ColorConstants.result_scrim_ff142846,
  ];
  static const Color result_statistics_background = ColorConstants.result_statistics_background_ff0c1d36;
  static const Color result_star_shadow = ColorConstants.result_star_shadow_a9eca936;
  static const Color result_crest_glow = ColorConstants.result_crest_glow_ffadbbe8;
  static const Color result_crest_glow_edge = ColorConstants.result_crest_glow_edge_ff657bb6;
  static const Color result_moon = ColorConstants.result_moon_ffd8dff7;
  static const Color celebration_lilac = ColorConstants.celebration_lilac_ffc1b4ff;

  /// 主要与次要操作共享相同命中尺寸，文字沿用 CJK/非 CJK 正文样式。
  static const double primary_button_height = LayoutConfig.button_height;
  static const double primary_button_radius = LayoutConfig.radius_16;
  static const double primary_button_icon_size = 19;
  static const double primary_button_icon_gap = LayoutConfig.space_6;
  static const double primary_button_border_opacity = .25;
  static const List<Color> primary_button_colors = [
    ColorConstants.celebration_lilac_ffffe6a0,
    ColorConstants.celebration_lilac_fff4bc54,
  ];
  static const List<Color> secondary_button_colors = [
    ColorConstants.celebration_lilac_ff344f78,
    ColorConstants.celebration_lilac_ff263e64,
  ];

  /// 主槽与备用槽都读取相同的圆角与描边材质。
  static const double tray_well_radius = LayoutConfig.radius_19;
  static const double tray_well_border_width = 1.5;
  static const double slot_well_radius = LayoutConfig.radius_9;
  static const Color tray_well_border = ColorConstants.tray_well_border_ff9dbcdc;
  static const Color slot_well_background = ColorConstants.slot_well_background_ff0b1931;
  static const Color slot_well_border = ColorConstants.slot_well_border_ff7796ba;
  static const Color reserve_well_background = ColorConstants.pages_tile_quest_style_tone_ff142544;

  /// 保存错误使用全站危险色，混入场景底色后仍保持文字对比度。
  static Color save_error_background(bool dark) => Color.alphaBlend(
    ColorConstants.dangerColor.withValues(alpha: .26),
    dark ? ink : ColorConstants.pages_tile_quest_style_tone_ff264972,
  );

  /// 顶栏图片图标显示尺寸。
  static const double header_icon_size = 42;

  /// 设置展开/收起：声音与重置滑出滑入，logo 同步淡出。
  static const int header_expand_ms = 260;
  static const double header_action_gap = LayoutConfig.space_7;

  /// 分享与声音之间更宽的间隔。
  static const double header_share_gap = LayoutConfig.space_14;
  static const double tutorial_top = 52;
  static const double board_top = 64;
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

  /// 飞牌目标速度（像素/毫秒）。短跳由时长下限托底显得干脆，
  /// 长跳由时长上限收敛到旧 340ms 观感，避免顶部飞牌过快发飘。
  static const double flight_speed = 1.5;

  /// 时长下限：近距离也保留完整起落节奏，不致闪现。
  static const double flight_duration_min_ms = 110;

  /// 时长上限：长距离依旧轻快，与旧固定 340ms 的最远航段观感一致。
  static const double flight_duration_max_ms = 340;

  /// 最长航段时长；等待“飞完”时可作保守上界。
  static const Duration flight_duration = Duration(milliseconds: 340);

  /// 由航距换算飞牌时长（毫秒），保证不同起点的观感速度一致。
  static double flight_duration_ms(double distance) => (distance / flight_speed)
      .clamp(flight_duration_min_ms, flight_duration_max_ms)
      .toDouble();

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
  static const Color cream = ColorConstants.game_cream;
  static const Color gold = ColorConstants.gold_ffffd879;
  static const Color ink = ColorConstants.ink_ff14213e;
  static const Color pale = ColorConstants.pale_ffcfdff7;
  static const Color mint = ColorConstants.mint_ff9fe9cc;
  static const List<Color> undo_colors = [ColorConstants.mint_ff60bbff, ColorConstants.mint_ff2775d8];
  static const List<Color> shuffle_colors = [
    ColorConstants.mint_ff70dda0,
    ColorConstants.mint_ff269373,
  ];
  static const List<Color> remove_colors = [
    ColorConstants.mint_ffde91ee,
    ColorConstants.mint_ff9960c6,
  ];

  static List<Color> sky(bool dark) => dark
      ? [
          ColorConstants.pages_tile_quest_style_tone_ff0b1430,
          ColorConstants.pages_tile_quest_style_tone_ff172c52,
          ColorConstants.pages_tile_quest_style_tone_ff174653,
        ]
      : [
          ColorConstants.pages_tile_quest_style_tone_ff172a59,
          ColorConstants.pages_tile_quest_style_tone_ff355b88,
          ColorConstants.pages_tile_quest_style_tone_ff477c83,
        ];

  static List<Color> background_scrim(bool dark) => dark
      ? const [ColorConstants.mint_2907142d, ColorConstants.mint_0d07142d, ColorConstants.mint_4207142d]
      : const [ColorConstants.mint_1a07142d, ColorConstants.mint_0007142d, ColorConstants.mint_2907142d];

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
      emphasis ? FontConfig.adjustedWeight(FontWeight.w600) : FontConfig.adjustedWeight(FontWeight.w400),
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
        color: (dark ? ColorConstants.pages_tile_quest_style_tone_ff142544 : ColorConstants.pages_tile_quest_style_tone_ff264972)
            .withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: ColorConstants.pages_tile_quest_style_tone_ffaccae5.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.shadowColor.withValues(alpha: 0.1608),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      );
}
