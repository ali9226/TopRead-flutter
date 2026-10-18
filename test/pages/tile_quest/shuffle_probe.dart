// ignore_for_file: non_constant_identifier_names
import 'package:app/pages/tile_quest/widgets/shuffle_motion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'scene_probe.dart';

/// 从真实 CustomPainter 读取绘制状态，避免为测试在生产代码里保留隐藏牌树。
Map<int, QuestShuffleFrame> quest_shuffle_frames(WidgetTester tester) {
  final result = <int, QuestShuffleFrame>{};
  for (final frame in quest_scene_frames(tester).values) {
    if (frame.previous_type == null) continue;
    result[frame.id] = QuestShuffleFrame(
      id: frame.id,
      type: frame.type,
      previous_type: frame.previous_type!,
      rect: frame.rect,
      rotation: frame.rotation,
      face_progress: frame.face_progress,
      blocked: frame.blocked,
    );
  }
  return result;
}
