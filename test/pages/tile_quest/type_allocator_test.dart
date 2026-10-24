// ignore_for_file: non_constant_identifier_names
import 'dart:math';
import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/type_allocator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'deep Shuffle allocation preserves sparse fifteen-type stock and every safe prefix',
    () {
      var pressure_six_runs = 0;
      for (var seed = 0; seed < 80; seed++) {
        final random = Random(seed);
        final supply = List<int>.filled(TileQuestConfig.max_tile_types, 0);
        final types = List<int>.generate(supply.length, (index) => index)
          ..shuffle(random);
        for (final type in types.take(6 + random.nextInt(12))) {
          supply[type] = (1 + random.nextInt(7)) * 3;
        }
        final original = List<int>.from(supply);
        final profile = DifficultyProfile.for_difficulty(seed.isEven ? 8 : 9);
        final path = TileQuestTypeAllocator.remaining(
          supply,
          profile: profile,
          random: Random(seed),
        );
        expect(
          supply,
          original,
          reason: 'caller inventory must not be mutated',
        );
        expect(
          path,
          TileQuestTypeAllocator.remaining(
            supply,
            profile: profile,
            random: Random(seed),
          ),
        );
        final used = List<int>.filled(supply.length, 0);
        final tray = List<int>.filled(supply.length, 0);
        var occupancy = 0, maximum = 0;
        for (final type in path) {
          used[type]++;
          tray[type]++;
          occupancy++;
          if (tray[type] == 3) {
            tray[type] = 0;
            occupancy -= 3;
          }
          maximum = max(maximum, occupancy);
          expect(occupancy, lessThan(TileQuestConfig.tray_capacity));
        }
        expect(used, original);
        expect(occupancy, 0);
        if (maximum == 6) pressure_six_runs++;
        final plain_groups = [
          for (var index = 0; index < path.length; index += 3)
            path[index] == path[index + 1] && path[index] == path[index + 2],
        ];
        expect(
          plain_groups.where((same) => same).length,
          lessThan(plain_groups.length ~/ 2),
          reason:
              'Shuffle must not turn the whole hidden remainder into consecutive triples',
        );
      }
      expect(pressure_six_runs, greaterThanOrEqualTo(72));
    },
  );

  test('fair allocation keeps stock even and never strands the tray', () {
    for (var difficulty = 1; difficulty <= 10; difficulty++) {
      final profile = DifficultyProfile.for_difficulty(difficulty);
      for (final seed in [0, 1, 17, 730]) {
        final sequence = TileQuestTypeAllocator.initial(
          profile,
          opening_count: 18,
          random: Random(seed),
        );
        final counts = List<int>.filled(profile.type_count, 0);
        var occupancy = 0;
        for (final type in sequence) {
          counts[type]++;
          occupancy = counts.fold<int>(0, (sum, count) => sum + count % 3);
          expect(occupancy, lessThan(TileQuestConfig.tray_capacity));
        }
        expect(sequence, hasLength(profile.tile_count));
        expect(counts.every((count) => count % 3 == 0), isTrue);
        expect(sequence.toSet(), hasLength(profile.type_count));
        // 公平化：不再有「全场仅3张」的稀有图，各图案数量大体均匀。
        final minimum = counts.reduce(min);
        final maximum = counts.reduce(max);
        expect(minimum * 2, greaterThanOrEqualTo(maximum));
      }
    }
  });

  test(
    'deep allocation rejects partial triples rather than losing inventory',
    () {
      expect(
        () => TileQuestTypeAllocator.remaining(
          [1, 2, 3],
          profile: DifficultyProfile.for_difficulty(8),
          random: Random(7),
        ),
        throwsArgumentError,
      );
    },
  );
}
