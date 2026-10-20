// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/index.dart';
import 'package:app/pages/tile_quest/logic.dart';
import 'package:app/pages/tile_quest/services/feedback_service.dart';
import 'package:app/pages/tile_quest/services/save_service.dart';
import 'package:app/pages/tile_quest/services/work_service.dart';
import 'package:app/pages/tile_quest/widgets/quest_controls.dart';
import 'package:app/pages/tile_quest/widgets/quest_result.dart';
import 'package:app/pages/tile_quest/widgets/quest_scene.dart';
import 'package:app/pages/tile_quest/widgets/slot_wells.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'scene_probe.dart';

const _portrait = Size(390, 844);
const _epsilon = .000001;

/// 场景消费真实引擎事务，测试不改变第一关的工具规则或牌局结构。
class _TutorialHarness extends StatefulWidget {
  const _TutorialHarness({
    super.key,
    required this.initial,
    this.animate_entry = true,
  });

  final TileQuestState initial;
  final bool animate_entry;

  @override
  State<_TutorialHarness> createState() => _TutorialHarnessState();
}

class _TutorialHarnessState extends State<_TutorialHarness> {
  late TileQuestEngine engine = TileQuestEngine(widget.initial);
  final actions = <TileQuestActionResult>[];

  void _record(TileQuestActionResult result) {
    expect(result.accepted, isTrue, reason: result.reason);
    setState(() => actions.add(result));
  }

  void tap(int id) => _record(engine.tap_tile(id));

