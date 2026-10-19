// ignore_for_file: non_constant_identifier_names
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/widgets/board_canvas.dart';
import 'package:app/pages/tile_quest/widgets/board_reveal.dart';
import 'package:app/pages/tile_quest/widgets/motion_canvas.dart';
import 'package:app/pages/tile_quest/widgets/quest_scene.dart';
import 'package:app/pages/tile_quest/widgets/reveal_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TileQuestTile _tile(bool blocked, {bool removed = false, int id = 0}) =>
    TileQuestTile(
      id: id,
      type: 0,
      layer: 0,
      x: 0,
      y: 0,
      is_blocked: blocked,
      is_removed: removed,
    );

TileQuestState _fixture() {
  final tiles = [
    _tile(true),
    const TileQuestTile(id: 1, type: 0, layer: 1, x: .5, y: .5),
    const TileQuestTile(id: 2, type: 0, layer: 0, x: 2, y: 0),
    for (var id = 3; id < 6; id++)
      TileQuestTile(id: id, type: 1, layer: 0, x: (id - 3).toDouble(), y: 3),
  ];
  return TileQuestState(
    tiles: TileQuestGeometry(tiles).refresh(tiles),
    level: 1,
    seed: 1,
    challenge_id: 'reveal-test',
  );
}

class _RevealHarness extends StatefulWidget {
  const _RevealHarness({super.key});
  @override
  State<_RevealHarness> createState() => _RevealHarnessState();
}

class _RevealHarnessState extends State<_RevealHarness> {
  final engine = TileQuestEngine(_fixture());
  final actions = <TileQuestActionResult>[];
  void tap(int id) {
    final result = engine.tap_tile(id);
    expect(result.accepted, isTrue);
    setState(() => actions.add(result));
  }

  void undo() {
    final result = engine.undo();
    expect(result.accepted, isTrue);
    setState(() => actions.add(result));
  }

  void shuffle() {
    final result = engine.shuffle(seed: 3);
    expect(result.accepted, isTrue, reason: result.reason);
    setState(() => actions.add(result));
  }

  @override
  Widget build(BuildContext context) => TileQuestScene(
    state: engine.state,
    action: actions.lastOrNull,
    recent_actions: actions,
    animate_entry: false,
    sound_enabled: false,
    busy: false,
    on_back: () {},
    on_restart: () {},
    on_sound: () {},
    on_tile: tap,
    on_reserve: (_) {},
    on_tool: (_) {},
  );
}

QuestBoardPainter _painter(WidgetTester tester) =>
    tester.widget<QuestBoardCanvas>(find.byType(QuestBoardCanvas)).painter;

