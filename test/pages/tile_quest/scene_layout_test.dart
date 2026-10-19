// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math' as math;
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/style.dart';
import 'package:app/pages/tile_quest/widgets/scene_layout.dart';
import 'package:app/pages/tile_quest/widgets/slot_wells.dart';
import 'package:app/pages/tile_quest/widgets/tile_surface_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final state = TileQuestGenerator.generate(level: 2, seed: 730);
  const sizes = [
    Size(320, 480),
    Size(320, 568),
    Size(430, 844),
    Size(680, 1268),
    Size(1024, 1366),
    Size(680, 343),
    Size(844, 390),
    Size(844, 300),
    Size(2048, 844),
  ];

  for (final size in sizes) {
    test('tall tray and reserve geometry fits $size', () {
      final layout = QuestSceneLayout(size, state);
      const tolerance = .000001;
      final expected_edge = math.min(
        QuestSceneLayout.maximum_tray_edge,
        (layout.tray.width -
                QuestSceneLayout.tray_padding * 2 -
                QuestSceneLayout.tray_gap * (QuestSceneLayout.slot_count - 1)) /
            QuestSceneLayout.slot_count,
      );
      for (var index = 0; index < QuestSceneLayout.slot_count; index++) {
        final slot = layout.tray_tile(index);
        expect(slot.width, closeTo(expected_edge, tolerance));
        expect(
          slot.height,
          closeTo(
            expected_edge * QuestTileSurfaceStyle.tile_aspect_ratio,
            tolerance,
          ),
        );
        expect(slot.left, greaterThanOrEqualTo(layout.tray.left));
        expect(slot.right, lessThanOrEqualTo(layout.tray.right));
        expect(slot.top, greaterThanOrEqualTo(layout.tray.top));
        expect(slot.bottom, lessThanOrEqualTo(layout.tray.bottom));
        if (index > 0) {
          expect(
            slot.left - layout.tray_tile(index - 1).right,
            closeTo(QuestSceneLayout.tray_gap, tolerance),
          );
        }
      }
      if (layout.compact_portrait) {
        expect(layout.reserve.overlaps(layout.tools), isFalse);
        expect(layout.tray.bottom, lessThanOrEqualTo(layout.reserve.top));
      } else {
        expect(layout.reserve.bottom, lessThanOrEqualTo(layout.tray.top));
      }
      expect(layout.tray.bottom, lessThanOrEqualTo(layout.tools.top));
      expect(layout.tools.bottom, lessThanOrEqualTo(size.height));
      expect(layout.board.bottom, lessThanOrEqualTo(size.height));

      for (var index = 0; index < QuestSceneLayout.reserve_count; index++) {
        final slot = layout.reserve_tile(index);
        expect(
          slot.height,
          closeTo(
            slot.width * QuestTileSurfaceStyle.tile_aspect_ratio,
            tolerance,
          ),
        );
        expect(slot.width, greaterThan(0));
        expect(
          slot.width,
          lessThanOrEqualTo(
            layout.compact_portrait
                ? TileQuestStyle.compact_reserve_max_edge
                : TileQuestStyle.reserve_tile_max_width,
          ),
        );
        expect(slot.left, greaterThanOrEqualTo(layout.reserve_label.right));
        expect(slot.right, lessThanOrEqualTo(layout.reserve.right));
        expect(slot.top, greaterThanOrEqualTo(layout.reserve.top));
        expect(slot.bottom, lessThanOrEqualTo(layout.reserve.bottom));
      }
      for (final tile in state.tiles) {
        final rect = layout.board_tile(tile);
        expect(rect.left, greaterThanOrEqualTo(layout.board.left - tolerance));
        expect(rect.right, lessThanOrEqualTo(layout.board.right + tolerance));
        expect(rect.top, greaterThanOrEqualTo(layout.board.top - tolerance));
        expect(rect.bottom, lessThanOrEqualTo(layout.board.bottom + tolerance));
      }
    });
  }

  test('phone slots use all available parent width with exact padding', () {
    for (final size in const [Size(390, 844), Size(430, 844)]) {
      final layout = QuestSceneLayout(size, state);
      final board_tile = layout.board_tile(state.tiles.first);
      final first = layout.tray_tile(0);
      final last = layout.tray_tile(QuestSceneLayout.slot_count - 1);
      expect(board_tile.width, greaterThan(0));
      expect(
        board_tile.height / board_tile.width,
        closeTo(QuestTileSurfaceStyle.tile_aspect_ratio, .000001),
      );
      expect(
        first.left - layout.tray.left,
        closeTo(QuestSceneLayout.tray_padding, .000001),
      );
      expect(
        layout.tray.right - last.right,
        closeTo(QuestSceneLayout.tray_padding, .000001),
      );
      expect(
        (first.left + last.right) / 2,
        closeTo(layout.tray.center.dx, .000001),
      );
      expect(
        layout.tray.height - first.height,
        closeTo(QuestSceneLayout.tray_padding * 2, .000001),
      );
    }
  });

  test('wide tray slots stop at the shared maximum and stay centered', () {
    for (final size in const [Size(1024, 1366), Size(2048, 1600)]) {
      final layout = QuestSceneLayout(size, state);
      final first = layout.tray_tile(0);
      final last = layout.tray_tile(QuestSceneLayout.slot_count - 1);
      expect(first.width, QuestSceneLayout.maximum_tray_edge);
      expect(
        (first.left + last.right) / 2,
        closeTo(layout.tray.center.dx, .000001),
      );
    }
  });

  test('tray widths respond continuously to parent width before the cap', () {
    final narrower = QuestSceneLayout(const Size(390, 844), state);
    final wider = QuestSceneLayout(const Size(397, 844), state);
    expect(
      wider.tray_tile(0).width - narrower.tray_tile(0).width,
      closeTo(1, .000001),
    );
  });

  test(
    'phone cards retain the widened full tile faces and their raised height',
    () {
      // 已交付上一版的实际牌宽；验证不是只改变ratio却被托盘挤回原尺寸。
      for (final (size, previous_width) in const [
        (Size(390, 844), 53.07),
        (Size(430, 844), 51.98),
      ]) {
        final layout = QuestSceneLayout(size, state);
        final card = layout.board_tile(state.tiles.first);
        expect(card.width, greaterThanOrEqualTo(previous_width + 2));
        expect(card.height, greaterThanOrEqualTo(previous_width * 1.125 - .5));
        expect(layout.tools.height, greaterThanOrEqualTo(44));
      }
    },
  );

  test('a legacy seven-column footprint still fits the available board', () {
    final wide_state = state.copy_with(
      tiles: [
        for (var index = 0; index < 21; index++)
          TileQuestTile(
            id: index,
            type: index % 3,
            layer: 0,
            x: (index % 7).toDouble(),
            y: (index ~/ 7).toDouble(),
          ),
      ],
    );
    final layout = QuestSceneLayout(const Size(390, 844), wide_state);
    for (final tile in wide_state.tiles) {
      final card = layout.board_tile(tile);
      expect(card.left, greaterThanOrEqualTo(layout.board.left - .000001));
      expect(card.right, lessThanOrEqualTo(layout.board.right + .000001));
      expect(card.top, greaterThanOrEqualTo(layout.board.top - .000001));
      expect(card.bottom, lessThanOrEqualTo(layout.board.bottom + .000001));
    }
  });

  testWidgets('well backgrounds use the exact scene rectangles', (
    tester,
  ) async {
    const size = Size(430, 844);
    final layout = QuestSceneLayout(size, state);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fromRect(
                rect: layout.tray,
                child: QuestSlotWell(layout: layout),
              ),
              Positioned.fromRect(
                rect: layout.reserve,
                child: QuestReserveWell(
                  layout: layout,
                  cjk: false,
                  occupied: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    for (var index = 0; index < QuestSceneLayout.slot_count; index++) {
      expect(
        tester.getRect(find.byKey(ValueKey('tile_quest_slot_$index'))),
        layout.tray_tile(index),
      );
    }
    for (var index = 0; index < QuestSceneLayout.reserve_count; index++) {
      expect(
        tester.getRect(find.byKey(ValueKey('tile_quest_reserve_slot_$index'))),
        layout.reserve_tile(index),
      );
    }
    expect(find.text('SEVEN TILE TRAY'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
