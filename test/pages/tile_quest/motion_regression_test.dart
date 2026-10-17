// ignore_for_file: non_constant_identifier_names
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/index.dart';
import 'package:app/pages/tile_quest/logic.dart';
import 'package:app/pages/tile_quest/services/feedback_service.dart';
import 'package:app/pages/tile_quest/services/save_service.dart';
import 'package:app/pages/tile_quest/services/work_service.dart';
import 'package:app/pages/tile_quest/widgets/quest_result.dart';
import 'package:app/pages/tile_quest/widgets/quest_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _frame = Duration(milliseconds: 8);

/// Three complete, unobscured tile groups keep the fixture valid under the
/// production engine's inventory and geometry validation.
TileQuestState _fixture({List<int> tray = const []}) => TileQuestState(
  tiles: [
    for (var id = 0; id < 9; id++)
      TileQuestTile(
        id: id,
        type: [0, 4, 2][id ~/ 3],
        layer: 0,
        x: (id % 3).toDouble(),
        y: (id ~/ 3).toDouble(),
        is_removed: tray.contains(id),
      ),
  ],
  tray: tray,
  level: 2,
  unlocked_level: 2,
  seed: 17,
  challenge_id: 'motion-regression',
);

class _SceneHarness extends StatefulWidget {
  const _SceneHarness({super.key, required this.initial_state});
  final TileQuestState initial_state;

  @override
  State<_SceneHarness> createState() => _SceneHarnessState();
}

class _SceneHarnessState extends State<_SceneHarness> {
  late final engine = TileQuestEngine(widget.initial_state);
  final actions = <TileQuestActionResult>[];
  final presentation_events = <bool>[];

  void _record(TileQuestActionResult result) {
    if (result.accepted) setState(() => actions.add(result));
  }

  void tap(int id) => _record(engine.tap_tile(id));

  void tool(TileQuestTool tool) => _record(switch (tool) {
    TileQuestTool.undo => engine.undo(),
    TileQuestTool.remove => engine.remove(),
    TileQuestTool.shuffle => engine.shuffle(seed: 18),
  });

  void return_reserve(int id) => _record(engine.return_reserve(id));

  @override
  Widget build(BuildContext context) => TileQuestScene(
    state: engine.state,
    action: actions.lastOrNull,
    recent_actions: actions,
    sound_enabled: false,
    busy: false,
    can_undo: engine.can_undo,
    on_presentation_busy_changed: presentation_events.add,
    on_back: () {},
    on_restart: () {},
    on_sound: () {},
    on_tile: tap,
    on_reserve: return_reserve,
    on_tool: tool,
  );
}

class _MemoryStore implements TileQuestSaveStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async => this.value = value;
}

class _QuietFeedback implements TileQuestFeedbackService {
  @override
  Future<void> play(TileQuestFeedbackEvent event) async {}
}

/// 全新进入应通过生成边界注入测试牌局，不能依赖恢复旧活局。
class _FixtureWork implements TileQuestWorkService {
  _FixtureWork(this.fixture);
  final TileQuestState fixture;

  @override
  Future<TileQuestState> generate({
    required int level,
    required int seed,
    required int unlocked_level,
    String? challenge_id,
  }) async => TileQuestState(
    tiles: fixture.tiles,
    level: level,
    seed: seed,
    unlocked_level: unlocked_level,
    challenge_id: challenge_id!,
  );

  @override
  Future<TileQuestPreparedShuffle> shuffle(
    Map<String, dynamic> engine_json, {
    required int seed,
  }) async {
    final engine = TileQuestEngine.restore(engine_json);
    return TileQuestPreparedShuffle(
      engine: engine,
      result: engine.shuffle(seed: seed),
    );
  }
}

