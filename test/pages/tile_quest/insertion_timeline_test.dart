// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/style.dart';
import 'package:app/pages/tile_quest/widgets/insertion_timeline.dart';
import 'package:app/pages/tile_quest/widgets/scene_layout.dart';
import 'package:app/pages/tile_quest/widgets/scene_motion.dart';
import 'package:app/pages/tile_quest/widgets/tile_surface_style.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _derivative_step = .001;
const _size = Size(390, 844);
const _tile_ratio = QuestTileSurfaceStyle.tile_aspect_ratio;

/// 每种图案均为完整三张，布局不覆盖，保证所有测试都通过真实规则引擎。
TileQuestState _fixture({List<int> tray = const []}) => TileQuestState(
  tiles: [
    for (var id = 0; id < 12; id++)
      TileQuestTile(
        id: id,
        type: id ~/ 3,
        layer: 0,
        x: (id % 4).toDouble(),
        y: (id ~/ 4).toDouble(),
        is_removed: tray.contains(id),
      ),
  ],
  tray: tray,
  level: 2,
  difficulty: 4,
  unlocked_level: 2,
  seed: 38,
  challenge_id: 'continuous-insertion',
);

/// 比较完整矩形，尺寸变化也必须连续，不能只修复牌中心的移动。
void _same_rect(Rect actual, Rect expected) {
  expect(actual.left, closeTo(expected.left, .000001));
  expect(actual.top, closeTo(expected.top, .000001));
  expect(actual.width, closeTo(expected.width, .000001));
  expect(actual.height, closeTo(expected.height, .000001));
}

/// 用实际画面坐标差分求速度，无需为测试暴露内部速度实现。
({Offset center, double width, double height}) _velocity(
  QuestInsertionTrack track,
  QuestSceneLayout layout,
  double first,
  double last,
) {
  final a = track.rect(layout, first);
  final b = track.rect(layout, last);
  final elapsed = last - first;
  return (
    center: (b.center - a.center) / elapsed,
    width: (b.width - a.width) / elapsed,
    height: (b.height - a.height) / elapsed,
  );
}

