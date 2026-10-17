// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Events are emitted by presentation at the visible impact/settlement frame.
enum TileQuestFeedbackEvent { tap, match, tool, won, lost, entry, shuffle }

abstract interface class TileQuestFeedbackService {
  Future<void> play(TileQuestFeedbackEvent event);
}

/// Optional lifecycle: existing injected silent feedback implementations remain valid.
abstract interface class TileQuestFeedbackLifecycle {
  Future<void> prepare();
  Future<void> stop();
  Future<void> dispose();
}

/// A small audio boundary permits deterministic race tests without native plugins.
abstract interface class TileQuestAudioVoice {
  Future<void> prepare(String asset);
  Future<void> play(double volume);
  Future<void> stop();
  Future<void> dispose();
}

class TileQuestSoundSpec {
  const TileQuestSoundSpec(this.asset, this.duration, this.voices, this.volume);
  final String asset;
  final Duration duration;
  final int voices;
  final double volume;
}

/// Original PCM effects, preloaded into a strictly bounded set of game-owned players.
/// No ringtone, global player, or other module's playback is stopped or disposed.
class TileQuestAudioFeedback
    implements TileQuestFeedbackService, TileQuestFeedbackLifecycle {
  TileQuestAudioFeedback({TileQuestAudioVoice Function()? voice_factory})
    : _voice_factory = voice_factory;

  static const sound_specs = <TileQuestFeedbackEvent, TileQuestSoundSpec>{
    TileQuestFeedbackEvent.tap: TileQuestSoundSpec(
      'audio/tile_quest/tap.wav',
      Duration(milliseconds: 110),
      4,
      .72,
    ),
    TileQuestFeedbackEvent.match: TileQuestSoundSpec(
      'audio/tile_quest/match.wav',
      Duration(milliseconds: 560),
      2,
      .78,
    ),
    TileQuestFeedbackEvent.tool: TileQuestSoundSpec(
      'audio/tile_quest/tool.wav',
      Duration(milliseconds: 260),
      1,
      .70,
    ),
    TileQuestFeedbackEvent.won: TileQuestSoundSpec(
      'audio/tile_quest/won.wav',
      Duration(milliseconds: 840),
      1,
      .80,
    ),
    TileQuestFeedbackEvent.lost: TileQuestSoundSpec(
      'audio/tile_quest/lost.wav',
      Duration(milliseconds: 680),
      1,
      .66,
    ),
    TileQuestFeedbackEvent.entry: TileQuestSoundSpec(
      'audio/tile_quest/entry.wav',
      Duration(milliseconds: 1040),
      1,
      .72,
    ),
    TileQuestFeedbackEvent.shuffle: TileQuestSoundSpec(
      'audio/tile_quest/shuffle.wav',
      Duration(milliseconds: 2100),
      1,
      .74,
    ),
  };

  static const _release_padding = Duration(milliseconds: 24);
  final TileQuestAudioVoice Function()? _voice_factory;
  final AudioCache _cache = AudioCache();
  final Map<TileQuestFeedbackEvent, List<_SoundVoice>> _pools = {};
  final Map<TileQuestFeedbackEvent, int> _next_voice = {};
  Future<void>? _preparation;
  Future<void>? _disposal;
  int _epoch = 0;
  bool _disposed = false;

  @override
  Future<void> prepare() {
    if (_disposed) return Future<void>.value();
    return _preparation ??= _prepare_pools();
  }

  Future<void> _prepare_pools() async {
    // Allocate every owned voice before awaiting, so dispose also sees voices
    // whose asset decoding is still in flight.
    for (final entry in sound_specs.entries) {
      final voices = <_SoundVoice>[];
      for (var index = 0; index < entry.value.voices; index++) {
        try {
          voices.add(
            _SoundVoice(_voice_factory?.call() ?? _AudioplayersVoice(_cache)),
          );
        } on Object {
          // One unavailable platform voice cannot prevent the other cues loading.
        }
      }
      _pools[entry.key] = voices;
    }
    await Future.wait(
      sound_specs.entries.map((entry) async {
        // Cache the first voice before preparing another copy of the same asset;
        // this avoids concurrent writes of identical temporary WAV files.
        for (final voice in _pools[entry.key]!) {
          if (_disposed) return;
          await voice.enqueue(() async {
            if (_disposed) return;
            await voice.backend.prepare(entry.value.asset);
            voice.ready = true;
          });
        }
      }),
    );
  }

  @override
  Future<void> play(TileQuestFeedbackEvent event) async {
    if (_disposed) return;
    final epoch = _epoch;
    try {
      await prepare();
      if (_disposed || epoch != _epoch) return;
      final voices = _pools[event]?.where((voice) => voice.ready).toList();
      if (voices == null || voices.isEmpty) return;
      final cursor = _next_voice[event] ?? 0;
      _next_voice[event] = cursor + 1;
      final voice = voices[cursor % voices.length];
      final token = ++voice.token;
      voice.timer?.cancel();
      final spec = sound_specs[event]!;
      await voice.enqueue(() async {
        bool cancelled() =>
            _disposed || epoch != _epoch || token != voice.token;
        if (cancelled()) return;
        await voice.backend.stop();
        if (cancelled()) return;
        await voice.backend.play(spec.volume);
        if (cancelled()) {
          await voice.backend.stop();
          return;
        }
        // Android SoundPool has no completion event. Recycle on the authored
        // duration; the token prevents an old timer stopping a reused voice.
        voice.timer = Timer(spec.duration + _release_padding, () {
          if (cancelled()) return;
          unawaited(
            voice.enqueue(() async {
              if (!cancelled()) await voice.backend.stop();
            }),
          );
        });
      });
    } on Object {
      // Missing plugins, audio interruption and device failures never reach rules.
    }
  }

  @override
  Future<void> stop() {
    // Invalidate delayed prepare/start continuations synchronously, before awaits.
    _epoch++;
    return Future.wait(
      _all_voices.map((voice) {
        voice.cancel();
        return voice.enqueue(voice.backend.stop);
      }),
    );
  }

  Iterable<_SoundVoice> get _all_voices => _pools.values.expand((pool) => pool);

  @override
  Future<void> dispose() {
    if (_disposal != null) return _disposal!;
    _disposed = true;
    _epoch++;
    final operations = <Future<void>>[];
    for (final voice in _all_voices) {
      voice.cancel();
      operations.add(
        voice.enqueue(() async {
          try {
            await voice.backend.stop();
          } on Object {
            // Disposal still runs when a platform stop reports an interruption.
          }
          await voice.backend.dispose();
        }),
      );
    }
    return _disposal = _dispose_all(operations);
  }

  Future<void> _dispose_all(List<Future<void>> operations) async {
    await Future.wait(operations);
    try {
      await _cache.clearAll();
    } on Object {
      // Cache cleanup failure has no bearing on gameplay or native disposal.
    }
  }
}

