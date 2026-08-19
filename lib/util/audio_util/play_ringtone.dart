// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// 铃声播放工具。
///
/// 使用 audioplayers 播放本地音频文件。
class AudioUtil {
    AudioUtil._();

    /// 音频播放器实例（单例复用）。
    static final AudioPlayer _player = AudioPlayer();

    /// 是否正在播放中（防止重复触发）。
    static bool _is_playing = false;

    /// 播放完成订阅（复用，避免每次播放都新增订阅造成泄漏）。
    static StreamSubscription<void>? _complete_sub;

    /// 播放消息提示铃声。
    ///
    /// 播放 assets/mp3/ringtone.mp3。
    /// 如果正在播放中则跳过，避免重叠。
    static Future<void> play_message_ringtone() async {
        if (_is_playing) return;
        _is_playing = true;
        try {
            await _player.play(AssetSource('mp3/ringtone.mp3'));
            // TODO 等待播放完成后重置标记
            // 先取消旧订阅再重新监听，保证同一时刻只有一个完成回调。
            _complete_sub?.cancel();
            _complete_sub = _player.onPlayerComplete.listen((_) {
                _is_playing = false;
            });
        } catch (e) {
            _is_playing = false;
        }
    }
}
