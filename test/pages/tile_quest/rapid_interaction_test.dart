// ignore_for_file: non_constant_identifier_names
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/logic.dart';
import 'package:app/pages/tile_quest/services/feedback_service.dart';
import 'package:app/pages/tile_quest/services/save_service.dart';
import 'package:app/pages/tile_quest/services/work_service.dart';
import 'package:app/pages/tile_quest/widgets/quest_scene.dart';
import 'package:app/pages/tile_quest/widgets/scene_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'scene_probe.dart';

const _portrait = Size(390, 844);
const _frame = Duration(milliseconds: 16);

/// 完整三张库存。大牌局分成每层30张，按id从上往下移除，全部动作合法。
TileQuestState _fixture({
  int count = 36,
  int first_id = 0,
  String challenge = 'rapid-interaction',
}) {
  final tiles = [
    for (var index = 0; index < count; index++)
      TileQuestTile(
        id: first_id + index,
        type: (index ~/ 3) % TileQuestConfig.max_tile_types,
        layer: count > 60 ? (count - 1 - index) ~/ 30 : 0,
        x: (index % 6).toDouble(),
        y: (count > 60 ? (index % 30) ~/ 6 : index ~/ 6).toDouble(),
      ),
  ];
  return TileQuestState(
    tiles: TileQuestGeometry(tiles).refresh(tiles),
    level: 2,
    difficulty: 4,
    unlocked_level: 2,
    seed: 97,
    challenge_id: challenge,
  );
}

