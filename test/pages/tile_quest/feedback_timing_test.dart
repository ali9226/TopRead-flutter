// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/index.dart';
import 'package:app/pages/tile_quest/logic.dart';
import 'package:app/pages/tile_quest/services/feedback_service.dart';
import 'package:app/pages/tile_quest/services/save_service.dart';
import 'package:app/pages/tile_quest/services/work_service.dart';
import 'package:app/pages/tile_quest/style.dart';
import 'package:app/pages/tile_quest/widgets/quest_result.dart';
import 'package:app/pages/tile_quest/widgets/quest_scene.dart';
import 'package:app/pages/tile_quest/widgets/scene_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scene_probe.dart';

/// 录制控制器真正送到音频边界的事件，同时验证所有权和生命周期清理。
class _RecordingFeedback
    implements TileQuestFeedbackService, TileQuestFeedbackLifecycle {
  final List<TileQuestFeedbackEvent> events = <TileQuestFeedbackEvent>[];
  int prepare_count = 0;
  int stop_count = 0;
  int dispose_count = 0;
  bool fail_operations = false;
  Completer<void>? prepare_gate;

  @override
  Future<void> prepare() async {
    prepare_count++;
    await prepare_gate?.future;
    if (fail_operations) throw StateError('prepare unavailable');
  }

  @override
  Future<void> play(TileQuestFeedbackEvent event) async {
    events.add(event);
    if (fail_operations) throw StateError('play unavailable');
  }

  @override
  Future<void> stop() async {
    stop_count++;
    if (fail_operations) throw StateError('stop unavailable');
  }

  @override
  Future<void> dispose() async {
    dispose_count++;
    if (fail_operations) throw StateError('dispose unavailable');
  }
}

class _FeedbackStore implements TileQuestSaveStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

/// 每种图案恰有三张的真实规则牌局，通过生成边界注入新的挑战。
class _FeedbackWork implements TileQuestWorkService {
  _FeedbackWork(this.types);
  final List<int> types;

  @override
  Future<TileQuestState> generate({
    required int level,
    required int seed,
    required int unlocked_level,
    String? challenge_id,
  }) async => TileQuestState(
    tiles: <TileQuestTile>[
      for (var id = 0; id < types.length; id++)
        TileQuestTile(
          id: id,
          type: types[id],
          layer: 0,
          x: (id % 7).toDouble(),
          y: (id ~/ 7).toDouble(),
        ),
    ],
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

TileQuestLogic _logic(
  TileQuestSaveService saves,
  _RecordingFeedback feedback, {
  List<int>? types,
}) => TileQuestLogic(
  save_service: saves,
  feedback_service: feedback,
  work_service: _FeedbackWork(types ?? <int>[0, 0, 0, 1, 1, 1, 2, 2, 2]),
  next_seed: () => 17,
  now_ms: () => 0,
  enable_timer: false,
);

Future<void> _mount_page(WidgetTester tester, TileQuestLogic logic) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(home: TileQuestPage(logic: logic)));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _close_page(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _late_events(TileQuestLogic logic) async {
  for (final event in TileQuestFeedbackEvent.values) {
    await logic.presentation_feedback(event);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'entry waits for audio readiness but a stalled backend cannot exceed its budget',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final ready_before_budget in <bool>[true, false]) {
        final feedback = _RecordingFeedback()..prepare_gate = Completer<void>();
        final saves = TileQuestSaveService(
          encode_snapshot: encode_tile_quest_snapshot,
          store: _FeedbackStore(),
        );
        final logic = _logic(saves, feedback);
        await tester.pumpWidget(MaterialApp(home: TileQuestPage(logic: logic)));
        await tester.pump();
        expect(feedback.prepare_count, 1);
        expect(logic.is_loading, isTrue);
        expect(logic.state, isNull);
        expect(find.byType(TileQuestScene), findsNothing);
        expect(feedback.events, isEmpty);

        if (ready_before_budget) {
          // 音频先准备好时无需把剩余预算等完，首张牌与入场声一起出现。
          await tester.pump(TileQuestLogic.feedback_preload_budget ~/ 2);
          expect(logic.state, isNull);
          feedback.prepare_gate!.complete();
          await tester.pump();
        } else {
          // 资源已生成也不能提前发布；卡住的 prepare 最多阻塞 240ms。
          await tester.pump(
            TileQuestLogic.feedback_preload_budget -
                const Duration(milliseconds: 1),
          );
          expect(logic.state, isNull);
          expect(find.byType(TileQuestScene), findsNothing);
          expect(feedback.events, isEmpty);
          await tester.pump(const Duration(milliseconds: 1));
        }
        expect(logic.is_loading, isFalse);
        expect(logic.state, isNotNull);
        expect(find.byType(TileQuestScene), findsOneWidget);
        expect(feedback.events, <TileQuestFeedbackEvent>[
          TileQuestFeedbackEvent.entry,
        ]);
        final challenge_id = logic.state!.challenge_id;
        if (!ready_before_budget) {
          feedback.prepare_gate!.complete();
        }
        await tester.pumpAndSettle();
        expect(logic.state!.challenge_id, challenge_id);
        expect(feedback.events, <TileQuestFeedbackEvent>[
          TileQuestFeedbackEvent.entry,
        ]);
        await _close_page(tester);
        // 存档编码在真实 isolate 中执行，等待时让真实事件循环派发结果。
        await tester.runAsync(saves.flush);
        expect(feedback.dispose_count, 1);
      }
    },
  );

