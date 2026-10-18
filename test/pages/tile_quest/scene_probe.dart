// ignore_for_file: non_constant_identifier_names
import 'package:app/pages/tile_quest/widgets/board_canvas.dart';
import 'package:app/pages/tile_quest/widgets/motion_canvas.dart';
import 'package:app/pages/tile_quest/widgets/tile_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
export 'package:app/pages/tile_quest/widgets/tile_frame.dart';

/// 直接读取实际绘制节点，禁止为finders在生产代码中保留隐藏牌树。
Map<int, QuestTileFrame> quest_scene_frames(WidgetTester tester) {
  final result = <int, QuestTileFrame>{};
  for (final element in find.byType(CustomPaint).evaluate()) {
    final painter = (element.widget as CustomPaint).painter;
    final Iterable<QuestTileFrame> frames;
    if (painter is QuestBoardPainter) {
      frames = painter.frames;
    } else if (painter is QuestMotionPainter) {
      frames = painter.frames;
    } else {
      continue;
    }
    final origin = (element.findRenderObject()! as RenderBox).localToGlobal(
      Offset.zero,
    );
    for (final frame in frames) {
      expect(
        result.containsKey(frame.id),
        isFalse,
        reason: 'tile ${frame.id} is drawn twice',
      );
      result[frame.id] = QuestTileFrame(
        id: frame.id,
        type: frame.type,
        rect: frame.rect.shift(origin),
        zone: frame.zone,
        blocked: frame.blocked,
        rotation: frame.rotation,
        dissolve: frame.dissolve,
        previous_type: frame.previous_type,
        face_progress: frame.face_progress,
      );
    }
  }
  return result;
}
