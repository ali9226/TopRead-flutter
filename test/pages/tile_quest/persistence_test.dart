// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'certificate_replay.dart';
import 'dart:convert';
import 'dart:io';

import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/logic.dart';
import 'package:app/pages/tile_quest/services/feedback_service.dart';
import 'package:app/pages/tile_quest/services/save_service.dart';
import 'package:app/pages/tile_quest/services/work_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:get/utils.dart';
import 'package:get_storage/get_storage.dart';

class _MemoryStore implements TileQuestSaveStore {
  String? value;
  bool fail_write = false;
  bool fail_read = false;
  int write_count = 0;

  @override
  Future<String?> read() async {
    if (fail_read) throw StateError('read unavailable');
    return value;
  }

  @override
  Future<void> write(String value) async {
    write_count++;
    if (fail_write) throw StateError('disk full');
    this.value = value;
  }
}

class _GatedStore extends _MemoryStore {
  final List<String> started_values = <String>[];
  final List<Completer<void>> gates = <Completer<void>>[];

  @override
  Future<void> write(String value) async {
    started_values.add(value);
    final Completer<void> gate = Completer<void>();
    gates.add(gate);
    await gate.future;
    await super.write(value);
  }
}

class _SilentFeedback implements TileQuestFeedbackService {
  @override
  Future<void> play(TileQuestFeedbackEvent event) async {}
}

class _FailedFlushQueue extends GetQueue {
  @override
  Future<T> add<T>(Function job) =>
      Future<T>.error(const FileSystemException('disk full'));
}

class _TestWork implements TileQuestWorkService {
  int generation_count = 0;
  Completer<void>? generation_gate;
  Completer<void>? shuffle_gate;

  @override
  Future<TileQuestState> generate({
    required int level,
    required int seed,
    required int unlocked_level,
    String? challenge_id,
    int? layout_seed,
    num? difficulty,
  }) async {
    generation_count++;
    await generation_gate?.future;
    return TileQuestGenerator.generate(
      level: level,
      seed: seed,
      unlocked_level: unlocked_level,
      challenge_id: challenge_id,
      layout_seed: layout_seed,
      difficulty: difficulty,
    );
  }

  @override
  Future<TileQuestPreparedShuffle> shuffle(
    Map<String, dynamic> engine_json, {
    required int seed,
  }) async {
    await shuffle_gate?.future;
    final TileQuestEngine engine = TileQuestEngine.restore(engine_json);
    return TileQuestPreparedShuffle(
      engine: engine,
      result: engine.shuffle(seed: seed),
    );
  }
}

TileQuestLogic _logic(
  TileQuestSaveService service, {
  _TestWork? work,
  int Function()? clock,
}) => TileQuestLogic(
  save_service: service,
  work_service: work ?? _TestWork(),
  feedback_service: _SilentFeedback(),
  now_ms: clock ?? () => 0,
  next_seed: () => 42,
  enable_timer: false,
);

Future<void> _drain() => Future<void>.delayed(Duration.zero);

