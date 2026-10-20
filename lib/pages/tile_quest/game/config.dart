// ignore_for_file: constant_identifier_names, non_constant_identifier_names

/// A single switch controls every challenge after the introductory level.
class TileQuestConfig {
  static const int level1Difficulty = 1;
  static const int gameDifficulty = 9;
  static const int tray_capacity = 7;

  /// 从第五档难度起，静态容量门槛确保必须实际使用道具。
  static const int mandatory_tool_difficulty = 5;
  static const int remove_uses_per_challenge = 2;
  static const int remove_batch_size = 3;
  static const int reserve_columns = 3;
  static const int reserve_capacity =
      reserve_columns * remove_uses_per_challenge;
  static const int save_version = 2;

  /// Shared by state, validation and UI so another Remove charge needs one edit.
  static int initial_tool_uses(Enum tool) =>
      tool.name == 'remove' ? remove_uses_per_challenge : 1;
  static const int max_generation_attempts = 8;
  static const int generation_budget_ms = 800;
  static const int shuffle_budget_ms = 250;
  static const int max_tiles = 600;

  /// A buried capacity chain occupies lower logical levels without adding
  /// screen-space elevation. Accept both earlier 64-level and new deep saves.
  static const int max_logical_layer = 96;
  static const int max_tile_types = 15;
  static const double board_logical_width = 7;
  static const double board_logical_height = 9;

  /// 多峰牌阵允许边肩自然露出；开局数量仍为完整三同且有严格上界。
  static const int minimum_opening_tiles = 12;
  static const int maximum_opening_tiles = 24;
  static const int max_seed = 0x7fffffff;

  /// 普通点击以固定短窗口合并存档，避免 GetStorage 每次点击编码整个盒子。
  static const Duration progress_save_window = Duration(milliseconds: 240);

  /// One logical tile wide: neighboring tiles share an edge without a sight gap.
  static const double board_grid_pitch = 1.0;
}

/// Centralized generation parameters; target rates require later player calibration.
class DifficultyProfile {
  final int difficulty;
  final int tile_count;
  final int type_count;
  final int layers;
  final int target_tray_pressure;
  final double overlap_offset;
  final double close_probability;

  /// Complete opening triples. The capacity proof is hidden under the main island.
  final int min_initial_choices;
  final int max_initial_choices;

  /// Prefer keeping a pair unresolved until this many intervening taps occurred.
  final int match_delay;

  /// Late phases may preserve a pair while independent chains are resolved.
  final int sealed_pair_span;
  final double target_failure_rate;

  const DifficultyProfile({
    required this.difficulty,
    required this.tile_count,
    required this.type_count,
    required this.layers,
    required this.target_tray_pressure,
    required this.overlap_offset,
    required this.close_probability,
    required this.min_initial_choices,
    required this.max_initial_choices,
    required this.match_delay,
    required this.sealed_pair_span,
    required this.target_failure_rate,
  });

  static DifficultyProfile for_difficulty(
    int difficulty, {
    bool tutorial = false,
  }) {
    if (difficulty < 1 || difficulty > 10) {
      throw ArgumentError.value(difficulty, 'difficulty', 'Must be 1–10');
    }
    const counts = [90, 126, 162, 198, 246, 294, 348, 402, 456, 528];
    const types = [5, 6, 8, 10, 11, 12, 13, 14, 15, 15];
    const layers = [4, 6, 8, 10, 13, 16, 20, 24, 40, 48];
    const pressure = [3, 4, 4, 5, 5, 6, 6, 6, 6, 6];
    const rates = [.15, .30, .45, .60, .70, .80, .90, .95, .99, 1.0];
    final index = difficulty - 1;
    return DifficultyProfile(
      difficulty: difficulty,
      tile_count: tutorial ? 18 : counts[index],
      type_count: tutorial ? 3 : types[index],
      layers: tutorial ? 2 : layers[index],
      target_tray_pressure: tutorial ? 2 : pressure[index],
      overlap_offset: tutorial ? .16 : .5,
      close_probability: tutorial
          ? .90
          : (.86 - difficulty * .085).clamp(.05, 1),
      min_initial_choices: tutorial ? 9 : TileQuestConfig.minimum_opening_tiles,
      max_initial_choices: tutorial ? 9 : TileQuestConfig.maximum_opening_tiles,
      match_delay: tutorial ? 0 : (difficulty - 2).clamp(0, 12),
      sealed_pair_span: tutorial
          ? 0
          : difficulty >= 9
          ? counts[index] ~/ 2
          : difficulty == 8
          ? counts[index] ~/ 4
          : 0,
      target_failure_rate: rates[index],
    );
  }

  /// 容量核心的图案与普通区域互不共用，防止从外区提前凑齐核心三同。
  DifficultyProfile with_inventory({
    required int tile_count,
    required int type_count,
  }) => DifficultyProfile(
    difficulty: difficulty,
    tile_count: tile_count,
    type_count: type_count,
    layers: layers,
    target_tray_pressure: target_tray_pressure,
    overlap_offset: overlap_offset,
    close_probability: close_probability,
    min_initial_choices: min_initial_choices,
    max_initial_choices: max_initial_choices,
    match_delay: match_delay,
    sealed_pair_span: sealed_pair_span,
    target_failure_rate: target_failure_rate,
  );
}
