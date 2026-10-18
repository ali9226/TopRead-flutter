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

Future<ui.Image> _icon(String name) async {
  final bytes = await rootBundle.load('assets/img/game/tile_$name.png');
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
    final data = await rootBundle.load(
      'assets/img/game/quest_tile_body_v4.png',
    );
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 192,
    );
    try {
      body = (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  });
  tearDownAll(() => body.dispose());

  test(
    'hit shape follows the cream face and thick base without transparent corners',
    () {
      for (final bounds in const [
        Rect.fromLTWH(0, 0, 192, 192),
        Rect.fromLTWH(23, 41, 48, 48),
        Rect.fromLTWH(80, 120, 96, 64),
      ]) {
        Offset at(double x, double y) => Offset(
          bounds.left + bounds.width * x,
          bounds.top + bounds.height * y,
        );
        expect(QuestTileSurface.contains(bounds, bounds.center), isTrue);
        expect(QuestTileSurface.contains(bounds, at(.5, .04)), isTrue);
        expect(QuestTileSurface.contains(bounds, at(.5, .925)), isTrue);
        expect(QuestTileSurface.contains(bounds, bounds.topLeft), isFalse);
        expect(QuestTileSurface.contains(bounds, at(.04, .04)), isFalse);
        expect(QuestTileSurface.contains(bounds, at(.016, .5)), isFalse);
        expect(QuestTileSurface.contains(bounds, at(.5, .975)), isFalse);
        expect(QuestTileSurface.contains(bounds, at(1.02, .5)), isFalse);
      }
      expect(QuestTileSurface.contains(Rect.zero, Offset.zero), isFalse);
    },
  );

  test('front depth stays visible at the smallest board size', () {
    // 参考主界面具有真实圆弧侧壁，必须在48px实体牌中保持可辨的厚度。
    final depth =
        QuestTileSurfaceStyle.body.bottom - QuestTileSurfaceStyle.face.bottom;
    expect(depth, inInclusiveRange(.09, .13));
    expect(depth * 48, greaterThan(2.8));
    final icon = QuestTileSurface.icon_rect(const Rect.fromLTWH(0, 0, 48, 48));
    expect(
      icon.center.dy,
      closeTo(QuestTileSurfaceStyle.face.center.dy * 48, .01),
    );
    expect(
      icon.bottom,
      lessThanOrEqualTo(QuestTileSurfaceStyle.face.bottom * 48),
    );
  });

  test(
    'raised skin preserves transparent corners, cream face and lower depth',
    () async {
      final icon = await _icon('strawberry');
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      QuestTileSurface.paint(
        canvas,
        const Rect.fromLTWH(0, 0, 192, 192),
        icon: icon,
        body: body,
      );
      QuestTileSurface.paint(
        canvas,
        const Rect.fromLTWH(192, 0, 192, 192),
        icon: icon,
        body: body,
        blocked: true,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(384, 192);
      try {
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        expect(_pixel(bytes, 384, 0, 0), [0, 0, 0, 0]);
        expect(_pixel(bytes, 384, 192, 0), [0, 0, 0, 0]);
        final face = _pixel(bytes, 384, 12, 72);
        final depth = _pixel(bytes, 384, 96, 175);
        expect(face[3], 255);
        expect(face[0], greaterThan(240));
        expect(face[1], greaterThan(225));
        expect(depth[3], 255);
        expect(depth[0], lessThan(face[0] - 40));
        expect(depth[1], lessThan(face[1] - 40));
        expect(_pixel(bytes, 384, 288, 175)[0], lessThan(depth[0]));
        final fruit = _pixel(bytes, 384, 96, 96);
        expect(fruit[0], greaterThan(fruit[1] * 1.7));
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
      const source = Rect.fromLTWH(224, 32, 192, 192);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(Colors.blue, BlendMode.src);
      canvas.drawRect(source, Paint()..blendMode = BlendMode.clear);
      QuestTileSurface.paint(canvas, source, icon: icon, body: body);
      final picture = recorder.endRecording();
      final atlas = await picture.toImage(448, 256);
      final output_recorder = ui.PictureRecorder();
      final output_canvas = Canvas(output_recorder);
      final field = QuestParticleField(42);
      QuestMatchParticlePainter(
        image: atlas,
        source_rect: source,
        field: field,
        progress: 0,
      ).paint(output_canvas, const Size.square(96));
      final output_picture = output_recorder.endRecording();
      final output = await output_picture.toImage(96, 96);
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
        final face = _pixel(bytes, 96, 6, 36);
        expect(face[0], greaterThan(240));
        expect(face[1], greaterThan(225));
        expect(_pixel(bytes, 96, 48, 87)[3], 255);
        final fruit = _pixel(bytes, 96, 48, 48);
        expect(fruit[0], greaterThan(fruit[1] * 1.7));
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
      canvas.drawColor(const Color(0xFF18324C), BlendMode.src);
      try {
        for (var index = 0; index < quest_tile_assets.length; index++) {
          final image = await _icon(quest_tile_assets[index]);
          images.add(image);
          QuestTileSurface.paint(
            canvas,
            Rect.fromLTWH(
              16 + index % 8 * 88.0,
              16 + index ~/ 8 * 90.0,
              82,
              82,
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
                  70,
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
            Rect.fromLTWH(500 + index * 60.0, 404, 56, 56),
            icon: images[[4, 0, images.length - 1][index]],
            body: body,
          );
          QuestTileSurface.paint(
            canvas,
            Rect.fromLTWH(500 + index * 60.0, 482, 56, 56),
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