  void replace(TileQuestState state) => setState(() {
    engine = TileQuestEngine(state);
    actions.clear();
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
    on_reserve: (id) => _record(engine.return_reserve(id)),
    on_tool: (tool) => _record(switch (tool) {
      TileQuestTool.undo => engine.undo(),
      TileQuestTool.shuffle => engine.shuffle(seed: 2027),
      TileQuestTool.remove => engine.remove(),
    }),
  );
}

class _TutorialStore implements TileQuestSaveStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

class _TutorialFeedback implements TileQuestFeedbackService {
  @override
  Future<void> play(TileQuestFeedbackEvent event) async {}
}

/// 直接调用生产生成器，页面仍经过全新第一关、真实胜利和下一关流程。
class _TutorialWork implements TileQuestWorkService {
  @override
  Future<TileQuestState> generate({
    required int level,
    required int seed,
    required int unlocked_level,
    String? challenge_id,
  }) async => TileQuestGenerator.generate(
    level: level,
    seed: seed,
    unlocked_level: unlocked_level,
    challenge_id: challenge_id,
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

Finder _key(String name) => find.byKey(ValueKey(name));

Finder get _reserve_cards => find.byWidgetPredicate((widget) {
  final key = widget.key;
  return key is ValueKey<String> && key.value.startsWith('tile_quest_reserve_');
});

/// 除视觉组件外同时检查语义树，防止只透明或禁用却仍朗读道具入口。
void _expect_tutorial_controls() {
  expect(find.byType(QuestToolButton), findsNothing);
  expect(find.byType(QuestReserveWell), findsNothing);
  expect(_reserve_cards, findsNothing);
  expect(
    find.bySemanticsLabel(
      RegExp(r'Undo|Shuffle|Remove|RESERVE|Tap the top tile to return'),
    ),
    findsNothing,
  );
  expect(find.byType(QuestSlotWell), findsOneWidget);
  for (var index = 0; index < 7; index++) {
    expect(_key('tile_quest_slot_$index'), findsOneWidget);
  }
}

void _expect_normal_controls() {
  expect(find.byType(QuestToolButton), findsNWidgets(3));
  expect(find.byType(QuestReserveWell), findsOneWidget);
  for (final tool in TileQuestTool.values) {
    expect(_key('tile_quest_tool_${tool.name}'), findsOneWidget);
  }
  for (var column = 0; column < 3; column++) {
    expect(_key('tile_quest_reserve_slot_$column'), findsOneWidget);
  }
  expect(find.byType(QuestSlotWell), findsOneWidget);
}

/// 关卡模板保留真实同层间隙，第二关的逻辑牌略小于一格。
/// 比较每逻辑格的显示尺度，防止把明确设计的留缝误判成关卡切换缩放。
void _expect_shared_card_scale(
  Rect first_rect,
  TileQuestTile first_tile,
  Rect second_rect,
  TileQuestTile second_tile,
) {
  expect(
    second_rect.width / second_tile.width,
    closeTo(first_rect.width / first_tile.width, _epsilon),
  );
  expect(
    second_rect.height / second_tile.height,
    closeTo(first_rect.height / first_tile.height, _epsilon),
  );
}

Future<GlobalKey<_TutorialHarnessState>> _mount_scene(
  WidgetTester tester,
  TileQuestState state, {
  bool animate_entry = true,
}) async {
  final key = GlobalKey<_TutorialHarnessState>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _TutorialHarness(
          key: key,
          initial: state,
          animate_entry: animate_entry,
        ),
      ),
    ),
  );
  return key;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'tutorial entry, tile flights and victory keep only the main tray controls',
    (tester) async {
      await tester.binding.setSurfaceSize(_portrait);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final initial = TileQuestGenerator.generate(level: 1, seed: 730);
      final host = await _mount_scene(tester, initial);
      // 包括入场中的第一帧，隐藏入口不能先闪现再消失。
      _expect_tutorial_controls();
      await tester.pump(const Duration(milliseconds: 100));
      _expect_tutorial_controls();
      await tester.pumpAndSettle();

      final first = initial.certified_solution.first;
      await tester.tapAt(quest_scene_frames(tester)[first]!.rect.center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(quest_scene_frames(tester)[first]!.zone, QuestTileZone.flight);
      _expect_tutorial_controls();
      await tester.pumpAndSettle();
      expect(quest_scene_frames(tester)[first]!.zone, QuestTileZone.tray);
      _expect_tutorial_controls();

      for (final id in initial.certified_solution.skip(1)) {
        host.currentState!.tap(id);
      }
      expect(host.currentState!.engine.state.status, TileQuestStatus.won);
      await tester.pump();
      _expect_tutorial_controls();
      await tester.pumpAndSettle();
      _expect_tutorial_controls();
      expect(host.currentState!.engine.state.tray, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('second level keeps three tools and an interactive reserve', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(_portrait);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = TileQuestGenerator.generate(level: 2, seed: 730);
    final host = await _mount_scene(tester, state, animate_entry: false);
    await tester.pumpAndSettle();
    _expect_normal_controls();
    expect(find.bySemanticsLabel(RegExp(r'Remove 2')), findsOneWidget);
    final id = state.clickable_tiles.first.id;
    await tester.tapAt(quest_scene_frames(tester)[id]!.rect.center);
    await tester.pumpAndSettle();
    await tester.tap(_key('tile_quest_tool_remove'));
    await tester.pumpAndSettle();
    expect(host.currentState!.engine.state.reserve, <int>[id]);
    expect(quest_scene_frames(tester)[id]!.zone, QuestTileZone.reserve);
    _expect_normal_controls();
    await tester.tapAt(quest_scene_frames(tester)[id]!.rect.center);
    await tester.pumpAndSettle();
    expect(host.currentState!.engine.state.reserve, isEmpty);
    expect(host.currentState!.engine.state.tray, <int>[id]);
    expect(tester.takeException(), isNull);
  });

  for (final size in <Size>[
    const Size(320, 568),
    _portrait,
    const Size(844, 390),
  ]) {
    testWidgets(
      'hidden tutorial controls preserve shared card and tray geometry at $size',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final tutorial = TileQuestGenerator.generate(level: 1, seed: 730);
        final main = TileQuestGenerator.generate(level: 2, seed: 730);
        final host = await _mount_scene(tester, tutorial, animate_entry: false);
        await tester.pumpAndSettle();
        final tutorial_card = quest_scene_frames(
          tester,
        )[tutorial.clickable_tiles.first.id]!.rect;
        final tutorial_slot = tester.getRect(_key('tile_quest_slot_0'));
        final tutorial_tray = tester.getRect(find.byType(QuestSlotWell));
        _expect_tutorial_controls();
        host.currentState!.replace(main);
        await tester.pumpAndSettle();
        _expect_normal_controls();
        final main_card = quest_scene_frames(
          tester,
        )[main.clickable_tiles.first.id]!.rect;
        _expect_shared_card_scale(
          tutorial_card,
          tutorial.clickable_tiles.first,
          main_card,
          main.clickable_tiles.first,
        );
        expect(tester.getRect(_key('tile_quest_slot_0')), tutorial_slot);
        expect(tester.getRect(find.byType(QuestSlotWell)), tutorial_tray);
        host.currentState!.replace(
          TileQuestGenerator.generate(level: 1, seed: 731),
        );
        await tester.pumpAndSettle();
        _expect_tutorial_controls();
        expect(tester.getRect(_key('tile_quest_slot_0')), tutorial_slot);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'page wins tutorial, enters level two and confirms restart back to tutorial controls',
    (tester) async {
      await tester.binding.setSurfaceSize(_portrait);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final saves = TileQuestSaveService(
        encode_snapshot: encode_tile_quest_snapshot,
        store: _TutorialStore(),
      );
      final logic = TileQuestLogic(
        save_service: saves,
        work_service: _TutorialWork(),
        feedback_service: _TutorialFeedback(),
        next_seed: () => 730,
        now_ms: () => 0,
        enable_timer: false,
      );
      await tester.pumpWidget(MaterialApp(home: TileQuestPage(logic: logic)));
      await tester.pumpAndSettle();
      expect(logic.state!.level, 1);
      _expect_tutorial_controls();
      final first_tile = logic.state!.clickable_tiles.first;
      final first_rect = quest_scene_frames(tester)[first_tile.id]!.rect;
      for (final id in logic.state!.certified_solution.toList()) {
        expect((await logic.tap_tile(id))!.accepted, isTrue);
      }
      await tester.pumpAndSettle();
      expect(find.byType(QuestResult), findsOneWidget);
      _expect_tutorial_controls();
      await tester.tap(_key('tile_quest_result_primary'));
      await tester.pumpAndSettle();
      expect(logic.state!.level, 2);
      _expect_normal_controls();
      final main_tile = logic.state!.clickable_tiles.first;
      _expect_shared_card_scale(
        first_rect,
        first_tile,
        quest_scene_frames(tester)[main_tile.id]!.rect,
        main_tile,
      );
      await tester.tap(_key('tile_quest_settings'));
      await tester.pumpAndSettle();
      await tester.tap(_key('tile_quest_restart'));
      await tester.pumpAndSettle();
      await tester.tap(_key('tile_quest_confirm_restart'));
      await tester.pumpAndSettle();
      expect(logic.state!.level, 1);
      _expect_tutorial_controls();
      final restarted_tile = logic.state!.clickable_tiles.first;
      _expect_shared_card_scale(
        first_rect,
        first_tile,
        quest_scene_frames(tester)[restarted_tile.id]!.rect,
        restarted_tile,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await saves.flush();
      expect(tester.takeException(), isNull);
    },
  );
}