TileQuestState _covered_fixture() {
  final tiles = [
    const TileQuestTile(id: 0, type: 0, layer: 0, x: 0, y: 0),
    const TileQuestTile(id: 1, type: 0, layer: 1, x: 0, y: 0),
    const TileQuestTile(id: 2, type: 0, layer: 0, x: 2, y: 0),
    for (var id = 3; id < 6; id++)
      TileQuestTile(id: id, type: 1, layer: 0, x: (id - 3).toDouble(), y: 2),
  ];
  return TileQuestState(
    tiles: TileQuestGeometry(tiles).refresh(tiles),
    level: 1,
    seed: 98,
    challenge_id: 'newly-uncovered',
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
    difficulty: 4,
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

class _RapidHarness extends StatefulWidget {
  const _RapidHarness({
    super.key,
    required this.initial,
    this.logic,
    this.animate_entry = false,
  });
  final TileQuestState initial;
  final TileQuestLogic? logic;
  final bool animate_entry;
  @override
  State<_RapidHarness> createState() => _RapidHarnessState();
}

class _RapidHarnessState extends State<_RapidHarness> {
  late TileQuestEngine engine = TileQuestEngine(widget.initial);
  final actions = <TileQuestActionResult>[];
  final busy_events = <bool>[];
  TileQuestState get current => widget.logic?.state ?? engine.state;
  void refresh() => setState(() {});
  void record(TileQuestActionResult result) {
    expect(
      result.accepted,
      isTrue,
      reason: '${result.action}: ${result.reason}',
    );
    setState(() => actions.add(result));
  }

  void tap(int id) => record(engine.tap_tile(id));
  void tool(TileQuestTool tool) => record(switch (tool) {
    TileQuestTool.undo => engine.undo(),
    TileQuestTool.remove => engine.remove(),
    TileQuestTool.shuffle => engine.shuffle(seed: 431),
  });
  void reserve(int id) => record(engine.return_reserve(id));
  void replace(TileQuestState state) => setState(() {
    engine = TileQuestEngine(state);
    actions.clear();
  });
  @override
  Widget build(BuildContext context) => TileQuestScene(
    state: current,
    action: widget.logic?.last_action ?? actions.lastOrNull,
    recent_actions: widget.logic?.recent_actions ?? actions,
    animate_entry: widget.animate_entry,
    sound_enabled: false,
    busy: false,
    can_undo: widget.logic?.can_undo ?? engine.can_undo,
    on_presentation_busy_changed: busy_events.add,
    on_back: () {},
    on_restart: () {},
    on_sound: () {},
    on_tile: tap,
    on_reserve: reserve,
    on_tool: tool,
  );
}

Future<GlobalKey<_RapidHarnessState>> _mount(
  WidgetTester tester, {
  TileQuestState? state,
  TileQuestLogic? logic,
  bool animate_entry = false,
}) async {
  await tester.binding.setSurfaceSize(_portrait);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final key = GlobalKey<_RapidHarnessState>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _RapidHarness(
          key: key,
          initial: state ?? _fixture(),
          logic: logic,
          animate_entry: animate_entry,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  key.currentState!.busy_events.clear();
  expect(tester.takeException(), isNull);
  return key;
}

/// 读取真实绘制帧；探针会对棋盘、动作和洗牌画布之间的重复牌直接报错。
Map<int, Rect> _visuals(WidgetTester tester) {
  final result = <int, Rect>{};
  for (final frame in quest_scene_frames(tester).values) {
    final rect = frame.rect;
    expect(
      [rect.left, rect.top, rect.width, rect.height].every((v) => v.isFinite),
      isTrue,
    );
    expect(rect.width, greaterThan(0));
    expect(rect.height, greaterThan(0));
    result[frame.id] = rect;
  }
  return result;
}

void _same(Rect actual, Rect expected) {
  expect((actual.center - expected.center).distance, lessThan(.7));
  expect(actual.width, closeTo(expected.width, .7));
  expect(actual.height, closeTo(expected.height, .7));
}

void _settled(WidgetTester tester, TileQuestState state, Size size) {
  final actual = _visuals(tester);
  final ids = {
    ...state.tiles.where((tile) => !tile.is_removed).map((tile) => tile.id),
    ...state.tray,
    ...state.reserve,
  };
  expect(actual.keys.toSet(), ids);
  final layout = QuestSceneLayout(size, state);
  for (final id in ids) {
    _same(actual[id]!, layout.location(state, id));
  }
  expect(
    quest_scene_frames(
      tester,
    ).values.where((frame) => frame.zone == QuestTileZone.flight),
    isEmpty,
  );
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets(
    'more than 256 production controller transactions in one frame preserve the first flight',
    (tester) async {
      final service = TileQuestSaveService(
        encode_snapshot: encode_tile_quest_snapshot,
        store: _MemoryStore(),
      );
      final logic = TileQuestLogic(
        save_service: service,
        work_service: _FixtureWork(_fixture(count: 300)),
        feedback_service: _QuietFeedback(),
        next_seed: () => 97,
        now_ms: () => 0,
        enable_timer: false,
      );
      await logic.initialize();
      addTearDown(logic.onClose);
      final host = await _mount(tester, state: logic.state, logic: logic);
      final first_source = _visuals(tester)[0]!;
      for (var id = 0; id < 300; id++) {
        expect((await logic.tap_tile(id))?.accepted, isTrue);
      }
      expect(logic.state!.status, TileQuestStatus.won);
      host.currentState!.refresh();
      await tester.pump();
      final first_frame = _visuals(tester);
      expect(
        first_frame[0],
        isNotNull,
        reason:
            'the earliest accepted action cannot disappear before its flight',
      );
      _same(first_frame[0]!, first_source);
      expect(first_frame.length, 300);
      await tester.pump(const Duration(minutes: 10));
      await tester.pumpAndSettle();
      _settled(tester, logic.state!, _portrait);
      expect(host.currentState!.busy_events, [true, false]);
    },
  );

  testWidgets(
    'a newly uncovered lower card can join an upper card still flying without overtaking',
    (tester) async {
      final host = await _mount(tester, state: _covered_fixture());
      final initial = _visuals(tester);
      await tester.tapAt(initial[1]!.center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(host.currentState!.current.tile_by_id(0).is_blocked, isFalse);
      await tester.tapAt(_visuals(tester)[0]!.center);
      expect(host.currentState!.current.tray, [1, 0]);
      await tester.pump();
      final arrivals = <int, int>{};
      for (var frame = 0; frame < 50; frame++) {
        await tester.pump(_frame);
        final actual = _visuals(tester);
        final layout = QuestSceneLayout(_portrait, host.currentState!.current);
        for (final id in [1, 0]) {
          if ((actual[id]!.center - layout.tray_tile(id == 1 ? 0 : 1).center)
                  .distance <
              .7) {
            arrivals.putIfAbsent(id, () => frame);
          }
        }
      }
      expect(arrivals.keys.toList(), [1, 0]);
      expect(arrivals[1], lessThan(arrivals[0]!));
      await tester.pumpAndSettle();
      _settled(tester, host.currentState!.current, _portrait);
      expect(host.currentState!.busy_events, [true, false]);
    },
  );

  testWidgets(
    'rapid taps interleaved with two Removes Undo reserve returns and Shuffle never duplicate or jump',
    (tester) async {
      final host = await _mount(tester);
      final controller = host.currentState!;
      for (final id in [0, 3, 6, 9, 12, 15]) {
        controller.tap(id);
      }
      controller.tool(TileQuestTool.remove);
      for (final id in [18, 21, 24]) {
        controller.tap(id);
      }
      controller.tool(TileQuestTool.remove);
      controller.reserve(9);
      controller.tool(TileQuestTool.undo);
      controller.reserve(9);
      controller.reserve(0);
      controller.tool(TileQuestTool.shuffle);
      await tester.pump();
      var previous = _visuals(tester);
      for (var frame = 0; frame < 400; frame++) {
        await tester.pump(_frame);
        final current = _visuals(tester);
        expect(
          current.length,
          36,
          reason: 'no match is pending so every card must retain one visual',
        );
        for (final id in current.keys) {
          if (previous.containsKey(id)) {
            expect(
              (current[id]!.center - previous[id]!.center).distance,
              lessThan(90),
              reason: 'tile $id jumps between queued containers',
            );
          }
        }
        previous = current;
        if (controller.busy_events.lastOrNull == false) break;
      }
      await tester.pumpAndSettle();
      _settled(tester, controller.current, _portrait);
      expect(controller.current.reserve, [3, 6, 12, 15]);
      expect(controller.busy_events, [true, false]);
    },
  );

  testWidgets(
    'queued shuffle never duplicates a tile currently flying toward Undo',
    (tester) async {
      final host = await _mount(tester);
      final controller = host.currentState!;
      controller.tap(0);
      controller.tool(TileQuestTool.undo);
      controller.tool(TileQuestTool.shuffle);
      await tester.pump();
      for (var frame = 0; frame < 180; frame++) {
        await tester.pump(_frame);
        expect(_visuals(tester).length, 36);
        if (controller.busy_events.lastOrNull == false) break;
      }
      await tester.pumpAndSettle();
      _settled(tester, controller.current, _portrait);
      expect(controller.busy_events, [true, false]);
    },
  );

  testWidgets(
    'changing challenge discards every old flight and queued tool even with reused ids',
    (tester) async {
      final host = await _mount(tester, animate_entry: true);
      for (final fresh_ids in [true, false]) {
        final controller = host.currentState!;
        final old_ids = controller.current.tiles.map((tile) => tile.id).toSet();
        for (final id
            in controller.current.tiles.take(3).map((tile) => tile.id)) {
          controller.tap(id);
        }
        controller.tool(TileQuestTool.undo);
        controller.tool(TileQuestTool.remove);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 48));
        final next = _fixture(first_id: 1000, challenge: 'reset-$fresh_ids');
        controller.replace(next);
        await tester.pump();
        final after_reset = _visuals(tester);
        expect(
          after_reset.keys.toSet(),
          next.tiles.map((tile) => tile.id).toSet(),
        );
        if (fresh_ids) {
          expect(after_reset.keys.toSet().intersection(old_ids), isEmpty);
        }
        expect(after_reset.values.every((rect) => rect.bottom <= 0), isTrue);
        await tester.pumpAndSettle();
        _settled(tester, next, _portrait);
        expect(controller.busy_events.last, isFalse);
        await tester.pump(const Duration(seconds: 20));
        _settled(tester, next, _portrait);
      }
    },
  );

  testWidgets(
    'resize midway through queued motions preserves inventory and final square coordinates',
    (tester) async {
      final host = await _mount(tester);
      final controller = host.currentState!;
      for (final id in [0, 3, 6]) {
        controller.tap(id);
      }
      controller.tool(TileQuestTool.remove);
      controller.reserve(0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 112));
      for (final size in [
        const Size(844, 390),
        const Size(320, 568),
        const Size(768, 1024),
      ]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pump();
        expect(_visuals(tester).length, 36);
        await tester.pump(const Duration(milliseconds: 112));
        expect(_visuals(tester).length, 36);
      }
      await tester.pumpAndSettle();
      _settled(tester, controller.current, const Size(768, 1024));
      for (final rect in _visuals(tester).values) {
        expect(rect.width, closeTo(rect.height, .001));
      }
      expect(controller.busy_events, [true, false]);
    },
  );

  testWidgets(
    'long frame catches up mixed matches tools and shuffle without stale sprites or a stuck clock',
    (tester) async {
      final host = await _mount(tester);
      final controller = host.currentState!;
      for (final id in [0, 1, 2, 3, 6, 9]) {
        controller.tap(id);
      }
      controller.tool(TileQuestTool.remove);
      controller.reserve(3);
      controller.tool(TileQuestTool.undo);
      controller.tool(TileQuestTool.shuffle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 48));
      _visuals(tester);
      await tester.pump(const Duration(minutes: 10));
      await tester.pumpAndSettle();
      _settled(tester, controller.current, _portrait);
      expect(controller.busy_events, [true, false]);
      final remaining = controller.current.clickable_tiles.first.id;
      controller.tap(remaining);
      await tester.pumpAndSettle();
      _settled(tester, controller.current, _portrait);
      expect(controller.busy_events, [true, false, true, false]);
    },
  );
}
