// ignore_for_file: non_constant_identifier_names
import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('强弱档配方把模型曲线压到目标±2%以内（取整误差已消除）', () {
    for (var difficulty = 1; difficulty <= 9; difficulty++) {
      final win = (10 - difficulty) / 10;
      final forks = TileQuestConfig.trap_recipe(win);
      var achieved = 1.0;
      for (final fork in forks) {
        achieved *= 1 - fork.hit_rate;
      }
      expect(
        (achieved - win).abs(),
        lessThanOrEqualTo(0.02),
        reason: 'difficulty $difficulty forks=${forks.length} '
            'achieved=$achieved target=$win',
      );
    }
    // 难度10 必败交给暗坑容量核；满分不布陷阱。
    expect(TileQuestConfig.trap_recipe(0), isEmpty);
    expect(TileQuestConfig.trap_recipe(1), isEmpty);
  });

  test('分叉数随难度增长，满档叉与残差叉混合', () {
    var previous = 0;
    for (var difficulty = 1; difficulty <= 9; difficulty++) {
      final forks = TileQuestConfig.trap_recipe((10 - difficulty) / 10);
      expect(forks.length, greaterThanOrEqualTo(previous));
      previous = forks.length;
    }
    // 难度8/9 至少一个满档叉（0.3 命中率）与若干弱叉混合。
    final hard = TileQuestConfig.trap_recipe(0.2);
    expect(hard.any((fork) => fork.hit_rate >= 0.3), isTrue);
  });

  test('难度档位携带配方；每叉结构合法（gap 3-6、spread 1-3）', () {
    for (var difficulty = 1; difficulty <= 10; difficulty++) {
      final profile = DifficultyProfile.for_difficulty(difficulty);
      expect(
        profile.trap_forks.length,
        TileQuestConfig.trap_recipe((10 - difficulty) / 10).length,
      );
      for (final fork in profile.trap_forks) {
        expect(fork.gap, inInclusiveRange(3, 6));
        expect(fork.spread, inInclusiveRange(1, 3));
        expect(fork.hit_rate, greaterThan(0));
        expect(fork.hit_rate, lessThanOrEqualTo(0.5));
      }
    }
  });

  test('生成盘面按配方埋入强弱档延迟三连', () {
    for (final difficulty in [2, 5, 8]) {
      final profile = DifficultyProfile.for_difficulty(difficulty);
      for (final seed in [0, 17, 730]) {
        final state = TileQuestGenerator.generate(
          level: 2,
          seed: seed,
          difficulty: difficulty,
        );
        final path =
            state.expert_barrier?.lead_solution ?? state.certified_solution;
        final position_of = {
          for (var index = 0; index < path.length; index++) path[index]: index,
        };
        final by_type = <int, List<int>>{};
        for (final id in path) {
          by_type.putIfAbsent(state.tile_by_id(id).type, () => []).add(
            position_of[id]!,
          );
        }
        for (final fork in profile.trap_forks) {
          final tail = fork.spread + fork.gap;
          var found = false;
          for (final positions in by_type.values) {
            final set = positions.toSet();
            for (final start in set) {
              if (set.contains(start + fork.spread) &&
                  set.contains(start + tail)) {
                found = true;
                break;
              }
            }
            if (found) break;
          }
          expect(
            found,
            isTrue,
            reason: 'difficulty $difficulty seed $seed '
                'gap=${fork.gap} spread=${fork.spread}',
          );
        }
      }
    }
  });

  test('延迟三连是普通图案：不制造全场仅3张的稀有图', () {
    for (final difficulty in [2, 8]) {
      final state = TileQuestGenerator.generate(
        level: 2,
        seed: 730,
        difficulty: difficulty,
      );
      final counts = <int, int>{};
      for (final tile in state.tiles) {
        counts[tile.type] = (counts[tile.type] ?? 0) + 1;
      }
      final sizes = counts.values.toList()..sort();
      expect(sizes.first * 2, greaterThanOrEqualTo(sizes.last));
    }
  });

  test('选错叠对会把槽压满：三组延迟对同时在手即越界', () {
    // 延迟三连的窗口里，每组把2张单牌压进槽里；三组重叠即 6 张单牌，
    // 加上任意一张新图单牌就到 7——死期落在分叉点之后，撤回只有1步。
    final tray = TileQuestConfig.tray_capacity;
    final stacked = 3 * 2;
    expect(stacked, greaterThanOrEqualTo(tray - 1));
  });
}