  test(
    'next level and restart stop the previous cue before generating a board',
    () async {
      final saves = TileQuestSaveService(
        encode_snapshot: encode_tile_quest_snapshot,
        store: _FeedbackStore(),
      );
      final feedback = _RecordingFeedback();
      final logic = _logic(saves, feedback, types: <int>[0, 0, 0]);
      await logic.initialize();
      for (final id in <int>[0, 1, 2]) {
        expect((await logic.tap_tile(id))!.accepted, isTrue);
      }
      expect(logic.state!.status, TileQuestStatus.won);
      await logic.presentation_feedback(TileQuestFeedbackEvent.won);
      final Future<bool> advancing = logic.next_level();
      expect(
        feedback.stop_count,
        1,
        reason: 'the victory tail stops synchronously before generation awaits',
      );
      expect(await advancing, isTrue);
      expect(logic.state!.level, 2);
      expect(logic.state!.unlocked_level, 2);
      final old_challenge = logic.state!.challenge_id;
      await logic.presentation_feedback(TileQuestFeedbackEvent.entry);
      final Future<void> restarting = logic.restart();
      expect(
        feedback.stop_count,
        2,
        reason: 'restart also stops a cue belonging to the discarded board',
      );
      await restarting;
      expect(logic.state!.level, 1);
      expect(logic.state!.unlocked_level, 2);
      expect(logic.state!.challenge_id, isNot(old_challenge));
      expect(logic.sound_enabled, isTrue);
      expect(await logic.next_level(), isFalse);
      expect(feedback.stop_count, 2);
      logic.onClose();
      await saves.flush();
      expect(feedback.dispose_count, 1);
    },
  );

