// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/models.dart';
import 'scene_layout.dart';

/// Seals shared tile edges and internal PNG corners, retaining rounded outer
/// corners. Small gutters in old saves are sealed without changing saved rules.
class QuestBoardBacking extends CustomPainter {
  QuestBoardBacking({required this.tiles, required this.layout});
  final List<TileQuestTile> tiles;
  final QuestSceneLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    final rectangles = {
      for (final tile in tiles) tile.id: layout.board_tile(tile),
    };
    final tolerance = layout.unit * .081;
    // Shared edges need a full logical-pixel overlap: fractional board origins
    // can otherwise leave a translucent anti-aliased pixel at four-way joins.
    const seam_overlap = 1.0;
    final paint = Paint()..isAntiAlias = true;
    for (final tile in tiles) {
      final rect = rectangles[tile.id]!;
      double left_gap = -1, right_gap = -1, top_gap = -1, bottom_gap = -1;
      for (final other in tiles) {
        if (other.id == tile.id) continue;
        final peer = rectangles[other.id]!;
        final vertical =
            math.min(rect.bottom, peer.bottom) - math.max(rect.top, peer.top);
        final horizontal =
            math.min(rect.right, peer.right) - math.max(rect.left, peer.left);
        if (vertical > math.min(rect.height, peer.height) * .9) {
          final left = rect.left - peer.right, right = peer.left - rect.right;
          if (left >= -.01 && left <= tolerance) left_gap = left;
          if (right >= -.01 && right <= tolerance) right_gap = right;
        }
        if (horizontal > math.min(rect.width, peer.width) * .9) {
          final top = rect.top - peer.bottom, bottom = peer.top - rect.bottom;
          if (top >= -.01 && top <= tolerance) top_gap = top;
          if (bottom >= -.01 && bottom <= tolerance) bottom_gap = bottom;
        }
      }
      final mask = Rect.fromLTRB(
        rect.left - (left_gap >= 0 ? left_gap / 2 + seam_overlap : 0),
        rect.top - (top_gap >= 0 ? top_gap / 2 + seam_overlap : 0),
        rect.right + (right_gap >= 0 ? right_gap / 2 + seam_overlap : 0),
        rect.bottom + (bottom_gap >= 0 ? bottom_gap / 2 + seam_overlap : 0),
      );
      final radius = Radius.circular(rect.shortestSide * .13);
      paint.color = Color.lerp(
        const Color(0xfff9eddc),
        Colors.black,
        tile.is_blocked ? .39 : 0,
      )!;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          mask,
          topLeft: left_gap >= 0 || top_gap >= 0 ? Radius.zero : radius,
          topRight: right_gap >= 0 || top_gap >= 0 ? Radius.zero : radius,
          bottomLeft: left_gap >= 0 || bottom_gap >= 0 ? Radius.zero : radius,
          bottomRight: right_gap >= 0 || bottom_gap >= 0 ? Radius.zero : radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(QuestBoardBacking oldDelegate) =>
      oldDelegate.tiles != tiles ||
      oldDelegate.layout.unit != layout.unit ||
      oldDelegate.layout.board_origin != layout.board_origin;
}
