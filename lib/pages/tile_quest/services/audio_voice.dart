/// 单个预载音效声部；所有操作由所属声部的队列串行执行。
abstract interface class TileQuestAudioVoice {
  Future<void> prepare(String asset);
  Future<void> play(double volume);
  Future<void> stop();
  Future<void> dispose();
}

/// 可在一次原生调用中从头播放已预热 PCM 的声部。
///
/// 原生声部自行自然结束和重新预热，不需要 Dart 计时 stop；每次先
/// stop 再播放会撤销声部的预热并增加平台通道和音频 I/O 等待。
abstract interface class TileQuestRestartableAudioVoice {
  Future<void> restart(double volume);
}
