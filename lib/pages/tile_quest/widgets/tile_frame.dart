// ignore_for_file: non_constant_identifier_names
import 'package:flutter/painting.dart';

enum QuestTileZone { board, entry, flight, tray, reserve }

/// 真实画布中的牌状态，同时供命中测试、辅助功能与回归读取。
class QuestTileFrame {
  const QuestTileFrame({
    required this.id,
    required this.type,
    required this.rect,
    required this.zone,
    this.blocked = false,
    this.rotation = 0,
    this.dissolve,
    this.previous_type,
    this.face_progress = 1,
  });
  final int id, type;
  final Rect rect;
  final QuestTileZone zone;
  final bool blocked;
  final double rotation;
  final double? dissolve;
  final int? previous_type;
  final double face_progress;
}
