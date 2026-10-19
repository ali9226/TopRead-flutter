// ignore_for_file: non_constant_identifier_names
import 'dart:ui' as ui;
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/style.dart';
import 'package:app/pages/tile_quest/widgets/board_motion.dart';
import 'package:app/pages/tile_quest/widgets/quest_scene.dart';
import 'package:app/pages/tile_quest/widgets/scene_layout.dart';
import 'package:app/pages/tile_quest/widgets/scene_motion.dart';
import 'package:app/pages/tile_quest/widgets/shuffle_motion.dart';
import 'package:app/pages/tile_quest/widgets/shuffle_textures.dart';
import 'package:app/pages/tile_quest/widgets/tile_card.dart';
import 'package:app/pages/tile_quest/widgets/tile_surface.dart';
import 'package:app/pages/tile_quest/widgets/motion_canvas.dart';
import 'package:app/pages/tile_quest/widgets/board_canvas.dart';
import 'scene_probe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = Size(390, 844);

Future<void> _wait_ready(
  WidgetTester tester,
  QuestShuffleTextures textures,
) async {
  for (var attempt = 0; attempt < 200 && !textures.ready; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump();
  }
  expect(
    textures.ready,
    isTrue,
    reason: 'real asset decode and atlas must finish',
  );
  await tester.pump();
}

TileQuestActionResult _shuffle(TileQuestState before) => TileQuestActionResult(
  accepted: true,
  before: before,
  after: before.copy_with(
    tiles: [
      for (var index = 0; index < before.tiles.length; index++)
        before.tiles[index].copy_with(
          type: before.tiles[(index + 1) % before.tiles.length].type,
        ),
    ],
  ),
  action: TileQuestAction.shuffle,
  moved_ids: before.tiles
      .where((tile) => !tile.is_removed)
      .map((tile) => tile.id)
      .toList(),
);

Future<ui.Image> _raster(
  QuestShufflePainter painter, {
  bool reference = false,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (!reference) {
    painter.paint(canvas, _size);
  } else {
    final paint = Paint()..filterQuality = FilterQuality.low;
    for (final id in painter.tile_ids) {
      final frame = painter.frame_of(id);
      final atlas = painter.textures.atlas!;
      final previous = painter.textures.source_of(
        frame.previous_type,
        blocked: frame.blocked,
      )!;
      final image = painter.textures.source_of(
        frame.type,
        blocked: frame.blocked,
      )!;
      canvas.save();
      canvas.translate(frame.rect.center.dx, frame.rect.center.dy);
      canvas.rotate(frame.rotation);
      // 长牌四边外扩相同像素数；高度不能再乘宽度专用的cell_scale。
      final dest = QuestTileSurface.cell_rect(
        Rect.fromCenter(
          center: Offset.zero,
          width: frame.rect.width,
          height: frame.rect.height,
        ),
      );
      if (frame.face_progress < 1) {
        paint.color = Colors.white;
        canvas.drawImageRect(atlas, previous, dest, paint);
      }
      if (frame.face_progress > 0 &&
          (frame.previous_type != frame.type || frame.face_progress >= 1)) {
        paint.color = Colors.white.withValues(alpha: frame.face_progress);
        canvas.drawImageRect(atlas, image, dest, paint);
      }
      canvas.restore();
    }
  }
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(_size.width.toInt(), _size.height.toInt());
  } finally {
    picture.dispose();
  }
}

