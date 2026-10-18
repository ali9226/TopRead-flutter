// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/game/validator.dart';
import 'package:app/pages/tile_quest/widgets/quest_controls.dart';
import 'package:app/pages/tile_quest/widgets/quest_scene.dart';
import 'package:app/pages/tile_quest/widgets/motion_canvas.dart';
import 'package:app/pages/tile_quest/widgets/scene_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'scene_probe.dart';

const _frame = Duration(milliseconds: 8);
const _tolerance = .01;

/// 每种图案恰有三张；前两批各三张互不相同，避免测试道具时自动三消。
TileQuestState _fixture() => TileQuestState(
  tiles: <TileQuestTile>[
    for (var id = 0; id < 18; id++)
      TileQuestTile(
        id: id,
        type: id % 6,
        layer: 0,
        x: (id % 6).toDouble(),
        y: (id ~/ 6).toDouble(),
      ),
  ],
  level: 2,
  difficulty: 4,
  unlocked_level: 2,
  seed: 2026,
  challenge_id: 'stacked-reserve-layout',
);

/// 按真实规则同步提交事务，由生产场景独立消费动画和实际点击。
class _ReserveHarness extends StatefulWidget {
  const _ReserveHarness({super.key});

  @override
  State<_ReserveHarness> createState() => _ReserveHarnessState();
}

class _ReserveHarnessState extends State<_ReserveHarness> {
  final TileQuestEngine engine = TileQuestEngine(_fixture());
  final List<TileQuestActionResult> actions = <TileQuestActionResult>[];
  final List<int> reserve_attempts = <int>[];
  bool presentation_busy = false;

  void _record(TileQuestActionResult result) {
    if (result.accepted) setState(() => actions.add(result));
  }

  void tap(int id) => _record(engine.tap_tile(id));

  void return_reserve(int id) {
    reserve_attempts.add(id);
    _record(engine.return_reserve(id));
  }

  void tool(TileQuestTool tool) => _record(switch (tool) {
    TileQuestTool.undo => engine.undo(),
    TileQuestTool.shuffle => engine.shuffle(seed: 2027),
    TileQuestTool.remove => engine.remove(),
  });

  @override
  Widget build(BuildContext context) => TileQuestScene(
    state: engine.state,
    action: actions.lastOrNull,
    recent_actions: actions,
    sound_enabled: false,
    busy: false,
    can_undo: engine.can_undo,
    on_presentation_busy_changed: (value) => presentation_busy = value,
    on_back: () {},
    on_restart: () {},
    on_sound: () {},
    on_tile: tap,
    on_reserve: return_reserve,
    on_tool: tool,
  );
}

Future<GlobalKey<_ReserveHarnessState>> _mount(WidgetTester tester) async {
  const size = Size(390, 844);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final key = GlobalKey<_ReserveHarnessState>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: _ReserveHarness(key: key)),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

Finder get _remove => find.byWidgetPredicate(
  (widget) => widget is QuestToolButton && widget.tool == TileQuestTool.remove,
);

Rect _slot(WidgetTester tester, int index) =>
    tester.getRect(find.byKey(ValueKey('tile_quest_slot_$index')));

/// 持牌、飞牌和棋盘牌中的同一 id 每帧必须只有一个可见副本。
Rect _visible_rect(WidgetTester tester, int id) {
  final frame = quest_scene_frames(tester)[id];
  expect(frame, isNotNull, reason: 'tile $id has one rendered location');
  return frame!.rect;
}

QuestMotionPainter _motion_painter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((widget) => widget.painter)
    .whereType<QuestMotionPainter>()
    .single;

void _same_rect(Rect actual, Rect expected, {String? reason}) {
  expect(actual.left, closeTo(expected.left, _tolerance), reason: reason);
  expect(actual.top, closeTo(expected.top, _tolerance), reason: reason);
  expect(actual.width, closeTo(expected.width, _tolerance), reason: reason);
  expect(actual.height, closeTo(expected.height, _tolerance), reason: reason);
}

