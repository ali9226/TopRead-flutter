// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:async';
import 'dart:ui' as ui;

import 'package:app/pages/tile_quest/widgets/shuffle_textures.dart';
import 'package:app/pages/tile_quest/widgets/tile_batch.dart';
import 'package:app/pages/tile_quest/widgets/tile_surface.dart';
import 'package:app/pages/tile_quest/widgets/tile_surface_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 真实皮肤只能在图集初始化时烘焙；静态、批量、普通与遮挡牌必须完全同面。
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
        final tile = Rect.fromLTWH(
          96,
          84,
          QuestTileSurfaceStyle.edge.toDouble(),
          QuestTileSurfaceStyle.height.toDouble(),
        );
        for (final blocked in const [false, true]) {
          final direct = await _paint_direct(textures, tile, blocked);
          final static_card = await _paint_static(textures, tile, blocked);
          final batched = await _paint_batched(textures, tile, blocked);
          try {
            final expected = (await direct.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            for (final (label, image) in [
              ('static', static_card),
              ('batch', batched),
            ]) {
              final actual = (await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!;
              var maximum_alpha_error = 0;
              var maximum_opaque_alpha_error = 0;
              var maximum_color_error = 0.0;
              var edge_pixels = 0;
              var soft_edge_pixels = 0;
              for (var pixel = 0; pixel < expected.lengthInBytes; pixel += 4) {
                final source_alpha = expected.getUint8(pixel + 3);
                final sample_alpha = actual.getUint8(pixel + 3);
                final alpha_error = (source_alpha - sample_alpha).abs();
                if (alpha_error > maximum_alpha_error) {
                  maximum_alpha_error = alpha_error;
                }
                if (source_alpha > 250 && sample_alpha > 250) {
                  if (alpha_error > maximum_opaque_alpha_error) {
                    maximum_opaque_alpha_error = alpha_error;
                  }
                } else if (alpha_error > 8) {
                  soft_edge_pixels++;
                }
                for (var channel = 0; channel < 3; channel++) {
                  // 抗锯齿边缘使用预乘颜色比较；极低 alpha 的反预乘舍入不代表色差。
                  final source =
                      expected.getUint8(pixel + channel) * source_alpha / 255;
                  final sample =
                      actual.getUint8(pixel + channel) * sample_alpha / 255;
                  final color_error = (source - sample).abs();
                  if (color_error > maximum_color_error) {
                    maximum_color_error = color_error;
                  }
                  if (color_error > 2) edge_pixels++;
                }
              }
              // 实心像素必须完全一致；模糊投影边缘允许极小的栅格化差异。
              expect(
                maximum_opaque_alpha_error,
                lessThanOrEqualTo(1),
                reason: '$label opaque skin alpha (blocked: $blocked)',
              );
              expect(
                maximum_alpha_error,
                lessThanOrEqualTo(72),
                reason: '$label soft edge skin alpha (blocked: $blocked)',
              );
              expect(
                soft_edge_pixels,
                lessThan(expected.lengthInBytes ~/ 16),
                reason: '$label soft edge pixel count (blocked: $blocked)',
              );
              // 图集采样与直接绘制在图案抗锯齿边缘可能出现孤立像素差：
              // 允许极少数像素（<64 个通道）存在 ≤32 的采样误差，但主体必须一致。
              expect(
                maximum_color_error,
                lessThanOrEqualTo(32),
                reason: '$label skin premultiplied color (blocked: $blocked)',
              );
              expect(
                edge_pixels,
                lessThan(64),
                reason:
                    '$label isolated sampler edge pixels (blocked: $blocked)',
              );
            }
          } finally {
            direct.dispose();
            static_card.dispose();
            batched.dispose();
          }
        }
      });
      await tester.runAsync(() async {
        for (final width in [192.0, 54.0, 40.0]) {
          final tile = Rect.fromCenter(
            center: const Offset(192, 192),
            width: width,
            height: width * QuestTileSurfaceStyle.tile_aspect_ratio,
          );
          for (final rotation in [-.18, 0.0, .21]) {
            for (final blocked in [false, true]) {
              final reference = await _paint_static(
                textures,
                tile,
                blocked,
                rotation: rotation,
              );
              final batched = await _paint_batched(
                textures,
                tile,
                blocked,
                rotation: rotation,
              );
              try {
                final expected = (await reference.toByteData(
                  format: ui.ImageByteFormat.rawRgba,
                ))!;
                final actual = (await batched.toByteData(
                  format: ui.ImageByteFormat.rawRgba,
                ))!;
                var total_error = 0;
                var occupied_pixels = 0;
                for (
                  var pixel = 0;
                  pixel < expected.lengthInBytes;
                  pixel += 4
                ) {
                  if (expected.getUint8(pixel + 3) > 200) occupied_pixels++;
                  for (var channel = 0; channel < 4; channel++) {
                    total_error +=
                        (expected.getUint8(pixel + channel) -
                                actual.getUint8(pixel + channel))
                            .abs();
                  }
                }
                expect(occupied_pixels, greaterThan(width * width * .6));
                expect(
                  total_error / expected.lengthInBytes,
                  lessThan(.2),
                  reason:
                      'rectangular atlas transform must match the full skin at width $width, rotation $rotation, blocked $blocked',
                );
              } finally {
                reference.dispose();
                batched.dispose();
              }
            }
          }
        }
      });
      expect(tester.takeException(), isNull);
    },
  );
}

Future<ui.Image> _render(void Function(Canvas canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(384, 384);
  } finally {
    picture.dispose();
  }
}

Future<ui.Image> _paint_direct(
  QuestShuffleTextures textures,
  Rect tile,
  bool blocked, {
  double rotation = 0,
}) => _render((canvas) {
  canvas.translate(tile.center.dx, tile.center.dy);
  canvas.rotate(rotation);
  canvas.translate(-tile.center.dx, -tile.center.dy);
  QuestTileSurface.paint(
    canvas,
    tile,
    icon: textures.image_of(0),
    body: textures.body_image,
    blocked: blocked,
    icon_shadow: true,
  );
});

Future<ui.Image> _paint_static(
  QuestShuffleTextures textures,
  Rect tile,
  bool blocked, {
  double rotation = 0,
}) => _render((canvas) {
  canvas.translate(tile.center.dx, tile.center.dy);
  canvas.rotate(rotation);
  canvas.translate(-tile.center.dx, -tile.center.dy);
  textures.paint_tile(canvas, tile, 0, blocked: blocked);
});

Future<ui.Image> _paint_batched(
  QuestShuffleTextures textures,
  Rect tile,
  bool blocked, {
  double rotation = 0,
}) => _render((canvas) {
  final batch = QuestTileBatch(1)
    ..begin()
    ..add(textures.source_of(0, blocked: blocked)!, tile, rotation: rotation);
  batch.paint(canvas, textures);
});
