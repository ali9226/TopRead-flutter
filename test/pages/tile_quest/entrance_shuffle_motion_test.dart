// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math' as math;
import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/style.dart';
import 'package:app/pages/tile_quest/widgets/board_motion.dart';
import 'package:app/pages/tile_quest/widgets/quest_scene.dart';
import 'package:app/pages/tile_quest/widgets/scene_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'shuffle_probe.dart';
import 'scene_probe.dart';

const _scene_size = Size(390, 844);
const _frame = Duration(milliseconds: 8);

/// 两层真实交叠保留被遮挡牌；每类三张，便于真实引擎洗牌验证。
TileQuestState _fixture({
  String challenge_id = 'entrance-first',
  int level = 1,
  bool held = false,
}) {
  final held_ids = held ? const [0, 1, 2] : const <int>[];
  final tiles = [
    for (var id = 0; id < 18; id++)
      TileQuestTile(
        id: id,
        type: id % 6,
        layer: id < 9 ? 0 : 1,
        x: ((id % 9) % 3) + (id < 9 ? 0.0 : .5),
        y: ((id % 9) ~/ 3) + (id < 9 ? 0.0 : .5),
        is_removed: held_ids.contains(id),
      ),
  ];
  return TileQuestState(
    tiles: TileQuestGeometry(tiles).refresh(tiles),
    tray: held ? const [0, 1] : const [],
    reserve: held ? const [2] : const [],
    level: level,
    difficulty: 4,
    unlocked_level: level,
    seed: 17,
    challenge_id: challenge_id,
    tools: {
      for (final tool in TileQuestTool.values)
        tool:
            TileQuestConfig.initial_tool_uses(tool) -
            (held && tool == TileQuestTool.remove ? 1 : 0),
    },
    tools_used: held ? 1 : 0,
  );
}

class _MotionHarness extends StatefulWidget {
  const _MotionHarness({
    super.key,
    required this.initial,
    this.animate_entry = true,
  });
  final TileQuestState initial;
  final bool animate_entry;

  @override
  State<_MotionHarness> createState() => _MotionHarnessState();
}

class _MotionHarnessState extends State<_MotionHarness> {
  late TileQuestEngine engine = TileQuestEngine(widget.initial);
  final actions = <TileQuestActionResult>[];
  final presentation_events = <bool>[];
  final tile_callbacks = <int>[];
  final reserve_callbacks = <int>[];
  final tool_callbacks = <TileQuestTool>[];
  bool sound = false;

  void _record(TileQuestActionResult result) {
    expect(result.accepted, isTrue, reason: result.reason);
    setState(() => actions.add(result));
  }

  void tap(int id) {
    tile_callbacks.add(id);
    _record(engine.tap_tile(id));
  }

  void tool(TileQuestTool tool) {
    tool_callbacks.add(tool);
    _record(switch (tool) {
      TileQuestTool.undo => engine.undo(),
      TileQuestTool.remove => engine.remove(),
      TileQuestTool.shuffle => engine.shuffle(seed: 18),
    });
  }

  void replace(TileQuestState state) => setState(() {
    engine = TileQuestEngine(state);
    actions.clear();
  });

  void rebuild_sound() => setState(() => sound = !sound);

  @override
  Widget build(BuildContext context) => TileQuestScene(
    state: engine.state,
    action: actions.lastOrNull,
    recent_actions: actions,
    animate_entry: widget.animate_entry,
    sound_enabled: sound,
    busy: false,
    can_undo: engine.can_undo,
    on_presentation_busy_changed: presentation_events.add,
    on_back: () {},
    on_restart: () {},
    on_sound: rebuild_sound,
    on_tile: tap,
    on_reserve: (id) {
      reserve_callbacks.add(id);
      _record(engine.return_reserve(id));
    },
    on_tool: tool,
  );
}

Future<GlobalKey<_MotionHarnessState>> _mount(
  WidgetTester tester, {
  TileQuestState? state,
  bool settle = false,
  bool animate_entry = true,
}) async {
  await tester.binding.setSurfaceSize(_scene_size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final host = GlobalKey<_MotionHarnessState>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _MotionHarness(
          key: host,
          initial: state ?? _fixture(),
          animate_entry: animate_entry,
        ),
      ),
    ),
  );
  await tester.pump();
  if (settle) await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return host;
}

Finder _key(String key) => find.byKey(ValueKey(key));

Rect _rect(WidgetTester tester, int id) => quest_scene_frames(tester)[id]!.rect;