void _inventory(TileQuestState state) {
  expect(
    state.remaining_count +
        state.tray.length +
        state.reserve.length +
        state.matched_count,
    state.total_count,
  );
  TileQuestValidator.validate_state(state);
}

bool _has_return_callback(WidgetTester tester, int id) {
  final frame = quest_scene_frames(tester)[id];
  return frame?.zone == QuestTileZone.reserve &&
      !frame!.blocked &&
      _motion_painter(tester).can_return(id);
}

void _counter(String value) {
  expect(
    find.descendant(of: _remove, matching: find.text(value)),
    findsOneWidget,
  );
}

Future<void> _tap_board(WidgetTester tester, int id) async {
  await tester.tapAt(_visible_rect(tester, id).center);
  await tester.pumpAndSettle();
}

/// 逐帧观察移出动作，验证两批牌飞行期间均不丢失或复制，最后精确入槽。
Future<void> _remove_batch(
  WidgetTester tester,
  _ReserveHarnessState host,
  List<int> batch,
  List<int> all_held,
) async {
  for (final id in batch) {
    await _tap_board(tester, id);
  }
  await tester.tap(find.byKey(const ValueKey('tile_quest_tool_remove')));
  await tester.pump();
  var saw_flight = false;
  for (var frame = 0; frame < 150; frame++) {
    await tester.pump(_frame);
    for (final id in all_held) {
      _visible_rect(tester, id);
      saw_flight |=
          quest_scene_frames(tester)[id]?.zone == QuestTileZone.flight;
    }
    _inventory(host.engine.state);
    if (!host.presentation_busy) break;
  }
  expect(saw_flight, isTrue);
  await tester.pumpAndSettle();
  final layout = QuestSceneLayout(const Size(390, 844), host.engine.state);
  for (final id in all_held) {
    expect(quest_scene_frames(tester)[id]?.zone, QuestTileZone.reserve);
    _same_rect(
      _visible_rect(tester, id),
      layout.reserve_tile(
        host.engine.state.reserve_column(id),
        depth: host.engine.state.reserve_depth(id),
      ),
      reason: 'tile $id lands at its stable column and stack depth',
    );
  }
  expect(host.engine.state.tray, isEmpty);
  _inventory(host.engine.state);
}

