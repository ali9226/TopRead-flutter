// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/index.dart';
import 'package:app/pages/tile_quest/logic.dart';
import 'package:app/pages/tile_quest/services/feedback_service.dart';
import 'package:app/pages/tile_quest/services/save_service.dart';
import 'package:app/pages/tile_quest/services/work_service.dart';
import 'package:app/pages/tile_quest/widgets/quest_controls.dart';
import 'package:app/pages/tile_quest/widgets/quest_result.dart';
import 'package:app/pages/tile_quest/widgets/quest_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 只延迟真正的存储边界，仍由生产队列捕获和顺序提交每张快照。
class _RaceStore implements TileQuestSaveStore {
  String? value;
  Completer<void>? write_gate;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    await write_gate?.future;
    this.value = value;
  }
}

class _RaceFeedback
    implements TileQuestFeedbackService, TileQuestFeedbackLifecycle {
  final events = <TileQuestFeedbackEvent>[];
  int stop_count = 0;

  @override
  Future<void> play(TileQuestFeedbackEvent event) async => events.add(event);

  @override
  Future<void> prepare() async {}

  @override
  Future<void> stop() async => stop_count++;

  @override
  Future<void> dispose() async {}
}

/// 小型真实规则牌局让竞态仅取决于受控的工作边界，不依赖生成耗时。
class _RaceWork implements TileQuestWorkService {
  int tile_count = 9;
  int generation_count = 0;
  int shuffle_count = 0;
  Completer<void>? generation_gate;
  Completer<void>? shuffle_gate;

  @override
  Future<TileQuestState> generate({
    required int level,
    required int seed,
    required int unlocked_level,
    String? challenge_id,
  }) async {
    generation_count++;
    await generation_gate?.future;
    return TileQuestState(
      tiles: <TileQuestTile>[
        for (var id = 0; id < tile_count; id++)
          TileQuestTile(
            id: id,
            type: (id ~/ 3) % 3,
            layer: 0,
            x: (id % 18).toDouble(),
            y: (id ~/ 18).toDouble(),
          ),
      ],
      level: level,
      difficulty: 4,
      seed: seed,
      unlocked_level: unlocked_level,
      challenge_id: challenge_id!,
    );
  }

  @override
  Future<TileQuestPreparedShuffle> shuffle(
    Map<String, dynamic> engine_json, {
    required int seed,
  }) async {
    shuffle_count++;
    await shuffle_gate?.future;
    final engine = TileQuestEngine.restore(engine_json);
    return TileQuestPreparedShuffle(
      engine: engine,
      result: engine.shuffle(seed: seed),
    );
  }
}

TileQuestLogic _logic(
  TileQuestSaveService saves,
  _RaceWork work, {
  _RaceFeedback? feedback,
  int Function()? now_ms,
}) => TileQuestLogic(
  save_service: saves,
  work_service: work,
  feedback_service: feedback ?? _RaceFeedback(),
  next_seed: () => 17,
  now_ms: now_ms ?? () => 0,
  enable_timer: false,
);

