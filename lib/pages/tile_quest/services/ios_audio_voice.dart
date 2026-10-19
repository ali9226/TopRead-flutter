// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:flutter/services.dart';

import 'audio_voice.dart';

/// iOS 短 PCM 音效直接调度到预热的 AVAudioEngine，不经过异步 seek。
///
/// 同一个音效池只申请固定数量的 voice；id 在页面切换后也不重复，
/// 防止旧页面迟到的 stop/dispose 影响新页面的声部。
class TileQuestIosAudioVoice
    implements TileQuestAudioVoice, TileQuestRestartableAudioVoice {
  TileQuestIosAudioVoice({MethodChannel? channel})
    : _channel = channel ?? platform_channel,
      _voice_id = ++_last_voice_id;

  static const platform_channel = MethodChannel(
    'com.topread.novel/tile_quest_audio',
  );
  static int _last_voice_id = 0;

  final MethodChannel _channel;
  final int _voice_id;
  bool _disposed = false;

  @override
  Future<void> prepare(String asset) async {
    if (_disposed) return;
    await _channel.invokeMethod<void>('prepare', {
      'voice_id': _voice_id,
      'asset': 'assets/$asset',
    });
  }

  @override
  Future<void> play(double volume) => restart(volume);

  @override
  Future<void> restart(double volume) async {
    if (_disposed) return;
    await _channel.invokeMethod<void>('restart', {
      'voice_id': _voice_id,
      'volume': volume,
    });
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    await _channel.invokeMethod<void>('stop', {'voice_id': _voice_id});
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _channel.invokeMethod<void>('dispose', {'voice_id': _voice_id});
  }
}
