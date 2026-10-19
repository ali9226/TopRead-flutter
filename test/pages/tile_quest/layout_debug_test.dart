// ignore_for_file: non_constant_identifier_names
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/widgets/layout_debug.dart';
import 'package:app/pages/tile_quest/widgets/scene_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'debug switch shows current geometry without consuming board taps',
    (tester) async {
      const size = Size(390, 844);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final tiles = [
        const TileQuestTile(
          id: 0,
          type: 0,
          layer: 0,
          x: 0,
          y: 0,
          region_id: 'core',
        ),
        const TileQuestTile(
          id: 1,
          type: 0,
          layer: 1,
          x: .5,
          y: .5,
          region_id: 'core',
        ),
        const TileQuestTile(
          id: 2,
          type: 0,
          layer: 0,
          x: 3,
          y: 0,
          region_id: 'side_top',
        ),
      ];
      final state = TileQuestState(
        tiles: TileQuestGeometry(tiles).refresh(tiles),
        level: 2,
        seed: 12345,
        challenge_id: 'debug-layout',
      );
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => tapped++,
                  ),
                ),
                Positioned.fill(
                  child: QuestLayoutDebug(
                    state: state,
                    layout: QuestSceneLayout(size, state),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      const toggle = ValueKey('tile_quest_layout_debug_toggle');
      const stats = ValueKey('tile_quest_layout_debug_stats');
      expect(find.byKey(stats), findsNothing);
      await tester.tap(find.byKey(toggle));
      await tester.pump();
      final text = tester.widget<Text>(find.byKey(stats)).data!;
      expect(text, contains('seed 12345'));
      expect(text, contains('clickable 2  blocked 1'));
      expect(text, contains('L0:2  L1:1'));
      await tester.tapAt(const Offset(80, 500));
      expect(tapped, 1);
      await tester.tap(find.byKey(toggle));
      await tester.pump();
      expect(find.byKey(stats), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
