// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:app/pages/tile_quest/services/feedback_service.dart';
import 'package:app/pages/tile_quest/services/ios_audio_voice.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Voice implements TileQuestAudioVoice {
  _Voice({this.prepare_gate, this.play_gate, this.fail_asset});
  final Completer<void>? prepare_gate;
  final Completer<void>? play_gate;
  final String? fail_asset;
  final calls = <String>[];
  final started = Completer<void>();
  String? asset;
  bool playing = false;
  int dispose_count = 0;
  bool fail_stop = false;

  @override
  Future<void> prepare(String value) async {
    asset = value;
    calls.add('prepare');
    await prepare_gate?.future;
    if (value == fail_asset) throw StateError('Audio prepare interrupted');
  }

  @override
  Future<void> play(double volume) async {
    expect(volume, inExclusiveRange(0, 1));
    calls.add('play');
    if (!started.isCompleted) started.complete();
    await play_gate?.future;
    playing = true;
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    playing = false;
    if (fail_stop) throw StateError('Audio stop interrupted');
  }

  @override
  Future<void> dispose() async {
    calls.add('dispose');
    playing = false;
    dispose_count++;
  }
}

/// 模拟单个入场文件迟迟无法就绪，点击音效文件已经预载完成的情况。
class _SlowEntryVoice extends _Voice {
  _SlowEntryVoice(this.entry_gate);
  final Completer<void> entry_gate;

