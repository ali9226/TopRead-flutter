// ignore_for_file: non_constant_identifier_names
import 'dart:math';
import 'config.dart';

/// Shared by fresh generation and Shuffle, without importing engine or models.
///
/// 公平化契约：所有图案均匀供三连，不使用稀有图、长封印等可识别机关；
/// 难度只由盘面规模、遮挡深度、槽压力与强弱档分叉陷阱承担。
class TileQuestTypeAllocator {
  /// 安装延迟三连所需的最短解序长度（保证三连组互不重叠）。
  static const int trap_min_sequence = 16;

  /// 每条分叉的落位尝试预算：换取互不重叠目标位的命中率。
  static const int trap_install_attempts = 12;

  /// 开局新盘的图案序列：暖场三连在前，其余按公平库存铺满，
  /// 最后按配方埋入强弱档延迟三连。[profile] 难度档（含陷阱配方）；
  /// [opening_count] 开局可见牌数（占暖场前缀）；[random] 种子随机源；
  /// [capacity] 槽位规划上限（暗坑盘给三连临时占用留出空位）。
  static List<int> initial(
    DifficultyProfile profile, {
    required int opening_count,
    required Random random,
    int capacity = TileQuestConfig.tray_capacity,
  }) {
    final supply = List<int>.filled(profile.type_count, 0);
    // Isolated hard openings need at least two full triples per warmup sprite;
    // a twelve-tile cap must not accidentally create extra one-triple keys.
    final warmup_types = min(
      profile.type_count - 1,
      profile.difficulty >= 9 ? min(3, opening_count ~/ 6) : 3,
    );
    final groups = List<int>.generate(
      opening_count ~/ 3,
      (index) => index % warmup_types,
    )..shuffle(random);
    final prefix = <int>[];
    for (final type in groups) {
      prefix.addAll([type, type, type]);
    }
    final triples = (profile.tile_count - opening_count) ~/ 3;
    for (var group = 0; group < triples; group++) {
      supply[group % profile.type_count] += 3;
    }
    final sequence = _allocate(
      supply,
      prefix,
      profile,
      random,
      hard: false,
      capacity: capacity,
    );
    _install_delayed_triples(sequence, profile.trap_forks, random);
    return sequence;
  }

  /// Continue from an empty held area using exactly the supplied triple stock.
  /// There is no tutorial prefix and no conversion to successive plain triples.
  /// Indices may be sparse across all fifteen sprites after a seeded palette shuffle.
  static List<int> remaining(
    List<int> supply, {
    required DifficultyProfile profile,
    required Random random,
  }) {
    if (supply.any((count) => count < 0 || count % 3 != 0)) {
      throw ArgumentError('Remaining allocation requires balanced triples');
    }
    return _allocate(List<int>.from(supply), [], profile, random, hard: true);
  }