Future<GlobalKey<_SceneHarnessState>> _mount(
  WidgetTester tester, {
  TileQuestState? state,
  Size size = const Size(390, 844),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final key = GlobalKey<_SceneHarnessState>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _SceneHarness(key: key, initial_state: state ?? _fixture()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  key.currentState!.presentation_events.clear();
  return key;
}

Rect _slot(WidgetTester tester, int index) =>
    tester.getRect(find.byKey(ValueKey('tile_quest_slot_$index')));

Rect? _tile(WidgetTester tester, int id) {
  Rect? result;
  for (final key in [
    'tile_quest_flight_$id',
    'tray_$id',
    'tile_quest_tile_$id',
    'tile_quest_reserve_$id',
  ]) {
    final finder = find.byKey(ValueKey(key));
    if (finder.evaluate().isNotEmpty) {
      expect(finder, findsOneWidget, reason: 'tile $id has one visible copy');
      expect(result, isNull, reason: 'tile $id cannot exist in two containers');
      result = tester.getRect(finder);
    }
  }
  return result;
}

bool _at(Rect? rect, Rect destination) =>
    rect != null &&
    (rect.center - destination.center).distance < .6 &&
    (rect.width - destination.width).abs() < .6 &&
    (rect.height - destination.height).abs() < .6;

void _same_rect(Rect actual, Rect expected, {String? reason}) {
  expect(actual.center.dx, closeTo(expected.center.dx, .6), reason: reason);
  expect(actual.center.dy, closeTo(expected.center.dy, .6), reason: reason);
  expect(actual.width, closeTo(expected.width, .6), reason: reason);
  expect(actual.height, closeTo(expected.height, .6), reason: reason);
}

void main() {
  testWidgets('same-frame rapid taps arrive in order and never rewind a tile', (
    tester,
  ) async {
    final host = await _mount(tester);
    final first_source = _tile(tester, 0)!;
    final second_source = _tile(tester, 3)!;
    final first_slot = _slot(tester, 0);
    final second_slot = _slot(tester, 1);
    expect(
      (second_source.center - second_slot.center).distance,
      lessThan((first_source.center - first_slot.center).distance),
      reason: 'the later tap starts closer to its tray slot',
    );

    // Both real on_tile callbacks run before a single widget frame is rendered.
    await tester.tapAt(first_source.center);
    await tester.tapAt(second_source.center);
    expect(host.currentState!.engine.state.tray, [0, 3]);
    await tester.pump();
    _same_rect(_tile(tester, 0)!, first_source);
    _same_rect(_tile(tester, 3)!, second_source);

    int? first_arrival;
    int? second_arrival;
    var saw_first_in_transit = false;
    var saw_second_in_transit = false;
    for (var frame = 1; frame <= 300; frame++) {
      await tester.pump(_frame);
      final first = _tile(tester, 0);
      final second = _tile(tester, 3);
      if (first != null &&
          !_at(first, first_source) &&
          !_at(first, first_slot)) {
        saw_first_in_transit = true;
      }
      if (second != null &&
          !_at(second, second_source) &&
          !_at(second, second_slot)) {
        saw_second_in_transit = true;
      }
      if (_at(first, first_slot)) first_arrival ??= frame;
      if (_at(second, second_slot)) second_arrival ??= frame;
      if (first_arrival != null) {
        _same_rect(
          first!,
          first_slot,
          reason: 'an already landed tile must not jump back to the board',
        );
      }
      if (second_arrival != null) break;
    }
    expect(saw_first_in_transit, isTrue);
    expect(saw_second_in_transit, isTrue);
    expect(first_arrival, isNotNull);
    expect(second_arrival, isNotNull);
    expect(
      first_arrival!,
      lessThan(second_arrival!),
      reason: 'the closer later tile must still land after the first tap',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'third strawberry inserts at slot five, shifts followers, then closes gap',
    (tester) async {
      final host = await _mount(
        tester,
        state: _fixture(tray: [0, 1, 3, 4, 6, 7]),
      );
      final slots = [for (var i = 0; i < 7; i++) _slot(tester, i)];
      _same_rect(_tile(tester, 3)!, slots[2]);
      _same_rect(_tile(tester, 4)!, slots[3]);
      _same_rect(_tile(tester, 6)!, slots[4]);
      _same_rect(_tile(tester, 7)!, slots[5]);

      await tester.tapAt(_tile(tester, 5)!.center);
      expect(host.currentState!.engine.state.tray, [0, 1, 6, 7]);
      await tester.pump();

      var saw_rightward_transition = false;
      var saw_inserted_strawberry = false;
      var saw_leftward_transition = false;
      var saw_final_slots = false;
      for (var frame = 1; frame <= 300; frame++) {
        await tester.pump(_frame);
        final strawberry = _tile(tester, 5);
        final first_follower = _tile(tester, 6)!;
        final second_follower = _tile(tester, 7)!;
        if (!saw_inserted_strawberry) {
          expect(
            first_follower.center.dx,
            greaterThanOrEqualTo(slots[4].center.dx - .6),
            reason: 'slot five cannot collapse left before the match lands',
          );
          expect(
            second_follower.center.dx,
            greaterThanOrEqualTo(slots[5].center.dx - .6),
          );
          if (first_follower.center.dx > slots[4].center.dx + .6 &&
              first_follower.center.dx < slots[5].center.dx - .6 &&
              second_follower.center.dx > slots[5].center.dx + .6 &&
              second_follower.center.dx < slots[6].center.dx - .6) {
            saw_rightward_transition = true;
          }
          expect(
            _at(strawberry, slots[6]),
            isFalse,
            reason: 'the third strawberry must not fly into the last slot',
          );
        }
        if (!saw_inserted_strawberry && _at(strawberry, slots[4])) {
          saw_inserted_strawberry = true;
          _same_rect(first_follower, slots[5]);
          _same_rect(second_follower, slots[6]);
          _same_rect(_tile(tester, 3)!, slots[2]);
          _same_rect(_tile(tester, 4)!, slots[3]);
        }
        if (saw_inserted_strawberry &&
            first_follower.center.dx > slots[2].center.dx + .6 &&
            first_follower.center.dx < slots[5].center.dx - .6 &&
            second_follower.center.dx > slots[3].center.dx + .6 &&
            second_follower.center.dx < slots[6].center.dx - .6) {
          saw_leftward_transition = true;
        }
        if (saw_inserted_strawberry &&
            _tile(tester, 3) == null &&
            _tile(tester, 4) == null &&
            strawberry == null &&
            _at(first_follower, slots[2]) &&
            _at(second_follower, slots[3])) {
          saw_final_slots = true;
          break;
        }
      }
      expect(saw_rightward_transition, isTrue);
      expect(saw_inserted_strawberry, isTrue);
      expect(saw_leftward_transition, isTrue);
      expect(saw_final_slots, isTrue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a rapid triple preserves each source until its ordered arrival',
    (tester) async {
      final host = await _mount(tester);
      final sources = [for (var id = 0; id < 3; id++) _tile(tester, id)!];
      for (var id = 0; id < 3; id++) {
        await tester.tapAt(sources[id].center);
      }
      expect(host.currentState!.engine.state.tray, isEmpty);
      expect(host.currentState!.engine.state.matched_count, 3);
      await tester.pump();
      for (var id = 0; id < 3; id++) {
        _same_rect(_tile(tester, id)!, sources[id]);
      }

      final arrivals = <int, int>{};
      var saw_match_before_last_arrival = false;
      for (var frame = 1; frame <= 300; frame++) {
        await tester.pump(_frame);
        final current = [for (var id = 0; id < 3; id++) _tile(tester, id)];
        for (var id = 0; id < 3; id++) {
          if (_at(current[id], _slot(tester, id))) {
            arrivals.putIfAbsent(id, () => frame);
          }
        }
        if (current.contains(null) && !arrivals.containsKey(2)) {
          saw_match_before_last_arrival = true;
        }
        if (arrivals.length == 3 && _tile(tester, 2) == null) break;
      }
      expect(arrivals.keys.toList(), [0, 1, 2]);
      expect(arrivals[0]!, lessThan(arrivals[1]!));
      expect(arrivals[1]!, lessThan(arrivals[2]!));
      expect(saw_match_before_last_arrival, isFalse);
      await tester.pumpAndSettle();
      for (var id = 0; id < 3; id++) {
        expect(_tile(tester, id), isNull);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tap, undo and retap keep one continuous visual for the same id',
    (tester) async {
      final host = await _mount(tester);
      final source = _tile(tester, 0)!;
      final destination = _slot(tester, 0);
      host.currentState!.tap(0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      host.currentState!.tool(TileQuestTool.undo);
      host.currentState!.tap(0);
      expect(host.currentState!.actions.length, 3);
      await tester.pump();

      var previous = _tile(tester, 0)!;
      var first_landed = false;
      var returned_to_board = false;
      var landed_again = false;
      for (var frame = 0; frame < 300; frame++) {
        await tester.pump(_frame);
        final current = _tile(tester, 0)!;
        expect(
          (current.center - previous.center).distance,
          lessThan(70),
          reason: 'queued undo and retap must join their predecessor endpoints',
        );
        previous = current;
        if (_at(current, destination)) {
          if (returned_to_board) {
            landed_again = true;
            break;
          }
          first_landed = true;
        }
        if (first_landed && _at(current, source)) returned_to_board = true;
      }
      expect(first_landed, isTrue);
      expect(returned_to_board, isTrue);
      expect(landed_again, isTrue);
      await tester.pumpAndSettle();
      expect(host.currentState!.engine.state.tray, [0]);
      expect(host.currentState!.presentation_events, [true, false]);
      _same_rect(_tile(tester, 0)!, destination);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('undo restores preceding match positions despite a future match', (
    tester,
  ) async {
    final host = await _mount(
      tester,
      state: _fixture(tray: [0, 1, 3, 4, 6, 7]),
    );
    final slots = [
      for (var index = 0; index < 7; index++) _slot(tester, index),
    ];
    // A later queued strawberry match occupies slots 1–3 after the stars clear.
    // It must not replace the earlier strawberry match's undo source at 3–5.
    host.currentState!.tap(5);
    host.currentState!.tool(TileQuestTool.undo);
    host.currentState!.tap(2);
    host.currentState!.tap(5);
    expect(host.currentState!.actions.length, 4);
    await tester.pump();

    var saw_cleared_pair = false;
    var saw_undo_pair = false;
    for (var frame = 0; frame < 300; frame++) {
      await tester.pump(_frame);
      final first = _tile(tester, 3);
      final second = _tile(tester, 4);
      if (first == null && second == null) saw_cleared_pair = true;
      if (saw_cleared_pair && first != null && second != null) {
        _same_rect(first, slots[2]);
        _same_rect(second, slots[3]);
        saw_undo_pair = true;
        break;
      }
    }
    expect(saw_cleared_pair, isTrue);
    expect(saw_undo_pair, isTrue);
    await tester.pumpAndSettle();
    expect(host.currentState!.engine.state.tray, [6, 7]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rapid taps then Remove and return keep the other reserve columns fixed',
    (tester) async {
      final host = await _mount(tester);
      for (final id in [0, 3, 6]) {
        host.currentState!.tap(id);
      }
      host.currentState!.tool(TileQuestTool.remove);
      await tester.pump();
      for (var frame = 0; frame < 300; frame++) {
        await tester.pump(_frame);
        for (final id in [0, 3, 6]) {
          expect(_tile(tester, id), isNotNull);
        }
        if (host.currentState!.presentation_events.lastOrNull == false) break;
      }
      expect(host.currentState!.engine.state.reserve, [0, 3, 6]);
      final return_source = _tile(tester, 0)!;
      final return_target = _slot(tester, 0);
      final first_neighbor_source = _tile(tester, 3)!;
      final second_neighbor_source = _tile(tester, 6)!;
      await tester.tapAt(return_source.center);
      await tester.pump();
      _same_rect(_tile(tester, 3)!, first_neighbor_source);
      _same_rect(_tile(tester, 6)!, second_neighbor_source);

      var saw_return_in_motion = false;
      for (var frame = 0; frame < 300; frame++) {
        await tester.pump(_frame);
        final incoming = _tile(tester, 0)!;
        _same_rect(_tile(tester, 3)!, first_neighbor_source);
        _same_rect(_tile(tester, 6)!, second_neighbor_source);
        if (!_at(incoming, return_source) && !_at(incoming, return_target)) {
          saw_return_in_motion = true;
        }
        if (_at(incoming, return_target)) break;
      }
      expect(saw_return_in_motion, isTrue);
      await tester.pumpAndSettle();
      expect(host.currentState!.engine.state.tray, [0]);
      expect(host.currentState!.engine.state.reserve, [3, 6]);
      _same_rect(_tile(tester, 0)!, return_target);
      _same_rect(_tile(tester, 3)!, first_neighbor_source);
      _same_rect(_tile(tester, 6)!, second_neighbor_source);
      expect(host.currentState!.presentation_events, [
        true,
        false,
        true,
        false,
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  for (final won in [true, false]) {
    testWidgets(
      '${won ? 'win' : 'loss'} result waits from the first motion frame',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final state = TileQuestState(
          tiles: [
            for (var id = 0; id < (won ? 3 : 21); id++)
              TileQuestTile(
                id: id,
                type: won ? 0 : id % 7,
                layer: 0,
                x: (id % 7).toDouble(),
                y: (id ~/ 7).toDouble(),
              ),
          ],
          level: 1,
          seed: 17,
          challenge_id: 'result-presentation-$won',
        );
        final saves = TileQuestSaveService(store: _MemoryStore());
        final logic = TileQuestLogic(
          save_service: saves,
          work_service: _FixtureWork(state),
          feedback_service: _QuietFeedback(),
          next_seed: () => 17,
          enable_timer: false,
        );
        await tester.pumpWidget(MaterialApp(home: TileQuestPage(logic: logic)));
        await tester.pumpAndSettle();
        for (var id = 0; id < (won ? 3 : 7); id++) {
          await logic.tap_tile(id);
        }
        expect(
          logic.state!.status,
          won ? TileQuestStatus.won : TileQuestStatus.lost,
        );
        await tester.pump();
        expect(
          find.byType(QuestResult),
          findsNothing,
          reason:
              'the first queued frame cannot create a premature result layer',
        );
        var saw_result = false;
        for (var frame = 0; frame < 300; frame++) {
          await tester.pump(_frame);
          if (find.byType(QuestResult).evaluate().isNotEmpty) {
            for (var id = 0; id < (won ? 3 : 7); id++) {
              expect(
                find.byKey(ValueKey('tile_quest_flight_$id')),
                findsNothing,
                reason: 'the result opens after the whole flight queue settles',
              );
            }
            saw_result = true;
            break;
          }
        }
        expect(saw_result, isTrue);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    testWidgets('tray squares and landing coincide at $size', (tester) async {
      await _mount(tester, size: size);
      final slots = [for (var i = 0; i < 7; i++) _slot(tester, i)];
      for (final slot in slots) {
        expect(slot.width, closeTo(slot.height, .01));
        expect(slot.width, greaterThan(0));
        expect(slot.left, greaterThanOrEqualTo(0));
        expect(slot.right, lessThanOrEqualTo(size.width));
        expect(slot.top, greaterThanOrEqualTo(0));
        expect(slot.bottom, lessThanOrEqualTo(size.height));
      }
      await tester.tapAt(_tile(tester, 0)!.center);
      await tester.pumpAndSettle();
      _same_rect(_tile(tester, 0)!, slots[0]);
      expect(tester.takeException(), isNull);
    });
  }
}