void main() {
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
    test('reserve stacks sit above equal-sized tray tiles at $size', () {
      final layout = QuestSceneLayout(size, _fixture());
      final tray_tile = layout.tray_tile(0);
      expect(layout.reserve.bottom, lessThanOrEqualTo(layout.tray.top));
      expect(layout.tray.bottom, lessThanOrEqualTo(layout.tools.top));
      for (var column = 0; column < TileQuestConfig.reserve_columns; column++) {
        for (var depth = 0; depth < 2; depth++) {
          final tile = layout.reserve_tile(column, depth: depth);
          expect(tile.width, closeTo(tray_tile.width, _tolerance));
          expect(tile.height, closeTo(tray_tile.height, _tolerance));
          expect(tile.left, greaterThanOrEqualTo(layout.reserve.left));
          expect(tile.right, lessThanOrEqualTo(layout.reserve.right));
          expect(tile.top, greaterThanOrEqualTo(layout.reserve.top));
          expect(tile.bottom, lessThanOrEqualTo(layout.reserve.bottom));
        }
      }
    });
  }

  testWidgets(
    'two Removes count down, preserve six tiles and land in two layers',
    (tester) async {
      final host = (await _mount(tester)).currentState!;
      _counter('2/2');
      await _remove_batch(tester, host, <int>[0, 1, 2], <int>[0, 1, 2]);
      _counter('1/2');
      final bottom_positions = <int, Rect>{
        for (final id in <int>[0, 1, 2]) id: _visible_rect(tester, id),
      };
      await _remove_batch(
        tester,
        host,
        <int>[3, 4, 5],
        <int>[0, 1, 2, 3, 4, 5],
      );
      _counter('0/2');
      expect(host.engine.state.reserve, <int>[0, 1, 2, 3, 4, 5]);
      expect(host.engine.state.tools[TileQuestTool.remove], 0);
      for (final id in <int>[0, 1, 2]) {
        _same_rect(_visible_rect(tester, id), bottom_positions[id]!);
      }
      final remove_ink = tester.widget<InkWell>(
        find.byKey(const ValueKey('tile_quest_tool_remove')),
      );
      expect(remove_ink.onTap, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('only stack tops return; another column never slides sideways', (
    tester,
  ) async {
    final host = (await _mount(tester)).currentState!;
    await _remove_batch(tester, host, <int>[0, 1, 2], <int>[0, 1, 2]);
    await _remove_batch(tester, host, <int>[3, 4, 5], <int>[0, 1, 2, 3, 4, 5]);
    final before = <int, Rect>{
      for (final id in <int>[0, 1, 2, 3, 4, 5]) id: _visible_rect(tester, id),
    };
    for (final id in <int>[0, 1, 2]) {
      expect(_has_return_callback(tester, id), isFalse);
    }
    for (final id in <int>[3, 4, 5]) {
      expect(_has_return_callback(tester, id), isTrue);
    }
    final paint_order = quest_scene_frames(tester).keys.toList();
    for (var column = 0; column < 3; column++) {
      final lower_index = paint_order.indexOf(column);
      final upper_index = paint_order.indexOf(column + 3);
      expect(lower_index, greaterThanOrEqualTo(0));
      expect(
        upper_index,
        greaterThan(lower_index),
        reason: 'each upper tile paints after the tile it covers',
      );
    }
    final exposed_lower_point = <Offset>[
      before[0]!.bottomCenter - const Offset(0, 1),
      before[0]!.topCenter + const Offset(0, 1),
      before[0]!.centerLeft + const Offset(1, 0),
      before[0]!.centerRight - const Offset(1, 0),
    ].firstWhere((point) => !before[3]!.contains(point));
    await tester.tapAt(exposed_lower_point);
    await tester.pumpAndSettle();
    expect(
      host.reserve_attempts,
      isEmpty,
      reason: 'an exposed edge of a covered tile cannot invoke its callback',
    );
    expect(host.engine.state.reserve, hasLength(6));

    await tester.tapAt(before[3]!.center);
    await tester.pump();
    expect(host.reserve_attempts, <int>[3]);
    var saw_return_flight = false;
    for (var frame = 0; frame < 150; frame++) {
      await tester.pump(_frame);
      final frames = quest_scene_frames(tester);
      if (frames[3]?.zone == QuestTileZone.flight) {
        saw_return_flight = true;
        final paint_order = frames.keys.toList();
        expect(
          paint_order.indexOf(3),
          greaterThan(paint_order.indexOf(0)),
          reason: 'the returning top tile paints above the newly exposed tile',
        );
      }
      for (final id in <int>[0, 1, 2, 4, 5]) {
        _same_rect(
          _visible_rect(tester, id),
          before[id]!,
          reason: 'returning 3 does not move reserve tile $id',
        );
      }
      _inventory(host.engine.state);
      if (!host.presentation_busy) break;
    }
    expect(saw_return_flight, isTrue);
    await tester.pumpAndSettle();
    _same_rect(_visible_rect(tester, 3), _slot(tester, 0));
    expect(host.engine.state.reserve, <int>[0, 1, 2, 4, 5]);
    expect(host.engine.state.is_reserve_available(0), isTrue);
    expect(_has_return_callback(tester, 0), isTrue);
    expect(_has_return_callback(tester, 1), isFalse);
    expect(_has_return_callback(tester, 2), isFalse);
    await tester.tapAt(before[0]!.center);
    await tester.pumpAndSettle();
    expect(host.reserve_attempts, <int>[3, 0]);
    expect(host.engine.state.tray, <int>[3, 0]);
    for (final id in <int>[1, 2, 4, 5]) {
      _same_rect(_visible_rect(tester, id), before[id]!);
    }
    _inventory(host.engine.state);
    expect(tester.takeException(), isNull);
  });
}
