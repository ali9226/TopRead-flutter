// ignore_for_file: non_constant_identifier_names
import 'dart:math';
import 'config.dart';

/// Shared by fresh generation and Shuffle, without importing engine or models.
class TileQuestTypeAllocator {
  static List<int> initial(
    DifficultyProfile profile, {
    required int opening_count,
    required Random random,
    List<List<int>> delayed_match_groups = const [],
  }) {
    final supply = List<int>.filled(profile.type_count, 0);
    final warmup_types = min(3, profile.type_count - 1);
    final groups = List<int>.generate(
      opening_count ~/ 3,
      (index) => index % warmup_types,
    )..shuffle(random);
    final prefix = <int>[];
    for (final type in groups) {
      prefix.addAll([type, type, type]);
    }
    // The hardest profiles isolate their opening stock so a saved cap tile
    // cannot rescue every deep chain. Earlier profiles retain those sprites
    // while adding new ones, so even five-type difficulty one becomes richer.
    final delayed_positions = <int, int>{};
    for (var group = 0; group < delayed_match_groups.length; group++) {
      final positions = delayed_match_groups[group];
      if (positions.length != 3 ||
          positions.first < opening_count ||
          positions.last >= profile.tile_count ||
          positions[0] >= positions[1] ||
          positions[1] >= positions[2]) {
        throw ArgumentError(
          'A delayed triple requires three ordered deep taps',
        );
      }
      for (final position in positions) {
        if (delayed_positions.containsKey(position)) {
          throw ArgumentError('Delayed triples cannot occupy the same tile');
        }
        delayed_positions[position] = warmup_types + group;
      }
    }
    final deep_start = profile.difficulty >= 9
        ? warmup_types + delayed_match_groups.length
        : 0;
    final deep_types = profile.type_count - deep_start;
    if (deep_types <= 0) {
      throw ArgumentError('A deep ordinary type is required');
    }
    for (var group = 0; group < delayed_match_groups.length; group++) {
      supply[warmup_types + group] = 3;
    }
    for (
      var group = 0;
      group <
          (profile.tile_count - opening_count) ~/ 3 -
              delayed_match_groups.length;
      group++
    ) {
      supply[deep_start + group % deep_types] += 3;
    }
    return _allocate(
      supply,
      prefix,
      profile,
      random,
      hard: false,
      delayed_positions: delayed_positions,
      delayed_openings: delayed_match_groups
          .expand((positions) => positions.take(2))
          .toSet(),
    );
  }

  /// Continue from an empty held area using exactly the supplied triple stock.
  /// There is no tutorial prefix and no conversion to successive plain triples.
  /// Indices may be sparse across all 32 sprites after a seeded palette shuffle.
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

  static List<int> _allocate(
    List<int> supply,
    List<int> prefix,
    DifficultyProfile profile,
    Random random, {
    required bool hard,
    Map<int, int> delayed_positions = const {},
    Set<int> delayed_openings = const {},
  }) {
    final total =
        prefix.length + supply.fold<int>(0, (sum, count) => sum + count);
    final opening_count = prefix.length;
    final warmup_types = min(3, supply.length);
    final sequence = List<int>.from(prefix);
    final counts = List<int>.filled(supply.length, 0);
    final last_tap = List<int>.filled(supply.length, -total);
    final delayed_types = delayed_positions.values.toSet();
    var occupancy = 0;
    var sealed_type = -1;
    var seal_until = -1;
    while (sequence.length < total) {
      final progress = hard
          ? 1.0
          : (sequence.length - opening_count) / (total - opening_count);
      if (sealed_type < 0 &&
          delayed_types.isEmpty &&
          profile.sealed_pair_span > 0 &&
          progress > (profile.difficulty >= 9 ? .3 : .5) &&
          occupancy < 6) {
        final pairs = List<int>.generate(
          supply.length,
          (index) => index,
        ).where((type) => counts[type] == 2 && supply[type] > 0).toList();
        if (pairs.isNotEmpty) {
          final candidate = pairs[random.nextInt(pairs.length)];
          final other_supply =
              supply.fold<int>(0, (sum, count) => sum + count) -
              supply[candidate];
          if (other_supply > 0) {
            sealed_type = candidate;
            seal_until = min(
              total - 6,
              sequence.length + min(profile.sealed_pair_span, other_supply),
            );
          }
        }
      }
      final seal_active = sequence.length < seal_until;
      final forced_type = delayed_positions[sequence.length];
      final forced_next = delayed_openings.contains(sequence.length + 1);
      final safe = <int>[];
      for (var type = 0; type < supply.length; type++) {
        if (supply[type] == 0 || (seal_active && type == sealed_type)) continue;
        if (forced_type != null
            ? type != forced_type
            : delayed_types.contains(type)) {
          continue;
        }
        final next = counts[type] == 2 ? occupancy - 2 : occupancy + 1;
        if (next >= TileQuestConfig.tray_capacity) continue;
        // A key is held through a real geometric dependency chain. Reserve
        // slack before its first two mandatory taps, then require an ordinary
        // closing pair at pressure six rather than pretending the key is free.
        final projected = next + (forced_next ? 1 : 0);
        if (projected >= TileQuestConfig.tray_capacity) continue;
        if (projected == TileQuestConfig.tray_capacity - 1) {
          final can_close = List<int>.generate(supply.length, (index) => index)
              .any(
                (candidate) =>
                    !delayed_types.contains(candidate) &&
                    !(seal_active && candidate == sealed_type) &&
                    (candidate == type && counts[type] == 2
                            ? 0
                            : counts[candidate] +
                                  (candidate == type ? 1 : 0)) ==
                        2 &&
                    supply[candidate] - (candidate == type ? 1 : 0) > 0,
              );
          if (!can_close) continue;
        }
        safe.add(type);
      }
      if (safe.isEmpty) throw StateError('Phased schedule exhausted');
      // Retain a final ordinary triple of each sprite for the deep phase. The
      // schedule must expand its variety rather than consume early sprites to
      // exhaustion and finish with a simpler, tiny leftover palette.
      final unreserved = !hard && progress < 2 / 3
          ? safe
                .where(
                  (type) =>
                      delayed_types.contains(type) ||
                      counts[type] > 0 ||
                      supply[type] > 3,
                )
                .toList()
          : safe;
      final phase_safe = unreserved.isEmpty ? safe : unreserved;
      final active_types = hard
          ? supply.length
          : min(
              supply.length,
              warmup_types +
                  max(
                    min(3, supply.length - warmup_types),
                    ((supply.length - warmup_types) * pow(progress, .8)).ceil(),
                  ),
            );
      final pressure =
          2 +
          ((profile.target_tray_pressure - 2) * min(1, progress * 1.7)).floor();
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
      final close_chance = .94 + (profile.close_probability - .94) * progress;
      final should_close =
          occupancy >= pressure ||
          random.nextDouble() < close_chance * pow(1 - progress, 3);
      final pool = should_close && closing.isNotEmpty
          ? (aged.isEmpty ? closing : aged)
          : opening.isNotEmpty
          ? opening
          : available;
      final type = pool[random.nextInt(pool.length)];
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
}
