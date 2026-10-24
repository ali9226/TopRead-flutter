// ignore_for_file: non_constant_identifier_names
import 'package:app/config/layout_config.dart';
import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../game/models.dart';
import '../game/config.dart';
import '../style.dart';
import '../services/feedback_service.dart';
import 'board_canvas.dart';
import 'board_motion.dart';
import 'board_reveal.dart';
import 'insertion_timeline.dart';
import 'match_particles.dart';
import 'layout_debug.dart';
import 'quest_controls.dart';
import 'quest_text.dart';
import 'scene_layout.dart';
import 'scene_motion.dart';
import 'motion_canvas.dart';
import 'shuffle_textures.dart';
import 'slot_wells.dart';
import 'tile_frame.dart';

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
    this.show_layout_debug = false,
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

  /// 仅用户信息 debug==2 时展示布局调试层，与构建模式无关。
  final bool show_layout_debug;
  @override
  State<TileQuestScene> createState() => _TileQuestSceneState();
}

class _TileQuestSceneState extends State<TileQuestScene>
    with SingleTickerProviderStateMixin {
  final Queue<QuestSceneMotion> _pending = Queue<QuestSceneMotion>();
  final Set<TileQuestActionResult> _seen_actions = {};
  final List<TileQuestActionResult> _completed_actions = [];
  final ValueNotifier<int?> _pressed = ValueNotifier(null);
  final Map<int, QuestParticleField> _particle_fields = {};
  QuestBoardCanvas? _board_cache;
  List<TileQuestTile> _board_cache_tiles = const [];
  final QuestShuffleTextures _shuffle_textures = QuestShuffleTextures();
  final ValueNotifier<double> _clock = ValueNotifier<double>(0);
  final QuestBoardReveal _reveal = QuestBoardReveal();
  late final Ticker _ticker;
  late TileQuestState _presented;
  QuestSceneMotion? _active;
  QuestInsertionTimeline? _insertions;
  double _ticker_origin = 0;
  bool _reported_busy = false;
  bool _entering = false;
  double _entry_started_at = 0;
  List<TileQuestTile> _entry_tiles = const [];

  /// 最近一帧的场景坐标表；调度飞行时长要用到真实航距。
  QuestSceneLayout? _latest_layout;
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
    _reveal.reset(widget.state.tiles, blocked_overrides: _reserve_shades);
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shuffle_textures.resolve(
      context,
      widget.state.tiles.map((tile) => tile.type),
    );
  }

  @override
  void didUpdateWidget(covariant TileQuestScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.challenge_id != widget.state.challenge_id) {
      _ticker.stop();
      _pending.clear();
      _active = null;
      _insertions = null;
      _seen_actions.clear();
      _completed_actions.clear();
      _particle_fields.clear();
      _board_cache = null;
      _board_cache_tiles = const [];
      _pressed.value = null;
      _presented = widget.state;
      _shuffle_textures.resolve(
        context,
        widget.state.tiles.map((tile) => tile.type),
      );
      _clock.value = 0;
      _reveal.reset(widget.state.tiles, blocked_overrides: _reserve_shades);
      _start_entrance();
    }
    _reveal.update(
      widget.state.tiles,
      _clock.value,
      animate: !MediaQuery.disableAnimationsOf(context),
      blocked_overrides: _reserve_shades,
    );
    final events = widget.recent_actions.isEmpty
        ? [if (widget.action != null) widget.action!]
        : widget.recent_actions;
    for (final result in events) {
      if (!result.accepted || !_seen_actions.add(result)) continue;
      final inserts =
          result.action == TileQuestAction.tap ||
          result.action == TileQuestAction.return_reserve;
      final id = inserts ? result.moved_ids.single : null;
      final has_prior_motion =
          id != null &&
          ((_active?.result.moved_ids.contains(id) ?? false) ||
              _pending.any((item) => item.result.moved_ids.contains(id)) ||
              _presented.tray.contains(id));
      // 撤回、移出和洗牌会改变后续牌的起点，必须等屏障交接后再飞。
      final has_tool_barrier =
          (_active != null && !_active!.inserts) ||
          _pending.any((motion) => !motion.inserts);
      _pending.add(
        QuestSceneMotion(
          result,
          _clock.value,
          preflight: id != null && !has_prior_motion && !has_tool_barrier,
        ),
      );
    }
    if (!_entering && _active == null && _pending.isNotEmpty) {
      _begin_next(_clock.value);
      _start_clock();
    } else if (_insertions != null) {
      _extend_insertions(_clock.value);
    }
    if (_reveal.is_animating) _start_clock();
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
    final motion = _pending.removeFirst();
    _presented = motion.result.before;
    _active = motion;
    if (motion.inserts) {
      _insertions = QuestInsertionTimeline(motion.result.before, now)
        ..add(motion, now, distance: _hop_distance(motion));
      _extend_insertions(now);
    } else {
      motion.start(now);
    }
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

  /// 起点到目标槽的航距；拿不到布局时返回 0，调用方按最长航段兜底。
  double _hop_distance(QuestSceneMotion motion) {
    final layout = _latest_layout;
    if (layout == null) return 0;
    final result = motion.result;
    final id = motion.incoming_id;
    final source = layout.location(result.before, id);
    final slot = result.settlement_tray.indexOf(id);
    if (slot < 0) return 0;
    return (source.center - layout.tray_tile(slot).center).distance;
  }

  /// 连续插入共享呈现批次；道具保持在队首，等待所有牌与碎粒完成。
  void _extend_insertions(double now) {
    while (_pending.isNotEmpty && _pending.first.inserts) {
      final motion = _pending.removeFirst();
      _insertions!.add(motion, now, distance: _hop_distance(motion));
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
    // Only the outer tree needs setState; motion visuals ride _clock.
    var outer_changed = false;
    if (_entering &&
        now - _entry_started_at >= TileQuestStyle.entry_duration_ms) {
      _entering = false;
      outer_changed = true;
      if (_pending.isNotEmpty) {
        _begin_next(
          _entry_started_at + TileQuestStyle.entry_duration_ms,
          observed_at: now,
        );
      }
    }
    while (_active != null &&
        now >= (_insertions?.ends_at ?? _active!.ends_at)) {
      final batch = _insertions;
      final completed = batch?.motions.last ?? _active!;
      final completed_at = batch?.ends_at ?? completed.ends_at;
      if (batch != null) {
        for (final motion in batch.motions) {
          _match_feedback(motion, now);
        }
      } else {
        _match_feedback(completed, now);
      }
      final reserve_before = _presented.reserve;
      final action = completed.result.action;
      _presented = completed.result.after;
      if (!listEquals(reserve_before, _presented.reserve)) outer_changed = true;
      // Undo and shuffle return tiles to the visible board set; taps leave
      // them removed so only the clock-driven motion layer needs to update.
      if (action == TileQuestAction.undo || action == TileQuestAction.shuffle) {
        outer_changed = true;
      }
      _completed_actions.addAll(
        batch?.motions.map((motion) => motion.result) ?? [completed.result],
      );
      _active = null;
      _insertions = null;
      if (completed.result.before.status != completed.result.after.status &&
          now - completed_at <= TileQuestStyle.feedback_frame_window_ms) {
        if (completed.result.after.status == TileQuestStatus.won) {
          _send_feedback(TileQuestFeedbackEvent.won);
        } else if (completed.result.after.status == TileQuestStatus.lost) {
          _send_feedback(TileQuestFeedbackEvent.lost);
        }
      }
      if (_pending.isNotEmpty) _begin_next(completed_at, observed_at: now);
    }
    if (_insertions != null) {
      for (final motion in _insertions!.motions) {
        _match_feedback(motion, now);
      }
    } else if (_active != null) {
      _match_feedback(_active!, now);
    }
    _clock.value = now;
    _reveal.advance(now);
    if (_active == null && !_entering && !_reveal.is_animating) {
      _ticker.stop();
      _report_busy(false);
    }
    if (outer_changed && mounted) setState(() {});
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
    _reveal.dispose();
    _shuffle_textures.dispose();
    _pressed.dispose();
    super.dispose();
  }

  Set<int> get _moving_board_ids => {
    if (_active != null) ..._active!.result.moved_ids,
    if (_insertions != null) ..._insertions!.incoming_ids,
    for (final motion in _pending) ...motion.result.moved_ids,
  };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final layout = QuestSceneLayout(
        Size(constraints.maxWidth, constraints.maxHeight),
        widget.state,
        display_features: MediaQuery.displayFeaturesOf(context),
      );
      _latest_layout = layout;
      final cjk = quest_is_cjk(context);
      return ClipRect(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ..._board_tiles(layout),
            Positioned.fromRect(
              rect: layout.tray,
              child: QuestSlotWell(layout: layout),
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
                        const SizedBox(width: LayoutConfig.space_10),
                      Expanded(
                        child: QuestToolButton(
                          key: ValueKey('tile_quest_tool_${tool.name}'),
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
            Positioned.fill(
              child: QuestMotionCanvas(
                key: const ValueKey('tile_quest_motion_canvas'),
                layout: layout,
                clock: _clock,
                textures: _shuffle_textures,
                reveal: _reveal,
                snapshot_at: (now) => _motion_snapshot(layout, now),
                particle_fields: _particle_fields,
                reduced_motion: MediaQuery.disableAnimationsOf(context),
                can_return: _can_return,
                on_reserve: widget.on_reserve,
              ),
            ),
            Positioned.fromRect(
              rect: layout.header,
              child: QuestHeader(
                compact: layout.compact_header,
                state: widget.state,
                sound_enabled: widget.sound_enabled,
                on_back: widget.on_back,
                on_restart: widget.on_restart,
                on_sound: widget.on_sound,
              ),
            ),
            if (widget.show_layout_debug)
              Positioned.fill(
                child: QuestLayoutDebug(state: widget.state, layout: layout),
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
    final visible = [
      for (final tile in widget.state.tiles)
        if (!tile.is_removed && !hidden.contains(tile.id)) tile,
    ];
    final enabled =
        !widget.busy &&
        !_board_locked &&
        widget.state.status == TileQuestStatus.playing;
    final cached = _board_cache;
    if (cached == null ||
        !listEquals(visible, _board_cache_tiles) ||
        cached.painter.layout.unit != layout.unit ||
        cached.painter.layout.board_origin != layout.board_origin ||
        cached.painter.layout.size != layout.size ||
        cached.painter.enabled != enabled) {
      _board_cache_tiles = visible;
      _board_cache = QuestBoardCanvas(
        key: const ValueKey('tile_quest_board_canvas'),
        tiles: visible,
        layout: layout,
        textures: _shuffle_textures,
        pressed: _pressed,
        reveal: _reveal,
        enabled: enabled,
        on_press: (id) => _pressed.value = id,
        on_tile: (id) => widget.on_tile(id),
      );
    }
    return [Positioned.fill(child: _board_cache!)];
  }

  bool _can_return(int id) =>
      _show_tools &&
      !widget.busy &&
      !_board_locked &&
      widget.state.status == TileQuestStatus.playing &&
      widget.state.is_reserve_available(id);

  /// 备用堆使用相同遮罩时钟；移出/撤回及露出下层时也连续衔接。
  Map<int, bool> get _reserve_shades => {
    for (final id in widget.state.reserve)
      id: !widget.state.is_reserve_available(id),
  };

  QuestTileFrame _tile(
    int id,
    int type,
    Rect rect, {
    bool flying = false,
    double rotation = 0,
    double? dissolve,
    bool reserve = false,
    bool blocked = false,
  }) => QuestTileFrame(
    id: id,
    type: type,
    rect: rect,
    zone: flying
        ? QuestTileZone.flight
        : reserve
        ? QuestTileZone.reserve
        : QuestTileZone.tray,
    rotation: rotation,
    dissolve: dissolve,
    blocked: blocked,
    blocked_amount: flying || reserve
        ? _reveal.amount_of(id, blocked: blocked)
        : null,
  );

  Rect _flight_rect(Rect start, Rect end, double progress) {
    final rect = Rect.lerp(start, end, progress)!;
    final lift =
        math.sin(progress * math.pi) *
        math.min(
          TileQuestStyle.flight_lift_max,
          (start.center - end.center).distance *
              TileQuestStyle.flight_lift_distance_fraction,
        );
    return rect.translate(0, -lift);
  }

  QuestMotionSnapshot _motion_snapshot(QuestSceneLayout layout, double now) {
    final rendered = <int>{};
    final children = <QuestTileFrame>[];
    QuestShuffleStage? shuffle;
    final active = _active;
    if (_entering) {
      final tiles = _entry_tiles;
      for (var rank = 0; rank < tiles.length; rank++) {
        final tile = tiles[rank];
        rendered.add(tile.id);
        final progress = QuestBoardMotion.entrance_progress(
          rank,
          tiles.length,
          now - _entry_started_at,
        );
        children.add(
          QuestTileFrame(
            id: tile.id,
            type: tile.type,
            rect: QuestBoardMotion.entrance_rect(
              layout,
              tile,
              rank,
              tiles.length,
              now - _entry_started_at,
            ),
            zone: QuestTileZone.entry,
            blocked: tile.is_blocked,
            rotation:
                (tile.id.isEven ? 1 : -1) *
                TileQuestStyle.entry_rotation *
                (1 - progress),
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
      shuffle = _tool_tiles(active, layout, now, children, rendered);
    }
    for (final motion in _pending) {
      final result = motion.result;
      if ((result.action == TileQuestAction.tap ||
              (motion.inserts && motion.preflight)) &&
          !rendered.contains(motion.incoming_id)) {
        final id = motion.incoming_id;
        rendered.add(id);
        final source = layout.location(result.before, id);
        final target = layout.tray_tile(motion.insertion_tray.indexOf(id));
        // 预飞先锁定航距时长，落入时间线时与落槽共用同一速度。
        motion.lock_flight((source.center - target.center).distance);
        children.add(
          _tile(
            id,
            result.before.tile_by_id(id).type,
            _flight_rect(source, target, motion.preflight_progress(now)),
            flying: true,
          ),
        );
      } else if (result.action == TileQuestAction.shuffle) {
        final excluded = Set<int>.of(rendered);
        rendered.addAll(result.moved_ids);
        shuffle = QuestShuffleStage(
          motion,
          waiting: true,
          excluded_ids: excluded,
        );
      }
    }
    return QuestMotionSnapshot(children, shuffle: shuffle);
  }

  /// 每张牌只绘制一次；已匹配牌在自己的时钟上粒子化，槽位可提前复用。
  void _insertion_tiles(
    QuestSceneMotion motion,
    QuestSceneLayout layout,
    double now,
    List<QuestTileFrame> children,
    Set<int> rendered,
  ) {
    final batch = _insertions!;
    for (final track in batch.tracks.values) {
      rendered.add(track.id);
      if (track.ends_at != null && now >= track.ends_at!) continue;
      children.add(
        _tile(
          track.id,
          track.type,
          track.rect(layout, now),
          flying: track.incoming,
          dissolve: track.fade_at == null ? null : track.fade(now),
          reserve: track.reserve,
          blocked: track.reserve && !batch.after.is_reserve_available(track.id),
        ),
      );
    }
  }

  /// Move every held neighbor in the same transaction, with one visual per id.
  /// Shuffle cards are batched into one canvas pass instead of hundreds of
  /// per-frame widget subtrees; static reserve cards stay ordinary widgets.
  QuestShuffleStage? _tool_tiles(
    QuestSceneMotion motion,
    QuestSceneLayout layout,
    double now,
    List<QuestTileFrame> children,
    Set<int> rendered,
  ) {
    final result = motion.result;
    final is_shuffle = result.action == TileQuestAction.shuffle;
    final ids = is_shuffle
        ? <int>{...result.after.tray, ...result.after.reserve}
        : motion.tool_ids;
    final progress = motion.travel(now);
    if (is_shuffle) rendered.addAll(result.moved_ids);
    for (final id in ids) {
      rendered.add(id);
      final tile = result.after.tile_by_id(id);
      final moved = motion.moved_ids.contains(id);
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
      children.add(
        _tile(
          id,
          tile.type,
          moved
              ? _flight_rect(source, destination, progress)
              : Rect.lerp(source, destination, progress)!,
          flying: moved,
          reserve: !moved && result.after.reserve.contains(id),
          blocked:
              result.after.reserve.contains(id) &&
              !result.after.is_reserve_available(id),
        ),
      );
    }
    return is_shuffle && result.moved_ids.isNotEmpty
        ? QuestShuffleStage(motion)
        : null;
  }
}