  testWidgets(
    'a long frame settles queued actions without replaying expired sounds',
    (tester) async {
      for (final outcome in <TileQuestStatus>[
        TileQuestStatus.playing,
        TileQuestStatus.won,
        TileQuestStatus.lost,
      ]) {
        final feedback = _RecordingFeedback();
        final types = switch (outcome) {
          TileQuestStatus.playing => <int>[0, 0, 0, 1, 1, 1, 2, 2, 2],
          TileQuestStatus.won => <int>[0, 0, 0],
          TileQuestStatus.lost => <int>[for (var id = 0; id < 21; id++) id % 7],
        };
        final logic = _logic(
          TileQuestSaveService(
            encode_snapshot: encode_tile_quest_snapshot,
            store: _FeedbackStore(),
          ),
          feedback,
          types: types,
        );
        await _mount_page(tester, logic);
        if (outcome == TileQuestStatus.playing) {
          // 备用区仅属于第二关；先完成教学再测试真实页面的道具与长帧。
          for (var id = 0; id < types.length; id++) {
            expect((await logic.tap_tile(id))!.accepted, isTrue);
          }
          expect(logic.state!.status, TileQuestStatus.won);
          expect(await logic.next_level(), isTrue);
          await tester.pumpAndSettle();
          expect(logic.state!.level, 2);
        }
        feedback.events.clear();
        final tap_count = outcome == TileQuestStatus.lost ? 7 : 3;
        for (var id = 0; id < tap_count; id++) {
          expect((await logic.tap_tile(id))!.accepted, isTrue);
        }
        if (outcome == TileQuestStatus.playing) {
          expect((await logic.tap_tile(3))!.accepted, isTrue);
          expect((await logic.remove())!.accepted, isTrue);
          expect((await logic.shuffle())!.accepted, isTrue);
        }
        expect(feedback.events, everyElement(TileQuestFeedbackEvent.tap));
        final expected = logic.state!.to_json();
        expect(logic.state!.status, outcome);
        // 先启动首个飞行动画；之后只有一个长帧，模拟恢复后追赶整个队列。
        await tester.pump();
        feedback.events.clear();
        await tester.pump(const Duration(seconds: 10));
        await tester.pump();
        expect(
          feedback.events,
          isEmpty,
          reason: 'old match/tool/shuffle/result cues cannot burst on resume',
        );
        expect(logic.state!.to_json(), expected);
        final frames = quest_scene_frames(tester);
        expect(
          frames.values.where((frame) => frame.zone == QuestTileZone.flight),
          isEmpty,
        );
        expect(
          find.byType(QuestResult),
          outcome == TileQuestStatus.playing ? findsNothing : findsOneWidget,
        );
        final layout = QuestSceneLayout(const Size(390, 844), logic.state!);
        for (final id in logic.state!.reserve) {
          expect(frames[id]!.rect, layout.location(logic.state!, id));
        }
        for (final id in logic.state!.tray) {
          expect(frames[id]!.rect, layout.location(logic.state!, id));
        }
        for (final tile in logic.state!.tiles.where(
          (tile) => !tile.is_removed,
        )) {
          expect(frames[tile.id]!.zone, QuestTileZone.board);
          expect(frames[tile.id]!.rect, layout.board_tile(tile));
        }

        if (outcome == TileQuestStatus.won) {
          await logic.restart();
          await tester.pumpAndSettle(const Duration(milliseconds: 20));
          expect(feedback.events, <TileQuestFeedbackEvent>[
            TileQuestFeedbackEvent.entry,
          ]);
          feedback.events.clear();
          await logic.tap_tile(0);
          expect(feedback.events, <TileQuestFeedbackEvent>[
            TileQuestFeedbackEvent.tap,
          ]);
        } else {
          // 正常的新撤回仍在开始时发声，证明长帧抑制不会永久静音。
          expect((await logic.undo())!.accepted, isTrue);
          expect(feedback.events, isEmpty);
          await tester.pump();
          expect(feedback.events, <TileQuestFeedbackEvent>[
            TileQuestFeedbackEvent.tool,
          ]);
          await tester.pumpAndSettle(const Duration(milliseconds: 20));
          feedback.events.clear();
          final id = logic.state!.clickable_tiles.first.id;
          expect((await logic.tap_tile(id))!.accepted, isTrue);
          expect(feedback.events, <TileQuestFeedbackEvent>[
            TileQuestFeedbackEvent.tap,
          ]);
        }
        await _close_page(tester);
      }
    },
  );

