// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';

import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/logic.dart';
import 'package:app/pages/tile_quest/services/feedback_service.dart';
import 'package:app/pages/tile_quest/services/save_service.dart';
import 'package:app/pages/tile_quest/services/work_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// 记录真正写入的快照，用于确认失败和过期计算不会覆盖既有存档。
class _EntryStore implements TileQuestSaveStore {
  String? value;
  int write_count = 0;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    write_count++;
    this.value = value;
  }
}

class _EntryFeedback implements TileQuestFeedbackService {
  @override
  Future<void> play(TileQuestFeedbackEvent event) async {}
}

/// 只控制计算开始和结束，牌局仍使用生产生成器以覆盖真实关卡元信息。
class _EntryWork implements TileQuestWorkService {
  int generation_count = 0;
  bool fail_generation = false;
  Completer<void>? generation_gate;

  @override
  Future<TileQuestState> generate({
    required int level,
    required int seed,
    required int unlocked_level,
    String? challenge_id,
  }) async {
    generation_count++;
    await generation_gate?.future;
    if (fail_generation) throw StateError('generation unavailable');
    return TileQuestGenerator.generate(
      level: level,
      seed: seed,
      unlocked_level: unlocked_level,
      challenge_id: challenge_id,
    );
  }

  @override
  Future<TileQuestPreparedShuffle> shuffle(
    Map<String, dynamic> engine_json, {
    required int seed,
  }) async {
    final TileQuestEngine engine = TileQuestEngine.restore(engine_json);
    return TileQuestPreparedShuffle(
      engine: engine,
      result: engine.shuffle(seed: seed),
    );
  }
}

TileQuestLogic _new_logic(
  TileQuestSaveService service, {
  _EntryWork? work,
  int Function()? now_ms,
  int Function()? next_seed,
}) => TileQuestLogic(
  save_service: service,
  work_service: work ?? _EntryWork(),
  feedback_service: _EntryFeedback(),
  now_ms: now_ms ?? () => 0,
  next_seed: next_seed ?? () => 42,
  enable_timer: false,
);