/// Retain the existing default constructor name for callers outside this module.
class TileQuestSystemFeedback extends TileQuestAudioFeedback {
  TileQuestSystemFeedback({super.voice_factory});
}

class _SoundVoice {
  _SoundVoice(this.backend);
  final TileQuestAudioVoice backend;
  Future<void> _tail = Future<void>.value();
  Timer? timer;
  int token = 0;
  bool ready = false;

  void cancel() {
    token++;
    timer?.cancel();
    timer = null;
  }

  /// Each native player has its own queue, allowing separate voices to overlap
  /// while preventing late resume/stop calls from racing on the same player.
  Future<void> enqueue(Future<void> Function() operation) {
    return _tail = _tail.then((_) async {
      try {
        await operation();
      } on Object {
        // The queue always remains usable after a platform call fails.
      }
    });
  }
}

class _AudioplayersVoice implements TileQuestAudioVoice {
  _AudioplayersVoice(this.cache);
  final AudioCache cache;
  AudioPlayer? _player;

  @override
  Future<void> prepare(String asset) async {
    final player = AudioPlayer()
      ..audioCache = cache
      // Effects never display a playhead; avoid one platform query per frame.
      ..positionUpdater = null;
    _player = player;
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        // Ambient naturally mixes with other audio and respects iPhone silent mode.
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      ),
    );
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource(asset));
  }

  @override
  Future<void> play(double volume) async {
    final player = _player;
    if (player == null) return;
    await player.setVolume(volume);
    await player.resume();
  }

  @override
  Future<void> stop() async => _player?.stop();

  @override
  Future<void> dispose() async {
    final player = _player;
    _player = null;
    await player?.dispose();
  }
}
