// ignore_for_file: non_constant_identifier_names
import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../game/models.dart';
import '../game/config.dart';
import '../style.dart';
import '../services/feedback_service.dart';
import 'board_backing.dart';
import 'board_motion.dart';
import 'match_particles.dart';
import 'quest_controls.dart';
import 'quest_text.dart';
import 'scene_layout.dart';
import 'scene_motion.dart';
import 'slot_wells.dart';
import 'tile_card.dart';

/// Rule transactions commit independently. One ordered visual clock owns every
/// flying/held tile, including the temporary seventh tile before a match.
class TileQuestScene extends StatefulWidget {
  const TileQuestScene({
    super.key,
    required this.state,
    required this.action,
    this.recent_actions = const [],
    this.can_undo = true,
    this.animate_entry = true,
    this.on_presentation_busy_changed,
    this.on_feedback,
    required this.sound_enabled,
    required this.busy,
    required this.on_back,
    required this.on_restart,
    required this.on_sound,
    required this.on_tile,
    required this.on_reserve,
    required this.on_tool,
  });
  final TileQuestState state;
  final TileQuestActionResult? action;
  final List<TileQuestActionResult> recent_actions;
  final bool sound_enabled, busy, can_undo, animate_entry;
  final ValueChanged<bool>? on_presentation_busy_changed;
  final ValueChanged<TileQuestFeedbackEvent>? on_feedback;
  final VoidCallback on_back, on_restart, on_sound;
  final ValueChanged<int> on_tile, on_reserve;
  final ValueChanged<TileQuestTool> on_tool;
  @override
  State<TileQuestScene> createState() => _TileQuestSceneState();
}