Future<void> _wait_for(bool Function() ready) async {
  final watch = Stopwatch()..start();
  while (!ready()) {
    if (watch.elapsed > const Duration(seconds: 5)) {
      throw StateError('Background save did not reach the expected checkpoint');
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'local adapter awaits GetStorage disk flush and catches flush errors',
    () async {
      final Directory directory = await Directory.systemTemp.createTemp(
        'tile_quest_storage_',
      );
      const MethodChannel path_channel = MethodChannel(
        'plugins.flutter.io/path_provider',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(path_channel, (_) async => directory.path);
      final GetStorage box = GetStorage('GetStorage', directory.path);
      await box.initStorage;
      final TileQuestLocalStore local_store = TileQuestLocalStore();
      await local_store.write('committed');
      final File file = File('${directory.path}/GetStorage.gs');
      expect(
        (jsonDecode(await file.readAsString())
            as Map)[TileQuestLocalStore.storage_key],
        'committed',
      );
      final GetQueue original_queue = box.queue;
      box.queue = _FailedFlushQueue();
      await expectLater(
        local_store.write('uncommitted'),
        throwsA(isA<FileSystemException>()),
      );
      box.queue = original_queue;
      await local_store.write('retried');
      expect(
        (jsonDecode(await file.readAsString())
            as Map)[TileQuestLocalStore.storage_key],
        'retried',
      );
      box.writeInMemory(TileQuestLocalStore.storage_key, <String, int>{
        'bad': 1,
      });
      expect(await local_store.read(), '');
      // GetStorage 的备用文件写入在 flush 尾部独立调度。
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await directory.delete(recursive: true);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(path_channel, null);
    },
  );

  test(
    'queue captures immutable snapshots and never writes concurrently',
    () async {
      final _GatedStore store = _GatedStore();
      final TileQuestSaveService service = TileQuestSaveService(store: store);
      final TileQuestEngine engine = TileQuestEngine(
        TileQuestGenerator.generate(level: 1, seed: 42),
      );
      final Future<void> first = service.save(engine);
      await _wait_for(() => store.started_values.length == 1);
      engine.tap_tile(engine.state.certified_solution.first);
      final Future<void> second = service.save(engine);
      bool load_finished = false;
      final Future<TileQuestLoadedSave> loading = service.load().then((value) {
        load_finished = true;
        return value;
      });
      await _drain();
      expect(store.started_values, hasLength(1));
      expect(load_finished, isFalse);
      store.gates.first.complete();
      await first;
      await _wait_for(() => store.started_values.length == 2);
      expect(store.started_values, hasLength(2));
      expect(load_finished, isFalse);
      store.gates.last.complete();
      await second;
      final TileQuestLoadedSave loaded = await loading;
      expect(loaded.engine!.state.tray, engine.state.tray);
      final Map<String, dynamic> first_json =
          jsonDecode(store.started_values.first) as Map<String, dynamic>;
      final TileQuestEngine original = TileQuestEngine.restore(
        Map<String, dynamic>.from(first_json['engine'] as Map),
      );
      expect(original.state.tray, isEmpty);
      expect(loaded.engine!.state.tray, hasLength(1));
    },
  );

  test(
    'waiting writes coalesce to the newest immutable state and flush it',
    () async {
      final store = _GatedStore();
      final service = TileQuestSaveService(store: store);
      final engine = TileQuestEngine(
        TileQuestGenerator.generate(level: 1, seed: 42),
      );
      final first = service.save(engine);
      await _wait_for(() => store.started_values.length == 1);
      final pending = <Future<void>>[];
      for (final id in List<int>.of(engine.state.certified_solution).take(3)) {
        engine.tap_tile(id);
        pending.add(service.save(engine));
      }
      final expected = engine.export_json();
      // A later mutation without save must not alter the pending snapshot.
      engine.update_metadata(sound_enabled: false);
      store.gates.first.complete();
      await first;
      await _wait_for(() => store.started_values.length == 2);
      expect(store.started_values, hasLength(2));
      store.gates.last.complete();
      await Future.wait(pending);
      await service.flush();
      expect((await service.load()).engine!.export_json(), expected);
      expect(store.write_count, 2);
    },
  );

  testWidgets(
    'tap saves share a fixed window without postponing its deadline',
    (tester) async {
      final store = _MemoryStore();
      final service = TileQuestSaveService(
        store: store,
        encode_snapshot: encode_tile_quest_snapshot,
      );
      final logic = _logic(service);
      await logic.initialize();
      await logic.flush_save();
      final initial_writes = store.write_count;
      final path = List<int>.of(logic.state!.certified_solution);
      await logic.tap_tile(path[0]);
      await tester.pump(const Duration(milliseconds: 120));
      await logic.tap_tile(path[1]);
      await tester.pump(const Duration(milliseconds: 119));
      expect(store.write_count, initial_writes);
      await tester.pump(const Duration(milliseconds: 1));
      await service.flush();
      expect(store.write_count, initial_writes + 1);
      expect((await service.load()).engine!.state.tray, logic.state!.tray);
      logic.onClose();
      await service.flush();
    },
  );

  testWidgets('background and restart flush and cancel a pending tap window', (
    tester,
  ) async {
    final store = _MemoryStore();
    final service = TileQuestSaveService(
      store: store,
      encode_snapshot: encode_tile_quest_snapshot,
    );
    final logic = _logic(service);
    await logic.initialize();
    await logic.flush_save();
    await logic.tap_tile(logic.state!.certified_solution.first);
    logic.set_foreground(false);
    await service.flush();
    expect((await service.load()).engine!.state.tray, logic.state!.tray);
    final background_writes = store.write_count;
    await tester.pump(TileQuestConfig.progress_save_window * 2);
    expect(store.write_count, background_writes);
    logic.set_foreground(true);
    await logic.tap_tile(logic.state!.certified_solution.first);
    await logic.restart();
    await service.flush();
    expect(
      (await service.load()).engine!.state.challenge_id,
      logic.state!.challenge_id,
    );
    final restart_writes = store.write_count;
    await tester.pump(TileQuestConfig.progress_save_window * 2);
    expect(store.write_count, restart_writes);
    logic.onClose();
    await service.flush();
  });

  test('isolate worker transfers generated and shuffled engines', () async {
    final TileQuestIsolateWork work = TileQuestIsolateWork();
    final TileQuestState state = await work.generate(
      level: 1,
      seed: 42,
      unlocked_level: 1,
      challenge_id: 'isolate_test',
    );
    expect(state.challenge_id, 'isolate_test');
    final TileQuestPreparedShuffle shuffled = await work.shuffle(
      TileQuestEngine(state).export_json(),
      seed: 43,
    );
    expect(shuffled.result.accepted, isTrue);
    expect(shuffled.engine.state.tools[TileQuestTool.shuffle], 0);
    expect(shuffled.engine.state.total_count, state.total_count);
  });

  test(
    'reentry creates a fresh challenge and retains sound preference',
    () async {
      final _MemoryStore store = _MemoryStore();
      final TileQuestSaveService service = TileQuestSaveService(store: store);
      final TileQuestLogic first = _logic(service);
      await first.initialize();
      final int tile_id = first.state!.certified_solution.first;
      await first.tap_tile(tile_id);
      await first.remove();
      await first.toggle_sound();
      await first.leave_game();
      final TileQuestState previous = first.state!;
      first.onClose();

      final TileQuestLogic second = _logic(service);
      await second.initialize();
      expect(second.state!.challenge_id, isNot(previous.challenge_id));
      expect(second.state!.seed, isNot(previous.seed));
      expect(second.state!.tray, isEmpty);
      expect(second.state!.reserve, isEmpty);
      expect(second.state!.tools_used, 0);
      expect(
        second.state!.tools[TileQuestTool.remove],
        TileQuestConfig.initial_tool_uses(TileQuestTool.remove),
      );
      expect(second.can_undo, isFalse);
      expect((await second.undo())!.accepted, isFalse);
      expect(second.sound_enabled, isFalse);
      expect(second.state!.remaining_count, second.state!.total_count);
      second.onClose();
      await service.flush();
    },
  );

  test(
    'saved level two reopens at level one with unlock and sound retained',
    () async {
      final TileQuestSaveService service = TileQuestSaveService(
        store: _MemoryStore(),
      );
      final TileQuestEngine previous = TileQuestEngine(
        TileQuestGenerator.generate(level: 2, seed: 42, unlocked_level: 2),
      );
      previous.update_metadata(sound_enabled: false, elapsed_ms: 9000);
      previous.tap_tile(previous.state.clickable_tiles.first.id);
      previous.remove();
      await service.save(previous);

      final TileQuestLogic logic = _logic(service);
      await logic.initialize();
      expect(logic.state!.level, 1);
      expect(logic.state!.difficulty, TileQuestConfig.level1Difficulty);
      expect(logic.state!.unlocked_level, 2);
      expect(logic.sound_enabled, isFalse);
      expect(logic.elapsed_ms, 0);
      expect(logic.state!.tray, isEmpty);
      expect(logic.state!.reserve, isEmpty);
      expect(await logic.next_level(), isFalse);
      await logic.flush_save();
      final TileQuestState saved = (await service.load()).engine!.state;
      expect(saved.level, 1);
      expect(saved.unlocked_level, 2);
      expect(saved.sound_enabled, isFalse);
      expect(
        saved.tools[TileQuestTool.remove],
        TileQuestConfig.initial_tool_uses(TileQuestTool.remove),
      );
      logic.onClose();
      await service.flush();
    },
  );

  test('bad, partial and future-version saves safely recover', () async {
    final TileQuestEngine original = TileQuestEngine(
      TileQuestGenerator.generate(level: 1, seed: 42),
    );
    final Map<String, dynamic> broken_engine = original.export_json();
    // 缺失的关键字段不能被静默补默认值。
    broken_engine.clear();
    final List<String> bad_saves = <String>[
      '',
      '{truncated',
      '[]',
      jsonEncode(<String, dynamic>{
        'version': 999,
        'engine': <String, dynamic>{},
      }),
      jsonEncode(<String, dynamic>{'version': 1, 'engine': broken_engine}),
    ];
    for (final String raw in bad_saves) {
      final _MemoryStore store = _MemoryStore()..value = raw;
      final TileQuestSaveService service = TileQuestSaveService(store: store);
      final TileQuestLogic logic = _logic(service);
      await logic.initialize();
      expect(logic.state!.status, TileQuestStatus.playing);
      expect(logic.state!.level, 1);
      expect(logic.save_recovered, isTrue);
      logic.onClose();
      await service.flush();
    }
  });

  test(
    'retired palette discards the board but keeps validated preferences',
    () async {
      final original = TileQuestEngine(
        TileQuestGenerator.generate(level: 1, seed: 42, unlocked_level: 2),
      );
      original.update_metadata(sound_enabled: false);
      final engine_json = original.export_json();
      final state_json = engine_json['state'] as Map<String, dynamic>;
      // 模拟旧 32 图案表，不能用 type % 15 合并类型来续玩旧棋盘。
      for (final tile in state_json['tiles'] as List) {
        tile['type'] = (tile['type'] as int) + 15;
      }
      final store = _MemoryStore()
        ..value = jsonEncode({
          'version': TileQuestSaveService.save_version,
          'engine': engine_json,
        });
      final service = TileQuestSaveService(store: store);
      final loaded = await service.load();
      expect(loaded.recovered, isTrue);
      expect(loaded.engine, isNull);
      expect(loaded.previous_seed, 42);
      expect(loaded.unlocked_level, 2);
      expect(loaded.sound_enabled, isFalse);
      final logic = _logic(service);
      await logic.initialize();
      expect(logic.state!.level, 1);
      expect(logic.state!.unlocked_level, 2);
      expect(logic.state!.sound_enabled, isFalse);
      expect(logic.state!.seed, isNot(42));
      expect(
        logic.state!.tiles.map((tile) => tile.type),
        everyElement(inInclusiveRange(0, TileQuestConfig.max_tile_types - 1)),
      );
      logic.onClose();
      await service.flush();
    },
  );

  test('save failure is visible and retry repairs the queue', () async {
    final _MemoryStore store = _MemoryStore();
    final TileQuestSaveService service = TileQuestSaveService(store: store);
    final TileQuestLogic logic = _logic(service);
    await logic.initialize();
    await logic.flush_save();
    store.fail_write = true;
    await logic.tap_tile(logic.state!.certified_solution.first);
    await logic.flush_save();
    expect(logic.has_save_error, isTrue);
    final TileQuestLogic reentered = _logic(service);
    await reentered.initialize();
    expect(reentered.has_save_error, isTrue);
    store.fail_write = false;
    await reentered.retry_save();
    expect(reentered.has_save_error, isFalse);
    expect(
      (await service.load()).engine!.state.to_json(),
      reentered.state!.to_json(),
    );
    logic.onClose();
    reentered.onClose();
    await service.flush();
  });

  test('read failure preserves old save until an explicit retry', () async {
    final _MemoryStore store = _MemoryStore()
      ..value = 'old contents'
      ..fail_read = true;
    final TileQuestSaveService service = TileQuestSaveService(store: store);
    final TileQuestLogic logic = _logic(service);
    await logic.initialize();
    expect(logic.state, isNull);
    expect(logic.error_message, 'tile_quest.load_error');
    expect(store.value, 'old contents');
    expect(store.write_count, 0);
    store.fail_read = false;
    await logic.initialize();
    expect(logic.state, isNotNull);
    logic.onClose();
    await service.flush();
  });

  test('initialization and expensive operations reject reentry', () async {
    final _MemoryStore store = _MemoryStore();
    final TileQuestSaveService service = TileQuestSaveService(store: store);
    final _TestWork work = _TestWork()..generation_gate = Completer<void>();
    final TileQuestLogic logic = _logic(service, work: work);
    final Future<void> first = logic.initialize();
    final Future<void> second = logic.initialize();
    await _drain();
    expect(work.generation_count, 1);
    work.generation_gate!.complete();
    await Future.wait(<Future<void>>[first, second]);

    work.shuffle_gate = Completer<void>();
    final Future<TileQuestActionResult?> shuffle = logic.shuffle();
    expect(logic.is_busy, isTrue);
    expect(await logic.shuffle(), isNull);
    expect(await logic.tap_tile(logic.state!.certified_solution.first), isNull);
    work.shuffle_gate!.complete();
    await shuffle;
    expect(logic.is_busy, isFalse);
    logic.onClose();
    await service.flush();
  });

  test('elapsed time excludes background and resets on new entry', () async {
    int now = 0;
    final _MemoryStore store = _MemoryStore();
    final TileQuestSaveService service = TileQuestSaveService(store: store);
    final TileQuestLogic logic = _logic(service, clock: () => now);
    await logic.initialize();
    now = 1250;
    logic.tick();
    expect(logic.elapsed_ms, 1250);
    logic.set_foreground(false);
    now = 901250;
    logic.tick();
    expect(logic.elapsed_ms, 1250);
    logic.set_foreground(true);
    now = 902000;
    logic.tick();
    expect(logic.elapsed_ms, 2000);
    await logic.leave_game();
    logic.onClose();
    now = 1902000;
    final TileQuestLogic restored = _logic(service, clock: () => now);
    await restored.initialize();
    expect(restored.elapsed_ms, 0);
    restored.onClose();
    await service.flush();
  });

  test(
    'restart is a new challenge and resets tools but retains sound',
    () async {
      final _MemoryStore store = _MemoryStore();
      final TileQuestSaveService service = TileQuestSaveService(store: store);
      final TileQuestLogic logic = _logic(service);
      await logic.initialize();
      final String old_id = logic.state!.challenge_id;
      await logic.tap_tile(logic.state!.certified_solution.first);
      await logic.remove();
      await logic.toggle_sound();
      await logic.restart();
      expect(logic.state!.challenge_id, isNot(old_id));
      expect(logic.state!.seed, 43);
      expect(logic.state!.tray, isEmpty);
      expect(logic.state!.reserve, isEmpty);
      expect(logic.state!.elapsed_ms, 0);
      expect(logic.sound_enabled, isFalse);
      expect(logic.state!.tools, <TileQuestTool, int>{
        for (final TileQuestTool tool in TileQuestTool.values)
          tool: TileQuestConfig.initial_tool_uses(tool),
      });
      expect(logic.state!.tools_used, 0);
      logic.onClose();
      await service.flush();
    },
  );

  test(
    'rapid same-frame actions are captured once and reset on restart',
    () async {
      final TileQuestSaveService service = TileQuestSaveService(
        store: _MemoryStore(),
      );
      final TileQuestLogic logic = _logic(service);
      await logic.initialize();
      final List<int> path = List<int>.of(logic.state!.certified_solution);
      final List<Future<TileQuestActionResult?>> actions = path
          .take(3)
          .map(logic.tap_tile)
          .toList();
      await Future.wait(actions);
      expect(logic.recent_actions, hasLength(3));
      expect((await logic.tap_tile(path.first))!.accepted, isFalse);
      logic.tick();
      expect(logic.recent_actions, hasLength(3));
      await logic.restart();
      expect(logic.recent_actions, isEmpty);
      expect(logic.last_action, isNull);
      logic.onClose();
      await service.flush();
    },
  );

  test(
    'new controller revokes old timers and delayed close cannot overwrite',
    () async {
      int now = 0;
      final TileQuestSaveService service = TileQuestSaveService(
        store: _MemoryStore(),
      );
      final TileQuestLogic first = _logic(service, clock: () => now);
      await first.initialize();
      await first.tap_tile(first.state!.certified_solution.first);
      await first.remove();
      now = 1000;

      final TileQuestLogic second = _logic(service, clock: () => now);
      await second.initialize();
      expect(first.session_suspended, isTrue);
      expect(
        second.state!.tools[TileQuestTool.remove],
        TileQuestConfig.initial_tool_uses(TileQuestTool.remove),
      );
      expect(second.elapsed_ms, 0);
      await second.restart();
      await second.tap_tile(second.state!.certified_solution.first);
      await second.remove();
      await second.toggle_sound();
      await second.flush_save();
      final Map<String, dynamic> expected = second.state!.to_json();
      final int old_elapsed = first.elapsed_ms;
      now = 10000;
      first.tick();
      expect(first.elapsed_ms, old_elapsed);
      expect(
        await first.tap_tile(first.state!.clickable_tiles.first.id),
        isNull,
      );
      await first.toggle_sound();
      first.onClose();
      await service.flush();
      expect((await service.load()).engine!.state.to_json(), expected);
      second.onClose();
      await service.flush();
    },
  );

  test(
    'suspended controller reads preferences and starts fresh on takeover',
    () async {
      final TileQuestSaveService service = TileQuestSaveService(
        store: _MemoryStore(),
      );
      final TileQuestLogic first = _logic(service);
      await first.initialize();
      final String old_challenge = first.state!.challenge_id;
      final TileQuestLogic second = _logic(service);
      await second.initialize();
      await second.restart();
      await second.tap_tile(second.state!.certified_solution.first);
      await second.toggle_sound();
      final TileQuestState previous = second.state!;
      await first.resume_session();
      expect(first.session_suspended, isFalse);
      expect(second.session_suspended, isTrue);
      expect(first.state!.challenge_id, isNot(previous.challenge_id));
      expect(first.state!.seed, isNot(previous.seed));
      expect(first.state!.challenge_id, isNot(old_challenge));
      expect(first.sound_enabled, isFalse);
      expect(first.state!.tray, isEmpty);
      expect(first.state!.reserve, isEmpty);
      expect((await first.remove())!.accepted, isFalse);
      final Map<String, dynamic> latest = first.state!.to_json();
      second.onClose();
      await first.flush_save();
      expect((await service.load()).engine!.state.to_json(), latest);
      first.onClose();
      await service.flush();
    },
  );

  for (final String operation in <String>['initialize', 'restart', 'shuffle']) {
    test(
      'revoked $operation worker cannot mutate or save after takeover',
      () async {
        final TileQuestSaveService service = TileQuestSaveService(
          store: _MemoryStore(),
        );
        final _TestWork work = _TestWork();
        final TileQuestLogic first = _logic(service, work: work);
        if (operation != 'initialize') await first.initialize();
        final Completer<void> gate = Completer<void>();
        final Future<void> pending;
        if (operation == 'shuffle') {
          work.shuffle_gate = gate;
          pending = first.shuffle().then<void>((_) {});
        } else {
          work.generation_gate = gate;
          pending = operation == 'initialize'
              ? first.initialize()
              : first.restart();
        }
        await _drain();
        final TileQuestLogic second = _logic(service);
        await second.initialize();
        await second.restart();
        await second.tap_tile(second.state!.certified_solution.first);
        await second.flush_save();
        final Map<String, dynamic> expected = second.state!.to_json();
        gate.complete();
        await pending;
        first.tick();
        first.onClose();
        await service.flush();
        expect((await service.load()).engine!.state.to_json(), expected);
        expect(second.state!.to_json(), expected);
        second.onClose();
        await service.flush();
      },
    );
  }

  test('victory unlocks level two and never creates a third level', () async {
    final _MemoryStore store = _MemoryStore();
    final TileQuestSaveService service = TileQuestSaveService(store: store);
    final TileQuestLogic logic = _logic(service);
    await logic.initialize();
    expect(await logic.next_level(), isFalse);
    for (final int id in List<int>.of(logic.state!.certified_solution)) {
      expect(
        (await replay_logic_certificate_step(logic, id))!.accepted,
        isTrue,
      );
    }
    expect(logic.state!.status, TileQuestStatus.won);
    expect(logic.state!.unlocked_level, 2);
    expect(await logic.next_level(), isTrue);
    expect(logic.state!.level, 2);
    for (final int id in List<int>.of(logic.state!.certified_solution)) {
      expect(
        (await replay_logic_certificate_step(logic, id))!.accepted,
        isTrue,
      );
    }
    expect(logic.state!.status, TileQuestStatus.won);
    expect(logic.state!.unlocked_level, 2);
    expect(await logic.next_level(), isFalse);
    expect(logic.state!.level, 2);
    logic.onClose();
    await service.flush();
  });
}
