// ignore_for_file: non_constant_identifier_names
import 'dart:async';
import 'dart:ui' as ui;

import 'package:app/pages/tile_quest/widgets/shuffle_textures.dart';
import 'package:app/pages/tile_quest/widgets/tile_batch.dart';
import 'package:app/pages/tile_quest/widgets/tile_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 真实皮肤只能在图集初始化时烘焙；普通、遮挡、静态和批量飞牌须完全同面。
void main() {
  testWidgets(
    'baked raised skins match static and batched cards within one sample',
    (tester) async {
      final textures = QuestShuffleTextures();
      addTearDown(textures.dispose);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                textures.resolve(context, const [0]);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });
      await tester.runAsync(() async {
        final deadline = DateTime.now().add(const Duration(seconds: 5));
        while (!textures.ready) {
          if (DateTime.now().isAfter(deadline)) {
            throw TimeoutException('Raised atlas did not finish');
          }
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        final direct_recorder = ui.PictureRecorder();
        final direct_canvas = Canvas(direct_recorder);
        final sampled_recorder = ui.PictureRecorder();
        final sampled_canvas = Canvas(sampled_recorder);
        final batch = QuestTileBatch(2)..begin();
        for (var column = 0; column < 2; column++) {
          final blocked = column == 1;
          final rect = Rect.fromLTWH(column * 192, 0, 192, 192);
          QuestTileSurface.paint(
            direct_canvas,
            rect,
            icon: textures.image_of(0),
            body: textures.body_image,
            blocked: blocked,
          );
          textures.paint_tile(sampled_canvas, rect, 0, blocked: blocked);
          batch.add(
            textures.source_of(0, blocked: blocked)!,
            rect.shift(const Offset(0, 192)),
          );
        }
        batch.paint(sampled_canvas, textures);
        final direct_picture = direct_recorder.endRecording();
        final sampled_picture = sampled_recorder.endRecording();
        final direct = await direct_picture.toImage(384, 192);
        final sampled = await sampled_picture.toImage(384, 384);
        try {
          final expected = (await direct.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final actual = (await sampled.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          for (var row = 0; row < 2; row++) {
            final offset = row * expected.lengthInBytes;
            var maximum_alpha_error = 0;
            var maximum_color_error = 0.0;
            for (var pixel = 0; pixel < expected.lengthInBytes; pixel += 4) {
              final source_alpha = expected.getUint8(pixel + 3);
              final sample_alpha = actual.getUint8(offset + pixel + 3);
              final alpha_error = (source_alpha - sample_alpha).abs();
              if (alpha_error > maximum_alpha_error) {
                maximum_alpha_error = alpha_error;
              }
              for (var channel = 0; channel < 3; channel++) {
                // 抗锯齿边缘使用预乘颜色比较；极低 alpha 的反预乘舍入不代表色差。
                final source =
                    expected.getUint8(pixel + channel) * source_alpha / 255;
                final sample =
                    actual.getUint8(offset + pixel + channel) *
                    sample_alpha /
                    255;
                final color_error = (source - sample).abs();
                if (color_error > maximum_color_error) {
                  maximum_color_error = color_error;
                }
              }
            }
            expect(
              maximum_alpha_error,
              lessThanOrEqualTo(1),
              reason: 'skin row $row alpha',
            );
            expect(
              maximum_color_error,
              lessThanOrEqualTo(2),
              reason: 'skin row $row premultiplied color',
            );
          }
        } finally {
          direct.dispose();
          sampled.dispose();
          direct_picture.dispose();
          sampled_picture.dispose();
        }
      });
      expect(tester.takeException(), isNull);
    },
  );
}
