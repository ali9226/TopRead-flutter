// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math' as math;
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/widgets/compact_board_layout.dart';
import 'package:app/pages/tile_quest/widgets/quest_controls.dart';
import 'package:app/pages/tile_quest/widgets/quest_result.dart';
import 'package:app/pages/tile_quest/widgets/playfield.dart';
import 'package:app/pages/tile_quest/widgets/quest_scene.dart';
import 'package:app/pages/tile_quest/widgets/scene_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'scene_probe.dart';

const _epsilon = .000001;

void _inside(Rect card, Rect bounds) {
  expect(card.left, greaterThanOrEqualTo(bounds.left - _epsilon));
  expect(card.top, greaterThanOrEqualTo(bounds.top - _epsilon));
  expect(card.right, lessThanOrEqualTo(bounds.right + _epsilon));
  expect(card.bottom, lessThanOrEqualTo(bounds.bottom + _epsilon));
}

double _overlap(Rect lower, Rect upper) {
  final width =
      math.min(lower.right, upper.right) - math.max(lower.left, upper.left);
  final height =
      math.min(lower.bottom, upper.bottom) - math.max(lower.top, upper.top);
  return width <= 0 || height <= 0
      ? 0
      : width * height / (lower.width * lower.height);
}

class _Game extends StatefulWidget {
  const _Game({super.key});
  @override
  State<_Game> createState() => _GameState();
}

class _GameState extends State<_Game> {
  final engine = TileQuestEngine(
    TileQuestGenerator.generate(level: 2, seed: 730),
  );
  final actions = <TileQuestActionResult>[];
  void tap(int id) => setState(() => actions.add(engine.tap_tile(id)));
  void tool(TileQuestTool tool) => setState(() {
    final result = switch (tool) {
      TileQuestTool.undo => engine.undo(),
      TileQuestTool.remove => engine.remove(),
      TileQuestTool.shuffle => engine.shuffle(seed: 431),
    };
    expect(result.accepted, isTrue, reason: result.reason);
    actions.add(result);
  });
  @override
  Widget build(BuildContext context) => TileQuestScene(
    state: engine.state,
    action: actions.lastOrNull,
    recent_actions: actions,
    animate_entry: false,
    sound_enabled: false,
    busy: false,
    can_undo: engine.can_undo,
    on_back: () {},
    on_restart: () {},
    on_sound: () {},
    on_tile: tap,
    on_reserve: (_) {},
    on_tool: tool,
  );
}