void main() {
  test(
    'board cards shrink into the tray without changing their tall aspect',
    () {
      final before = _fixture();
      final engine = TileQuestEngine(before);
      final layout = QuestSceneLayout(_size, before);
      final timeline = QuestInsertionTimeline(before, 0);
      final source = layout.board_tile(before.tile_by_id(0));
      final target = layout.tray_tile(0);
      expect(source.width, greaterThan(target.width * 1.10));
      expect(source.height / source.width, closeTo(_tile_ratio, .000001));
      timeline.add(QuestSceneMotion(engine.tap_tile(0), 0), 0);
      final track = timeline.tracks[0]!;
      final duration = TileQuestStyle.flight_duration.inMilliseconds.toDouble();
      _same_rect(track.rect(layout, 0), source);
      var previous_width = source.width;
      for (var now = 1.0; now < duration; now += 3) {
        final rect = track.rect(layout, now);
        expect(rect.height / rect.width, closeTo(_tile_ratio, .000001));
        expect(rect.width, lessThanOrEqualTo(previous_width));
        expect(rect.width, greaterThan(target.width));
        previous_width = rect.width;
      }
      _same_rect(track.rect(layout, duration), target);
      final initial = _velocity(track, layout, 0, _derivative_step);
      final final_velocity = _velocity(
        track,
        layout,
        duration - _derivative_step,
        duration,
      );
      for (final velocity in [initial, final_velocity]) {
        expect(velocity.width.abs(), lessThan(.00001));
        expect(velocity.height.abs(), lessThan(.00001));
      }
    },
  );

  test('rapid retargeting preserves shrinking size velocity and aspect', () {
    final before = _fixture();
    final engine = TileQuestEngine(before);
    final layout = QuestSceneLayout(_size, before);
    final timeline = QuestInsertionTimeline(before, 0);
    void tap(int id, double time) => timeline.add(
      QuestSceneMotion(engine.tap_tile(id), time, preflight: true),
      time,
    );
    tap(0, 0);
    tap(3, 28);
    final neighbor = timeline.tracks[3]!;
    const redirect_at = 76.0;
    final original = neighbor.rect(layout, redirect_at);
    final incoming = _velocity(
      neighbor,
      layout,
      redirect_at - _derivative_step,
      redirect_at,
    );
    expect(incoming.width, lessThan(-.01));
    tap(1, redirect_at);
    _same_rect(neighbor.rect(layout, redirect_at), original);
    final outgoing = _velocity(
      neighbor,
      layout,
      redirect_at,
      redirect_at + _derivative_step,
    );
    expect(outgoing.width, closeTo(incoming.width, .00001));
    expect(outgoing.height, closeTo(incoming.height, .00001));
    expect((outgoing.center - incoming.center).distance, lessThan(.0001));
    final arrival = 28 + TileQuestStyle.flight_duration.inMilliseconds;
    for (var now = redirect_at; now < arrival; now += 4) {
      final rect = neighbor.rect(layout, now);
      expect(rect.height / rect.width, closeTo(_tile_ratio, .000001));
      expect(rect.width, greaterThanOrEqualTo(layout.tray_tile(2).width));
    }
    _same_rect(neighbor.rect(layout, arrival.toDouble()), layout.tray_tile(2));
  });

  test('A B A redirect preserves position size and instantaneous velocity', () {
    final before = _fixture();
    final engine = TileQuestEngine(before);
    final layout = QuestSceneLayout(_size, before);
    final timeline = QuestInsertionTimeline(before, 0);
    void tap(int id, double time) => timeline.add(
      QuestSceneMotion(engine.tap_tile(id), time, preflight: true),
      time,
    );

    tap(0, 0);
    tap(3, 40);
    final neighbor = timeline.tracks[3]!;
    const redirect_at = 100.0;
    final position = neighbor.rect(layout, redirect_at);
    final incoming_velocity = _velocity(
      neighbor,
      layout,
      redirect_at - _derivative_step,
      redirect_at,
    );
    expect(incoming_velocity.center.distance, greaterThan(.1));

    tap(1, redirect_at);
    _same_rect(neighbor.rect(layout, redirect_at), position);
    final outgoing_velocity = _velocity(
      neighbor,
      layout,
      redirect_at,
      redirect_at + _derivative_step,
    );
    expect(
      (outgoing_velocity.center - incoming_velocity.center).distance,
      lessThan(.0001),
      reason: 'redirecting a flying neighbor must not reset its velocity',
    );
    expect(outgoing_velocity.width, closeTo(incoming_velocity.width, .00001));
    expect(outgoing_velocity.height, closeTo(incoming_velocity.height, .00001));
    _same_rect(
      neighbor.rect(
        layout,
        40 + TileQuestStyle.flight_duration.inMilliseconds.toDouble(),
      ),
      layout.tray_tile(2),
    );
  });

  test('late retarget keeps velocity while allowing a full slot shift', () {
    final before = _fixture();
    final engine = TileQuestEngine(before);
    final layout = QuestSceneLayout(_size, before);
    final timeline = QuestInsertionTimeline(before, 0);
    final duration = TileQuestStyle.flight_duration.inMilliseconds.toDouble();
    timeline.add(QuestSceneMotion(engine.tap_tile(0), 0), 0);
    timeline.add(QuestSceneMotion(engine.tap_tile(3), 0), 0);
    final neighbor = timeline.tracks[3]!;
    final redirect_at = duration - 16;
    final position = neighbor.rect(layout, redirect_at);
    final incoming_velocity = _velocity(
      neighbor,
      layout,
      redirect_at - _derivative_step,
      redirect_at,
    );
    timeline.add(
      QuestSceneMotion(engine.tap_tile(1), redirect_at),
      redirect_at,
    );
    _same_rect(neighbor.rect(layout, redirect_at), position);
    final outgoing_velocity = _velocity(
      neighbor,
      layout,
      redirect_at,
      redirect_at + _derivative_step,
    );
    expect(
      (outgoing_velocity.center - incoming_velocity.center).distance,
      lessThan(.0001),
    );
    expect(
      (neighbor.rect(layout, duration).center - layout.tray_tile(2).center)
          .distance,
      greaterThan(1),
      reason: 'a late click must not cause an instantaneous one-slot jump',
    );
    _same_rect(
      neighbor.rect(layout, redirect_at + TileQuestStyle.tray_compact_ms),
      layout.tray_tile(2),
    );
  });

  test('successive triples fly continuously until each real slot release', () {
    final before = _fixture();
    final engine = TileQuestEngine(before);
    final layout = QuestSceneLayout(_size, before);
    final timeline = QuestInsertionTimeline(before, 0);
    for (var id = 0; id < 7; id++) {
      timeline.add(QuestSceneMotion(engine.tap_tile(id), 0), 0);
    }
    final duration = TileQuestStyle.flight_duration.inMilliseconds.toDouble();
    final second_arrival =
        duration +
        TileQuestStyle.match_hold_ms +
        TileQuestStyle.tray_compact_ms;
    final third_arrival =
        second_arrival +
        TileQuestStyle.match_hold_ms +
        TileQuestStyle.tray_compact_ms;
    for (final (id, arrival) in [(3, second_arrival), (6, third_arrival)]) {
      final track = timeline.tracks[id]!;
      final source = layout.location(before, id);
      var previous = source;
      for (var now = 16.0; now < arrival - 16; now += 16) {
        final current = track.rect(layout, now);
        expect(
          (current.center - previous.center).distance,
          greaterThan(.01),
          reason: 'a capacity barrier must extend the path without a hover',
        );
        expect(
          (current.center - layout.tray_tile(0).center).distance,
          greaterThan(.01),
        );
        previous = current;
      }
      _same_rect(track.rect(layout, arrival), layout.tray_tile(0));
      expect(track.fade(arrival), 0);
    }
    final first_match = timeline.motions[2];
    final second_match = timeline.motions[5];
    expect(
      first_match.started_at + first_match.match_start,
      duration + TileQuestStyle.match_hold_ms,
    );
    expect(
      second_match.started_at + second_match.match_start,
      second_arrival + TileQuestStyle.match_hold_ms,
    );
    expect(timeline.tracks[3]!.fade(second_arrival), 0);
  });

  test('compaction joins a settled survivor with zero boundary velocity', () {
    final before = _fixture(tray: [0, 1, 3, 4, 6]);
    final engine = TileQuestEngine(before);
    final layout = QuestSceneLayout(_size, before);
    final timeline = QuestInsertionTimeline(before, 0);
    final motion = QuestSceneMotion(engine.tap_tile(2), 0);
    timeline.add(motion, 0);
    final compact_at = motion.started_at + motion.match_start;
    final track = timeline.tracks[6]!;
    final incoming = _velocity(
      track,
      layout,
      compact_at - _derivative_step,
      compact_at,
    );
    final outgoing = _velocity(
      track,
      layout,
      compact_at,
      compact_at + _derivative_step,
    );
    expect(incoming.center.distance, lessThan(.000001));
    expect(outgoing.center.distance, lessThan(.0001));
    _same_rect(
      track.rect(layout, compact_at + TileQuestStyle.tray_compact_ms),
      layout.tray_tile(2),
    );
  });

  test('shared travel curve has stationary ends without repeated easing', () {
    final engine = TileQuestEngine(_fixture());
    final motion = QuestSceneMotion(engine.tap_tile(0), 0, preflight: true)
      ..start(0);
    final duration = TileQuestStyle.flight_duration.inMilliseconds.toDouble();
    expect(motion.travel(duration * .25), closeTo(.15625, .0000001));
    expect(
      motion.preflight_progress(duration * .25),
      motion.travel(duration * .25),
    );
    expect(motion.travel(0), 0);
    expect(motion.travel(duration), 1);
    expect(
      motion.travel(_derivative_step) / _derivative_step,
      lessThan(.000001),
    );
    expect(
      (1 - motion.travel(duration - _derivative_step)) / _derivative_step,
      lessThan(.000001),
    );
  });

  test('flight duration scales with hop distance so near tiles stay quick', () {
    final before = _fixture();
    final engine = TileQuestEngine(before);
    final layout = QuestSceneLayout(_size, before);
    // 取棋盘最上与最下两枚，航距差应驱动时长差。
    TileQuestTile top = before.tiles.first;
    TileQuestTile bottom = before.tiles.first;
    for (final tile in before.tiles) {
      if (tile.y < top.y) top = tile;
      if (tile.y > bottom.y) bottom = tile;
    }
    expect(top.id, isNot(bottom.id));

    final top_motion = QuestSceneMotion(engine.tap_tile(top.id), 0);
    final top_from = layout.location(top_motion.result.before, top_motion.incoming_id);
    final top_to = layout.tray_tile(top_motion.insertion_tray.indexOf(top_motion.incoming_id));
    final top_distance = (top_from.center - top_to.center).distance;
    final top_ms = TileQuestStyle.flight_duration_ms(top_distance);

    final bottom_engine = TileQuestEngine(top_motion.result.after);
    final bottom_motion = QuestSceneMotion(bottom_engine.tap_tile(bottom.id), 0);
    final bottom_from = layout.location(
      bottom_motion.result.before,
      bottom_motion.incoming_id,
    );
    final bottom_to = layout.tray_tile(
      bottom_motion.insertion_tray.indexOf(bottom_motion.incoming_id),
    );
    final bottom_distance =
        (bottom_from.center - bottom_to.center).distance;
    final bottom_ms = TileQuestStyle.flight_duration_ms(bottom_distance);

    expect(top_distance, greaterThan(bottom_distance + 80));
    expect(bottom_ms, lessThan(top_ms));
    expect(bottom_ms, greaterThanOrEqualTo(TileQuestStyle.flight_duration_min_ms));
    expect(top_ms, lessThanOrEqualTo(TileQuestStyle.flight_duration_max_ms));
    // 中段匀速：时长 = clamp(航距 / 速度)。
    expect(
      top_ms,
      closeTo(
        (top_distance / TileQuestStyle.flight_speed)
            .clamp(
              TileQuestStyle.flight_duration_min_ms,
              TileQuestStyle.flight_duration_max_ms,
            )
            .toDouble(),
        .001,
      ),
    );

    final top_timeline = QuestInsertionTimeline(before, 0)
      ..add(top_motion, 0, distance: top_distance);
    _same_rect(
      top_timeline.tracks[top_motion.incoming_id]!.rect(layout, top_ms),
      top_to,
    );

    final bottom_timeline =
        QuestInsertionTimeline(bottom_motion.result.before, 0)
          ..add(bottom_motion, 0, distance: bottom_distance);
    final bottom_track = bottom_timeline.tracks[bottom_motion.incoming_id]!;
    _same_rect(bottom_track.rect(layout, bottom_ms), bottom_to);
    // 近牌落槽时，远牌仍在途中。
    expect(bottom_ms, lessThan(top_ms - 30));
    expect(
      (top_timeline.tracks[top_motion.incoming_id]!.rect(layout, bottom_ms)
              .center -
          top_to.center)
          .distance,
      greaterThan(1),
      reason: 'far hop must still be flying when the near hop lands',
    );
  });
}