  /// 按槽位安全策略把三连库存排成合法解序：凑对优先、压力达标即关对，
  /// 任何一步都不许让槽位越界。[supply] 每图三连库存（就地消耗）；
  /// [prefix] 已定的暖场前缀；[hard] 为 true 时不做暖场/阶段化（洗牌续排）。
  static List<int> _allocate(
    List<int> supply,
    List<int> prefix,
    DifficultyProfile profile,
    Random random, {
    required bool hard,
    int capacity = TileQuestConfig.tray_capacity,
  }) {
    final total =
        prefix.length + supply.fold<int>(0, (sum, count) => sum + count);
    final opening_count = prefix.length;
    final warmup_types = min(3, supply.length);
    final sequence = List<int>.from(prefix);
    final counts = List<int>.filled(supply.length, 0);
    final last_tap = List<int>.filled(supply.length, -total);
    var occupancy = 0;
    while (sequence.length < total) {
      final progress = hard
          ? 1.0
          : (sequence.length - opening_count) / (total - opening_count);
      final safe = <int>[];
      for (var type = 0; type < supply.length; type++) {
        if (supply[type] == 0) continue;
        final next = counts[type] == 2 ? occupancy - 2 : occupancy + 1;
        if (next >= capacity) continue;
        // 填到容量-1 时必须确认还存在可关对，避免六张单牌锁死槽位。
        if (next == capacity - 1) {
          final can_close = List<int>.generate(
            supply.length,
            (index) => index,
          ).any(
            (candidate) =>
                (candidate == type && counts[type] == 2
                        ? 0
                        : counts[candidate] + (candidate == type ? 1 : 0)) ==
                    2 &&
                supply[candidate] - (candidate == type ? 1 : 0) > 0,
          );
          if (!can_close) continue;
        }
        safe.add(type);
      }
      if (safe.isEmpty) {
        throw StateError(
          'Phased schedule exhausted at ${sequence.length}, '
          'occupancy $occupancy, counts $counts, supply $supply',
        );
      }
      // Retain a final ordinary triple of each sprite for the deep phase. The
      // schedule must expand its variety rather than consume early sprites to
      // exhaustion and finish with a simpler, tiny leftover palette.
      // 低难度不为深区预留末组三连（减少「第三张很晚才出现」的压槽感）。
      final unreserved = !hard && profile.difficulty >= 5 && progress < 2 / 3
          ? safe
                .where((type) => counts[type] > 0 || supply[type] > 3)
                .toList()
          : safe;
      final phase_safe = unreserved.isEmpty ? safe : unreserved;
      final demanding = profile.difficulty >= 6;
      // 难度梯度：图案多样性与槽位压力都随进度渐进放开。开局只有暖场图、
      // 低压盘面；难度越高放开越快，但任何难度都不再一步到位——避免
      // 「一开局就高难、满盘还没动就死」的劝退体验。
      final ramp = pow(progress, demanding ? .55 : .8);
      final active_types = hard
          ? supply.length
          : min(
              supply.length,
              warmup_types +
                  max(
                    min(3, supply.length - warmup_types),
                    ((supply.length - warmup_types) * ramp).ceil(),
                  ),
            );
      final pressure =
          2 +
          ((profile.target_tray_pressure - 2) *
                  min(1, progress * (demanding ? 1.35 : 1.7)))
              .floor();
      final staged = phase_safe
          .where((type) => type < active_types || counts[type] > 0)
          .toList();
      final use_full_pool =
          staged.isEmpty ||
          (occupancy < pressure &&
              staged.every((type) => counts[type] == 2) &&
              phase_safe.any((type) => counts[type] < 2));
      final available = use_full_pool ? phase_safe : staged;
      final closing = available.where((type) => counts[type] == 2).toList();
      final opening = available.where((type) => counts[type] < 2).toList();
      final aged = closing
          .where(
            (type) =>
                sequence.length - last_tap[type] >=
                profile.match_delay * progress,
          )
          .toList();
      // 关对倾向同样渐进：前期积极关对把槽清空，后期才收紧到难度给定的
      // 关对概率（close_probability），把压力真正推到后半程。
      final close_chance = .94 + (profile.close_probability - .94) * progress;
      final should_close =
          occupancy >= pressure ||
          random.nextDouble() < close_chance * pow(1 - progress, 3);
      final pool = should_close && closing.isNotEmpty
          ? (aged.isEmpty ? closing : aged)
          : opening.isNotEmpty
          ? opening
          : available;
      // Shuffle stock can be uneven after real held tiles are fixed. Sampling
      // every remaining sprite equally exhausts small inventories too early
      // and can leave a long one-sprite tail despite a mixed legal supply.
      final type = hard
          ? _stock_weighted_type(pool, supply, random)
          : pool[random.nextInt(pool.length)];
      sequence.add(type);
      last_tap[type] = sequence.length;
      supply[type]--;
      counts[type]++;
      occupancy++;
      if (counts[type] == 3) {
        counts[type] = 0;
        occupancy -= 3;
      }
    }
    return sequence;
  }

  /// 陷阱配方：把若干组三连改造成强弱档「延迟三连」——前两张在解序上
  /// 隔 spread 步、第三张再滞后 gap 步。选错提前开对就把单牌压进槽里；
  /// 叠对后槽位在 3-6 步内见底，而撤回只有 1 步，死期落在分叉点之后。
  /// 类型取自普通库存，不制造稀有图；位置多重集不变，解的可行性由校验兜底。
  static void _install_delayed_triples(
    List<int> sequence,
    List<TileQuestTrapFork> forks,
    Random random,
  ) {
    if (forks.isEmpty || sequence.length < trap_min_sequence) return;
    // 陷阱只落在解序的最后 1/4 深区：前 3/4 留给暖场与中盘，分叉的
    // 难度完全压在后半程，开局不出现任何人为张力。
    final origin = sequence.length * 3 ~/ 4;
    final used = <int>{};
    var installed = 0;
    for (
      var attempt = 0;
      attempt < forks.length * trap_install_attempts &&
          installed < forks.length;
      attempt++
    ) {
      final fork = forks[installed];
      // 三连目标位：前两张间隔 spread 步，第三张再滞后 gap 步。
      final tail = fork.spread + fork.gap;
      final span = sequence.length - origin - tail - 1;
      if (span <= 0) break;
      final pivot = origin + random.nextInt(span);
      final targets = <int>[pivot, pivot + fork.spread, pivot + tail];
      if (targets.any(used.contains)) continue;
      final occurrences = <int, List<int>>{};
      for (var position = 0; position < sequence.length; position++) {
        (occurrences[sequence[position]] ??= []).add(position);
      }
      final donor = occurrences.entries.where((entry) {
        return entry.value.length == 3 &&
            entry.value.every((position) => !used.contains(position));
      }).toList();
      if (donor.isEmpty) continue;
      final picked = donor[random.nextInt(donor.length)];
      final displaced = [for (final position in targets) sequence[position]];
      for (var index = 0; index < 3; index++) {
        sequence[targets[index]] = picked.key;
      }
      for (var index = 0; index < 3; index++) {
        sequence[picked.value[index]] = displaced[index];
      }
      used.addAll(targets);
      used.addAll(picked.value);
      installed++;
    }
  }

  /// Preserve the existing safe/pressure decision, then balance only its legal
  /// alternatives according to actual remaining stock instead of type count.
  static int _stock_weighted_type(
    List<int> pool,
    List<int> supply,
    Random random,
  ) {
    var ticket = random.nextInt(
      pool.fold<int>(0, (total, type) => total + supply[type]),
    );
    for (final type in pool) {
      ticket -= supply[type];
      if (ticket < 0) return type;
    }
    return pool.last;
  }
}