void main() {
  test('reveal fades continuously and returns to an idle painter', () {
    final reveal = QuestBoardReveal()..reset([_tile(true)]);
    addTearDown(reveal.dispose);
    var notifications = 0;
    reveal.addListener(() => notifications++);
    reveal.update([_tile(false)], 10);
    expect(reveal.amount_of(0, blocked: false), 1);
    expect(reveal.is_animating, isTrue);
    reveal.advance(10 + QuestRevealStyle.duration_ms / 2);
    expect(reveal.amount_of(0, blocked: false), closeTo(.5, 1e-10));
    reveal.advance(10 + QuestRevealStyle.duration_ms);
    expect(reveal.amount_of(0, blocked: false), 0);
    expect(reveal.is_animating, isFalse);
    final settled_notifications = notifications;
    reveal.advance(1000);
    reveal.advance(2000);
    expect(notifications, settled_notifications);
  });

  test('rapid Undo/reblock preserves brightness and its velocity', () {
    final reveal = QuestBoardReveal()..reset([_tile(true)]);
    addTearDown(reveal.dispose);
    reveal.update([_tile(false)], 0);
    final before = reveal.sample_at(0, 70, blocked: false);
    reveal.update([_tile(true)], 70);
    final after = reveal.sample_at(0, 70, blocked: true);
    expect(after.amount, closeTo(before.amount, 1e-12));
    expect(after.velocity, closeTo(before.velocity, 1e-12));
    for (var now = 70.0; now <= 290; now += 1) {
      final sample = reveal.sample_at(0, now, blocked: true);
      expect(sample.amount, inInclusiveRange(0, 1));
    }
    reveal.advance(290);
    expect(reveal.amount_of(0, blocked: true), 1);
    expect(reveal.is_animating, isFalse);
  });

  test(
    'reserve exposure and return use the same shade trajectory as board cards',
    () {
      final tiles = [_tile(false, removed: true)];
      final reveal = QuestBoardReveal()
        ..reset(tiles, blocked_overrides: {0: true});
      addTearDown(reveal.dispose);
      expect(reveal.amount_of(0, blocked: true), 1);
      reveal.update(tiles, 0, blocked_overrides: {0: false});
      reveal.advance(80);
      final exposed = reveal.amount_of(0, blocked: false);
      expect(exposed, inExclusiveRange(0, 1));
      // 回到棋盘/入槽时移出reserve覆写，不得丢失未完成的淡出轨迹。
      reveal.update(tiles, 80);
      expect(reveal.amount_of(0, blocked: false), closeTo(exposed, 1e-10));
      reveal.update(tiles, 100, blocked_overrides: {0: true});
      final before = reveal.sample_at(0, 100, blocked: true);
      expect(before.amount, inExclusiveRange(0, 1));
      reveal.advance(320);
      expect(reveal.amount_of(0, blocked: true), 1);
    },
  );

  test(
    'flying IDs keep their fade; missing IDs and new challenges discard it',
    () {
      final reveal = QuestBoardReveal()..reset([_tile(true)]);
      addTearDown(reveal.dispose);
      reveal.update([_tile(false)], 0);
      reveal.update([_tile(false, removed: true)], 40);
      expect(reveal.is_animating, isTrue);
      expect(reveal.amount_of(0, blocked: false), inExclusiveRange(0, 1));
      reveal.update([], 50);
      expect(reveal.is_animating, isFalse);
      reveal.reset([_tile(false)]);
      expect(reveal.amount_of(0, blocked: false), 0);
      reveal.update([_tile(true)], 0, animate: false);
      expect(reveal.amount_of(0, blocked: true), 1);
      expect(reveal.is_animating, isFalse);
    },
  );

  testWidgets(
    'real scene unlocks immediately while the shade fades on canvas',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final key = GlobalKey<_RevealHarnessState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: _RevealHarness(key: key)),
        ),
      );
      await tester.pumpAndSettle();
      key.currentState!.tap(1);
      await tester.pump();
      var painter = _painter(tester);
      var frame = painter.frames.singleWhere((frame) => frame.id == 0);
      expect(frame.blocked, isFalse);
      expect(painter.reveal_amount_of(frame), 1);
      await tester.pump(const Duration(milliseconds: 80));
      painter = _painter(tester);
      frame = painter.frames.singleWhere((frame) => frame.id == 0);
      final partial = painter.reveal_amount_of(frame);
      expect(partial, inExclusiveRange(0, 1));
      await tester.binding.setSurfaceSize(const Size(844, 390));
      await tester.pump();
      painter = _painter(tester);
      frame = painter.frames.singleWhere((frame) => frame.id == 0);
      expect(painter.reveal_amount_of(frame), closeTo(partial, 1e-10));
      // 淡出尚未完成，下层仍可立刻点击；不会等待视觉遮罩结束。
      key.currentState!.tap(0);
      await tester.pump();
      expect(_painter(tester).frames.any((frame) => frame.id == 0), isFalse);
      final motion = tester.widget<QuestMotionCanvas>(
        find.byType(QuestMotionCanvas),
      );
      final flying = motion.painter.frames.singleWhere(
        (frame) => frame.id == 0,
      );
      expect(flying.blocked_amount, closeTo(partial, 1e-10));
      await tester.pump(const Duration(milliseconds: 40));
      final next = motion.painter.frames.singleWhere((frame) => frame.id == 0);
      expect(next.blocked_amount!, lessThan(partial));
      expect(next.blocked_amount!, greaterThan(0));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Undo during a reveal darkens from its current visible shade', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey<_RevealHarnessState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: _RevealHarness(key: key)),
      ),
    );
    await tester.pumpAndSettle();
    key.currentState!.tap(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    var painter = _painter(tester);
    var frame = painter.frames.singleWhere((frame) => frame.id == 0);
    final before = painter.reveal_amount_of(frame);
    key.currentState!.undo();
    await tester.pump();
    painter = _painter(tester);
    frame = painter.frames.singleWhere((frame) => frame.id == 0);
    expect(frame.blocked, isTrue);
    expect(painter.reveal_amount_of(frame), closeTo(before, 1e-10));
    await tester.pumpAndSettle();
    painter = _painter(tester);
    frame = painter.frames.singleWhere((frame) => frame.id == 0);
    expect(painter.reveal_amount_of(frame), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('queued shuffle keeps an unfinished reveal instead of flashing', (
    tester,
  ) async {
    final key = GlobalKey<_RevealHarnessState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: _RevealHarness(key: key)),
      ),
    );
    await tester.pumpAndSettle();
    key.currentState!.tap(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final board = _painter(tester);
    final before = board.reveal_amount_of(
      board.frames.singleWhere((frame) => frame.id == 0),
    );
    key.currentState!.shuffle();
    await tester.pump();
    final motion = tester.widget<QuestMotionCanvas>(
      find.byType(QuestMotionCanvas),
    );
    var frame = motion.painter.frames.singleWhere((frame) => frame.id == 0);
    expect(frame.blocked_amount, closeTo(before, 1e-10));
    await tester.pump(const Duration(milliseconds: 40));
    frame = motion.painter.frames.singleWhere((frame) => frame.id == 0);
    expect(frame.blocked_amount!, inExclusiveRange(0, before));
    await tester.pumpAndSettle();
    final settled = _painter(tester);
    final tile = settled.frames.singleWhere((frame) => frame.id == 0);
    expect(settled.reveal_amount_of(tile), 0);
    expect(tester.takeException(), isNull);
  });
}