  testWidgets(
    'match sounds at fade start and victory only after the final fade',
    (tester) async {
      final feedback = _RecordingFeedback();
      final logic = _logic(
        TileQuestSaveService(
          encode_snapshot: encode_tile_quest_snapshot,
          store: _FeedbackStore(),
        ),
        feedback,
        types: <int>[0, 0, 0],
      );
      await _mount_page(tester, logic);
      expect(feedback.prepare_count, 1);
      expect(feedback.events, <TileQuestFeedbackEvent>[
        TileQuestFeedbackEvent.entry,
      ]);
      for (final id in <int>[0, 1]) {
        expect((await logic.tap_tile(id))!.accepted, isTrue);
        await tester.pumpAndSettle();
      }
      feedback.events.clear();

      final result = await logic.tap_tile(2);
      expect(result!.matched_ids, <int>[0, 1, 2]);
      expect(result.after.status, TileQuestStatus.won);
      expect(
        feedback.events,
        <TileQuestFeedbackEvent>[TileQuestFeedbackEvent.tap],
        reason: 'accepting the rule result cannot play a future match or win',
      );
      await tester.pump();
      final before_match =
          TileQuestStyle.flight_duration +
          Duration(milliseconds: TileQuestStyle.match_hold_ms.toInt() - 1);
      await tester.pump(before_match);
      expect(feedback.events, <TileQuestFeedbackEvent>[
        TileQuestFeedbackEvent.tap,
      ]);
      expect(find.byType(QuestResult), findsNothing);

      await tester.pump(const Duration(milliseconds: 1));
      expect(feedback.events, <TileQuestFeedbackEvent>[
        TileQuestFeedbackEvent.tap,
        TileQuestFeedbackEvent.match,
      ]);
      await tester.pump(
        Duration(milliseconds: TileQuestStyle.match_fade_ms.toInt() - 1),
      );
      expect(
        feedback.events.where((event) => event == TileQuestFeedbackEvent.won),
        isEmpty,
      );
      expect(find.byType(QuestResult), findsNothing);
      final final_particle_frame = quest_scene_frames(tester)[2]!;
      expect(final_particle_frame.dissolve, greaterThan(0));
      expect(
        final_particle_frame.dissolve,
        lessThan(1),
        reason: 'the last group remains visible until its fade ends',
      );

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(feedback.events, <TileQuestFeedbackEvent>[
        TileQuestFeedbackEvent.tap,
        TileQuestFeedbackEvent.match,
        TileQuestFeedbackEvent.won,
      ]);
      expect(find.byType(QuestResult), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      expect(
        feedback.events.where((event) => event == TileQuestFeedbackEvent.match),
        hasLength(1),
      );
      expect(
        feedback.events.where((event) => event == TileQuestFeedbackEvent.won),
        hasLength(1),
      );
      await _close_page(tester);
      expect(feedback.dispose_count, 1);
    },
  );

  testWidgets('loss sound waits until the seventh tile reaches the full tray', (
    tester,
  ) async {
    final feedback = _RecordingFeedback();
    final logic = _logic(
      TileQuestSaveService(
        encode_snapshot: encode_tile_quest_snapshot,
        store: _FeedbackStore(),
      ),
      feedback,
      types: <int>[for (var id = 0; id < 21; id++) id % 7],
    );
    await _mount_page(tester, logic);
    for (var id = 0; id < 6; id++) {
      expect((await logic.tap_tile(id))!.accepted, isTrue);
      await tester.pumpAndSettle();
    }
    feedback.events.clear();
    final result = await logic.tap_tile(6);
    expect(result!.after.status, TileQuestStatus.lost);
    expect(feedback.events, <TileQuestFeedbackEvent>[
      TileQuestFeedbackEvent.tap,
    ]);
    await tester.pump();
    await tester.pump(
      TileQuestStyle.flight_duration - const Duration(milliseconds: 1),
    );
    expect(feedback.events, <TileQuestFeedbackEvent>[
      TileQuestFeedbackEvent.tap,
    ]);
    expect(find.byType(QuestResult), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(feedback.events, <TileQuestFeedbackEvent>[
      TileQuestFeedbackEvent.tap,
      TileQuestFeedbackEvent.lost,
    ]);
    expect(find.byType(QuestResult), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(
      feedback.events.where((event) => event == TileQuestFeedbackEvent.lost),
      hasLength(1),
    );
    await _close_page(tester);
  });

  test(
    'logical matches and tools emit no presentation cues before rendering',
    () async {
      final saves = TileQuestSaveService(
        encode_snapshot: encode_tile_quest_snapshot,
        store: _FeedbackStore(),
      );
      final feedback = _RecordingFeedback();
      final logic = _logic(saves, feedback);
      await logic.initialize();
      expect(feedback.prepare_count, 1);
      expect(feedback.events, isEmpty);
      for (final id in <int>[0, 1, 2]) {
        expect((await logic.tap_tile(id))!.accepted, isTrue);
      }
      expect(logic.last_action!.matched_ids, <int>[0, 1, 2]);
      expect(feedback.events, List.filled(3, TileQuestFeedbackEvent.tap));
      expect((await logic.undo())!.accepted, isTrue);
      expect((await logic.remove())!.accepted, isTrue);
      expect((await logic.shuffle())!.accepted, isTrue);
      expect(feedback.events, List.filled(3, TileQuestFeedbackEvent.tap));
      await logic.presentation_feedback(TileQuestFeedbackEvent.match);
      await logic.presentation_feedback(TileQuestFeedbackEvent.tool);
      await logic.presentation_feedback(TileQuestFeedbackEvent.shuffle);
      expect(feedback.events.skip(3), <TileQuestFeedbackEvent>[
        TileQuestFeedbackEvent.match,
        TileQuestFeedbackEvent.tool,
        TileQuestFeedbackEvent.shuffle,
      ]);
      logic.onClose();
      await saves.flush();
    },
  );

  test(
    'mute, background and leaving stop audio and reject late visual callbacks',
    () async {
      final saves = TileQuestSaveService(
        encode_snapshot: encode_tile_quest_snapshot,
        store: _FeedbackStore(),
      );
      final feedback = _RecordingFeedback();
      final logic = _logic(saves, feedback);
      await logic.initialize();
      await logic.presentation_feedback(TileQuestFeedbackEvent.entry);
      expect(feedback.events, <TileQuestFeedbackEvent>[
        TileQuestFeedbackEvent.entry,
      ]);

      await logic.toggle_sound();
      expect(logic.sound_enabled, isFalse);
      expect(feedback.stop_count, 1);
      await _late_events(logic);
      expect(feedback.events, hasLength(1));
      expect((await logic.tap_tile(0))!.accepted, isTrue);
      expect(feedback.events, hasLength(1));

      await logic.toggle_sound();
      expect(logic.sound_enabled, isTrue);
      await logic.presentation_feedback(TileQuestFeedbackEvent.tool);
      expect(feedback.events.last, TileQuestFeedbackEvent.tool);
      logic.set_foreground(false);
      expect(feedback.stop_count, 2);
      await _late_events(logic);
      expect(feedback.events, hasLength(2));
      expect(await logic.tap_tile(1), isNull);

      logic.set_foreground(true);
      await logic.presentation_feedback(TileQuestFeedbackEvent.match);
      expect(feedback.events.last, TileQuestFeedbackEvent.match);
      await logic.leave_game();
      expect(feedback.stop_count, 3);
      await _late_events(logic);
      expect(feedback.events, hasLength(3));
      logic.onClose();
      logic.onClose();
      await saves.flush();
      expect(feedback.dispose_count, 1);
      await _late_events(logic);
      expect(feedback.events, hasLength(3));
    },
  );

  test(
    'session takeover stops only the old page and rejects all of its late cues',
    () async {
      final saves = TileQuestSaveService(
        encode_snapshot: encode_tile_quest_snapshot,
        store: _FeedbackStore(),
      );
      final old_feedback = _RecordingFeedback();
      final new_feedback = _RecordingFeedback();
      final old_page = _logic(saves, old_feedback);
      final new_page = _logic(saves, new_feedback);
      await old_page.initialize();
      await old_page.presentation_feedback(TileQuestFeedbackEvent.entry);
      await new_page.initialize();
      expect(old_page.session_suspended, isTrue);
      expect(old_feedback.stop_count, 1);
      expect(new_feedback.stop_count, 0);
      await _late_events(old_page);
      expect(old_feedback.events, hasLength(1));
      await new_page.presentation_feedback(TileQuestFeedbackEvent.entry);
      expect(new_feedback.events, <TileQuestFeedbackEvent>[
        TileQuestFeedbackEvent.entry,
      ]);
      old_page.onClose();
      await saves.flush();
      expect(old_feedback.dispose_count, 1);
      expect(new_feedback.dispose_count, 0);
      await old_page.presentation_feedback(TileQuestFeedbackEvent.won);
      await new_page.presentation_feedback(TileQuestFeedbackEvent.match);
      expect(old_feedback.events, hasLength(1));
      expect(new_feedback.events.last, TileQuestFeedbackEvent.match);
      new_page.onClose();
      await saves.flush();
      expect(new_feedback.dispose_count, 1);
    },
  );

  test(
    'audio lifecycle errors cannot interrupt rules, saving or page cleanup',
    () async {
      final saves = TileQuestSaveService(
        encode_snapshot: encode_tile_quest_snapshot,
        store: _FeedbackStore(),
      );
      final feedback = _RecordingFeedback()..fail_operations = true;
      final logic = _logic(saves, feedback);
      await logic.initialize();
      expect(logic.state, isNotNull);
      expect(feedback.prepare_count, 1);
      expect((await logic.tap_tile(0))!.accepted, isTrue);
      await logic.presentation_feedback(TileQuestFeedbackEvent.match);
      await logic.toggle_sound();
      expect(feedback.stop_count, 1);
      await logic.toggle_sound();
      await logic.flush_save();
      expect(logic.has_save_error, isFalse);
      logic.onClose();
      await saves.flush();
      expect(feedback.dispose_count, 1);
    },
  );
}