int _type(WidgetTester tester, int id) {
  final frame = quest_scene_frames(tester)[id]!;
  return frame.previous_type != null && frame.face_progress <= 0
      ? frame.previous_type!
      : frame.type;
}

void _same_rect(Rect actual, Rect expected, {String? reason}) {
  expect(actual.left, closeTo(expected.left, .6), reason: reason);
  expect(actual.top, closeTo(expected.top, .6), reason: reason);
  expect(actual.width, closeTo(expected.width, .6), reason: reason);
  expect(actual.height, closeTo(expected.height, .6), reason: reason);
}

bool _at(Rect actual, Rect expected) =>
    (actual.center - expected.center).distance < .6;

void _ring(Rect rect, QuestSceneLayout layout) {
  final radius = QuestBoardMotion.shuffle_radius(layout);
  expect(
    (rect.center - layout.board.center).distance,
    closeTo(radius, .000001),
  );
}

void main() {
  test(
    'entrance geometry begins fully above screen and finishes at exact cells',
    () {
      final state = _fixture();
      for (final size in [
        const Size(320, 568),
        _scene_size,
        const Size(844, 390),
      ]) {
        final layout = QuestSceneLayout(size, state);
        for (var rank = 0; rank < state.tiles.length; rank++) {
          final tile = state.tiles[rank];
          final target = layout.board_tile(tile);
          final initial = QuestBoardMotion.entrance_rect(
            layout,
            tile,
            rank,
            state.tiles.length,
            0,
          );
          expect(initial.bottom, lessThanOrEqualTo(0));
          expect(initial.width, target.width);
          expect(initial.height, target.height);
          _same_rect(
            QuestBoardMotion.entrance_rect(
              layout,
              tile,
              rank,
              state.tiles.length,
              TileQuestStyle.entry_duration_ms,
            ),
            target,
          );
        }
        final first = state.tiles.first;
        final last = state.tiles.last;
        final first_start = QuestBoardMotion.entrance_rect(
          layout,
          first,
          0,
          18,
          0,
        );
        final last_start = QuestBoardMotion.entrance_rect(
          layout,
          last,
          17,
          18,
          0,
        );
        expect(
          QuestBoardMotion.entrance_rect(layout, first, 0, 18, 180).top,
          greaterThan(first_start.top),
        );
        _same_rect(
          QuestBoardMotion.entrance_rect(layout, last, 17, 18, 180),
          last_start,
          reason: 'later ranks must wait for their stagger',
        );
      }
    },
  );

  testWidgets(
    'all board cards including blocked tiles drop once without static ghosts',
    (tester) async {
      final state = _fixture();
      final host = await _mount(tester, state: state);
      final layout = QuestSceneLayout(_scene_size, state);
      expect(state.tiles.any((tile) => tile.is_blocked), isTrue);
      for (final tile in state.tiles) {
        expect(quest_scene_frames(tester)[tile.id]!.zone, QuestTileZone.entry);
        expect(_rect(tester, tile.id).bottom, lessThanOrEqualTo(0));
        expect(_key('tile_quest_tile_${tile.id}'), findsNothing);
      }
      expect(host.currentState!.presentation_events, [true]);
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        state.tiles.any((tile) => _rect(tester, tile.id).bottom > 0),
        isTrue,
      );
      await tester.pumpAndSettle();
      for (final tile in state.tiles) {
        expect(quest_scene_frames(tester)[tile.id]!.zone, QuestTileZone.board);
        _same_rect(_rect(tester, tile.id), layout.board_tile(tile));
      }
      expect(host.currentState!.presentation_events, [true, false]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('entry locks tile and tool input until the last card settles', (
    tester,
  ) async {
    final state = _fixture(level: 2);
    final host = await _mount(tester, state: state);
    final layout = QuestSceneLayout(_scene_size, state);
    await tester.tapAt(layout.board_tile(state.tile_by_id(9)).center);
    await tester.tap(_key('tile_quest_tool_shuffle'));
    await tester.pump(const Duration(milliseconds: 650));
    await tester.tapAt(_rect(tester, 9).center);
    expect(host.currentState!.tile_callbacks, isEmpty);
    expect(host.currentState!.tool_callbacks, isEmpty);
    expect(host.currentState!.engine.state.tray, isEmpty);
    await tester.pumpAndSettle();
    await tester.tapAt(_rect(tester, 9).center);
    expect(host.currentState!.tile_callbacks, [9]);
    expect(host.currentState!.engine.state.tray, [9]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'new challenges and the next level replay entry while sound rebuilds do not',
    (tester) async {
      final host = await _mount(tester, settle: true);
      for (final next in [
        _fixture(challenge_id: 'new-same-level'),
        _fixture(challenge_id: 'next-level', level: 2),
      ]) {
        host.currentState!.replace(next);
        await tester.pump();
        for (final tile in next.tiles) {
          expect(
            quest_scene_frames(tester)[tile.id]!.zone,
            QuestTileZone.entry,
          );
          expect(_rect(tester, tile.id).bottom, lessThanOrEqualTo(0));
        }
        await tester.pumpAndSettle();
        final layout = QuestSceneLayout(_scene_size, next);
        host.currentState!.rebuild_sound();
        await tester.pump();
        for (final tile in next.tiles) {
          expect(
            quest_scene_frames(tester)[tile.id]!.zone,
            QuestTileZone.board,
          );
          _same_rect(_rect(tester, tile.id), layout.board_tile(tile));
        }
      }
      expect(host.currentState!.presentation_events, [
        true,
        false,
        true,
        false,
        true,
        false,
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'shuffle geometry gathers every index, turns at least three times, then returns exactly',
    () {
      final state = _fixture(level: 2, held: true);
      final layout = QuestSceneLayout(_scene_size, state);
      final tiles = state.tiles.where((tile) => !tile.is_removed).toList();
      final gather = TileQuestStyle.shuffle_gather_fraction;
      final scatter = TileQuestStyle.shuffle_scatter_fraction;
      final angles = <int, double>{};
      for (var index = 0; index < tiles.length; index++) {
        final source = layout.board_tile(tiles[index]);
        _same_rect(
          QuestBoardMotion.shuffle_rect(layout, source, index, tiles.length, 0),
          source,
        );
        _same_rect(
          QuestBoardMotion.shuffle_rect(layout, source, index, tiles.length, 1),
          source,
        );
        final first = QuestBoardMotion.shuffle_rect(
          layout,
          source,
          index,
          tiles.length,
          gather,
        );
        final halfway = QuestBoardMotion.shuffle_rect(
          layout,
          source,
          index,
          tiles.length,
          (gather + scatter) / 2,
        );
        _ring(first, layout);
        _ring(halfway, layout);
        expect(
          (first.center - halfway.center).distance,
          greaterThan(math.min(layout.board.width, layout.board.height) * .4),
          reason: 'the turn must move past the opposite half of the circle',
        );
        var previous = math.atan2(
          first.center.dy - layout.board.center.dy,
          first.center.dx - layout.board.center.dx,
        );
        var total_angle = 0.0;
        for (var step = 1; step <= 40; step++) {
          final progress = gather + (scatter - gather) * step / 40;
          final rect = QuestBoardMotion.shuffle_rect(
            layout,
            source,
            index,
            tiles.length,
            progress,
          );
          _ring(rect, layout);
          final current = math.atan2(
            rect.center.dy - layout.board.center.dy,
            rect.center.dx - layout.board.center.dx,
          );
          var delta = current - previous;
          while (delta < -math.pi) {
            delta += math.pi * 2;
          }
          while (delta > math.pi) {
            delta -= math.pi * 2;
          }
          total_angle += delta;
          previous = current;
        }
        angles[index] = total_angle;
      }
      expect(angles, hasLength(tiles.length));
      for (final angle in angles.values) {
        expect(angle.abs(), greaterThanOrEqualTo(math.pi * 6));
        expect(angle.abs(), lessThan(math.pi * 8));
      }
    },
  );

  testWidgets(
    'shuffle includes blocked board cards once, preserves held cards and changes faces in its second half',
    (tester) async {
      final initial = _fixture(level: 2, held: true);
      final host = await _mount(tester, state: initial, settle: true);
      host.currentState!.presentation_events.clear();
      final held_rects = {
        for (final id in [...initial.tray, ...initial.reserve])
          id: _rect(tester, id),
      };
      final layout = QuestSceneLayout(_scene_size, initial);
      host.currentState!.tool(TileQuestTool.shuffle);
      final result = host.currentState!.actions.single;
      final board_ids = initial.tiles
          .where((tile) => !tile.is_removed)
          .map((tile) => tile.id)
          .toSet();
      expect(result.moved_ids.toSet(), board_ids);
      expect(board_ids.any((id) => initial.tile_by_id(id).is_blocked), isTrue);
      expect(
        board_ids.any(
          (id) =>
              initial.tile_by_id(id).type != result.after.tile_by_id(id).type,
        ),
        isTrue,
      );
      await tester.pump();
      for (final id in board_ids) {
        expect(quest_shuffle_frames(tester), contains(id));
        expect(_key('tile_quest_flight_$id'), findsNothing);
        expect(_key('tile_quest_tile_$id'), findsNothing);
        _same_rect(
          _rect(tester, id),
          layout.board_tile(initial.tile_by_id(id)),
        );
      }
      await tester.pump(
        Duration(
          milliseconds: (TileQuestStyle.shuffle_duration_ms * .3).round(),
        ),
      );
      final ring_centers = <String>{};
      for (final id in board_ids) {
        _ring(_rect(tester, id), layout);
        expect(_type(tester, id), initial.tile_by_id(id).type);
        final center = _rect(tester, id).center;
        ring_centers.add(
          '${center.dx.toStringAsFixed(3)},${center.dy.toStringAsFixed(3)}',
        );
      }
      expect(
        ring_centers,
        hasLength(board_ids.length),
        reason: 'every board id must occupy its own angle on the ring',
      );
      final first_ring = _rect(tester, board_ids.first);
      await tester.tapAt(first_ring.center);
      await tester.tapAt(_rect(tester, initial.reserve.single).center);
      await tester.tap(_key('tile_quest_tool_remove'));
      expect(host.currentState!.tile_callbacks, isEmpty);
      expect(host.currentState!.reserve_callbacks, isEmpty);
      expect(host.currentState!.tool_callbacks, [TileQuestTool.shuffle]);
      await tester.pump(
        Duration(
          milliseconds: (TileQuestStyle.shuffle_duration_ms * .3).round(),
        ),
      );
      for (final id in board_ids) {
        _ring(_rect(tester, id), layout);
        expect(_type(tester, id), result.after.tile_by_id(id).type);
      }
      expect(
        (_rect(tester, board_ids.first).center - first_ring.center).distance,
        greaterThan(math.min(layout.board.width, layout.board.height) * .1),
      );
      for (final entry in held_rects.entries) {
        _same_rect(_rect(tester, entry.key), entry.value);
        expect(_key('tile_quest_flight_${entry.key}'), findsNothing);
      }
      await tester.pumpAndSettle();
      for (final id in board_ids) {
        expect(_key('tile_quest_flight_$id'), findsNothing);
        _same_rect(
          _rect(tester, id),
          layout.board_tile(initial.tile_by_id(id)),
        );
      }
      expect(host.currentState!.presentation_events, [true, false]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rapid taps after entry land together before a queued shuffle', (
    tester,
  ) async {
    final host = await _mount(tester, state: _fixture(level: 2), settle: true);
    host.currentState!.presentation_events.clear();
    final first_source = _rect(tester, 9);
    final second_source = _rect(tester, 12);
    final first_slot = tester.getRect(_key('tile_quest_slot_0'));
    final second_slot = tester.getRect(_key('tile_quest_slot_1'));
    await tester.tapAt(first_source.center);
    await tester.tapAt(second_source.center);
    host.currentState!.tool(TileQuestTool.shuffle);
    expect(host.currentState!.engine.state.tray, [9, 12]);
    await tester.pump();
    int? first_arrival;
    int? second_arrival;
    // 航距不同时落槽帧不同：先到的停在槽内，等两枚都到达再收尾。
    for (var frame = 1; frame <= 300; frame++) {
      await tester.pump(_frame);
      if (_at(_rect(tester, 9), first_slot)) first_arrival ??= frame;
      if (_at(_rect(tester, 12), second_slot)) second_arrival ??= frame;
      if (first_arrival != null) _same_rect(_rect(tester, 9), first_slot);
      if (second_arrival != null) _same_rect(_rect(tester, 12), second_slot);
      if (first_arrival != null && second_arrival != null) break;
    }
    expect(first_arrival, isNotNull);
    expect(second_arrival, isNotNull);
    expect(
      math.max(first_arrival!, second_arrival!) * _frame.inMilliseconds,
      lessThanOrEqualTo(TileQuestStyle.flight_duration_max_ms),
      reason: 'rapid taps must land within the longest single hop',
    );
    await tester.pumpAndSettle();
    _same_rect(_rect(tester, 9), first_slot);
    _same_rect(_rect(tester, 12), second_slot);
    expect(host.currentState!.actions.map((action) => action.action), [
      TileQuestAction.tap,
      TileQuestAction.tap,
      TileQuestAction.shuffle,
    ]);
    expect(host.currentState!.presentation_events, [true, false]);
    expect(tester.takeException(), isNull);
  });
}