  @override
  Future<void> prepare(String value) async {
    if (value.endsWith('/entry.wav')) await entry_gate.future;
    await super.prepare(value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all original cues are compact, quiet-ended unclipped mono PCM assets',
    () {
      final specs = TileQuestAudioFeedback.sound_specs;
      expect(specs.keys.toSet(), TileQuestFeedbackEvent.values.toSet());
      var bytes_total = 0;
      for (final spec in specs.values) {
        final bytes = File('assets/${spec.asset}').readAsBytesSync();
        bytes_total += bytes.length;
        final data = ByteData.sublistView(bytes);
        expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
        expect(data.getUint16(20, Endian.little), 1); // Integer PCM.
        expect(data.getUint16(22, Endian.little), 1); // Mono.
        expect(data.getUint16(34, Endian.little), 16);
        final rate = data.getUint32(24, Endian.little);
        expect(rate, 22050);
        final sample_count = data.getUint32(40, Endian.little) ~/ 2;
        expect(bytes.length, 44 + sample_count * 2);
        expect(
          sample_count / rate,
          closeTo(spec.duration.inMicroseconds / 1000000, 1 / rate),
        );
        var maximum = 0;
        var sum = 0;
        var sum_squares = 0.0;
        for (var index = 0; index < sample_count; index++) {
          final value = data.getInt16(44 + index * 2, Endian.little);
          maximum = max(maximum, value.abs());
          sum += value;
          sum_squares += value * value;
        }
        expect(data.getInt16(44, Endian.little), 0);
        expect(data.getInt16(bytes.length - 2, Endian.little), 0);
        expect(maximum / 32768, lessThan(.60));
        expect(sqrt(sum_squares / sample_count) / 32768, greaterThan(.01));
        expect(sum.abs() / sample_count / 32768, lessThan(.002));
      }
      expect(bytes_total, lessThan(280 * 1024));
    },
  );

  test(
    'preload is idempotent and rapid sounds use a bounded overlapping pool',
    () async {
      final voices = <_Voice>[];
      final service = TileQuestAudioFeedback(
        voice_factory: () {
          final voice = _Voice();
          voices.add(voice);
          return voice;
        },
      );
      await Future.wait([service.prepare(), service.prepare()]);
      final expected_voices = TileQuestAudioFeedback.sound_specs.values
          .fold<int>(0, (sum, spec) => sum + spec.voices);
      expect(voices.length, expected_voices);
      expect(
        voices.every(
          (voice) => voice.calls.where((call) => call == 'prepare').length == 1,
        ),
        isTrue,
      );
      await Future.wait(
        List.generate(4, (_) => service.play(TileQuestFeedbackEvent.tap)),
      );
      final taps = voices.where((voice) => voice.asset!.endsWith('/tap.wav'));
      expect(taps.where((voice) => voice.playing), hasLength(4));
      await Future.wait(
        List.generate(80, (_) => service.play(TileQuestFeedbackEvent.tap)),
      );
      expect(voices.length, expected_voices);
      await service.stop();
      expect(voices.any((voice) => voice.playing), isFalse);
      await service.dispose();
      expect(voices.every((voice) => voice.dispose_count == 1), isTrue);
    },
  );

  test(
    'stop cancels pending starts while assets are still preparing',
    () async {
      final gate = Completer<void>();
      final voices = <_Voice>[];
      final service = TileQuestAudioFeedback(
        voice_factory: () {
          final voice = _Voice(prepare_gate: gate);
          voices.add(voice);
          return voice;
        },
      );
      final playing = service.play(TileQuestFeedbackEvent.entry);
      final stopping = service.stop();
      gate.complete();
      await Future.wait([playing, stopping]);
      expect(voices.expand((voice) => voice.calls), isNot(contains('play')));
      await service.dispose();
    },
  );

  test('an unrelated stalled cue cannot delay a prewarmed tap', () async {
    final entry_gate = Completer<void>();
    final voices = <_SlowEntryVoice>[];
    final service = TileQuestAudioFeedback(
      voice_factory: () {
        final voice = _SlowEntryVoice(entry_gate);
        voices.add(voice);
        return voice;
      },
    );
    var all_prepared = false;
    final preparation = service.prepare().then((_) => all_prepared = true);
    await service.play(TileQuestFeedbackEvent.tap);
    expect(all_prepared, isFalse);
    expect(
      voices.where((voice) => voice.playing).single.asset,
      'audio/tile_quest/tap.wav',
    );
    entry_gate.complete();
    await preparation;
    await service.dispose();
  });

  testWidgets(
    'iOS rapid cues restart prewarmed PCM in one call without seek or timer stop',
    (tester) async {
      final calls = <MethodCall>[];
      final channel = TileQuestIosAudioVoice.platform_channel;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        return null;
      });
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
      });
      final service = TileQuestAudioFeedback();
      await service.prepare();
      final prepared = calls.where((call) => call.method == 'prepare').toList();
      expect(prepared, hasLength(11));
      final ids = prepared.map((call) => (call.arguments as Map)['voice_id']);
      expect(ids.toSet(), hasLength(11));
      final tap_ids = prepared
          .where(
            (call) =>
                (call.arguments as Map)['asset'] ==
                'assets/audio/tile_quest/tap.wav',
          )
          .map((call) => (call.arguments as Map)['voice_id'])
          .toSet();
      expect(tap_ids, hasLength(4));
      calls.clear();

      for (var index = 0; index < 20; index++) {
        await service.play(TileQuestFeedbackEvent.tap);
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(calls, hasLength(20));
      expect(calls.every((call) => call.method == 'restart'), isTrue);
      expect(
        calls.map((call) => (call.arguments as Map)['voice_id']).toSet(),
        tap_ids,
      );
      expect(
        calls.every((call) => (call.arguments as Map)['volume'] == .72),
        isTrue,
      );
      await tester.pump(const Duration(seconds: 3));
      expect(calls, hasLength(20));

      await service.play(TileQuestFeedbackEvent.match);
      expect(calls.last.method, 'restart');
      expect((calls.last.arguments as Map)['volume'], .78);
      await service.stop();
      expect(calls.where((call) => call.method == 'stop'), hasLength(11));
      await service.dispose();
      expect(calls.where((call) => call.method == 'dispose'), hasLength(11));
      final final_count = calls.length;
      await service.play(TileQuestFeedbackEvent.tap);
      await service.prepare();
      await service.dispose();
      expect(calls, hasLength(final_count));
      debugDefaultTargetPlatformOverride = null;
    },
  );

  test('stop wins against a native resume already in flight', () async {
    final gate = Completer<void>();
    final voices = <_Voice>[];
    final service = TileQuestAudioFeedback(
      voice_factory: () {
        final voice = _Voice(play_gate: gate);
        voices.add(voice);
        return voice;
      },
    );
    await service.prepare();
    final entry = voices.singleWhere(
      (voice) => voice.asset!.endsWith('/entry.wav'),
    );
    final playing = service.play(TileQuestFeedbackEvent.entry);
    await entry.started.future;
    final stopping = service.stop();
    gate.complete();
    await Future.wait([playing, stopping]);
    expect(entry.playing, isFalse);
    expect(entry.calls.last, 'stop');
    await service.dispose();
  });

  test('dispose during preload releases every allocated voice once', () async {
    final gate = Completer<void>();
    final voices = <_Voice>[];
    final service = TileQuestAudioFeedback(
      voice_factory: () {
        final voice = _Voice(prepare_gate: gate);
        voices.add(voice);
        return voice;
      },
    );
    final playing = service.play(TileQuestFeedbackEvent.shuffle);
    final disposing = service.dispose();
    gate.complete();
    await Future.wait([playing, disposing]);
    await service.dispose();
    await service.play(TileQuestFeedbackEvent.tap);
    await service.prepare();
    expect(voices.every((voice) => voice.dispose_count == 1), isTrue);
    expect(voices.expand((voice) => voice.calls), isNot(contains('play')));
  });

  testWidgets(
    'duration recycling cannot let an old timer cut off a reused cue',
    (tester) async {
      final voices = <_Voice>[];
      final service = TileQuestAudioFeedback(
        voice_factory: () {
          final voice = _Voice();
          voices.add(voice);
          return voice;
        },
      );
      await service.prepare();
      final entry = voices.singleWhere(
        (voice) => voice.asset!.endsWith('/entry.wav'),
      );
      await service.play(TileQuestFeedbackEvent.entry);
      await tester.pump(const Duration(milliseconds: 800));
      await service.play(TileQuestFeedbackEvent.entry);
      await tester.pump(const Duration(milliseconds: 300));
      expect(entry.playing, isTrue);
      await tester.pump(const Duration(milliseconds: 800));
      expect(entry.playing, isFalse);
      await service.dispose();
    },
  );

  test(
    'stop permits a fresh cue and never touches an unrelated player',
    () async {
      final unrelated = _Voice()..playing = true;
      final service = TileQuestAudioFeedback(voice_factory: _Voice.new);
      await service.prepare();
      await service.play(TileQuestFeedbackEvent.entry);
      await service.stop();
      await service.play(TileQuestFeedbackEvent.won);
      await service.dispose();
      expect(unrelated.playing, isTrue);
      expect(unrelated.calls, isEmpty);
    },
  );

  test(
    'one failed asset and failed stop never poison playback or disposal',
    () async {
      final voices = <_Voice>[];
      final service = TileQuestSystemFeedback(
        voice_factory: () {
          final voice = _Voice(fail_asset: 'audio/tile_quest/match.wav');
          voices.add(voice);
          return voice;
        },
      );
      await service.prepare();
      await service.play(TileQuestFeedbackEvent.match);
      expect(voices.where((voice) => voice.playing), isEmpty);
      await service.play(TileQuestFeedbackEvent.tap);
      expect(voices.where((voice) => voice.playing), hasLength(1));
      for (final voice in voices) {
        voice.fail_stop = true;
      }
      await service.stop();
      await service.dispose();
      expect(voices.every((voice) => voice.dispose_count == 1), isTrue);
    },
  );

  test('an unavailable audio backend cannot propagate into the game', () async {
    final service = TileQuestAudioFeedback(
      voice_factory: () => throw StateError('No audio device'),
    );
    await service.prepare();
    for (final event in TileQuestFeedbackEvent.values) {
      await service.play(event);
    }
    await service.stop();
    await service.dispose();
  });
}