void main() {
  for (final difficulty in [8, 10]) {
    testWidgets(
      'shuffle of difficulty $difficulty uses one constant widget subtree',
      (tester) async {
        await tester.binding.setSurfaceSize(_size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final before = TileQuestGenerator.generate(
          level: 2,
          seed: 730,
          difficulty: difficulty,
        );
        final result = _shuffle(before);
        final state = ValueNotifier<TileQuestActionResult?>(null);
        addTearDown(state.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder(
                valueListenable: state,
                builder: (context, action, child) => TileQuestScene(
                  state: action?.after ?? before,
                  action: action,
                  animate_entry: false,
                  sound_enabled: false,
                  busy: false,
                  on_back: () {},
                  on_restart: () {},
                  on_sound: () {},
                  on_tile: (_) {},
                  on_reserve: (_) {},
                  on_tool: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        state.value = result;
        await tester.pump();
        final canvas = find.byType(QuestMotionCanvas);
        expect(canvas, findsOneWidget);
        final surface = find.descendant(
          of: canvas,
          matching: find.byType(CustomPaint),
        );
        final painter =
            tester.widget<CustomPaint>(surface).painter! as QuestMotionPainter;
        await _wait_ready(tester, painter.textures);
        expect(painter.frames.length, difficulty == 8 ? 402 : 528);
        expect(
          find.byType(QuestTileCard),
          findsNothing,
          reason:
              'the batch must not retain hundreds of invisible card widgets',
        );
        final subtree_size = find
            .descendant(
              of: canvas,
              matching: find.byWidgetPredicate((_) => true),
            )
            .evaluate()
            .length;
        expect(subtree_size, lessThan(12));
        for (var frame = 0; frame < 100; frame++) {
          await tester.pump(const Duration(milliseconds: 8));
          expect(tester.widget<CustomPaint>(surface).painter, same(painter));
          expect(
            find
                .descendant(
                  of: canvas,
                  matching: find.byWidgetPredicate((_) => true),
                )
                .evaluate()
                .length,
            subtree_size,
          );
        }
        await tester.pumpAndSettle();
        expect(find.byType(QuestTileCard), findsNothing);
        expect(find.byType(QuestBoardCanvas), findsOneWidget);
        expect(quest_scene_frames(tester).length, before.total_count);
        expect(
          quest_scene_frames(
            tester,
          ).values.every((frame) => frame.zone == QuestTileZone.board),
          isTrue,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'atlas raster matches full size ordered cards throughout the shuffle',
    (tester) async {
      final before = TileQuestGenerator.generate(level: 2, seed: 730);
      final result = _shuffle(before);
      final textures = QuestShuffleTextures();
      addTearDown(textures.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              textures.resolve(context, {
                ...before.tiles.map((tile) => tile.type),
                ...result.after.tiles.map((tile) => tile.type),
              });
              return const SizedBox();
            },
          ),
        ),
      );
      await _wait_ready(tester, textures);
      final clock = ValueNotifier<double>(0);
      addTearDown(clock.dispose);
      final motion = QuestSceneMotion(result, 0)..start(0);
      final layout = QuestSceneLayout(_size, before);
      final painter = QuestShufflePainter(
        motion: motion,
        layout: layout,
        clock: clock,
        textures: textures,
      );
      for (final time in [0.0, .3, .5, .9, 1.0]) {
        clock.value = TileQuestStyle.shuffle_duration_ms * time;
        for (final id in painter.tile_ids) {
          final frame = painter.frame_of(id);
          final index = result.moved_ids.indexOf(id);
          final expected = QuestBoardMotion.shuffle_rect(
            layout,
            layout.board_tile(before.tile_by_id(id)),
            index,
            before.total_count,
            time,
          );
          expect(
            (frame.rect.center - expected.center).distance,
            lessThan(.000001),
          );
          expect(
            frame.rect.width,
            closeTo(layout.board_tile(before.tile_by_id(id)).width, .000001),
          );
          expect(
            frame.rect.height,
            closeTo(layout.board_tile(before.tile_by_id(id)).height, .000001),
          );
        }
        await tester.runAsync(() async {
          final actual_image = await _raster(painter);
          final reference_image = await _raster(painter, reference: true);
          try {
            final actual = (await actual_image.toByteData())!.buffer
                .asUint8List();
            final reference = (await reference_image.toByteData())!.buffer
                .asUint8List();
            var difference = 0;
            var opaque_pixels = 0;
            for (var index = 0; index < actual.length; index++) {
              difference += (actual[index] - reference[index]).abs();
              if (index % 4 == 3 && actual[index] > 200) opaque_pixels++;
            }
            expect(
              opaque_pixels,
              greaterThan(5000),
              reason: 'the atlas must actually paint the board',
            );
            expect(
              difference / actual.length,
              lessThan(1.5),
              reason:
                  'atlas geometry, rotation, masks, type order and blend at $time',
            );
          } finally {
            actual_image.dispose();
            reference_image.dispose();
          }
        });
      }
      // 记录CPU命令生成耗时供复核，不将桌面软件光栅化冒充真机帧率。
      final timer = Stopwatch()..start();
      for (var frame = 0; frame < 240; frame++) {
        clock.value = TileQuestStyle.shuffle_duration_ms * frame / 239;
        final recorder = ui.PictureRecorder();
        painter.paint(Canvas(recorder), _size);
        recorder.endRecording().dispose();
      }
      debugPrint(
        '402-card atlas command recording: ${timer.elapsedMicroseconds / 240 / 1000} ms/frame',
      );
    },
  );
}