Map<TileQuestTool, int> get _initial_tools => <TileQuestTool, int>{
  for (final TileQuestTool tool in TileQuestTool.values)
    tool: TileQuestConfig.initial_tool_uses(tool),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'each page entry discards active board, tools and Undo history',
    () async {
      int now = 0;
      final _EntryStore store = _EntryStore();
      final TileQuestSaveService service = TileQuestSaveService(store: store);
      final TileQuestLogic first = _new_logic(service, now_ms: () => now);
      await first.initialize();
      final TileQuestState original = first.state!;
      await first.tap_tile(original.certified_solution.first);
      await first.remove();
      await first.toggle_sound();
      now = 8000;
      first.tick();
      await first.leave_game();
      first.onClose();

      final TileQuestLogic next = _new_logic(service, now_ms: () => now);
      await next.initialize();
      expect(next.state!.seed, original.seed + 1);
      expect(next.state!.challenge_id, isNot(original.challenge_id));
      expect(next.state!.level, 1);
      expect(next.state!.status, TileQuestStatus.playing);
      expect(next.state!.tray, isEmpty);
      expect(next.state!.reserve, isEmpty);
      expect(next.state!.remaining_count, next.state!.total_count);
      expect(next.elapsed_ms, 0);
      expect(next.state!.tools, _initial_tools);
      expect(next.state!.tools_used, 0);
      expect(next.can_undo, isFalse);
      expect(next.recent_actions, isEmpty);
      expect(next.sound_enabled, isFalse);
      next.onClose();
      await service.flush();
    },
  );

  test('unlocked second level reopens at the easy first level', () async {
    final TileQuestSaveService service = TileQuestSaveService(
      store: _EntryStore(),
    );
    final TileQuestLogic first = _new_logic(service);
    await first.initialize();
    for (final int id in first.state!.certified_solution.toList()) {
      expect((await first.tap_tile(id))!.accepted, isTrue);
    }
    expect(first.state!.unlocked_level, 2);
    expect(await first.next_level(), isTrue);
    await first.tap_tile(first.state!.clickable_tiles.first.id);
    final TileQuestState previous = first.state!;
    first.onClose();

    final TileQuestLogic next = _new_logic(service);
    await next.initialize();
    expect(next.state!.level, 1);
    expect(next.state!.difficulty, TileQuestConfig.level1Difficulty);
    expect(next.state!.unlocked_level, 2);
    expect(next.state!.challenge_id, isNot(previous.challenge_id));
    expect(next.state!.seed, isNot(previous.seed));
    expect(next.state!.remaining_count, next.state!.total_count);
    expect(next.state!.tray, isEmpty);
    expect(next.state!.tools, _initial_tools);
    expect(await next.next_level(), isFalse);
    for (final int id in next.state!.certified_solution.toList()) {
      expect((await next.tap_tile(id))!.accepted, isTrue);
    }
    expect(await next.next_level(), isTrue);
    expect(next.state!.level, 2);
    expect(next.state!.difficulty, TileQuestConfig.gameDifficulty);
    next.onClose();
    await service.flush();
  });

  test(
    'restarting level two returns to a fresh first level and keeps preferences',
    () async {
      int now = 0;
      final TileQuestSaveService service = TileQuestSaveService(
        store: _EntryStore(),
      );
      final TileQuestLogic logic = _new_logic(service, now_ms: () => now);
      await logic.initialize();
      for (final int id in logic.state!.certified_solution.toList()) {
        await logic.tap_tile(id);
      }
      expect(await logic.next_level(), isTrue);
      expect(logic.state!.level, 2);
      final TileQuestState previous = logic.state!;
      await logic.tap_tile(logic.state!.clickable_tiles.first.id);
      await logic.remove();
      await logic.toggle_sound();
      now = 5000;
      logic.tick();
      expect(logic.elapsed_ms, 5000);
      await logic.restart();
      expect(logic.state!.level, 1);
      expect(logic.state!.difficulty, TileQuestConfig.level1Difficulty);
      expect(logic.state!.unlocked_level, 2);
      expect(logic.state!.challenge_id, isNot(previous.challenge_id));
      expect(logic.state!.seed, isNot(previous.seed));
      expect(logic.state!.tray, isEmpty);
      expect(logic.state!.reserve, isEmpty);
      expect(logic.state!.tools, _initial_tools);
      expect(logic.state!.tools_used, 0);
      expect(logic.state!.remaining_count, logic.state!.total_count);
      expect(logic.elapsed_ms, 0);
      expect(logic.can_undo, isFalse);
      expect(logic.recent_actions, isEmpty);
      expect(logic.sound_enabled, isFalse);
      expect(await logic.next_level(), isFalse);
      await logic.flush_save();
      final TileQuestState saved = (await service.load()).engine!.state;
      expect(saved.level, 1);
      expect(saved.unlocked_level, 2);
      expect(saved.sound_enabled, isFalse);
      logic.onClose();
      await service.flush();
    },
  );

  test(
    'same page initialization and foreground changes keep the current game',
    () async {
      int now = 0;
      final TileQuestSaveService service = TileQuestSaveService(
        store: _EntryStore(),
      );
      final _EntryWork work = _EntryWork();
      final TileQuestLogic logic = _new_logic(
        service,
        work: work,
        now_ms: () => now,
      );
      await logic.initialize();
      final String challenge = logic.state!.challenge_id;
      await logic.tap_tile(logic.state!.certified_solution.first);
      now = 500;
      logic.set_foreground(false);
      now = 60000;
      logic.set_foreground(true);
      await logic.initialize();
      await logic.resume_session();
      expect(work.generation_count, 1);
      expect(logic.state!.challenge_id, challenge);
      expect(logic.state!.tray, hasLength(1));
      expect(logic.elapsed_ms, 500);
      now += 250;
      logic.tick();
      expect(logic.elapsed_ms, 750);
      logic.onClose();
      await service.flush();
    },
  );

  test(
    'failed fresh generation preserves the old snapshot until retry succeeds',
    () async {
      final _EntryStore store = _EntryStore();
      final TileQuestSaveService service = TileQuestSaveService(store: store);
      final TileQuestEngine old = TileQuestEngine(
        TileQuestGenerator.generate(level: 2, seed: 42, unlocked_level: 2),
      );
      old.update_metadata(sound_enabled: false, elapsed_ms: 9000);
      old.tap_tile(old.state.clickable_tiles.first.id);
      await service.save(old);
      final String? previous_raw = store.value;
      final int previous_writes = store.write_count;
      final _EntryWork work = _EntryWork()..fail_generation = true;
      final TileQuestLogic logic = _new_logic(service, work: work);
      await logic.initialize();
      expect(logic.state, isNull);
      expect(logic.error_message, 'tile_quest.load_error');
      expect(store.value, previous_raw);
      expect(store.write_count, previous_writes);

      work.fail_generation = false;
      await logic.initialize();
      expect(work.generation_count, 2);
      expect(logic.state!.level, 1);
      expect(logic.state!.difficulty, TileQuestConfig.level1Difficulty);
      expect(logic.state!.unlocked_level, 2);
      expect(logic.state!.seed, 43);
      expect(logic.sound_enabled, isFalse);
      expect(logic.state!.tray, isEmpty);
      expect(logic.elapsed_ms, 0);
      expect(logic.error_message, isNull);
      logic.onClose();
      await service.flush();
    },
  );

  test(
    'a revoked fresh-generation worker cannot overwrite the next entry',
    () async {
      final _EntryStore store = _EntryStore();
      final TileQuestSaveService service = TileQuestSaveService(store: store);
      final TileQuestEngine old = TileQuestEngine(
        TileQuestGenerator.generate(level: 2, seed: 42, unlocked_level: 2),
      );
      await service.save(old);
      final _EntryWork slow_work = _EntryWork()
        ..generation_gate = Completer<void>();
      final TileQuestLogic first = _new_logic(service, work: slow_work);
      final Future<void> pending = first.initialize();
      await Future<void>.delayed(Duration.zero);
      expect(slow_work.generation_count, 1);

      final TileQuestLogic next = _new_logic(service);
      await next.initialize();
      await next.tap_tile(next.state!.clickable_tiles.first.id);
      await next.flush_save();
      final String? expected_raw = store.value;
      slow_work.generation_gate!.complete();
      await pending;
      expect(first.session_suspended, isTrue);
      expect(first.state, isNull);
      first.onClose();
      await service.flush();
      expect(store.value, expected_raw);
      expect(
        (await service.load()).engine!.state.challenge_id,
        next.state!.challenge_id,
      );
      next.onClose();
      await service.flush();
    },
  );

  test('repeated maximum seed wraps to a valid new challenge seed', () async {
    final TileQuestSaveService service = TileQuestSaveService(
      store: _EntryStore(),
    );
    final TileQuestLogic logic = _new_logic(
      service,
      next_seed: () => TileQuestConfig.max_seed,
    );
    await logic.initialize();
    final String previous_id = logic.state!.challenge_id;
    await logic.restart();
    expect(logic.state!.seed, 0);
    expect(logic.state!.challenge_id, isNot(previous_id));
    await logic.flush_save();
    expect((await service.load()).engine!.state.seed, 0);
    logic.onClose();
    await service.flush();
  });

  test(
    'Remove remains enabled with reserved tiles until its second use',
    () async {
      final TileQuestSaveService service = TileQuestSaveService(
        store: _EntryStore(),
      );
      final TileQuestLogic logic = _new_logic(service);
      await logic.initialize();
      final List<int> first_triple = logic.state!.certified_solution
          .take(3)
          .toList();
      await logic.tap_tile(first_triple[0]);
      await logic.tap_tile(first_triple[1]);
      expect(logic.can_remove, isTrue);
      expect((await logic.remove())!.accepted, isTrue);
      expect(logic.state!.reserve, hasLength(2));
      await logic.tap_tile(first_triple[2]);
      expect(logic.can_remove, isTrue);
      expect((await logic.remove())!.accepted, isTrue);
      expect(logic.state!.reserve, hasLength(3));
      expect(logic.state!.tools[TileQuestTool.remove], 0);
      expect(logic.can_remove, isFalse);
      logic.onClose();
      await service.flush();
    },
  );
}
