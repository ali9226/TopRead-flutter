// ignore_for_file: non_constant_identifier_names
import 'package:flutter/animation.dart';
import '../game/models.dart';
import '../style.dart';

/// Ordered presentation of an already committed rule transaction.
class QuestSceneMotion {
  QuestSceneMotion(this.result, this.queued_at, {this.preflight = false});
  final TileQuestActionResult result;
  final double queued_at;
  final bool preflight;
  double started_at = 0;
  double source_progress = 0;
  double travel_ms = 0;
  bool match_feedback_sent = false;
  late final Set<int> moved_ids = result.moved_ids.toSet();
  late final Map<int, int> moved_indices = {
    for (var index = 0; index < result.moved_ids.length; index++)
      result.moved_ids[index]: index,
  };
  late final List<int> tool_ids = _ordered_tool_ids();

  /// Sorting and membership lookup are cached per transaction, not per frame.
  List<int> _ordered_tool_ids() =>
      {
        ...result.before.tray,
        ...result.before.reserve,
        ...result.after.tray,
        ...result.after.reserve,
        ...result.moved_ids,
      }.toList()..sort((a, b) {
        int rank(int id) =>
            (moved_ids.contains(id) ? 100 : 0) +
            (result.after.reserve.contains(id)
                ? result.after.reserve_depth(id)
                : -1);
        final order = rank(a).compareTo(rank(b));
        if (order != 0) return order;
        if (result.action == TileQuestAction.shuffle &&
            moved_ids.contains(a) &&
            moved_ids.contains(b)) {
          final layer_order = result.before
              .tile_by_id(a)
              .layer
              .compareTo(result.before.tile_by_id(b).layer);
          if (layer_order != 0) return layer_order;
        }
        return a.compareTo(b);
      });
  bool get inserts =>
      result.action == TileQuestAction.tap ||
      result.action == TileQuestAction.return_reserve;
  bool get matches => inserts && result.matched_ids.isNotEmpty;
  int get incoming_id => result.moved_ids.single;
  List<int> get insertion_tray => result.settlement_tray;

  double preflight_progress(double now) => preflight
      ? TileQuestStyle.preflight_progress *
            Curves.easeOutCubic.transform(
              ((now - queued_at) / TileQuestStyle.preflight_duration_ms).clamp(
                0.0,
                1.0,
              ),
            )
      : 0;

  void start(double now) {
    started_at = now;
    source_progress = preflight_progress(now);
    final base = TileQuestStyle.flight_duration.inMilliseconds.toDouble();
    travel_ms = inserts
        ? (base * (1 - source_progress)).clamp(
            TileQuestStyle.queued_flight_min_ms,
            base,
          )
        : result.action == TileQuestAction.shuffle
        ? TileQuestStyle.shuffle_duration_ms
        : TileQuestStyle.tool_motion_ms;
  }

  double get compact_ms => matches && result.after.tray.isNotEmpty
      ? TileQuestStyle.tray_compact_ms
      : 0;
  double get match_start => travel_ms + TileQuestStyle.match_hold_ms;
  double get compact_start => match_start + TileQuestStyle.match_fade_ms;
  double get duration_ms => matches ? compact_start + compact_ms : travel_ms;
  double get ends_at => started_at + duration_ms;
  double elapsed(double now) => (now - started_at).clamp(0.0, duration_ms);
  double travel(double now) => Curves.easeInOutCubic.transform(
    (elapsed(now) / travel_ms).clamp(0.0, 1.0),
  );
  double flight(double now) =>
      source_progress + (1 - source_progress) * travel(now);
  double fade(double now) => matches
      ? ((elapsed(now) - match_start) / TileQuestStyle.match_fade_ms).clamp(
          0.0,
          1.0,
        )
      : 0;
  double compact(double now) => compact_ms == 0
      ? 0
      : Curves.easeOutCubic.transform(
          ((elapsed(now) - compact_start) / compact_ms).clamp(0.0, 1.0),
        );
}
