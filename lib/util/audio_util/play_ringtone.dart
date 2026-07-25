// ignore_for_file: non_constant_identifier_names

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
            _player.onPlayerComplete.listen((_) {
                _is_playing = false;
            });
        } catch (e) {
            _is_playing = false;
        }
    }
}
