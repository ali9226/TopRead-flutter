// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/widgets/board_backing.dart';
import 'package:app/pages/tile_quest/widgets/scene_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _canvas_size = Size(420, 720);
const _lower_red = Color(0xffff0000);
const _lower_blue = Color(0xff0000ff);

/// A copy of rasterized RGBA pixels remains usable after releasing its ui.Image.
class _BoardPixels {
  const _BoardPixels(this.rgba, this.width);
  final ByteData rgba;
  final int width;

  List<int> at(Offset point) {
    final offset = (point.dy.floor() * width + point.dx.floor()) * 4;
    return List.generate(4, (index) => rgba.getUint8(offset + index));
  }
}

/// Real PNG cards are painted over an intentionally high-contrast lower layer.
/// Comparing red/blue versions detects even partial alpha leaks along a seam.
Future<_BoardPixels> _paint_board({
  required List<TileQuestTile> tiles,
  required QuestSceneLayout layout,
  required ui.Image tile_image,
  required Color lower_color,
  bool backing = true,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..drawColor(lower_color, BlendMode.src);
  if (backing) {
    QuestBoardBacking(tiles: tiles, layout: layout).paint(canvas, _canvas_size);
  }
  final source = Rect.fromLTWH(
    0,
    0,
    tile_image.width.toDouble(),
    tile_image.height.toDouble(),
  );
  for (final tile in tiles) {
    canvas.drawImageRect(
      tile_image,
      source,
      layout.board_tile(tile),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }
  final picture = recorder.endRecording();
  final rendered = await picture.toImage(
    _canvas_size.width.toInt(),
    _canvas_size.height.toInt(),
  );
  final data = await rendered.toByteData(format: ui.ImageByteFormat.rawRgba);
  final result = _BoardPixels(data!, rendered.width);
  rendered.dispose();
  picture.dispose();
  return result;
}

TileQuestState _board_state(List<TileQuestTile> tiles) => TileQuestState(
  tiles: tiles,
  level: 2,
  seed: 1,
  challenge_id: 'backing_pixels',
);

/// A 2-by-2 grid exercises both straight seams and the four-corner intersection.
List<TileQuestTile> _square_tiles(double pitch) => [
  for (var index = 0; index < 4; index++)
    TileQuestTile(
      id: index,
      type: 4,
      layer: 1,
      x: (index % 2) * pitch,
      y: (index ~/ 2) * pitch,
    ),
];

void _expect_opaque_samples(
  _BoardPixels red,
  _BoardPixels blue,
  Iterable<Offset> samples,
) {
  for (final point in samples) {
    expect(
      red.at(point),
      blue.at(point),
      reason: 'Lower layer leaks through the upper board at $point',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ui.Image strawberry;

  setUpAll(() async {
    final codec = await ui.instantiateImageCodec(
      File('assets/img/game/tile_strawberry.png').readAsBytesSync(),
    );
    strawberry = (await codec.getNextFrame()).image;
    codec.dispose();
  });
  tearDownAll(() => strawberry.dispose());

  for (final pitch in [1.0, 1.04, 1.06]) {
    testWidgets('two real PNG cards seal their shared seam at pitch $pitch', (
      tester,
    ) async {
      final tiles = _square_tiles(pitch).take(2).toList();
      final layout = QuestSceneLayout(_canvas_size, _board_state(tiles));
      final left = layout.board_tile(tiles[0]);
      final right = layout.board_tile(tiles[1]);
      final samples = [
        for (final fraction in [.02, .08, .5, .92, .98])
          for (var x = left.right - 1; x <= right.left + 1; x += .5)
            Offset(x, left.top + left.height * fraction),
      ];
      await tester.runAsync(() async {
        final red = await _paint_board(
          tiles: tiles,
          layout: layout,
          tile_image: strawberry,
          lower_color: _lower_red,
        );
        final blue = await _paint_board(
          tiles: tiles,
          layout: layout,
          tile_image: strawberry,
          lower_color: _lower_blue,
        );
        _expect_opaque_samples(red, blue, samples);
      });
    });

    testWidgets(
      'real PNG corner junction seals and removal reveals pitch $pitch',
      (tester) async {
        final tiles = _square_tiles(pitch);
        final layout = QuestSceneLayout(_canvas_size, _board_state(tiles));
        final upper_left = layout.board_tile(tiles[0]);
        final lower_right = layout.board_tile(tiles[3]);
        final junction = Rect.fromLTRB(
          upper_left.right - layout.unit * .06,
          upper_left.bottom - layout.unit * .06,
          lower_right.left + layout.unit * .06,
          lower_right.top + layout.unit * .06,
        );
        final samples = [
          for (var y = junction.top; y <= junction.bottom; y += 1)
            for (var x = junction.left; x <= junction.right; x += 1)
              Offset(x, y),
        ];
        await tester.runAsync(() async {
          final red = await _paint_board(
            tiles: tiles,
            layout: layout,
            tile_image: strawberry,
            lower_color: _lower_red,
          );
          final blue = await _paint_board(
            tiles: tiles,
            layout: layout,
            tile_image: strawberry,
            lower_color: _lower_blue,
          );
          _expect_opaque_samples(red, blue, samples);

          // Transparent external corners remain transparent with a visible lower
          // layer, rather than becoming a solid rectangle around the whole board.
          // Sample the actual corner pixel. At the shared fixed tile scale a
          // point 1px inward can already lie on the smaller rounded arc.
          final outer_corner = upper_left.topLeft + const Offset(.01, .01);
          expect(red.at(outer_corner), [255, 0, 0, 255]);
          expect(blue.at(outer_corner), [0, 0, 255, 255]);

          final survivors = tiles.skip(1).toList();
          final removed_red = await _paint_board(
            tiles: survivors,
            layout: layout,
            tile_image: strawberry,
            lower_color: _lower_red,
          );
          final removed_blue = await _paint_board(
            tiles: survivors,
            layout: layout,
            tile_image: strawberry,
            lower_color: _lower_blue,
          );
          expect(removed_red.at(upper_left.center), [255, 0, 0, 255]);
          expect(removed_blue.at(upper_left.center), [0, 0, 255, 255]);

          // The actual PNG has a transparent junction without backing, making
          // this a regression check of concealed lower information.
          final unsealed_red = await _paint_board(
            tiles: tiles,
            layout: layout,
            tile_image: strawberry,
            lower_color: _lower_red,
            backing: false,
          );
          final unsealed_blue = await _paint_board(
            tiles: tiles,
            layout: layout,
            tile_image: strawberry,
            lower_color: _lower_blue,
            backing: false,
          );
          expect(
            samples.any(
              (point) =>
                  !_same_pixel(unsealed_red.at(point), unsealed_blue.at(point)),
            ),
            isTrue,
            reason:
                'The tested corner region must contain transparent PNG pixels',
          );
        });
      },
    );
  }

  testWidgets(
    'backing keeps exact card hit rectangles and geometric blockers',
    (tester) async {
      final tiles = _square_tiles(1.04).take(2).toList();
      final layout = QuestSceneLayout(_canvas_size, _board_state(tiles));
      final lower = TileQuestTile(id: 10, type: 4, layer: 0, x: .5, y: 0);
      final geometry_before = TileQuestGeometry([lower, ...tiles]);
      int? tapped;
      await tester.binding.setSurfaceSize(_canvas_size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: QuestBoardBacking(tiles: tiles, layout: layout),
                  ),
                ),
              ),
              for (final tile in tiles)
                Positioned.fromRect(
                  rect: layout.board_tile(tile),
                  child: GestureDetector(
                    key: ValueKey('backing_hit_${tile.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => tapped = tile.id,
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          ),
        ),
      );
      for (final tile in tiles) {
        final finder = find.byKey(ValueKey('backing_hit_${tile.id}'));
        expect(tester.getRect(finder), layout.board_tile(tile));
        await tester.tap(finder);
        expect(tapped, tile.id);
      }
      tapped = null;
      final left = layout.board_tile(tiles.first);
      final right = layout.board_tile(tiles.last);
      await tester.tapAt(Offset((left.right + right.left) / 2, left.center.dy));
      expect(
        tapped,
        isNull,
        reason: 'A sealed legacy gap is not a new hit target',
      );
      final geometry_after = TileQuestGeometry([lower, ...tiles]);
      expect(geometry_after.blockers, geometry_before.blockers);
      expect(geometry_after.blockers[lower.id], {0, 1});
    },
  );
}

bool _same_pixel(List<int> first, List<int> second) {
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
