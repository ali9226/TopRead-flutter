// ignore_for_file: non_constant_identifier_names
import 'dart:math' as math;

import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/style.dart';
import 'package:app/pages/tile_quest/widgets/board_motion.dart';
import 'package:app/pages/tile_quest/widgets/scene_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final state = TileQuestGenerator.generate(level: 1, seed: 2034);
  final layout = QuestSceneLayout(const Size(390, 844), state);
  final source = layout.board_tile(state.tiles.first);
  const count = 528;

  test('shuffle winds continuously for over three turns before scattering', () {
    for (final index in [0, 1, 17, 203, 527]) {
      var previous = 0.0;
      var winding = 0.0;
      for (var frame = 0; frame <= 360; frame++) {
        final time =
            TileQuestStyle.shuffle_gather_fraction +
            (TileQuestStyle.shuffle_scatter_fraction -
                    TileQuestStyle.shuffle_gather_fraction) *
                frame /
                360;
        final center = QuestBoardMotion.shuffle_rect(
          layout,
          source,
          index,
          count,
          time,
        ).center;
        final offset = center - layout.board.center;
        final angle = math.atan2(offset.dy, offset.dx);
        if (frame > 0) {
          var delta = angle - previous;
          if (delta < -math.pi) delta += math.pi * 2;
          if (delta > math.pi) delta -= math.pi * 2;
          expect(delta, greaterThan(0), reason: 'no reversal or abrupt jump');
          winding += delta;
        }
        previous = angle;
      }
      expect(winding, greaterThanOrEqualTo(math.pi * 6));
    }
    expect(QuestBoardMotion.shuffle_turns(0), 0);
    expect(
      QuestBoardMotion.shuffle_turns(1),
      closeTo(TileQuestStyle.shuffle_turns, 1e-10),
    );
  });

  test(
    'shuffle starts and ends exactly and all phase velocities are continuous',
    () {
      const epsilon = .00001;
      for (final index in [0, 1, 17, 203, 527]) {
        Rect sample(double time) =>
            QuestBoardMotion.shuffle_rect(layout, source, index, count, time);
        expect(sample(0), source);
        expect(sample(1), source);
        for (final boundary in [
          TileQuestStyle.shuffle_gather_fraction,
          TileQuestStyle.shuffle_scatter_fraction,
        ]) {
          final middle = sample(boundary).center;
          final before = sample(boundary - epsilon).center;
          final after = sample(boundary + epsilon).center;
          final left_velocity = (middle - before) / epsilon;
          final right_velocity = (after - middle) / epsilon;
          expect((left_velocity - right_velocity).distance, lessThan(2));
        }
        expect(
          (sample(epsilon).center - source.center).distance,
          lessThan(.001),
        );
        expect(
          (sample(1 - epsilon).center - source.center).distance,
          lessThan(.001),
        );
        expect(QuestBoardMotion.shuffle_scale(0), 1);
        expect(QuestBoardMotion.shuffle_scale(1), 1);
        expect(QuestBoardMotion.shuffle_rotation(0, index: index), 0);
        expect(QuestBoardMotion.shuffle_rotation(1, index: index), 0);
      }
    },
  );

  test(
    'every spinning card shares one constant circular radius at all aspects',
    () {
      for (final size in [
        const Size(320, 568),
        const Size(390, 844),
        const Size(768, 1024),
        const Size(844, 390),
      ]) {
        final current = QuestSceneLayout(size, state);
        double? fixed_radius;
        for (var frame = 0; frame <= 80; frame++) {
          final time =
              TileQuestStyle.shuffle_gather_fraction +
              (TileQuestStyle.shuffle_scatter_fraction -
                      TileQuestStyle.shuffle_gather_fraction) *
                  frame /
                  80;
          final centers = <Offset>[];
          for (var index = 0; index < 32; index++) {
            final tile = state.tiles[index % state.tiles.length];
            final rect = QuestBoardMotion.shuffle_rect(
              current,
              current.board_tile(tile),
              index,
              32,
              time,
            );
            centers.add(rect.center);
            final radius = (rect.center - current.board.center).distance;
            fixed_radius ??= radius;
            expect(
              radius,
              closeTo(fixed_radius, .000001),
              reason:
                  'all cards, directions and spin frames must share one radius',
            );
          }
          final width =
              centers.map((point) => point.dx).reduce(math.max) -
              centers.map((point) => point.dx).reduce(math.min);
          final height =
              centers.map((point) => point.dy).reduce(math.max) -
              centers.map((point) => point.dy).reduce(math.min);
          expect(
            width,
            closeTo(height, .000001),
            reason: 'a rectangular viewport must not stretch the spinning ring',
          );
        }
      }
    },
  );

  test(
    'face blending is smooth and staggered while every shuffle scale stays one',
    () {
      final switch_times = <double>[];
      for (final index in [0, 1, 17, 203, 527]) {
        var previous = 0.0;
        double? halfway;
        for (var frame = 0; frame <= 400; frame++) {
          final time = frame / 400;
          final face = QuestBoardMotion.shuffle_face_progress(
            time,
            index: index,
            count: count,
          );
          expect(face, inInclusiveRange(0, 1));
          expect(face, greaterThanOrEqualTo(previous));
          expect(face - previous, lessThan(.04));
          expect(
            QuestBoardMotion.shuffle_scale(time),
            1,
            reason: 'gather, blend, spin and scatter must keep full card size',
          );
          if (face >= .5) halfway ??= time;
          previous = face;
        }
        expect(previous, 1);
        switch_times.add(halfway!);
      }
      expect(switch_times.last - switch_times.first, greaterThan(.05));
    },
  );

  test(
    'shuffle keeps every card inside small, tablet and landscape boards',
    () {
      for (final size in [
        const Size(320, 568),
        const Size(390, 844),
        const Size(768, 1024),
        const Size(844, 390),
      ]) {
        final current_layout = QuestSceneLayout(size, state);
        for (var index = 0; index < state.tiles.length; index++) {
          final current_source = current_layout.board_tile(state.tiles[index]);
          for (var frame = 0; frame <= 126; frame++) {
            final rect = QuestBoardMotion.shuffle_rect(
              current_layout,
              current_source,
              index,
              state.tiles.length,
              frame / 126,
            );
            final bounds = current_layout.board.inflate(.001);
            expect(bounds.contains(rect.topLeft), isTrue);
            expect(bounds.contains(rect.bottomRight), isTrue);
          }
        }
      }
    },
  );
}
