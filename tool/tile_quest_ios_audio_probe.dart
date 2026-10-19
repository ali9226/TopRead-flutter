// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:app/pages/tile_quest/services/ios_audio_voice.dart';
import 'package:flutter/foundation.dart' show debugPrintSynchronously;
import 'package:flutter/material.dart';

/// 真机原生桥探针，不加载登录、路由、网络、广告或游戏规则。
///
/// fvm flutter run --profile -t tool/tile_quest_ios_audio_probe.dart -d DEVICE_ID
/// 数值仅为 Dart 到原生方法返回的往返耗时，不代表扬声器声学输出延迟。
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: _IosAudioProbe()));
}

class _IosAudioProbe extends StatefulWidget {
  const _IosAudioProbe();

  @override
  State<_IosAudioProbe> createState() => _IosAudioProbeState();
}

class _IosAudioProbeState extends State<_IosAudioProbe>
    with WidgetsBindingObserver {
  static const _tap_count = 20;
  static const _tap_interval = Duration(milliseconds: 40);
  static const _call_deadline = Duration(seconds: 5);
  static const _settle_duration = Duration(milliseconds: 700);
  static const _log_prefix = 'TILE_QUEST_IOS_AUDIO_PROBE';

  final _taps = List.generate(4, (_) => TileQuestIosAudioVoice());
  final _matches = List.generate(2, (_) => TileQuestIosAudioVoice());
  final _tool = TileQuestIosAudioVoice();
  final _records = <Map<String, Object?>>[];
  final _run_clock = Stopwatch();
  bool _cancelled = false;
  bool _finished = false;
  bool _succeeded = false;
  String _status = 'Preparing 7 native PCM voices…';

  Iterable<TileQuestIosAudioVoice> get _voices => [
    ..._taps,
    ..._matches,
    _tool,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
  }

  void _emit(Map<String, Object?> record) {
    debugPrintSynchronously('$_log_prefix ${jsonEncode(record)}');
  }

  Future<void> _measure(
    String operation,
    String voice,
    Future<void> Function() action, {
    int? scheduled_us,
  }) async {
    final dispatch_us = _run_clock.elapsedMicroseconds;
    final clock = Stopwatch()..start();
    Object? failure;
    try {
      await action().timeout(_call_deadline);
    } on Object catch (error) {
      failure = error.toString();
    }
    clock.stop();
    final record = <String, Object?>{
      'kind': 'call',
      'operation': operation,
      'voice': voice,
      'elapsed_us': clock.elapsedMicroseconds,
      'ok': failure == null,
      'error': ?failure,
      'scheduled_us': ?scheduled_us,
      if (scheduled_us != null)
        'dispatch_lateness_us': dispatch_us - scheduled_us,
    };
    _records.add(record);
    _emit(record);
  }

  Future<void> _run() async {
    _emit({
      'kind': 'start',
      'measurement': 'platform_method_round_trip_not_acoustic_latency',
      'tap_count': _tap_count,
      'tap_interval_us': _tap_interval.inMicroseconds,
      'voice_count': _voices.length,
    });
    try {
      for (var index = 0; index < _taps.length; index++) {
        if (_cancelled) break;
        await _measure(
          'prepare',
          'tap_$index',
          () => _taps[index].prepare('audio/tile_quest/tap.wav'),
        );
      }
      for (var index = 0; index < _matches.length; index++) {
        if (_cancelled) break;
        await _measure(
          'prepare',
          'match_$index',
          () => _matches[index].prepare('audio/tile_quest/match.wav'),
        );
      }
      if (!_cancelled) {
        await _measure(
          'prepare',
          'tool_0',
          () => _tool.prepare('audio/tile_quest/tool.wav'),
        );
      }
      if (mounted) {
        setState(() => _status = '20 taps at 40 ms + overlapping matches…');
      }

      final concurrent_matches = <Future<void>>[];
      _run_clock.start();
      for (var index = 0; index < _tap_count && !_cancelled; index++) {
        // 用绝对时间安排输入，不把上一条平台返回耗时加到 40 ms 间隔上。
        final scheduled_us = index * _tap_interval.inMicroseconds;
        final remaining_us = scheduled_us - _run_clock.elapsedMicroseconds;
        if (remaining_us > 0) {
          await Future<void>.delayed(Duration(microseconds: remaining_us));
        }
        if (_cancelled) break;
        if (index == 5 || index == 13) {
          final match_index = index == 5 ? 0 : 1;
          concurrent_matches.add(
            _measure(
              'restart',
              'match_$match_index',
              () => _matches[match_index].restart(.78),
              scheduled_us: scheduled_us,
            ),
          );
        }
        final voice_index = index % _taps.length;
        await _measure(
          'restart',
          'tap_$voice_index',
          () => _taps[voice_index].restart(.72),
          scheduled_us: scheduled_us,
        );
      }
      await Future.wait(concurrent_matches);
      if (!_cancelled) {
        await _measure('restart', 'tool_0', () => _tool.restart(.70));
        await Future<void>.delayed(_settle_duration);
      }
    } finally {
      // 先停止所有自有声音，再逐一释放；即使某个调用失败也完成其他清理。
      var index = 0;
      await Future.wait(
        _voices.map(
          (voice) => _measure('stop', 'voice_${index++}', voice.stop),
        ),
      );
      index = 0;
      await Future.wait(
        _voices.map(
          (voice) => _measure('dispose', 'voice_${index++}', voice.dispose),
        ),
      );
      _run_clock.stop();
      _complete();
    }
  }

  void _complete() {
    final failures = _records.where((record) => record['ok'] != true).length;
    final groups = <String, List<int>>{};
    for (final record in _records) {
      final operation = record['operation']! as String;
      (groups[operation] ??= []).add(record['elapsed_us']! as int);
    }
    final timing_summary = <String, Object?>{};
    for (final entry in groups.entries) {
      final values = entry.value..sort();
      timing_summary[entry.key] = {
        'count': values.length,
        'min_us': values.first,
        'p50_us': values[(values.length * .50).ceil() - 1],
        'p95_us': values[(values.length * .95).ceil() - 1],
        'max_us': values.last,
      };
    }
    _succeeded = !_cancelled && failures == 0;
    _finished = true;
    _emit({
      'kind': 'summary',
      'measurement': 'platform_method_round_trip_not_acoustic_latency',
      'ok': _succeeded,
      'cancelled': _cancelled,
      'success_count': _records.length - failures,
      'failure_count': failures,
      'tap_restart_count': _records
          .where(
            (record) =>
                record['operation'] == 'restart' &&
                (record['voice']! as String).startsWith('tap_'),
          )
          .length,
      'timings': timing_summary,
    });
    debugPrintSynchronously('${_log_prefix}_DONE');
    if (mounted) {
      setState(() {
        _status = _succeeded
            ? 'Completed: 20 taps, 2 matches, 1 tool.\nAll 7 voices stopped and disposed.'
            : 'Completed with $failures failed calls.\nCancelled: $_cancelled';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_finished &&
        (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused ||
            state == AppLifecycleState.detached)) {
      _cancelled = true;
      for (final voice in _voices) {
        unawaited(voice.stop().catchError((Object _) {}));
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelled = true;
    for (final voice in _voices) {
      unawaited(voice.dispose().catchError((Object _) {}));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('iOS PCM Audio Probe')),
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _finished
                    ? (_succeeded ? Icons.check_circle : Icons.error)
                    : Icons.volume_up,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(_status, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text(
                'Method round-trip timings only.\nAcoustic output latency is not measured.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
