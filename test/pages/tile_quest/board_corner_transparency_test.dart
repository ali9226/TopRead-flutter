// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/widgets/board_canvas.dart';
import 'package:app/pages/tile_quest/widgets/board_reveal.dart';
import 'package:app/pages/tile_quest/widgets/scene_layout.dart';
import 'package:app/pages/tile_quest/widgets/shuffle_textures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Pixels {
  const _Pixels(this.bytes, this.width);
  final ByteData bytes;
  final int width;
  List<int> at(Offset position) {
    final start = (position.dy.floor() * width + position.dx.floor()) * 4;
    return [
      for (var channel = 0; channel < 4; channel++)
        bytes.getUint8(start + channel),
    ];
  }
}

TileQuestState _state(List<TileQuestTile> tiles) => TileQuestState(
  tiles: tiles,
  level: 2,
  difficulty: 4,
  seed: 1,
  challenge_id: 'real-corner-pixels',
);

List<TileQuestTile> _square(double pitch, {Set<int> removed = const {}}) => [
  for (var id = 0; id < 4; id++)
    TileQuestTile(
      id: id,
      type: 2,
      layer: 1,
      x: (id % 2) * pitch,
      y: (id ~/ 2) * pitch,
      is_removed: removed.contains(id),
    ),
];

Future<_Pixels> _paint({
  required List<TileQuestTile> upper,
  required QuestSceneLayout layout,
  required QuestShuffleTextures textures,
  required Color background,
  int lower_type = 0,
  bool lower_removed = false,
  int? pressed,
  QuestBoardReveal? reveal,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..drawColor(background, BlendMode.src);
  final notifier = ValueNotifier<int?>(pressed);
  final painter = QuestBoardPainter(
    tiles: [
      TileQuestTile(
        id: 100,
        type: lower_type,
        layer: 0,
        x: .5,
        y: .5,
        is_removed: lower_removed,
      ),
      ...upper,
    ],
    layout: layout,
    textures: textures,
    pressed: notifier,
    enabled: true,
    on_tile: (_) {},
    reveal: reveal,
  );
  painter.paint(canvas, layout.size);
  notifier.dispose();
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    layout.size.width.toInt(),
    layout.size.height.toInt(),
  );
  try {
    return _Pixels(
      (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!,
      image.width,
    );
  } finally {
    image.dispose();
    picture.dispose();
  }
}

Future<QuestShuffleTextures> _load(WidgetTester tester) async {
  final textures = QuestShuffleTextures();
  addTearDown(textures.dispose);
  await tester.runAsync(() async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            textures.resolve(context, const [0, 1, 2]);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!textures.ready) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('Actual tile atlas did not finish');
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  });
  return textures;
}

void main() {
  for (final size in const [Size(390, 844), Size(844, 390)]) {
    testWidgets('last layer keeps real PNG corner transparency at $size', (
      tester,
    ) async {
      final textures = await _load(tester);
      await tester.runAsync(() async {
        final upper = _square(1);
        final layout = QuestSceneLayout(size, _state(upper));
        final first = layout.board_tile(upper[0]);
        final fourth = layout.board_tile(upper[3]);
        final junction = Offset(first.right, first.bottom);
        final samples = [
          for (final y in [-.025, 0.0, .025])
            for (final x in [-.025, 0.0, .025])
              junction + Offset(first.width * x, first.height * y),
        ];
        final red = await _paint(
          upper: upper,
          layout: layout,
          textures: textures,
          background: Colors.red,
          lower_removed: true,
        );
        final blue = await _paint(
          upper: upper,
          layout: layout,
          textures: textures,
          background: Colors.blue,
          lower_removed: true,
        );
        // 四张最后一层牌的共享圆角确实透出背景，不能凭空补一块棕色挡板。
        expect(
          samples.any((point) => red.at(point)[0] - blue.at(point)[0] > 100),
          isTrue,
        );
        expect(fourth.topLeft, junction);
        // 紧贴的直边中段由真实牌体覆盖，透明只来自素材的圆角轮廓。
        final straight = Offset(first.right - .5, first.center.dy);
        for (var channel = 0; channel < 4; channel++) {
          expect(
            red.at(straight)[channel],
            closeTo(blue.at(straight)[channel], 3),
          );
        }
      });
    });

    testWidgets(
      'genuine lower cards show naturally through PNG corners at $size',
      (tester) async {
        final textures = await _load(tester);
        await tester.runAsync(() async {
          final upper = _square(1);
          final layout = QuestSceneLayout(size, _state(upper));
          final first = layout.board_tile(upper[0]);
          final junction = Offset(first.right, first.bottom);
          final with_lower = await _paint(
            upper: upper,
            layout: layout,
            textures: textures,
            background: Colors.green,
          );
          final no_lower = await _paint(
            upper: upper,
            layout: layout,
            textures: textures,
            background: Colors.green,
            lower_removed: true,
          );
          expect(with_lower.at(junction), isNot(no_lower.at(junction)));
          final different_lower = await _paint(
            upper: upper,
            layout: layout,
            textures: textures,
            background: Colors.green,
            lower_type: 1,
          );
          expect(with_lower.at(junction), isNot(different_lower.at(junction)));
          // 牌被移除后，共享圆角继续显示背景；没有独立残留的底板。
          final removed = _square(1, removed: {0});
          final cleared = await _paint(
            upper: removed,
            layout: layout,
            textures: textures,
            background: Colors.green,
            lower_removed: true,
          );
          expect(cleared.at(first.center), [76, 175, 80, 255]);
        });
      },
    );
  }
}
