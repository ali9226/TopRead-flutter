// ignore_for_file: non_constant_identifier_names
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/widgets/scene_layout.dart';
import 'package:app/pages/tile_quest/widgets/slot_wells.dart';
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
  ];

  for (final size in sizes) {
    test('square tray and reserve geometry fits $size', () {
      final layout = QuestSceneLayout(size, state);
      const tolerance = .000001;
      final expected_edge = (layout.tray.width - 16 - 18) / 7;
      for (var index = 0; index < QuestSceneLayout.slot_count; index++) {
        final slot = layout.tray_tile(index);
        expect(slot.width, closeTo(expected_edge, tolerance));
        expect(slot.height, closeTo(expected_edge, tolerance));
        expect(slot.left, greaterThanOrEqualTo(layout.tray.left));
        expect(slot.right, lessThanOrEqualTo(layout.tray.right));
        expect(slot.bottom, lessThanOrEqualTo(layout.tray_caption.top));
        if (index > 0) {
          expect(
            slot.left - layout.tray_tile(index - 1).right,
            closeTo(QuestSceneLayout.tray_gap, tolerance),
          );
        }
      }
      expect(layout.tray_caption.bottom, lessThanOrEqualTo(layout.tray.bottom));
      expect(layout.reserve.bottom, lessThanOrEqualTo(layout.tray.top));
      expect(layout.tray.bottom, lessThanOrEqualTo(layout.tools.top));
      expect(layout.tools.bottom, lessThanOrEqualTo(size.height));
      expect(layout.board.bottom, lessThanOrEqualTo(size.height));

      for (var index = 0; index < QuestSceneLayout.reserve_count; index++) {
        final slot = layout.reserve_tile(index);
        expect(slot.width, closeTo(slot.height, tolerance));
        expect(slot.width, closeTo(layout.tray_tile(0).width, tolerance));
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
                child: QuestSlotWell(
                  layout: layout,
                  caption: 'SEVEN TILE TRAY',
                  cjk: false,
                ),
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
    expect(tester.takeException(), isNull);
  });
}