class _TileQuestSceneState extends State<TileQuestScene>
    with SingleTickerProviderStateMixin {
  final Queue<QuestSceneMotion> _pending = Queue<QuestSceneMotion>();
  final Set<TileQuestActionResult> _seen_actions = {};
  final List<TileQuestActionResult> _completed_actions = [];
  final Map<(int, bool), Widget> _cards = {};
  final ValueNotifier<double> _clock = ValueNotifier<double>(0);
  late final Ticker _ticker;
  late TileQuestState _presented;
  QuestSceneMotion? _active;
  double _ticker_origin = 0;
  bool _reported_busy = false;
  bool _entering = false;
  double _entry_started_at = 0;
  List<TileQuestTile> _entry_tiles = const [];
  bool get _show_tools => widget.state.level > 1;

  /// Only board-wide effects lock input; normal flights still accept rapid taps.
  bool get _board_locked =>
      _entering ||
      _active?.result.action == TileQuestAction.shuffle ||
      _pending.any((motion) => motion.result.action == TileQuestAction.shuffle);

  @override
  void initState() {
    super.initState();
    _presented = widget.state;
    // Historical actions never replay, but each newly mounted challenge falls in.
    _seen_actions.addAll(widget.recent_actions);
    if (widget.action != null) _seen_actions.add(widget.action!);
    _ticker = createTicker(_tick);
    _start_entrance();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _active == null && !_entering) {
        widget.on_presentation_busy_changed?.call(false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant TileQuestScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.challenge_id != widget.state.challenge_id) {
      _ticker.stop();
      _pending.clear();
      _active = null;
      _seen_actions.clear();
      _completed_actions.clear();
      _cards.clear();
      _presented = widget.state;
      _clock.value = 0;
      _start_entrance();
    }
    final events = widget.recent_actions.isEmpty
        ? [if (widget.action != null) widget.action!]
        : widget.recent_actions;
    for (final result in events) {
      if (!result.accepted || !_seen_actions.add(result)) continue;
      final id = result.action == TileQuestAction.tap
          ? result.moved_ids.single
          : null;
      final has_prior_motion =
          id != null &&
          ((_active?.result.moved_ids.contains(id) ?? false) ||
              _pending.any((item) => item.result.moved_ids.contains(id)) ||
              _presented.tray.contains(id) ||
              _presented.reserve.contains(id));
      _pending.add(
        QuestSceneMotion(
          result,
          _clock.value,
          preflight: id != null && !has_prior_motion,
        ),
      );
    }
    if (!_entering && _active == null && _pending.isNotEmpty) {
      _begin_next(_clock.value);
      _start_clock();
    }
  }

  void _start_clock() {
    if (_ticker.isActive) return;
    _ticker_origin = _clock.value;
    _ticker.start();
  }

  void _start_entrance() {
    _entering =
        widget.animate_entry &&
        widget.state.status == TileQuestStatus.playing &&
        widget.state.tiles.any((tile) => !tile.is_removed);
    _entry_started_at = _clock.value;
    _entry_tiles = widget.state.tiles.where((tile) => !tile.is_removed).toList()
      ..sort(
        (a, b) => a.layer == b.layer
            ? a.id.compareTo(b.id)
            : a.layer.compareTo(b.layer),
      );
    _report_busy(_entering);
    if (!_entering) return;
    final challenge_id = widget.state.challenge_id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _entering && widget.state.challenge_id == challenge_id) {
        _send_feedback(TileQuestFeedbackEvent.entry);
      }
    });
    _start_clock();
  }

  void _send_feedback(TileQuestFeedbackEvent event) {
    if (widget.sound_enabled) widget.on_feedback?.call(event);
  }

  void _begin_next(double now, {double? observed_at}) {
    final motion = _pending.removeFirst()..start(now);
    _presented = motion.result.before;
    _active = motion;
    _report_busy(true);
    if (!motion.inserts &&
        (observed_at ?? now) - now <= TileQuestStyle.feedback_frame_window_ms) {
      _send_feedback(
        motion.result.action == TileQuestAction.shuffle
            ? TileQuestFeedbackEvent.shuffle
            : TileQuestFeedbackEvent.tool,
      );
    }
  }

  void _match_feedback(QuestSceneMotion motion, double now) {
    if (motion.matches &&
        !motion.match_feedback_sent &&
        motion.elapsed(now) >= motion.match_start) {
      motion.match_feedback_sent = true;
      // A background/long-frame catch-up must not burst expired cues at once.
      if (now - motion.started_at - motion.match_start <=
          TileQuestStyle.feedback_frame_window_ms) {
        _send_feedback(TileQuestFeedbackEvent.match);
      }
    }
  }

  /// A delayed frame may complete multiple transactions, but cannot reorder them.
  void _tick(Duration elapsed) {
    final now = _ticker_origin + elapsed.inMicroseconds / 1000;
    bool changed = false;
    if (_entering &&
        now - _entry_started_at >= TileQuestStyle.entry_duration_ms) {
      _entering = false;
      changed = true;
      if (_pending.isNotEmpty) {
        _begin_next(
          _entry_started_at + TileQuestStyle.entry_duration_ms,
          observed_at: now,
        );
      }
    }
    while (_active != null && now >= _active!.ends_at) {
      final completed = _active!;
      _match_feedback(completed, now);
      _presented = completed.result.after;
      _completed_actions.add(completed.result);
      _active = null;
      if (completed.result.before.status != completed.result.after.status &&
          now - completed.ends_at <= TileQuestStyle.feedback_frame_window_ms) {
        if (completed.result.after.status == TileQuestStatus.won) {
          _send_feedback(TileQuestFeedbackEvent.won);
        } else if (completed.result.after.status == TileQuestStatus.lost) {
          _send_feedback(TileQuestFeedbackEvent.lost);
        }
      }
      changed = true;
      if (_pending.isNotEmpty) _begin_next(completed.ends_at, observed_at: now);
    }
    if (_active != null) _match_feedback(_active!, now);
    _clock.value = now;
    if (_active == null && !_entering) {
      _ticker.stop();
      _report_busy(false);
    }
    if (changed && mounted) setState(() {});
  }

  void _report_busy(bool value) {
    if (_reported_busy == value) return;
    _reported_busy = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _reported_busy == value) {
        widget.on_presentation_busy_changed?.call(value);
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  Set<int> get _moving_board_ids => {
    if (_active != null) ..._active!.result.moved_ids,
    for (final motion in _pending) ...motion.result.moved_ids,
  };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final layout = QuestSceneLayout(
        Size(constraints.maxWidth, constraints.maxHeight),
        widget.state,
      );
      final cjk = quest_is_cjk(context);
      return ClipRect(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fromRect(
              rect: layout.header,
              child: QuestHeader(
                state: widget.state,
                sound_enabled: widget.sound_enabled,
                on_back: widget.on_back,
                on_restart: widget.on_restart,
                on_sound: widget.on_sound,
              ),
            ),
            if (layout.tutorial.height > 0)
              Positioned.fromRect(
                rect: layout.tutorial,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      quest_text(
                        context,
                        'tutorial',
                        'Match 3 identical tiles to clear them!',
                      ),
                      style: TileQuestStyle.caption(
                        cjk,
                        color: TileQuestStyle.cream,
                      ).copyWith(letterSpacing: 0),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
              ),
            ..._board_tiles(layout),
            Positioned.fromRect(
              rect: layout.tray,
              child: QuestSlotWell(
                layout: layout,
                caption: quest_text(context, 'tray', 'SEVEN TILE TRAY'),
                cjk: cjk,
              ),
            ),
            if (_show_tools)
              Positioned.fromRect(
                rect: layout.reserve,
                child: QuestReserveWell(
                  layout: layout,
                  cjk: cjk,
                  occupied: _presented.reserve.isNotEmpty,
                ),
              ),
            if (_show_tools)
              Positioned.fromRect(
                rect: layout.tools,
                child: Row(
                  children: [
                    for (final tool in TileQuestTool.values) ...[
                      if (tool != TileQuestTool.values.first)
                        const SizedBox(width: 10),
                      Expanded(
                        child: QuestToolButton(
                          tool: tool,
                          remaining: widget.state.tools[tool] ?? 0,
                          enabled: _tool_enabled(tool),
                          on_tap: () => widget.on_tool(tool),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            // The board, header and slot backgrounds are outside the frame listener.
            // Decoded image widgets are cached and repaint-isolated across positions.
            Positioned.fill(
              child: ListenableBuilder(
                listenable: _clock,
                builder: (context, child) =>
                    _motion_layer(layout, _clock.value),
              ),
            ),
          ],
        ),
      );
    },
  );

  bool _tool_enabled(TileQuestTool tool) {
    if (!_show_tools ||
        widget.busy ||
        _board_locked ||
        (widget.state.tools[tool] ?? 0) == 0 ||
        widget.state.status == TileQuestStatus.won) {
      return false;
    }
    return switch (tool) {
      TileQuestTool.undo => widget.can_undo,
      TileQuestTool.shuffle =>
        widget.state.status == TileQuestStatus.playing &&
            widget.state.remaining_count > 0,
      TileQuestTool.remove =>
        widget.state.status == TileQuestStatus.playing &&
            widget.state.tray.isNotEmpty &&
            widget.state.reserve.length +
                    math.min(
                      TileQuestConfig.remove_batch_size,
                      widget.state.tray.length,
                    ) <=
                TileQuestConfig.reserve_capacity,
    };
  }

  List<Widget> _board_tiles(QuestSceneLayout layout) {
    if (_entering) return const [];
    final hidden = _moving_board_ids;
    final groups = <int, List<TileQuestTile>>{};
    for (final tile in widget.state.tiles) {
      if (!tile.is_removed && !hidden.contains(tile.id)) {
        (groups[tile.layer] ??= []).add(tile);
      }
    }
    final layers = groups.keys.toList()..sort();
    return [
      for (final layer in layers) ...[
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: QuestBoardBacking(
                  tiles: groups[layer]!,
                  layout: layout,
                ),
              ),
            ),
          ),
        ),
        for (final tile in groups[layer]!..sort((a, b) => a.id.compareTo(b.id)))
          Positioned.fromRect(
            key: ValueKey('tile_quest_tile_${tile.id}'),
            rect: layout.board_tile(tile),
            child: RepaintBoundary(
              child: QuestTileCard(
                key: ValueKey('board_card_${tile.id}'),
                type: tile.type,
                blocked: tile.is_blocked,
                label:
                    '${quest_tile_assets[tile.type % quest_tile_assets.length]} ${tile.id}',
                on_tap:
                    widget.busy ||
                        _board_locked ||
                        tile.is_blocked ||
                        widget.state.status != TileQuestStatus.playing
                    ? null
                    : () => widget.on_tile(tile.id),
              ),
            ),
          ),
      ],
    ];
  }

  Widget _cached_card(int type, {bool blocked = false}) => _cards.putIfAbsent(
    (type, blocked),
    () => RepaintBoundary(
      child: QuestTileCard(type: type, blocked: blocked),
    ),
  );

  Widget _tile(
    int id,
    int type,
    Rect rect, {
    bool flying = false,
    double opacity = 1,
    double scale = 1,
    double rotation = 0,
    double? dissolve,
    int? previous_type,
    double face_progress = 1,
    bool reserve = false,
    bool blocked = false,
  }) {
    // 教学关不呈现任何备用牌或可归还点击区域。
    if (reserve && !_show_tools) return const SizedBox.shrink();
    Widget child = _cached_card(type, blocked: blocked);
    if (previous_type != null && previous_type != type && face_progress < 1) {
      final previous = _cached_card(previous_type, blocked: blocked);
      child = face_progress <= 0
          ? previous
          : Stack(
              fit: StackFit.expand,
              children: [
                // 底板持续不透明，新图案以完整正常尺寸柔和覆盖。
                previous,
                Opacity(opacity: face_progress, child: child),
              ],
            );
    }
    if (dissolve != null) {
      child = QuestMatchParticles(
        type: type,
        seed: id,
        progress: dissolve,
        child: child,
      );
    }
    if (reserve) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap:
            widget.busy ||
                _board_locked ||
                widget.state.status != TileQuestStatus.playing ||
                blocked ||
                !widget.state.is_reserve_available(id)
            ? null
            : () => widget.on_reserve(id),
        child: child,
      );
    } else {
      child = IgnorePointer(child: child);
    }
    return Positioned.fromRect(
      key: ValueKey(
        flying
            ? 'tile_quest_flight_$id'
            : reserve
            ? 'tile_quest_reserve_$id'
            : 'tray_$id',
      ),
      rect: rect,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(scale: scale, child: child),
        ),
      ),
    );
  }

  Rect _flight_rect(Rect start, Rect end, double progress) {
    final rect = Rect.lerp(start, end, progress)!;
    final lift =
        math.sin(progress * math.pi) *
        math.min(18.0, (start.center - end.center).distance * .06);
    return rect.translate(0, -lift);
  }

  Widget _motion_layer(QuestSceneLayout layout, double now) {
    final rendered = <int>{};
    final children = <Widget>[];
    final active = _active;
    if (_entering) {
      final tiles = _entry_tiles;
      for (var rank = 0; rank < tiles.length; rank++) {
        final tile = tiles[rank];
        final progress = QuestBoardMotion.entrance_progress(
          rank,
          tiles.length,
          now - _entry_started_at,
        );
        children.add(
          Positioned.fromRect(
            key: ValueKey('tile_quest_entry_${tile.id}'),
            rect: QuestBoardMotion.entrance_rect(
              layout,
              tile,
              rank,
              tiles.length,
              now - _entry_started_at,
            ),
            child: IgnorePointer(
              child: Transform.rotate(
                angle:
                    (tile.id.isEven ? 1 : -1) *
                    TileQuestStyle.entry_rotation *
                    (1 - progress),
                child: _cached_card(tile.type, blocked: tile.is_blocked),
              ),
            ),
          ),
        );
      }
    }
    if (active == null) {
      for (var index = 0; index < _presented.tray.length; index++) {
        final id = _presented.tray[index];
        rendered.add(id);
        children.add(
          _tile(id, _presented.tile_by_id(id).type, layout.tray_tile(index)),
        );
      }
      for (var index = 0; index < _presented.reserve.length; index++) {
        final id = _presented.reserve[index];
        rendered.add(id);
        children.add(
          _tile(
            id,
            _presented.tile_by_id(id).type,
            layout.location(_presented, id),
            reserve: true,
            blocked: !_presented.is_reserve_available(id),
          ),
        );
      }
    } else if (active.inserts) {
      _insertion_tiles(active, layout, now, children, rendered);
    } else {
      _tool_tiles(active, layout, now, children, rendered);
    }
    for (final motion in _pending) {
      final result = motion.result;
      if (result.action == TileQuestAction.tap &&
          !rendered.contains(motion.incoming_id)) {
        final id = motion.incoming_id;
        rendered.add(id);
        final source = layout.location(result.before, id);
        final target = layout.tray_tile(motion.insertion_tray.indexOf(id));
        children.add(
          _tile(
            id,
            result.before.tile_by_id(id).type,
            _flight_rect(source, target, motion.preflight_progress(now)),
            flying: true,
          ),
        );
      } else if (result.action == TileQuestAction.shuffle) {
        // Pending shuffles keep their old visible faces until their flip starts.
        for (final id in result.moved_ids) {
          if (!rendered.add(id)) continue;
          final tile = result.before.tile_by_id(id);
          children.add(
            _tile(
              id,
              tile.type,
              layout.board_tile(tile),
              flying: true,
              blocked: tile.is_blocked,
            ),
          );
        }
      }
    }
    return Stack(clipBehavior: Clip.none, children: children);
  }

  void _insertion_tiles(
    QuestSceneMotion motion,
    QuestSceneLayout layout,
    double now,
    List<Widget> children,
    Set<int> rendered,
  ) {
    final result = motion.result;
    final order = motion.insertion_tray;
    final fade = motion.fade(now), compact = motion.compact(now);
    Widget? incoming_card;
    for (var index = 0; index < order.length; index++) {
      final id = order[index];
      rendered.add(id);
      final is_match = result.matched_ids.contains(id);
      if (is_match && motion.elapsed(now) >= motion.compact_start) continue;
      final destination = layout.tray_tile(index);
      final incoming = id == motion.incoming_id;
      final Rect rect;
      if (motion.elapsed(now) < motion.travel_ms) {
        rect = incoming
            ? _flight_rect(
                layout.location(result.before, id),
                destination,
                motion.flight(now),
              )
            : Rect.lerp(
                layout.location(result.before, id),
                destination,
                motion.travel(now),
              )!;
      } else if (!is_match && motion.matches) {
        rect = Rect.lerp(
          destination,
          layout.tray_tile(result.after.tray.indexOf(id)),
          compact,
        )!;
      } else {
        rect = destination;
      }
      final card = _tile(
        id,
        result.before.tile_by_id(id).type,
        rect,
        flying: incoming,
        dissolve: is_match ? fade : null,
      );
      if (incoming) {
        incoming_card = card;
      } else {
        children.add(card);
      }
    }
    for (var index = 0; index < result.after.reserve.length; index++) {
      final id = result.after.reserve[index];
      rendered.add(id);
      children.add(
        _tile(
          id,
          result.after.tile_by_id(id).type,
          Rect.lerp(
            layout.location(result.before, id),
            layout.location(result.after, id),
            motion.travel(now),
          )!,
          reserve: true,
          blocked: !result.after.is_reserve_available(id),
        ),
      );
    }
    // A returning top tile must stay above the lower tile it is leaving.
    if (incoming_card != null) children.add(incoming_card);
  }

  /// Move every held neighbor in the same transaction, with one visual per id.
  void _tool_tiles(
    QuestSceneMotion motion,
    QuestSceneLayout layout,
    double now,
    List<Widget> children,
    Set<int> rendered,
  ) {
    final result = motion.result;
    final ids = motion.tool_ids;
    final progress = motion.travel(now);
    final shuffle_progress = (motion.elapsed(now) / motion.travel_ms).clamp(
      0.0,
      1.0,
    );
    for (final id in ids) {
      rendered.add(id);
      final tile = result.after.tile_by_id(id);
      var source = layout.location(result.before, id);
      if (result.action == TileQuestAction.undo &&
          result.before.tile_by_id(id).is_removed &&
          !result.before.tray.contains(id) &&
          !result.before.reserve.contains(id)) {
        final cleared = _completed_actions
            .where(
              (event) =>
                  event.matched_ids.contains(id) &&
                  event.settlement_tray.contains(id),
            )
            .lastOrNull;
        if (cleared != null) {
          source = layout.tray_tile(cleared.settlement_tray.indexOf(id));
        } else {
          final restored_slot = result.after.tray.indexOf(id);
          final previous_same = result.after.tray.lastIndexWhere(
            (held) => result.after.tile_by_id(held).type == tile.type,
          );
          source = layout.tray_tile(
            restored_slot >= 0
                ? restored_slot
                : previous_same >= 0
                ? previous_same + 1
                : result.after.tray.length.clamp(0, 6),
          );
        }
      }
      final destination = layout.location(result.after, id);
      final moved = motion.moved_ids.contains(id);
      final shuffle = result.action == TileQuestAction.shuffle && moved;
      final shuffle_index = motion.moved_indices[id] ?? 0;
      final shuffle_count = result.moved_ids.length;
      final face = shuffle
          ? QuestBoardMotion.shuffle_face_progress(
              shuffle_progress,
              index: shuffle_index,
              count: shuffle_count,
            )
          : 1.0;
      children.add(
        _tile(
          id,
          tile.type,
          shuffle
              ? QuestBoardMotion.shuffle_rect(
                  layout,
                  source,
                  shuffle_index,
                  shuffle_count,
                  shuffle_progress,
                )
              : moved
              ? _flight_rect(source, destination, progress)
              : Rect.lerp(source, destination, progress)!,
          flying: moved,
          reserve: !moved && result.after.reserve.contains(id),
          blocked: shuffle
              ? tile.is_blocked
              : result.after.reserve.contains(id) &&
                    !result.after.is_reserve_available(id),
          scale: shuffle ? QuestBoardMotion.shuffle_scale(shuffle_progress) : 1,
          previous_type: shuffle ? result.before.tile_by_id(id).type : null,
          face_progress: face,
          rotation: shuffle
              ? QuestBoardMotion.shuffle_rotation(
                  shuffle_progress,
                  index: shuffle_index,
                )
              : 0,
        ),
      );
    }
  }
}
