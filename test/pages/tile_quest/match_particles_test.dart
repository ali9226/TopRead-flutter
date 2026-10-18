// ignore_for_file: non_constant_identifier_names
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/style.dart';
import 'package:app/pages/tile_quest/widgets/match_particles.dart';
import 'package:app/pages/tile_quest/widgets/quest_scene.dart';
import 'package:app/pages/tile_quest/widgets/tile_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'scene_probe.dart';

Future<ui.Image> _asset_image() async {
  final data = await rootBundle.load('assets/img/game/tile_strawberry.png');
  final codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(),
    targetWidth: 192,
  );
  final icon = (await codec.getNextFrame()).image;
  codec.dispose();
  final recorder = ui.PictureRecorder();
  QuestTileSurface.paint(
    Canvas(recorder),
    const Rect.fromLTWH(0, 0, 192, 192),
    icon: icon,
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(192, 192);
  } finally {
    icon.dispose();
    picture.dispose();
  }
}

Future<(int, int, int)> _pixels(ui.Image asset, double progress) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..translate(72, 72);
  QuestMatchParticlePainter(
    image: asset,
    field: QuestParticleField(42),
    progress: progress,
  ).paint(canvas, const Size(64, 64));
  final picture = recorder.endRecording();
  final image = await picture.toImage(208, 208);
  final bytes = (await image.toByteData())!.buffer.asUint8List();
  var visible = 0, outside = 0, red = 0;
  for (var y = 0; y < 208; y++) {
    for (var x = 0; x < 208; x++) {
      final offset = (y * 208 + x) * 4;
      if (bytes[offset + 3] < 12) continue;
      visible++;
      if (x < 72 || x >= 136 || y < 72 || y >= 136) outside++;
      if (bytes[offset] > bytes[offset + 1] * 1.5 &&
          bytes[offset] > bytes[offset + 2] * 1.5) {
        red++;
      }
    }
  }
  image.dispose();
  picture.dispose();
  return (visible, outside, red);
}

class _MatchHarness extends StatefulWidget {
  const _MatchHarness({super.key});
  @override
  State<_MatchHarness> createState() => _MatchHarnessState();
}

class _MatchHarnessState extends State<_MatchHarness> {
  final engine = TileQuestEngine(
    TileQuestState(
      tiles: [
        for (var id = 0; id < 6; id++)
          TileQuestTile(
            id: id,
            type: id < 3 ? 4 : 9,
            layer: 0,
            x: (id % 3).toDouble(),
            y: (id ~/ 3).toDouble(),
            is_removed: id < 2,
          ),
      ],
      tray: [0, 1],
      level: 1,
      seed: 42,
      challenge_id: 'particles',
    ),
  );
  TileQuestActionResult? action;
  void match() => setState(() => action = engine.tap_tile(2));
  @override
  Widget build(BuildContext context) => TileQuestScene(
    state: engine.state,
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
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'image fragments disperse from their original silhouette and fade out',
    () async {
      final asset = await _asset_image();
      final start = await _pixels(asset, 0);
      final first_frame = await _pixels(asset, .005);
      final middle = await _pixels(asset, .38);
      final end = await _pixels(asset, 1);
      expect(start.$1, greaterThan(3000));
      expect(start.$2, 0);
      expect(first_frame.$1, greaterThan(start.$1 * .96));
      expect(middle.$1, greaterThan(300));
      expect(
        middle.$2,
        greaterThan(100),
        reason: 'actual textured fragments leave the tile',
      );
      expect(
        middle.$3,
        greaterThan(80),
        reason: 'retain strawberry red, not generic gold dots',
      );
      expect(end.$1, 0);
      asset.dispose();
    },
  );

  testWidgets('three particles begin after arrival and share the scene clock', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey<_MatchHarnessState>();
    await tester.pumpWidget(MaterialApp(home: _MatchHarness(key: key)));
    await tester.pumpAndSettle();
    key.currentState!.match();
    await tester.pump();
    expect(key.currentState!.engine.state.tray, isEmpty);
    final matched_ids = key.currentState!.action!.matched_ids;
    expect(matched_ids, hasLength(3));
    final first_frames = quest_scene_frames(tester);
    for (final id in matched_ids) {
      expect(first_frames[id], isNotNull);
      expect(first_frames[id]!.dissolve, 0);
    }
    await tester.pump(
      TileQuestStyle.flight_duration +
          Duration(milliseconds: TileQuestStyle.match_hold_ms.toInt()),
    );
    await tester.pump(const Duration(milliseconds: 180));
    final middle_frames = quest_scene_frames(tester);
    for (final id in matched_ids) {
      expect(
        middle_frames[id]!.dissolve,
        closeTo(180 / TileQuestStyle.match_fade_ms, .001),
      );
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 16));
    final final_frames = quest_scene_frames(tester);
    expect(matched_ids.where(final_frames.containsKey), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  test('export textured particle progression for visual inspection', () async {
    final asset = await _asset_image();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(const Color(0xFF233F62), BlendMode.src);
    for (var index = 0; index < 4; index++) {
      canvas.save();
      canvas.translate(index * 160.0 + 48, 64);
      QuestMatchParticlePainter(
        image: asset,
        field: QuestParticleField(42),
        progress: [0.0, .18, .38, .68][index],
      ).paint(canvas, const Size(64, 64));
      canvas.restore();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(640, 192);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File(
      '/tmp/tile_quest_particles_preview.png',
    ).writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
    picture.dispose();
    asset.dispose();
  });
}
