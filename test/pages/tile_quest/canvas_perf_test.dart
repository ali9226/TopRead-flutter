// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/widgets/board_canvas.dart';
import 'package:app/pages/tile_quest/widgets/motion_canvas.dart';
import 'package:app/pages/tile_quest/widgets/quest_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scene_probe.dart';

const _size = Size(390, 844);
const _frame = Duration(milliseconds: 16);

/// 每层保留三十张完整三消库存，大牌局的首批 id 位于最上层。
TileQuestState _fixture({int count = 36}) {
  final tiles = [
    for (var id = 0; id < count; id++)
      TileQuestTile(
        id: id,
        type: (id ~/ 3) % TileQuestConfig.max_tile_types,
        layer: count > 60 ? (count - 1 - id) ~/ 30 : 0,
        x: (id % 6).toDouble(),
        y: (count > 60 ? (id % 30) ~/ 6 : id ~/ 6).toDouble(),
      ),
  ];
  return TileQuestState(
    tiles: TileQuestGeometry(tiles).refresh(tiles),
    level: 2,
    difficulty: 4,
    unlocked_level: 2,
    seed: 94,
    challenge_id: 'canvas-inventory-$count',
  );
}

/// 上方牌与下方牌错开半格，透明圆角内仍能看到下方实体牌面。
TileQuestState _overlap_fixture({required bool layered}) {
  final tiles = [
    const TileQuestTile(id: 0, type: 0, layer: 0, x: 0, y: 0),
    TileQuestTile(id: 1, type: 0, layer: layered ? 1 : 0, x: .5, y: .5),
    const TileQuestTile(id: 2, type: 0, layer: 0, x: 2, y: 0),
  ];
  return TileQuestState(
    tiles: TileQuestGeometry(tiles).refresh(tiles),
    level: 2,
    difficulty: 4,
    unlocked_level: 2,
    seed: 95,
    challenge_id: 'canvas-overlap-$layered',
  );
}

class _CanvasHarness extends StatefulWidget {
  const _CanvasHarness({
    super.key,
    required this.initial,
    this.animate_entry = false,
  });
  final TileQuestState initial;
  final bool animate_entry;

  @override
  State<_CanvasHarness> createState() => _CanvasHarnessState();
}

class _CanvasHarnessState extends State<_CanvasHarness> {
  late final engine = TileQuestEngine(widget.initial);
  final actions = <TileQuestActionResult>[];
  final tapped = <int>[];

  void tap(int id) {
    final result = engine.tap_tile(id);
    expect(result.accepted, isTrue, reason: result.reason);
    setState(() {
      tapped.add(id);
      actions.add(result);
    });
  }

  void tool(TileQuestTool tool) {
    final result = switch (tool) {
      TileQuestTool.undo => engine.undo(),
      TileQuestTool.remove => engine.remove(),
      TileQuestTool.shuffle => engine.shuffle(seed: 431),
    };
    expect(result.accepted, isTrue, reason: result.reason);
    setState(() => actions.add(result));
  }

  void metadata() => setState(() {
    engine.update_metadata(elapsed_ms: engine.state.elapsed_ms + 1000);
  });

  @override
  Widget build(BuildContext context) => TileQuestScene(
    state: engine.state,
    action: actions.lastOrNull,
    recent_actions: actions,
    animate_entry: widget.animate_entry,
    sound_enabled: false,
    busy: false,
    can_undo: engine.can_undo,
    on_back: () {},
    on_restart: () {},
    on_sound: () {},
    on_tile: tap,
    on_reserve: (id) {
      final result = engine.return_reserve(id);
      expect(result.accepted, isTrue, reason: result.reason);
      setState(() => actions.add(result));
    },
    on_tool: tool,
  );
}

