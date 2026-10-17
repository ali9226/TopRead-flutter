// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

/// 游戏的视觉尺度、文字适配与配色集中在此，避免布局中分散调整。
class TileQuestStyle {
  const TileQuestStyle._();

  static const double max_width = 680;
  static const double page_inset = 16;
  static const double header_height = 104;
  static const double tutorial_top = 114;
  static const double board_top = 148;
  static const double corner = 22;
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
  static const Duration flight_duration = Duration(milliseconds: 220);
  static const double queued_flight_min_ms = 95;
  static const double preflight_duration_ms = 180;
  static const double preflight_progress = .62;
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
