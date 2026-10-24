// ignore_for_file: constant_identifier_names, non_constant_identifier_names

/// 强弱档分叉：一次「选错延迟致死」陷阱。
class TileQuestTrapFork {
  const TileQuestTrapFork({
    required this.gap,
    required this.spread,
    required this.hit_rate,
  });

  /// 第三张滞后步数（3-6，防撤回逃逸）。
  final int gap;

  /// 前两张在解序上的间隔（1=相邻，越大越难被同时点到）。
  final int spread;

  /// 参考玩家踩中该分叉的概率（乘法模型）。
  final double hit_rate;
}

/// A single switch controls every challenge after the introductory level.
class TileQuestConfig {
  static const int level1Difficulty = 1;
  static const int gameDifficulty = 6;
  static const int tray_capacity = 7;

  /// 从第五档难度起，静态容量门槛确保必须实际使用道具。
  static const int mandatory_tool_difficulty = 5;
  static const int remove_uses_per_challenge = 2;

  /// 暗坑必败阈值：难度达到该值后启用容量核（道具 1/1/2 全用完仍无法通关）。
  static const int trap_difficulty = 10;

  /// 分叉陷阱乘法模型的技能锚点：参考玩家踩中一个满档分叉的概率。
  /// 真实玩家曲线由对局遥测回收后校正。
  static const double trap_hit_rate = 0.3;

  /// 残差叉的判定阈值：小于该值视为无残差（目标已被满档叉精确覆盖）。
  static const double trap_residual_epsilon = 0.001;

  /// 一条延迟三连在途中最多压进槽里的单牌数（前两张各占 1 槽）。
  static const int trap_pair_hold = 2;

  /// 强弱档分叉：强度由「第三张滞后步数 gap × 前两张解序间隔 spread」
  /// 决定——gap 越大压槽越久、spread 越小越容易被同时点到，命中率越高。
  static const List<TileQuestTrapFork> trap_palette = [
    TileQuestTrapFork(gap: 3, spread: 1, hit_rate: 0.225),
    TileQuestTrapFork(gap: 3, spread: 2, hit_rate: 0.15),
    TileQuestTrapFork(gap: 3, spread: 3, hit_rate: 0.1),
    TileQuestTrapFork(gap: 4, spread: 1, hit_rate: 0.3),
    TileQuestTrapFork(gap: 4, spread: 2, hit_rate: 0.2),
    TileQuestTrapFork(gap: 4, spread: 3, hit_rate: 0.15),
    TileQuestTrapFork(gap: 5, spread: 1, hit_rate: 0.375),
    TileQuestTrapFork(gap: 5, spread: 2, hit_rate: 0.25),
    TileQuestTrapFork(gap: 6, spread: 1, hit_rate: 0.45),
    TileQuestTrapFork(gap: 6, spread: 2, hit_rate: 0.3),
    TileQuestTrapFork(gap: 5, spread: 3, hit_rate: 0.1875),
    TileQuestTrapFork(gap: 6, spread: 3, hit_rate: 0.225),
  ];

  /// 目标通关率 win_rate 的分叉配方：floor(S) 个满档叉 + 1 个残差叉，
  /// 乘积精确落在目标附近（S=ln(win)/ln(1-trap_hit_rate)）。残差叉按
  /// 强度档量化，消掉「分叉数只能取整」的偏差。win<=0 交给暗坑容量核。
  static List<TileQuestTrapFork> trap_recipe(double win_rate) {
    if (win_rate <= 0 || win_rate >= 1) return const [];
    final unit = 1 - trap_hit_rate;
    var full = 0;
    while (_pow(unit, full + 1) >= win_rate) {
      full++;
    }
    final forks = <TileQuestTrapFork>[
      for (var index = 0; index < full; index++) trap_palette[3],
    ];
    final residual = 1 - win_rate / _pow(unit, full);
    if (residual > trap_residual_epsilon) {
      var best = trap_palette.first;
      for (final candidate in trap_palette) {
        if ((candidate.hit_rate - residual).abs() <
            (best.hit_rate - residual).abs()) {
          best = candidate;
        }
      }
      forks.add(best);
    }
    return forks;
  }

  static double _pow(double base, int exponent) {
    var value = 1.0;
    for (var index = 0; index < exponent; index++) {
      value *= base;
    }
    return value;
  }
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

  /// 陷阱配方：强弱档分叉列表（每叉一张延迟三连：前两张间隔 spread、
  /// 第三张滞后 gap 步）。选错提前开对会把单牌压进槽里，叠对致死。
  final List<TileQuestTrapFork> trap_forks;

  /// Late phases may preserve a pair while independent chains are resolved.
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
    required this.trap_forks,
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
    const pressure = [2, 2, 3, 3, 5, 6, 6, 6, 6, 6];
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
      // 分叉陷阱乘法模型：目标通关率 win=(10-难度)/10，参考玩家踩中
      // 单个分叉的概率 q=trap_hit_rate，则 win=(1-q)^F → F=ln(win)/ln(1-q)。
      // q 是技能锚点，真实玩家曲线由对局遥测回收后校正。
      trap_forks: tutorial
          ? const []
          : TileQuestConfig.trap_recipe((10 - difficulty) / 10),
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
    trap_forks: trap_forks,
    target_failure_rate: target_failure_rate,
  );
}