Future<GlobalKey<_CanvasHarnessState>> _mount(
  WidgetTester tester,
  TileQuestState state, {
  bool animate_entry = false,
  bool settle = true,
}) async {
  await tester.binding.setSurfaceSize(_size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final key = GlobalKey<_CanvasHarnessState>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _CanvasHarness(
          key: key,
          initial: state,
          animate_entry: animate_entry,
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return key;
}

Finder _motion_surface() => find.byWidgetPredicate(
  (widget) => widget is CustomPaint && widget.painter is QuestMotionPainter,
);

int _scene_elements(WidgetTester tester) {
  var count = 0;
  void visit(Element element) {
    count++;
    element.visitChildren(visit);
  }

  visit(tester.element(find.byType(TileQuestScene)));
  return count;
}

void main() {
  testWidgets('scene node count stays fixed from 36 to 300 tiles', (
    tester,
  ) async {
    await _mount(tester, _fixture());
    final small_count = _scene_elements(tester);
    expect(quest_scene_frames(tester), hasLength(36));
    await _mount(tester, _fixture(count: 300));
    expect(quest_scene_frames(tester), hasLength(300));
    expect(_scene_elements(tester), small_count);
    expect(find.byType(QuestBoardCanvas), findsOneWidget);
    expect(find.byType(QuestMotionCanvas), findsOneWidget);
  });

  testWidgets('shuffle clock repaints stable widgets and render objects', (
    tester,
  ) async {
    final host = await _mount(tester, _fixture(count: 300));
    host.currentState!.tool(TileQuestTool.shuffle);
    await tester.pump();
    final scene_count = _scene_elements(tester);
    final canvas_widget = tester.widget<QuestMotionCanvas>(
      find.byType(QuestMotionCanvas),
    );
    final surface_widget = tester.widget<CustomPaint>(_motion_surface());
    final surface = tester.renderObject<RenderCustomPaint>(_motion_surface());
    final initial = quest_scene_frames(tester)[0]!.rect;
    var previous = initial;
    var moved_frames = 0;
    for (var frame = 0; frame < 70; frame++) {
      await tester.pump(_frame);
      expect(
        tester.widget(find.byType(QuestMotionCanvas)),
        same(canvas_widget),
      );
      expect(tester.widget(_motion_surface()), same(surface_widget));
      expect(tester.renderObject(_motion_surface()), same(surface));
      expect(_scene_elements(tester), scene_count);
      final current = quest_scene_frames(tester)[0]!.rect;
      if ((current.center - previous.center).distance > .001) moved_frames++;
      previous = current;
      expect(quest_scene_frames(tester), hasLength(300));
    }
    expect(moved_frames, greaterThan(60));
    expect((previous.center - initial.center).distance, greaterThan(1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('elapsed metadata does not invalidate the static board paint', (
    tester,
  ) async {
    final host = await _mount(tester, _fixture(count: 300));
    final before = tester.widget<QuestBoardCanvas>(
      find.byType(QuestBoardCanvas),
    );
    host.currentState!.metadata();
    await tester.pump();
    final after = tester.widget<QuestBoardCanvas>(
      find.byType(QuestBoardCanvas),
    );
    expect(after.painter.shouldRepaint(before.painter), isFalse);
    expect(after.painter.shouldRebuildSemantics(before.painter), isFalse);
  });

  testWidgets('entry owns each tile once until a queued action can start', (
    tester,
  ) async {
    final host = await _mount(
      tester,
      _fixture(count: 9),
      animate_entry: true,
      settle: false,
    );
    host.currentState!.tap(0);
    await tester.pump();
    expect(quest_scene_frames(tester), hasLength(9));
    expect(quest_scene_frames(tester)[0]!.zone, QuestTileZone.entry);
    await tester.pump(const Duration(milliseconds: 100));
    expect(quest_scene_frames(tester), hasLength(9));
    await tester.pumpAndSettle();
    expect(quest_scene_frames(tester), hasLength(9));
    expect(quest_scene_frames(tester)[0]!.zone, QuestTileZone.tray);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'same layer transparent corner passes through to the visible face',
    (tester) async {
      final host = await _mount(tester, _overlap_fixture(layered: false));
      final frames = quest_scene_frames(tester);
      final top = frames[1]!.rect;
      final visible_lower =
          top.topLeft + Offset(top.width * .005, top.height * .005);
      expect(frames[0]!.rect.contains(visible_lower), isTrue);
      await tester.tapAt(visible_lower);
      expect(host.currentState!.tapped, [0]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'layered hit testing preserves blocking and exposes the next face',
    (tester) async {
      final host = await _mount(tester, _overlap_fixture(layered: true));
      final frames = quest_scene_frames(tester);
      expect(frames[0]!.blocked, isTrue);
      final top = frames[1]!.rect;
      await tester.tapAt(
        top.topLeft + Offset(top.width * .005, top.height * .005),
      );
      expect(host.currentState!.tapped, isEmpty);
      await tester.tapAt(top.center);
      await tester.pump();
      expect(host.currentState!.tapped, [1]);
      final exposed = quest_scene_frames(tester)[0]!;
      expect(exposed.blocked, isFalse);
      await tester.tapAt(exposed.rect.center);
      await tester.pump();
      expect(host.currentState!.tapped, [1, 0]);
      expect(quest_scene_frames(tester).keys.toSet(), {0, 1, 2});
      await tester.pumpAndSettle();
    },
  );

  testWidgets('second Remove exposes reserve accessibility after it settles', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final host = await _mount(tester, _fixture());
      final controller = host.currentState!;
      for (final group in [
        [0, 3, 6],
        [9, 12, 15],
      ]) {
        for (final id in group) {
          controller.tap(id);
        }
        await tester.pumpAndSettle();
        controller.tool(TileQuestTool.remove);
        await tester.pumpAndSettle();
        for (final id in group) {
          expect(
            find.semantics.byLabel('Reserve tile $id').evaluate(),
            hasLength(1),
          );
          expect(quest_scene_frames(tester)[id]!.zone, QuestTileZone.reserve);
        }
      }
      expect(controller.engine.state.reserve, [0, 3, 6, 9, 12, 15]);
      for (final id in [0, 3, 6]) {
        expect(find.semantics.byLabel('Reserve tile $id').evaluate(), isEmpty);
      }
      tester.semantics.tap(find.semantics.byLabel('Reserve tile 9'));
      await tester.pumpAndSettle();
      expect(controller.engine.state.tray, [9]);
      expect(find.semantics.byLabel('Reserve tile 0').evaluate(), hasLength(1));
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