Future<void> _mount(WidgetTester tester, TileQuestLogic logic) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(home: TileQuestPage(logic: logic)));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'same-frame legal actions remain complete until the next challenge',
    () async {
      final saves = TileQuestSaveService(
        encode_snapshot: encode_tile_quest_snapshot,
        store: _RaceStore(),
      );
      final work = _RaceWork()..tile_count = 270;
      final logic = _logic(saves, work);
      await logic.initialize();
      final results = await Future.wait([
        for (var id = 0; id < work.tile_count; id++) logic.tap_tile(id),
      ]);
      expect(results.every((result) => result?.accepted == true), isTrue);
      expect(logic.state!.status, TileQuestStatus.won);
      expect(logic.recent_actions, orderedEquals(results));
      await logic.restart();
      expect(logic.recent_actions, isEmpty);
      logic.onClose();
      await saves.flush();
    },
  );

  for (final computing in <String>['shuffle', 'restart']) {
    test(
      'leaving invalidates an outstanding $computing before its result commits',
      () async {
        final saves = TileQuestSaveService(
          encode_snapshot: encode_tile_quest_snapshot,
          store: _RaceStore(),
        );
        final work = _RaceWork();
        final feedback = _RaceFeedback();
        final logic = _logic(saves, work, feedback: feedback);
        await logic.initialize();
        await logic.flush_save();
        final previous = logic.state!;
        final gate = Completer<void>();
        final Future<dynamic> pending;
        if (computing == 'shuffle') {
          work.shuffle_gate = gate;
          pending = logic.shuffle();
        } else {
          work.generation_gate = gate;
          pending = logic.restart();
        }
        expect(logic.is_busy, isTrue);
        await logic.leave_game();
        gate.complete();
        await pending;
        logic.set_foreground(true);
        expect(await logic.tap_tile(0), isNull);
        expect(logic.state!.challenge_id, previous.challenge_id);
        expect(logic.state!.tools, previous.tools);
        expect(logic.recent_actions, isEmpty);
        expect(logic.is_busy, isFalse);
        await logic.presentation_feedback(TileQuestFeedbackEvent.shuffle);
        expect(feedback.events, isEmpty);
        await saves.flush();
        final saved = (await saves.load()).engine!.state;
        expect(saved.challenge_id, previous.challenge_id);
        expect(saved.tools, previous.tools);
        logic.onClose();
        await saves.flush();
      },
    );
  }

  test('slow ordered saves do not hold the new board input lock', () async {
    final store = _RaceStore();
    final saves = TileQuestSaveService(
      encode_snapshot: encode_tile_quest_snapshot,
      store: store,
    );
    final logic = _logic(saves, _RaceWork());
    await logic.initialize();
    await logic.flush_save();
    final previous = logic.state!.challenge_id;
    final gate = Completer<void>();
    store.write_gate = gate;
    var completed = false;
    final restart = logic.restart().then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);
    expect(logic.state!.challenge_id, isNot(previous));
    // 先记录以便失败也能释放磁盘栅栏，避免悬挂测试和排队写入。
    final unlocked = !logic.is_busy && completed;
    final tap = await logic.tap_tile(0);
    gate.complete();
    await restart;
    await logic.flush_save();
    expect(unlocked, isTrue);
    expect(tap?.accepted, isTrue);
    expect((await saves.load()).engine!.state.tray, <int>[0]);
    logic.onClose();
    await saves.flush();
  });

  test(
    'one pending shuffle rejects duplicate inputs and preserves background metadata',
    () async {
      var now = 0;
      final saves = TileQuestSaveService(
        encode_snapshot: encode_tile_quest_snapshot,
        store: _RaceStore(),
      );
      final work = _RaceWork();
      final feedback = _RaceFeedback();
      final logic = _logic(saves, work, feedback: feedback, now_ms: () => now);
      await logic.initialize();
      now = 1000;
      final gate = Completer<void>();
      work.shuffle_gate = gate;
      final pending = logic.shuffle();
      expect(await logic.shuffle(), isNull);
      expect(await logic.tap_tile(0), isNull);
      expect(await logic.undo(), isNull);
      expect(await logic.remove(), isNull);
      await logic.restart();
      expect(await logic.next_level(), isFalse);
      expect(work.generation_count, 1);
      expect(work.shuffle_count, 1);
      now = 2000;
      logic.set_foreground(false);
      await logic.toggle_sound();
      gate.complete();
      expect((await pending)?.accepted, isTrue);
      expect(logic.is_busy, isFalse);
      expect(logic.state!.tools[TileQuestTool.shuffle], 0);
      expect(logic.sound_enabled, isFalse);
      expect(logic.elapsed_ms, 1000);
      expect(logic.recent_actions, hasLength(1));
      await logic.presentation_feedback(TileQuestFeedbackEvent.shuffle);
      expect(feedback.events, isEmpty);
      now = 60000;
      logic.set_foreground(true);
      now += 250;
      logic.tick();
      expect(logic.elapsed_ms, 1250);
      logic.onClose();
      await saves.flush();
    },
  );

  test(
    'a revoked worker cannot clear the replacement session busy lock',
    () async {
      final saves = TileQuestSaveService(
        encode_snapshot: encode_tile_quest_snapshot,
        store: _RaceStore(),
      );
      final work = _RaceWork();
      final first = _logic(saves, work);
      await first.initialize();
      final old_gate = Completer<void>();
      work.shuffle_gate = old_gate;
      final old_shuffle = first.shuffle();
      final second = _logic(saves, _RaceWork());
      await second.initialize();
      expect(first.session_suspended, isTrue);
      await first.resume_session();
      expect(second.session_suspended, isTrue);
      final new_gate = Completer<void>();
      work.shuffle_gate = new_gate;
      final new_shuffle = first.shuffle();
      old_gate.complete();
      expect(await old_shuffle, isNull);
      expect(first.is_busy, isTrue);
      expect(first.recent_actions, isEmpty);
      expect(first.state!.tools[TileQuestTool.shuffle], 1);
      new_gate.complete();
      expect((await new_shuffle)?.accepted, isTrue);
      expect(first.is_busy, isFalse);
      expect(first.recent_actions, hasLength(1));
      first.onClose();
      second.onClose();
      await saves.flush();
    },
  );

  test(
    'repeated restart and next requests share the synchronous generation lock',
    () async {
      final saves = TileQuestSaveService(
        encode_snapshot: encode_tile_quest_snapshot,
        store: _RaceStore(),
      );
      final work = _RaceWork()..tile_count = 3;
      final logic = _logic(saves, work);
      await logic.initialize();
      for (final id in <int>[0, 1, 2]) {
        await logic.tap_tile(id);
      }
      final gate = Completer<void>();
      work.generation_gate = gate;
      final advancing = logic.next_level();
      expect(await logic.next_level(), isFalse);
      await logic.restart();
      expect(work.generation_count, 2);
      gate.complete();
      expect(await advancing, isTrue);
      expect(logic.state!.level, 2);
      final reset_gate = Completer<void>();
      work.generation_gate = reset_gate;
      final resetting = logic.restart();
      await logic.restart();
      expect(work.generation_count, 3);
      reset_gate.complete();
      await resetting;
      expect(logic.state!.level, 1);
      expect(logic.recent_actions, isEmpty);
      logic.onClose();
      await saves.flush();
    },
  );

  testWidgets(
    'a stale displayed board cannot tap or spend tools after shuffle commits',
    (tester) async {
      final saves = TileQuestSaveService(
        encode_snapshot: encode_tile_quest_snapshot,
        store: _RaceStore(),
      );
      final feedback = _RaceFeedback();
      final logic = _logic(saves, _RaceWork(), feedback: feedback);
      await _mount(tester, logic);
      final old_scene = tester.widget<TileQuestScene>(
        find.byType(TileQuestScene),
      );
      final previous_revision = logic.board_revision;
      expect((await logic.shuffle())?.accepted, isTrue);
      expect(logic.board_revision, previous_revision + 1);
      // 不 pump：真实页面仍展示旧图案，旧 hit callback 不能选择新图案。
      old_scene.on_tile(0);
      old_scene.on_tool(TileQuestTool.remove);
      old_scene.on_feedback!(TileQuestFeedbackEvent.match);
      expect(logic.state!.tray, isEmpty);
      expect(logic.state!.reserve, isEmpty);
      expect(logic.state!.tools[TileQuestTool.remove], 2);
      expect(logic.recent_actions, hasLength(1));
      expect(feedback.events, isNot(contains(TileQuestFeedbackEvent.match)));
      await tester.pumpAndSettle();
      final current_scene = tester.widget<TileQuestScene>(
        find.byType(TileQuestScene),
      );
      current_scene.on_tile(0);
      current_scene.on_tile(1);
      // 普通 tap 不更换牌面版本，同帧第二次合法点击仍应提交。
      expect(logic.recent_actions, hasLength(3));
      expect(logic.state!.tray, hasLength(2));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await saves.flush();
    },
  );

  testWidgets('dialog pause never overrides the actual app lifecycle', (
    tester,
  ) async {
    var now = 0;
    final saves = TileQuestSaveService(
      encode_snapshot: encode_tile_quest_snapshot,
      store: _RaceStore(),
    );
    final logic = _logic(saves, _RaceWork(), now_ms: () => now);
    await _mount(tester, logic);
    now = 1000;
    tester.widget<TileQuestScene>(find.byType(TileQuestScene)).on_restart();
    await tester.pumpAndSettle();
    now = 2000;
    logic.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = 5000;
    logic.didChangeAppLifecycleState(AppLifecycleState.resumed);
    now = 9000;
    logic.tick();
    expect(logic.elapsed_ms, 1000);
    expect(await logic.tap_tile(0), isNull);
    logic.didChangeAppLifecycleState(AppLifecycleState.paused);
    final cancel = tester
        .widgetList<QuestPrimaryButton>(find.byType(QuestPrimaryButton))
        .firstWhere((button) => !button.primary);
    cancel.on_tap!();
    await tester.pumpAndSettle();
    now = 15000;
    logic.tick();
    expect(logic.elapsed_ms, 1000);
    expect(await logic.tap_tile(0), isNull);
    logic.didChangeAppLifecycleState(AppLifecycleState.resumed);
    now += 250;
    expect((await logic.tap_tile(0))?.accepted, isTrue);
    expect(logic.elapsed_ms, 1250);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await saves.flush();
  });

  testWidgets(
    'old challenge feedback is ignored after reset and during departure',
    (tester) async {
      final saves = TileQuestSaveService(
        encode_snapshot: encode_tile_quest_snapshot,
        store: _RaceStore(),
      );
      final feedback = _RaceFeedback();
      final logic = _logic(saves, _RaceWork(), feedback: feedback);
      await _mount(tester, logic);
      final old_scene = tester.widget<TileQuestScene>(
        find.byType(TileQuestScene),
      );
      await logic.restart();
      feedback.events.clear();
      old_scene.on_feedback!(TileQuestFeedbackEvent.won);
      expect(feedback.events, isEmpty);
      await tester.pumpAndSettle();
      final current_scene = tester.widget<TileQuestScene>(
        find.byType(TileQuestScene),
      );
      current_scene.on_feedback!(TileQuestFeedbackEvent.match);
      expect(feedback.events, contains(TileQuestFeedbackEvent.match));
      await logic.leave_game();
      feedback.events.clear();
      current_scene.on_feedback!(TileQuestFeedbackEvent.lost);
      expect(feedback.events, isEmpty);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await saves.flush();
    },
  );

  test(
    'exit during initialization cancels publication and duplicate exits share a save fence',
    () async {
      final store = _RaceStore();
      final saves = TileQuestSaveService(
        encode_snapshot: encode_tile_quest_snapshot,
        store: store,
      );
      final gate = Completer<void>();
      final work = _RaceWork()..generation_gate = gate;
      final logic = _logic(saves, work);
      final initializing = logic.initialize();
      await Future<void>.delayed(Duration.zero);
      expect(work.generation_count, 1);
      final first_exit = logic.leave_game();
      final repeated_exit = logic.leave_game();
      expect(identical(first_exit, repeated_exit), isTrue);
      await first_exit;
      gate.complete();
      await initializing;
      await logic.initialize();
      expect(logic.state, isNull);
      expect(logic.is_loading, isFalse);
      expect(work.generation_count, 1);
      expect(store.value, isNull);
      logic.onClose();
      await saves.flush();
    },
  );

  testWidgets(
    'old winner controls cannot act on a newly committed next level',
    (tester) async {
      final saves = TileQuestSaveService(
        encode_snapshot: encode_tile_quest_snapshot,
        store: _RaceStore(),
      );
      final logic = _logic(saves, _RaceWork()..tile_count = 3);
      await _mount(tester, logic);
      for (final id in <int>[0, 1, 2]) {
        await logic.tap_tile(id);
      }
      await tester.pumpAndSettle();
      final old_result = tester.widget<QuestResult>(find.byType(QuestResult));
      expect(await logic.next_level(), isTrue);
      // 下一帧前保留的胜利按钮不能再操作已生成的第二关。
      old_result.on_next();
      old_result.on_restart();
      old_result.on_undo();
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(QuestResult), findsNothing);
      expect(logic.state!.level, 2);
      expect(logic.state!.tools[TileQuestTool.undo], 1);
      for (final id in <int>[0, 1, 2]) {
        await logic.tap_tile(id);
      }
      await tester.pumpAndSettle();
      final current_result = tester.widget<QuestResult>(
        find.byType(QuestResult),
      );
      expect(current_result.coming_soon, isFalse);
      current_result.on_next();
      await tester.pumpAndSettle();
      expect(
        tester.widget<QuestResult>(find.byType(QuestResult)).coming_soon,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await saves.flush();
    },
  );

  testWidgets(
    'same-frame restart requests create only one confirmation route',
    (tester) async {
      final saves = TileQuestSaveService(
        encode_snapshot: encode_tile_quest_snapshot,
        store: _RaceStore(),
      );
      final logic = _logic(saves, _RaceWork());
      await _mount(tester, logic);
      final scene = tester.widget<TileQuestScene>(find.byType(TileQuestScene));
      scene.on_restart();
      scene.on_restart();
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      // 默认 finder 只搜索最上层路由，因此包括离屏路由才能捕捉重复弹层。
      expect(find.byType(Dialog, skipOffstage: false), findsOneWidget);
      final confirm = tester.widget<QuestPrimaryButton>(
        find.byKey(const ValueKey('tile_quest_confirm_restart')),
      );
      confirm.on_tap!();
      confirm.on_tap!();
      await tester.pumpAndSettle();
      expect(find.byType(Dialog, skipOffstage: false), findsNothing);
      expect(find.byType(TileQuestPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await saves.flush();
    },
  );
}
