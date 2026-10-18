// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/services/save_service.dart';
import 'package:app/pages/tile_quest/services/work_service.dart';
import 'package:app/pages/tile_quest/widgets/quest_scene.dart';

/// 独立 profile 入口；只运行真实棋盘、规则和存档，不触碰正式应用会话。
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (const bool.fromEnvironment('TILE_QUEST_SINGLE_CPU')) {
    _limit_to_single_cpu();
  }
  runApp(const MaterialApp(home: _PerformancePage()));
}

class _PerformancePage extends StatefulWidget {
  const _PerformancePage();
  @override
  State<_PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<_PerformancePage> {
  final _work = TileQuestIsolateWork();
  final _save = TileQuestSaveService(store: _MemoryStore());
  final _actions = <TileQuestActionResult>[];
  final _frames = <FrameTiming>[];
  TileQuestEngine? _engine;
  bool _scene_busy = false;
  String? _phase;
  String _label = 'Preparing';

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_on_frames);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
  }

  void _on_frames(List<FrameTiming> frames) {
    if (_phase != null) _frames.addAll(frames);
  }

  Future<void> _run() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    // 覆盖默认关、极限可解关与最大必败关，避免只测较浅的默认棋盘。
    for (final difficulty in [8, 9, 10]) {
      final state = await compute(_generate, difficulty);
      setState(() {
        _engine = TileQuestEngine(state);
        _actions.clear();
        _label = '${state.total_count} tiles: warmup';
      });
      await Future<void>.delayed(const Duration(seconds: 3));
      await _measure('${state.total_count}_shuffle', () async {
        final prepared = await _work.shuffle(
          _engine!.export_json(),
          seed: 54321,
        );
        setState(() {
          _engine = prepared.engine;
          _actions.add(prepared.result);
        });
        unawaited(_save.save(_engine!));
        await Future<void>.delayed(const Duration(milliseconds: 2600));
      });
      setState(() {
        _engine = TileQuestEngine(state);
        _actions.clear();
      });
      await Future<void>.delayed(const Duration(seconds: 1));
      await _measure('${state.total_count}_rapid_40ms', () async {
        final snapshot = _engine!.state;
        final path =
            snapshot.expert_barrier?.lead_solution ??
            snapshot.certified_solution;
        final solution = List<int>.of(path).take(60);
        for (final id in solution) {
          final result = _engine!.tap_tile(id);
          if (!result.accepted) throw StateError('Profile move rejected: $id');
          setState(() => _actions.add(result));
          unawaited(_save.save(_engine!));
          await Future<void>.delayed(const Duration(milliseconds: 40));
        }
        await Future<void>.delayed(const Duration(milliseconds: 1800));
      });
      await _save.flush();
    }
    setState(() => _label = 'Profile completed');
    debugPrint('TILE_QUEST_PROFILE_DONE');
  }

  Future<void> _measure(String phase, Future<void> Function() run) async {
    _frames.clear();
    _phase = phase;
    setState(() => _label = phase);
    await run();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _phase = null;
    if (!mounted) return;
    if (_scene_busy) {
      throw StateError('Visual transactions did not settle after $phase');
    }
    final build = _frames
        .map((f) => f.buildDuration.inMicroseconds / 1000)
        .toList();
    final raster = _frames
        .map((f) => f.rasterDuration.inMicroseconds / 1000)
        .toList();
    final worst = _frames
        .map(
          (f) =>
              math.max(
                f.buildDuration.inMicroseconds,
                f.rasterDuration.inMicroseconds,
              ) /
              1000,
        )
        .toList();
    final result = <String, dynamic>{
      'phase': phase,
      'difficulty': _engine!.state.difficulty,
      'barrier_minimum_remove_uses':
          _engine!.state.expert_barrier?.minimum_remove_uses ?? 0,
      'profile_mode': kProfileMode,
      'single_cpu': const bool.fromEnvironment('TILE_QUEST_SINGLE_CPU'),
      'action_count': _actions.length,
      'presentation_settled': !_scene_busy,
      'refresh_hz': View.of(context).display.refreshRate,
      'frame_count': _frames.length,
      'build_ms': _statistics(build),
      'raster_ms': _statistics(raster),
      'slowest_thread_ms': _statistics(worst),
      'jank_60hz': worst.where((ms) => ms > 1000 / 60).length,
      'jank_30hz': worst.where((ms) => ms > 1000 / 30).length,
    };
    debugPrint('TILE_QUEST_PROFILE ${jsonEncode(result)}');
  }

  Map<String, double> _statistics(List<double> values) {
    values.sort();
    if (values.isEmpty) return {'p50': 0, 'p95': 0, 'max': 0};
    double at(double p) => values[((values.length - 1) * p).round()];
    return {'p50': at(.50), 'p95': at(.95), 'max': values.last};
  }

  @override
  Widget build(BuildContext context) {
    final engine = _engine;
    return Scaffold(
      backgroundColor: const Color(0xff132743),
      body: engine == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                TileQuestScene(
                  state: engine.state,
                  action: _actions.lastOrNull,
                  recent_actions: List.of(_actions),
                  animate_entry: false,
                  sound_enabled: false,
                  busy: false,
                  on_presentation_busy_changed: (value) => _scene_busy = value,
                  on_back: () {},
                  on_restart: () {},
                  on_sound: () {},
                  on_tile: (_) {},
                  on_reserve: (_) {},
                  on_tool: (_) {},
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Text(
                    _label,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_on_frames);
    super.dispose();
  }
}

TileQuestState _generate(int difficulty) => TileQuestGenerator.generate(
  level: 2,
  seed: 12345,
  difficulty: difficulty,
  challenge_id: 'tile_quest_profile_$difficulty',
);

class _MemoryStore implements TileQuestSaveStore {
  String? _value;
  @override
  Future<String?> read() async => _value;
  @override
  Future<void> write(String value) async => _value = value;
}

/// 仅对独立基准进程施加单核亲和压力；不更改系统频率、刷新率或正式应用。
/// 全部现有线程绑定到 CPU0，后续线程继承其创建线程的亲和掩码。
void _limit_to_single_cpu() {
  if (!Platform.isAndroid) {
    throw UnsupportedError('Single CPU profiling requires Android');
  }
  final libc = ffi.DynamicLibrary.open('libc.so');
  final allocate = libc
      .lookupFunction<
        ffi.Pointer<ffi.Uint8> Function(ffi.UintPtr),
        ffi.Pointer<ffi.Uint8> Function(int)
      >('malloc');
  final release = libc
      .lookupFunction<
        ffi.Void Function(ffi.Pointer<ffi.Uint8>),
        void Function(ffi.Pointer<ffi.Uint8>)
      >('free');
  final set_affinity = libc
      .lookupFunction<
        ffi.Int32 Function(ffi.Int32, ffi.UintPtr, ffi.Pointer<ffi.Uint8>),
        int Function(int, int, ffi.Pointer<ffi.Uint8>)
      >('sched_setaffinity');
  const mask_size = 128;
  final mask = allocate(mask_size);
  if (mask == ffi.nullptr) throw StateError('CPU mask allocation failed');
  try {
    mask.asTypedList(mask_size).fillRange(0, mask_size, 0);
    mask[0] = 1;
    var threads = 0;
    for (final entity in Directory('/proc/self/task').listSync()) {
      final tid = int.parse(entity.path.split('/').last);
      if (set_affinity(tid, mask_size, mask) != 0) {
        throw StateError('Single CPU affinity rejected for thread $tid');
      }
      threads++;
    }
    debugPrint('TILE_QUEST_PROFILE_CPU {"cpu":0,"threads":$threads}');
  } finally {
    release(mask);
  }
}
