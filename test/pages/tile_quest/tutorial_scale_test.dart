// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/game/tutorial_layout.dart';
import 'package:app/pages/tile_quest/game/validator.dart';
import 'package:app/pages/tile_quest/widgets/quest_scene.dart';
import 'package:app/pages/tile_quest/widgets/scene_layout.dart';
import 'package:app/pages/tile_quest/widgets/tile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _epsilon = .000001;
const _shape_seeds = <int>[1, 3, 11, 0, 5, 13];

/// 按逻辑坐标配对两层，与随机 id、图案或证书顺序完全无关。
TileQuestTile _upper_partner(TileQuestState state, TileQuestTile lower) =>
    state.tiles.singleWhere(
      (tile) =>
          tile.layer == 1 &&
          (tile.x - lower.x).abs() < _epsilon &&
          (tile.y - lower.y - .5).abs() < _epsilon,
    );

void _expect_tutorial(TileQuestState state) {
  expect(state.level, 1);
  expect(state.difficulty, 1);
  expect(state.total_count, 18);
  expect(state.tiles.map((tile) => tile.layer).toSet(), <int>{0, 1});
  expect(state.tiles.map((tile) => tile.type).toSet(), hasLength(3));
  for (final type in state.tiles.map((tile) => tile.type).toSet()) {
    expect(state.tiles.where((tile) => tile.type == type), hasLength(6));
  }
  for (final layer in <int>[0, 1]) {
    final tiles = state.tiles.where((tile) => tile.layer == layer).toList();
    expect(tiles, hasLength(9));
    final xs = tiles.map((tile) => tile.x).toSet().toList()..sort();
    final ys = tiles.map((tile) => tile.y).toSet().toList()..sort();
    expect(xs, hasLength(3));
    expect(ys, hasLength(3));
    for (final x in xs) {
      for (final y in ys) {
        expect(tiles.where((tile) => tile.x == x && tile.y == y), hasLength(1));
      }
    }
    for (var index = 1; index < 3; index++) {
      // 每组两张的整体高度为1.5，横/纵都保留清楚的整组间隔。
      expect(xs[index] - xs[index - 1] - 1, greaterThanOrEqualTo(.5));
      expect(ys[index] - ys[index - 1] - 1.5, greaterThanOrEqualTo(.25));
    }
  }
  for (final lower in state.tiles.where((tile) => tile.layer == 0)) {
    final upper = _upper_partner(state, lower);
    expect(upper.x, lower.x);
    expect(upper.y - lower.y, closeTo(lower.height / 2, _epsilon));
    expect(upper.width, lower.width);
    expect(upper.height, lower.height);
    expect(lower.is_blocked, isTrue);
    expect(upper.is_blocked, isFalse);
  }
  expect(state.clickable_tiles, hasLength(9));
  expect(TileQuestValidator.validate_solution(state).valid, isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'tutorial has exactly two separated 3 by 3 layers with vertical half overlap',
    () {
      for (final seed in <int>[0, 1, 17, 730, 2147483647]) {
        final state = TileQuestGenerator.generate(level: 1, seed: seed);
        _expect_tutorial(state);
        final helper = TileQuestTutorial.generate_state(seed: seed);
        expect(state.to_json(), helper.to_json());
        final engine = TileQuestEngine(state);
        for (final id in state.certified_solution) {
          expect(engine.tap_tile(id).accepted, isTrue);
        }
        expect(engine.state.status, TileQuestStatus.won);
        expect(engine.state.tools_used, 0);
      }
    },
  );

  test(
    'tutorial selects reproducible red, blue and green shapes across seeds',
    () {
      const red_shapes = <String>{'strawberry', 'apple', 'heart', 'rose'};
      const blue_shapes = <String>{'blue_gem', 'snowflake'};
      const green_shapes = <String>{'leaf', 'clover', 'cactus', 'pine_tree'};
      final palettes = <String>{};
      for (var seed = 0; seed < 128; seed++) {
        final state = TileQuestGenerator.generate(level: 1, seed: seed);
        final same_seed = TileQuestGenerator.generate(level: 1, seed: seed);
        expect(same_seed.to_json(), state.to_json());
        _expect_tutorial(state);
        final names = state.tiles
            .map((tile) => quest_tile_assets[tile.type])
            .toSet();
        expect(names.intersection(red_shapes), hasLength(1));
        expect(names.intersection(blue_shapes), hasLength(1));
        expect(names.intersection(green_shapes), hasLength(1));
        expect(names.intersection(<String>{'star', 'moon', 'sun'}), isEmpty);
        for (final layer in <int>[0, 1]) {
          for (final type in state.tiles.map((tile) => tile.type).toSet()) {
            expect(
              state.tiles.where(
                (tile) => tile.layer == layer && tile.type == type,
              ),
              hasLength(3),
            );
          }
        }
        palettes.add((names.toList()..sort()).join(','));
      }
      expect(
        palettes.length,
        greaterThanOrEqualTo(8),
        reason: 'new seeds vary the picture set as well as the tile positions',
      );
    },
  );

  final challenges = <TileQuestState>[];
  setUpAll(() {
    for (var difficulty = 1; difficulty <= 10; difficulty++) {
      for (final seed in _shape_seeds) {
        challenges.add(
          TileQuestGenerator.generate(
            level: 2,
            seed: seed,
            difficulty: difficulty,
          ),
        );
      }
    }
  });

  for (final size in <Size>[
    const Size(320, 480),
    const Size(320, 568),
    const Size(390, 844),
    const Size(680, 1268),
    const Size(1024, 1366),
    const Size(680, 343),
    const Size(844, 390),
    const Size(844, 300),
  ]) {
    test(
      'all levels, shapes and difficulties retain the same tile edge at $size',
      () {
        final tutorial = TileQuestGenerator.generate(level: 1, seed: 730);
        final reference_layout = QuestSceneLayout(size, tutorial);
        final expected_edge = reference_layout
            .board_tile(tutorial.tiles.first)
            .width;
        expect(expected_edge, greaterThan(0));
        for (final state in <TileQuestState>[tutorial, ...challenges]) {
          final layout = QuestSceneLayout(size, state);
          expect(
            layout.unit,
            closeTo(expected_edge, _epsilon),
            reason:
                'level ${state.level}, difficulty ${state.difficulty}, '
                'seed ${state.seed} must not resize the tiles',
          );
          for (final tile in state.tiles) {
            final rect = layout.board_tile(tile);
            expect(rect.width, closeTo(expected_edge, _epsilon));
            expect(rect.height, closeTo(expected_edge, _epsilon));
            expect(
              rect.left,
              greaterThanOrEqualTo(layout.board.left - _epsilon),
            );
            expect(
              rect.right,
              lessThanOrEqualTo(layout.board.right + _epsilon),
            );
            expect(rect.top, greaterThanOrEqualTo(layout.board.top - _epsilon));
            expect(
              rect.bottom,
              lessThanOrEqualTo(layout.board.bottom + _epsilon),
            );
          }
          // 减少剩余牌不应改变统一边长，也不能改变任何牌的原始定位。
          final removed = state.copy_with(
            tiles: state.tiles
                .map((tile) => tile.copy_with(is_removed: true))
                .toList(),
          );
          final empty_layout = QuestSceneLayout(size, removed);
          expect(empty_layout.unit, closeTo(expected_edge, _epsilon));
          expect(empty_layout.board_origin, layout.board_origin);
        }
      },
    );
  }

  testWidgets(
    'exposed lower half stays blocked while its upper partner is clickable',
    (tester) async {
      const size = Size(390, 844);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = TileQuestGenerator.generate(level: 1, seed: 730);
      final layout = QuestSceneLayout(size, state);
      final tapped = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TileQuestScene(
              state: state,
              action: null,
              animate_entry: false,
              sound_enabled: false,
              busy: false,
              on_back: () {},
              on_restart: () {},
              on_sound: () {},
              on_tile: tapped.add,
              on_reserve: (_) {},
              on_tool: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final lower in state.tiles.where((tile) => tile.layer == 0)) {
        final upper = _upper_partner(state, lower);
        final lower_card = tester.widget<QuestTileCard>(
          find.byKey(ValueKey('board_card_${lower.id}')),
        );
        final upper_card = tester.widget<QuestTileCard>(
          find.byKey(ValueKey('board_card_${upper.id}')),
        );
        expect(lower_card.blocked, isTrue);
        expect(lower_card.on_tap, isNull);
        expect(upper_card.blocked, isFalse);
        expect(upper_card.on_tap, isNotNull);
        final lower_rect = layout.board_tile(lower);
        final upper_rect = layout.board_tile(upper);
        expect(upper_rect.center.dx, closeTo(lower_rect.center.dx, _epsilon));
        expect(
          upper_rect.top - lower_rect.top,
          closeTo(lower_rect.height / 2, _epsilon),
        );
        final visible_lower_half = Rect.fromLTRB(
          lower_rect.left,
          lower_rect.top,
          lower_rect.right,
          math.min(lower_rect.bottom, upper_rect.top),
        );
        expect(
          visible_lower_half.height,
          closeTo(lower_rect.height / 2, _epsilon),
        );
        await tester.tapAt(visible_lower_half.center);
        expect(tapped, isEmpty);
        await tester.tapAt(upper_rect.center);
        expect(tapped, <int>[upper.id]);
        tapped.clear();
      }
      expect(tester.takeException(), isNull);
    },
  );
}