void main() {
  test('only complete vertical separating folds can use both columns', () {
    const size = Size(867, 635);
    const bounds = Rect.fromLTWH(455.5, 0, 40, 635);
    for (final feature in const [
      DisplayFeature(
        bounds: bounds,
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
      DisplayFeature(
        bounds: bounds,
        type: DisplayFeatureType.fold,
        state: DisplayFeatureState.postureFlat,
      ),
      DisplayFeature(
        bounds: Rect.fromLTWH(455.5, 20, 40, 500),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      ),
      DisplayFeature(
        bounds: Rect.fromLTWH(0, 300, 867, 40),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      ),
      DisplayFeature(
        bounds: Rect.fromLTWH(200, 0, 40, 635),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      ),
    ]) {
      expect(QuestPlayfield.split_columns(size, [feature]), isNull);
    }
    for (final type in [DisplayFeatureType.hinge, DisplayFeatureType.fold]) {
      final columns = QuestPlayfield.split_columns(size, [
        DisplayFeature(
          bounds: bounds,
          type: type,
          state: DisplayFeatureState.postureHalfOpened,
        ),
      ]);
      expect(columns, [
        const Rect.fromLTWH(0, 0, 455.5, 635),
        const Rect.fromLTWH(495.5, 0, 371.5, 635),
      ]);
    }
  });

  test(
    'short portrait uses real independent islands without changing any occlusion',
    () {
      for (final difficulty in [1, 5, 8, 10]) {
        for (final seed in [1, 730]) {
          final state = TileQuestGenerator.generate(
            level: 2,
            difficulty: difficulty,
            seed: seed,
          );
          final original = state.to_json();
          final compact = QuestCompactBoardLayout(state.tiles);
          expect(compact.reflowed, isTrue);
          final layout = QuestSceneLayout(const Size(466, 568), state);
          expect(layout.compact_portrait, isTrue);
          expect(layout.compact_header, isTrue);
          expect(
            layout.board_tile(state.tiles.first).width,
            greaterThanOrEqualTo(44),
          );
          for (final lower in state.tiles) {
            final lower_rect = layout.board_tile(lower);
            _inside(lower_rect, layout.board);
            expect(lower_rect.overlaps(layout.tray), isFalse);
            expect(lower_rect.overlaps(layout.tools), isFalse);
            expect(lower_rect.overlaps(layout.reserve), isFalse);
            for (final upper in state.tiles) {
              expect(
                _overlap(lower_rect, layout.board_tile(upper)),
                closeTo(
                  TileQuestGeometry.occlusion_area_ratio(lower, upper),
                  _epsilon,
                ),
              );
            }
          }
          expect(state.to_json(), original);
          final removed = state.copy_with(
            tiles: [
              for (final tile in state.tiles) tile.copy_with(is_removed: true),
            ],
          );
          final empty = QuestSceneLayout(layout.size, removed);
          for (final tile in state.tiles) {
            expect(empty.board_tile(tile), layout.board_tile(tile));
          }
        }
      }
    },
  );

  test(
    'compact layout safely preserves unknown and interdependent legacy regions',
    () {
      final tiles = [
        const TileQuestTile(id: 0, type: 0, layer: 0, x: 0, y: 0),
        const TileQuestTile(
          id: 1,
          type: 1,
          layer: 1,
          x: .5,
          y: .5,
          region_id: 'side_top',
        ),
        const TileQuestTile(
          id: 2,
          type: 2,
          layer: 0,
          x: 2,
          y: 0,
          region_id: 'side_bottom',
        ),
      ];
      final layout = QuestCompactBoardLayout(tiles);
      expect(layout.reflowed, isFalse);
      for (final tile in tiles) {
        expect(layout.position(tile), Offset(tile.x, tile.y));
      }
    },
  );

  testWidgets(
    'folding while a tile flies retains state and exact tray landing',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(466, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final key = GlobalKey<_GameState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: _Game(key: key)),
        ),
      );
      await tester.pumpAndSettle();
      final game = key.currentState!;
      final id = game.engine.state.clickable_tiles.first.id;
      await tester.tapAt(quest_scene_frames(tester)[id]!.rect.center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(quest_scene_frames(tester)[id]!.zone, QuestTileZone.flight);
      final during = game.engine.state.to_json();
      await tester.binding.setSurfaceSize(const Size(669, 851));
      await tester.pump(const Duration(milliseconds: 50));
      expect(key.currentState, same(game));
      expect(game.engine.state.to_json(), during);
      await tester.pumpAndSettle();
      final expanded = QuestSceneLayout(
        const Size(669, 851),
        game.engine.state,
      );
      expect(quest_scene_frames(tester)[id]!.rect, expanded.tray_tile(0));
      await tester.binding.setSurfaceSize(const Size(466, 568));
      await tester.pumpAndSettle();
      final compact = QuestSceneLayout(const Size(466, 568), game.engine.state);
      expect(quest_scene_frames(tester)[id]!.rect, compact.tray_tile(0));
      expect(game.engine.state.to_json(), during);
      expect(find.byType(QuestToolButton), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'wide vertical folds use both panes while small or horizontal panes stay safe',
    (tester) async {
      const window = Size(669, 951);
      await tester.binding.setSurfaceSize(window);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final data = ValueNotifier(
        const MediaQueryData(
          size: window,
          padding: EdgeInsets.only(top: 44, bottom: 34),
        ),
      );
      addTearDown(data.dispose);
      final key = GlobalKey<_GameState>();
      final playfield = QuestPlayfield(child: _Game(key: key));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<MediaQueryData>(
              valueListenable: data,
              child: playfield,
              builder: (_, media, child) =>
                  MediaQuery(data: media, child: child!),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final game = key.currentState!;
      final id = game.engine.state.clickable_tiles.first.id;
      game.tap(id);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final saved = game.engine.state.to_json();
      final scenarios = [
        (
          const Rect.fromLTWH(330, 0, 9, 951),
          const Rect.fromLTWH(0, 44, 669, 873),
        ),
        (
          const Rect.fromLTWH(0, 400, 669, 12),
          const Rect.fromLTWH(0, 412, 669, 505),
        ),
        (
          const Rect.fromLTWH(200, 0, 0, 951),
          const Rect.fromLTWH(200, 44, 469, 873),
        ),
      ];
      for (final scenario in scenarios) {
        data.value = data.value.copyWith(
          displayFeatures: [
            DisplayFeature(
              bounds: scenario.$1,
              type: DisplayFeatureType.hinge,
              state: DisplayFeatureState.postureHalfOpened,
            ),
          ],
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(key.currentState, same(game));
        expect(game.engine.state.to_json(), saved);
        final scene = tester.getRect(find.byType(TileQuestScene));
        expect(scene, scenario.$2);
        for (final frame in quest_scene_frames(tester).values) {
          if (frame.zone != QuestTileZone.flight) _inside(frame.rect, scene);
        }
        await tester.pumpAndSettle();
        final geometry = QuestSceneLayout(
          scene.size,
          game.engine.state,
          display_features: MediaQuery.displayFeaturesOf(
            tester.element(find.byType(TileQuestScene)),
          ),
        );
        expect(
          quest_scene_frames(tester)[id]!.rect,
          geometry.tray_tile(0).shift(scene.topLeft),
        );
        expect(tester.takeException(), isNull);
      }
      data.value = data.value.copyWith(displayFeatures: []);
      await tester.pumpAndSettle();
      expect(key.currentState, same(game));
      expect(game.engine.state.to_json(), saved);
      expect(
        tester.getRect(find.byType(TileQuestScene)),
        const Rect.fromLTWH(0, 44, 669, 873),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Duo half-open uses both panes and unfolds a flying tile into readable slots',
    (tester) async {
      const window = Size(951, 669);
      const hinge = Rect.fromLTWH(455.5, 0, 40, 669);
      await tester.binding.setSurfaceSize(window);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final media = ValueNotifier(
        const MediaQueryData(
          size: window,
          padding: EdgeInsets.only(right: 84, bottom: 34),
          displayFeatures: [
            DisplayFeature(
              bounds: hinge,
              type: DisplayFeatureType.hinge,
              state: DisplayFeatureState.postureHalfOpened,
            ),
            DisplayFeature(
              bounds: Rect.fromLTWH(867, 0, 84, 124),
              type: DisplayFeatureType.cutout,
              state: DisplayFeatureState.unknown,
            ),
          ],
        ),
      );
      addTearDown(media.dispose);
      final key = GlobalKey<_GameState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<MediaQueryData>(
              valueListenable: media,
              child: QuestPlayfield(child: _Game(key: key)),
              builder: (_, data, child) =>
                  MediaQuery(data: data, child: child!),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final game = key.currentState!;
      final scene = find.byType(TileQuestScene);
      final folded = QuestSceneLayout(
        tester.getSize(scene),
        game.engine.state,
        display_features: MediaQuery.displayFeaturesOf(tester.element(scene)),
      );
      expect(folded.folded, isTrue);
      expect(folded.board.right, lessThan(hinge.left));
      for (final rect in [folded.reserve, folded.tray, folded.tools]) {
        expect(rect.left, greaterThan(hinge.right));
      }
      expect(folded.unit, greaterThanOrEqualTo(44));
      expect(folded.tray_tile(0).width, greaterThanOrEqualTo(44));
      for (final tile in game.engine.state.tiles) {
        expect(folded.board_tile(tile).overlaps(hinge), isFalse);
      }
      for (final tool in TileQuestTool.values) {
        final button = tester.getRect(
          find.byKey(ValueKey('tile_quest_tool_${tool.name}')),
        );
        expect(button.overlaps(hinge), isFalse);
        expect(button.width, greaterThanOrEqualTo(44));
      }
      final id = game.engine.state.clickable_tiles.first.id;
      game.tap(id);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final saved = game.engine.state.to_json();
      media.value = media.value.copyWith(displayFeatures: []);
      await tester.pumpAndSettle();
      expect(key.currentState, same(game));
      expect(game.engine.state.to_json(), saved);
      final expanded = QuestSceneLayout(
        tester.getSize(scene),
        game.engine.state,
      );
      expect(expanded.landscape, isTrue);
      expect(expanded.unit, greaterThanOrEqualTo(44));
      expect(expanded.tray_tile(0).width, greaterThanOrEqualTo(44));
      expect(quest_scene_frames(tester)[id]!.rect, expanded.tray_tile(0));
      media.value = media.value.copyWith(
        displayFeatures: const [
          DisplayFeature(
            bounds: hinge,
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(game.engine.state.to_json(), saved);
      expect(quest_scene_frames(tester)[id]!.rect, folded.tray_tile(0));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('folded result panel fits one complete pane', (tester) async {
    const window = Size(951, 669);
    const hinge = Rect.fromLTWH(455.5, 0, 40, 669);
    await tester.binding.setSurfaceSize(window);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              size: window,
              padding: EdgeInsets.only(right: 84, bottom: 34),
              displayFeatures: [
                DisplayFeature(
                  bounds: hinge,
                  type: DisplayFeatureType.hinge,
                  state: DisplayFeatureState.postureHalfOpened,
                ),
              ],
            ),
            child: QuestPlayfield(
              child: QuestResult(
                state: TileQuestGenerator.generate(
                  level: 2,
                  seed: 730,
                ).copy_with(status: TileQuestStatus.lost),
                coming_soon: false,
                busy: false,
                on_next: () {},
                on_restart: () {},
                on_back: () {},
                on_undo: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final primary = tester.getRect(
      find.byKey(const ValueKey('tile_quest_result_primary')),
    );
    _inside(primary, const Rect.fromLTWH(0, 0, 455.5, 635));
    expect(primary.overlaps(hinge), isFalse);
    expect(primary.height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  for (final tool in TileQuestTool.values) {
    testWidgets('folding during ${tool.name} keeps action and exact targets', (
      tester,
    ) async {
      const window = Size(951, 669);
      const hinge = DisplayFeature(
        bounds: Rect.fromLTWH(455.5, 0, 40, 669),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      );
      await tester.binding.setSurfaceSize(window);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final data = ValueNotifier(
        const MediaQueryData(
          size: window,
          padding: EdgeInsets.only(right: 84, bottom: 34),
        ),
      );
      addTearDown(data.dispose);
      final key = GlobalKey<_GameState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<MediaQueryData>(
              valueListenable: data,
              child: QuestPlayfield(child: _Game(key: key)),
              builder: (_, media, child) =>
                  MediaQuery(data: media, child: child!),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final game = key.currentState!;
      game.tap(game.engine.state.clickable_tiles.first.id);
      await tester.pumpAndSettle();
      game.tool(tool);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final saved = game.engine.state.to_json();
      data.value = data.value.copyWith(displayFeatures: [hinge]);
      await tester.pump(const Duration(milliseconds: 60));
      expect(key.currentState, same(game));
      expect(game.engine.state.to_json(), saved);
      await tester.pumpAndSettle();
      final scene = find.byType(TileQuestScene);
      final rect = tester.getRect(scene);
      final layout = QuestSceneLayout(
        rect.size,
        game.engine.state,
        display_features: MediaQuery.displayFeaturesOf(tester.element(scene)),
      );
      final frames = quest_scene_frames(tester);
      for (var index = 0; index < game.engine.state.tray.length; index++) {
        expect(
          frames[game.engine.state.tray[index]]!.rect,
          layout.tray_tile(index).shift(rect.topLeft),
        );
      }
      for (var index = 0; index < game.engine.state.reserve.length; index++) {
        expect(
          frames[game.engine.state.reserve[index]]!.rect,
          layout.reserve_tile(index).shift(rect.topLeft),
        );
      }
      data.value = data.value.copyWith(displayFeatures: []);
      await tester.pumpAndSettle();
      expect(key.currentState, same(game));
      expect(game.engine.state.to_json(), saved);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'closed window preserves the actual right-hand sensor safe area',
    (tester) async {
      const window = Size(466, 678);
      const content = Rect.fromLTWH(0, 0, 382, 644);
      await tester.binding.setSurfaceSize(window);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final key = GlobalKey<_GameState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                size: window,
                padding: EdgeInsets.only(right: 84, bottom: 34),
              ),
              child: QuestPlayfield(child: _Game(key: key)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(TileQuestScene)), content);
      final layout = QuestSceneLayout(
        content.size,
        key.currentState!.engine.state,
      );
      expect(layout.compact_portrait, isTrue);
      expect(layout.unit, greaterThanOrEqualTo(44));
      for (final frame in quest_scene_frames(tester).values) {
        _inside(frame.rect, content);
      }
      for (final tool in TileQuestTool.values) {
        final button = tester.getRect(
          find.byKey(ValueKey('tile_quest_tool_${tool.name}')),
        );
        _inside(button, content);
        expect(button.width, greaterThanOrEqualTo(44));
        expect(button.height, greaterThanOrEqualTo(44));
      }
      expect(tester.takeException(), isNull);
    },
  );

  for (final window in const [Size(951, 669), Size(669, 951)]) {
    testWidgets('expanded window $window uses its actual safe constraints', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(window);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final key = GlobalKey<_GameState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(
                size: window,
                padding: const EdgeInsets.only(right: 84, bottom: 34),
              ),
              child: QuestPlayfield(child: _Game(key: key)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final content = tester.getRect(find.byType(TileQuestScene));
      expect(
        content,
        Rect.fromLTWH(0, 0, window.width - 84, window.height - 34),
      );
      final layout = QuestSceneLayout(
        content.size,
        key.currentState!.engine.state,
      );
      expect(layout.unit, greaterThanOrEqualTo(44));
      for (final frame in quest_scene_frames(tester).values) {
        _inside(frame.rect, content);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
