// ignore_for_file: non_constant_identifier_names
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app/pages/tile_quest/widgets/match_particles.dart';
import 'package:app/pages/tile_quest/widgets/tile_assets.dart';
import 'package:app/pages/tile_quest/widgets/tile_surface.dart';
import 'package:app/pages/tile_quest/widgets/tile_surface_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/config/color_config.dart';

Future<ui.Image> _icon(String name) async {
  final bytes = await rootBundle.load(
    'assets/img/tile_quest/icons/tile_$name.png',
  );
  final codec = await ui.instantiateImageCodec(
    bytes.buffer.asUint8List(),
    targetWidth: 192,
  );
  try {
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
}

List<int> _pixel(ByteData bytes, int width, int x, int y) {
  final offset = (y * width + x) * 4;
  return List.generate(4, (channel) => bytes.getUint8(offset + channel));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ui.Image body;
  setUpAll(() async {
    QuestTileSurface.prepare();
    final data = await rootBundle.load('assets/img/tile_quest/lattice.png');
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: QuestTileSurfaceStyle.cell_edge,
    );
    try {
      body = (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  });
  tearDownAll(() => body.dispose());

  test(
    'fallback reveal interpolates the bright body and preserves opaque pixels',
    () async {
      final samples = <List<int>>[];
      for (final amount in [0.0, .5, 1.0]) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        QuestTileSurface.paint(
          canvas,
          const Rect.fromLTWH(20, 20, 200, 216),
          body: body,
          blocked_amount: amount,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(240, 256);
        try {
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          samples.add(_pixel(bytes, image.width, 120, 110));
        } finally {
          picture.dispose();
          image.dispose();
        }
      }
      for (var channel = 0; channel < 3; channel++) {
        expect(samples[0][channel], greaterThan(samples[1][channel]));
        expect(samples[1][channel], greaterThan(samples[2][channel]));
        expect(
          samples[1][channel],
          closeTo((samples[0][channel] + samples[2][channel]) / 2, 2),
        );
      }
      // 用户 PNG 的抗锯齿/解码可保留254 alpha，滤镜不能令整牌半透明。
      expect(samples[0][3], greaterThanOrEqualTo(250));
      for (final sample in samples.skip(1)) {
        expect(sample[3], closeTo(samples[0][3], 1));
      }
    },
  );

  test(
    'hit shape follows the cream face and thick base without transparent corners',
    () {
      for (final bounds in const [
        Rect.fromLTWH(0, 0, 192, 216),
        Rect.fromLTWH(23, 41, 48, 54),
        Rect.fromLTWH(80, 120, 96, 64),
      ]) {
        Offset at(double x, double y) => Offset(
          bounds.left + bounds.width * x,
          bounds.top + bounds.height * y,
        );
        expect(QuestTileSurface.contains(bounds, bounds.center), isTrue);
        expect(QuestTileSurface.contains(bounds, at(.5, .04)), isTrue);
        expect(QuestTileSurface.contains(bounds, at(.5, .925)), isTrue);
        // 牌体每边超出牌格 1.2%，边缘处仍可点击；牌格外不命中。
        expect(QuestTileSurface.contains(bounds, at(.5, .99)), isTrue);
        expect(QuestTileSurface.contains(bounds, at(.016, .5)), isTrue);
        expect(QuestTileSurface.contains(bounds, bounds.topLeft), isFalse);
        expect(QuestTileSurface.contains(bounds, at(.012, .012)), isFalse);
        expect(QuestTileSurface.contains(bounds, at(1.02, .5)), isFalse);
        expect(QuestTileSurface.contains(bounds, at(.5, 1.02)), isFalse);
      }
      expect(QuestTileSurface.contains(Rect.zero, Offset.zero), isFalse);
    },
  );

  test('thick base and big ceramic body stay visible at board size', () {
    // 用户lattice原图的下部实体约占15%，必须在48px牌中可辨。
    final depth =
        QuestTileSurfaceStyle.body.bottom - QuestTileSurfaceStyle.face.bottom;
    expect(depth, inInclusiveRange(.14, .17));
    expect(depth * 48, greaterThan(2.8));
    expect(
      QuestTileSurfaceStyle.body.width,
      greaterThan(.92),
      reason: 'the ceramic body must nearly fill its board cell',
    );
    final icon = QuestTileSurface.icon_rect(const Rect.fromLTWH(0, 0, 48, 54));
    expect(icon.left, greaterThan(QuestTileSurfaceStyle.body.left * 48));
    expect(
      icon.center.dx,
      closeTo(QuestTileSurfaceStyle.face.center.dx * 48, .01),
    );
    expect(
      icon.center.dy,
      closeTo(QuestTileSurfaceStyle.face.center.dy * 54, 1),
    );
    expect(
      icon.bottom,
      lessThanOrEqualTo(QuestTileSurfaceStyle.face.bottom * 54),
    );
  });

  test('tall tiles preserve square icons and equal pixel shadow padding', () {
    for (final width in [40.0, 54.0, 192.0]) {
      final tile = Rect.fromLTWH(
        23,
        41,
        width,
        width * QuestTileSurfaceStyle.tile_aspect_ratio,
      );
      final icon = QuestTileSurface.icon_rect(tile);
      final cell = QuestTileSurface.cell_rect(tile);
      expect(icon.width, closeTo(icon.height, .000001));
      expect(icon.center.dy, lessThan(tile.center.dy));
      expect(
        cell.width - tile.width,
        closeTo(cell.height - tile.height, .000001),
      );
      expect((cell.center - tile.center).distance, lessThan(.000001));
      expect(
        cell.width / QuestTileSurfaceStyle.cell_edge,
        closeTo(cell.height / QuestTileSurfaceStyle.cell_height, .000001),
      );
    }
  });

  test(
    'raised skin preserves transparent corners, cream face and lower depth',
    () async {
      final icon = await _icon('strawberry');
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      QuestTileSurface.paint(
        canvas,
        const Rect.fromLTWH(0, 0, 192, 216),
        icon: icon,
        body: body,
      );
      QuestTileSurface.paint(
        canvas,
        const Rect.fromLTWH(192, 0, 192, 216),
        icon: icon,
        body: body,
        blocked: true,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(384, 216);
      try {
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        expect(_pixel(bytes, 384, 0, 0), [0, 0, 0, 0]);
        expect(_pixel(bytes, 384, 192, 0), [0, 0, 0, 0]);
        final face = _pixel(bytes, 384, 12, 81);
        final depth = _pixel(bytes, 384, 96, 197);
        expect(face[3], greaterThanOrEqualTo(250));
        expect(face[0], greaterThan(240));
        expect(face[1], greaterThan(225));
        expect(depth[3], greaterThanOrEqualTo(250));
        expect(depth[0], lessThan(face[0] - 40));
        expect(depth[1], lessThan(face[1] - 40));
        expect(_pixel(bytes, 384, 288, 197)[0], lessThan(depth[0]));
        // 原底板最下缘约108/83/82；亮度曲线应提升阴影黑位，
        // 但保留面与实体侧壁的明暗层次以及独立的被遮挡状态。
        final lower_edge = _pixel(bytes, 384, 96, 205);
        expect(lower_edge[0], greaterThanOrEqualTo(130));
        expect(lower_edge[1], greaterThanOrEqualTo(105));
        expect(lower_edge[2], greaterThanOrEqualTo(100));
        expect(lower_edge[0], lessThan(face[0] - 45));
        expect(_pixel(bytes, 384, 288, 205)[0], lessThan(lower_edge[0]));
        final fruit = _pixel(bytes, 384, 96, 108);
        expect(fruit[0], greaterThan(fruit[1] * 1.5));
        final preview = (await image.toByteData(
          format: ui.ImageByteFormat.png,
        ))!;
        File(
          '/tmp/tile_quest_single_tile_preview.png',
        ).writeAsBytesSync(preview.buffer.asUint8List());
      } finally {
        image.dispose();
        picture.dispose();
        icon.dispose();
      }
    },
  );

  test(
    'particle cuts stay within a raised card subrectangle of the shared atlas',
    () async {
      final icon = await _icon('strawberry');
      final cell = Rect.fromLTWH(
        212,
        20,
        QuestTileSurfaceStyle.cell_edge.toDouble(),
        QuestTileSurfaceStyle.cell_height.toDouble(),
      );
      final source = Rect.fromCenter(
        center: cell.center,
        width: QuestTileSurfaceStyle.edge.toDouble(),
        height: QuestTileSurfaceStyle.height.toDouble(),
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(Colors.blue, BlendMode.src);
      canvas.drawRect(cell, Paint()..blendMode = BlendMode.clear);
      QuestTileSurface.paint(canvas, source, icon: icon, body: body);
      final picture = recorder.endRecording();
      final atlas = await picture.toImage(464, 296);
      final output_recorder = ui.PictureRecorder();
      final output_canvas = Canvas(output_recorder);
      final field = QuestParticleField(42);
      QuestMatchParticlePainter(
        image: atlas,
        source_rect: source,
        field: field,
        progress: 0,
      ).paint(output_canvas, const Size(96, 108));
      final output_picture = output_recorder.endRecording();
      final output = await output_picture.toImage(96, 108);
      try {
        for (var index = 0; index < QuestParticleField.count; index++) {
          final start = index * 4;
          expect(field.sources[start], greaterThanOrEqualTo(source.left));
          expect(field.sources[start + 1], greaterThanOrEqualTo(source.top));
          expect(field.sources[start + 2], lessThanOrEqualTo(source.right));
          expect(field.sources[start + 3], lessThanOrEqualTo(source.bottom));
        }
        final bytes = (await output.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        expect(_pixel(bytes, 96, 0, 0), [0, 0, 0, 0]);
        final face = _pixel(bytes, 96, 6, 41);
        expect(face[0], greaterThan(240));
        expect(face[1], greaterThan(225));
        expect(_pixel(bytes, 96, 48, 98)[3], greaterThanOrEqualTo(250));
        var red_pixels = 0;
        for (var offset = 0; offset < bytes.lengthInBytes; offset += 4) {
          if (bytes.getUint8(offset + 3) > 200 &&
              bytes.getUint8(offset) > bytes.getUint8(offset + 1) * 1.5 &&
              bytes.getUint8(offset) > bytes.getUint8(offset + 2) * 1.5) {
            red_pixels++;
          }
        }
        expect(
          red_pixels,
          greaterThan(300),
          reason: 'reassembled tall particles must retain the strawberry icon',
        );
      } finally {
        output.dispose();
        output_picture.dispose();
        atlas.dispose();
        picture.dispose();
        icon.dispose();
      }
    },
  );

  test(
    'export raised tile sheet and layered board for visual inspection',
    () async {
      final images = <ui.Image>[];
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(ColorConstants.test_pages_tile_quest_tile_surface_test_tone, BlendMode.src);
      try {
        for (var index = 0; index < quest_tile_assets.length; index++) {
          final image = await _icon(quest_tile_assets[index]);
          images.add(image);
          QuestTileSurface.paint(
            canvas,
            Rect.fromLTWH(
              16 + index % 8 * 88.0,
              16 + index ~/ 8 * 102.0,
              82,
              82 * QuestTileSurfaceStyle.tile_aspect_ratio,
            ),
            icon: image,
            body: body,
          );
        }
        for (var layer = 0; layer < 4; layer++) {
          for (var row = 0; row < 4 - layer; row++) {
            for (var column = 0; column < 5 - layer; column++) {
              QuestTileSurface.paint(
                canvas,
                Rect.fromLTWH(
                  80 + column * 66.0 + layer * 34,
                  414 + row * 60.0 - layer * 23,
                  70,
                  70 * QuestTileSurfaceStyle.tile_aspect_ratio,
                ),
                icon: images[(layer * 11 + column * 3 + row) % images.length],
                body: body,
                blocked: layer < 3,
              );
            }
          }
        }
        for (var index = 0; index < 3; index++) {
          QuestTileSurface.paint(
            canvas,
            Rect.fromLTWH(
              500 + index * 60.0,
              404,
              56,
              56 * QuestTileSurfaceStyle.tile_aspect_ratio,
            ),
            icon: images[[4, 0, images.length - 1][index]],
            body: body,
          );
          QuestTileSurface.paint(
            canvas,
            Rect.fromLTWH(
              500 + index * 60.0,
              482,
              56,
              56 * QuestTileSurfaceStyle.tile_aspect_ratio,
            ),
            icon: images[[4, 0, images.length - 1][index]],
            body: body,
            blocked: true,
          );
        }
        final picture = recorder.endRecording();
        final image = await picture.toImage(736, 700);
        try {
          final data = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          File(
            '/tmp/tile_quest_raised_tiles_preview.png',
          ).writeAsBytesSync(data.buffer.asUint8List());
        } finally {
          image.dispose();
          picture.dispose();
        }
      } finally {
        for (final image in images) {
          image.dispose();
        }
      }
    },
  );
}
