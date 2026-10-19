// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/style.dart';
import 'package:app/pages/tile_quest/widgets/board_canvas.dart';
import 'package:app/pages/tile_quest/widgets/motion_canvas.dart';
import 'package:app/pages/tile_quest/widgets/quest_scene.dart';
import 'package:app/pages/tile_quest/widgets/tile_card.dart';
import 'package:app/pages/tile_quest/widgets/tile_skin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _export = bool.fromEnvironment('TILE_QUEST_EXPORT_REVEAL');
const _size = Size(390, 844);
const _directory = 'build/tile_quest';

/// The lower card's upper-left face remains visible before and after the tap.
/// Its sampled pixels therefore measure actual shading, never changing cover.
TileQuestState _fixture() {
  const tiles = [
    TileQuestTile(id: 0, type: 0, layer: 0, x: 0, y: 0),
    TileQuestTile(id: 1, type: 0, layer: 1, x: .75, y: .75),
    TileQuestTile(id: 2, type: 0, layer: 0, x: 2, y: 0),
    TileQuestTile(id: 3, type: 1, layer: 0, x: 0, y: 3),
    TileQuestTile(id: 4, type: 1, layer: 0, x: 1, y: 3),
    TileQuestTile(id: 5, type: 1, layer: 0, x: 2, y: 3),
  ];
  return TileQuestState(
    tiles: TileQuestGeometry(tiles).refresh(tiles),
    level: 2,
    difficulty: 1,
    unlocked_level: 2,
    seed: 1,
    challenge_id: 'real-reveal-pixels',
  );
}

class _Harness extends StatefulWidget {
  const _Harness({super.key});
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final engine = TileQuestEngine(_fixture());
  final actions = <TileQuestActionResult>[];
  void tap(int id) {
    final result = engine.tap_tile(id);
    expect(result.accepted, isTrue, reason: result.reason);
    setState(() => actions.add(result));
  }

  @override
  Widget build(BuildContext context) => TileQuestScene(
    state: engine.state,
    action: actions.lastOrNull,
    recent_actions: actions,
    animate_entry: false,
    sound_enabled: false,
    busy: false,
    on_back: () {},
    on_restart: () {},
    on_sound: () {},
    on_tile: tap,
    on_reserve: (_) {},
    on_tool: (_) {},
  );
}

QuestBoardPainter _board(WidgetTester tester) =>
    tester.widget<QuestBoardCanvas>(find.byType(QuestBoardCanvas)).painter;

Future<GlobalKey<_HarnessState>> _mount(
  WidgetTester tester,
  GlobalKey boundary,
) async {
  await tester.binding.setSurfaceSize(_size);
  final key = GlobalKey<_HarnessState>();
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark, fontFamily: 'Roboto'),
      home: RepaintBoundary(
        key: boundary,
        child: Scaffold(
          backgroundColor: const Color(0xff233a56),
          body: _Harness(key: key),
        ),
      ),
    ),
  );
  await tester.runAsync(() async {
    await Future.wait([
      precacheImage(QuestTileSkin.provider, boundary.currentContext!),
      for (final type in [0, 1])
        precacheImage(
          ResizeImage(
            AssetImage(quest_tile_asset_path(type)),
            width: TileQuestStyle.tile_cache_width,
          ),
          boundary.currentContext!,
        ),
    ]);
  });
  await tester.pumpAndSettle();
  expect(_board(tester).textures.ready, isTrue);
  expect(tester.takeException(), isNull);
  return key;
}

Rect _face_sample(Rect rect) => Rect.fromLTWH(
  rect.left + rect.width * .18,
  rect.top + rect.height * .22,
  rect.width * .10,
  rect.height * .12,
);

/// Reads genuine Flutter raster output; no postprocessing changes the PNGs.
Future<double> _capture(
  WidgetTester tester,
  GlobalKey boundary,
  String name,
  Rect sample,
) async {
  return (await tester.runAsync(() async {
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    const scale = 2.0;
    final image = await render.toImage(pixelRatio: scale);
    try {
      if (_export) {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '$_directory/reveal_$name.png',
        ).writeAsBytesSync(png!.buffer.asUint8List());
      }
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final pixels = data!.buffer.asUint8List();
      var luminance = 0.0;
      var count = 0;
      for (
        var y = (sample.top * scale).ceil();
        y < (sample.bottom * scale).floor();
        y++
      ) {
        for (
          var x = (sample.left * scale).ceil();
          x < (sample.right * scale).floor();
          x++
        ) {
          final offset = (y * image.width + x) * 4;
          luminance +=
              pixels[offset] * .2126 +
              pixels[offset + 1] * .7152 +
              pixels[offset + 2] * .0722;
          count++;
        }
      }
      expect(count, greaterThan(0));
      return luminance / count;
    } finally {
      image.dispose();
    }
  }))!;
}

Future<void> _load_fonts() async {
  if (!_export) return;
  final font_path =
      '${Directory.current.path}/.fvm/flutter_sdk/bin/cache/artifacts/material_fonts';
  for (final font in [
    ('Roboto', 'Roboto-Regular.ttf'),
    ('MaterialIcons', 'MaterialIcons-Regular.otf'),
  ]) {
    final file = File('$font_path/${font.$2}');
    if (!file.existsSync()) continue;
    await (FontLoader(font.$1)
          ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync()))))
        .load();
  }
}

void main() {
  setUpAll(() async {
    if (_export) Directory(_directory).createSync(recursive: true);
    await _load_fonts();
  });

  testWidgets('real lower-card pixels brighten progressively across 220ms', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final boundary = GlobalKey();
    final host = await _mount(tester, boundary);
    final lower = _board(tester).frames.singleWhere((frame) => frame.id == 0);
    final sample = _face_sample(lower.rect);
    final values = <String, double>{
      'blocked': await _capture(tester, boundary, 'blocked', sample),
    };
    host.currentState!.tap(1);
    await tester.pump();
    values['0ms'] = await _capture(tester, boundary, '0ms', sample);
    var elapsed = 0;
    for (final now in [50, 110, 220]) {
      await tester.pump(Duration(milliseconds: now - elapsed));
      elapsed = now;
      values['${now}ms'] = await _capture(tester, boundary, '${now}ms', sample);
    }
    expect(values['0ms'], closeTo(values['blocked']!, 1));
    expect(values['50ms']!, greaterThan(values['0ms']! + 1));
    expect(values['110ms']!, greaterThan(values['50ms']! + 1));
    expect(values['220ms']!, greaterThan(values['110ms']! + 1));
    final current = _board(tester);
    final frame = current.frames.singleWhere((frame) => frame.id == 0);
    expect(frame.blocked, isFalse);
    expect(current.reveal_amount_of(frame), 0);
    if (_export) {
      File(
        '$_directory/reveal_luminance.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(values));
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a newly revealed card keeps its rendered shade when flown early',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final boundary = GlobalKey();
      final host = await _mount(tester, boundary);
      host.currentState!.tap(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 110));
      final board = _board(tester);
      final lower = board.frames.singleWhere((frame) => frame.id == 0);
      final sample = _face_sample(lower.rect);
      final before = await _capture(
        tester,
        boundary,
        'before_early_flight',
        sample,
      );
      final amount = board.reveal_amount_of(lower);
      expect(amount, inExclusiveRange(0, 1));
      host.currentState!.tap(0);
      await tester.pump();
      final motion = tester.widget<QuestMotionCanvas>(
        find.byType(QuestMotionCanvas),
      );
      final flying = motion.painter.frames.singleWhere(
        (frame) => frame.id == 0,
      );
      expect(flying.blocked_amount, closeTo(amount, .000001));
      expect(
        (flying.rect.center - lower.rect.center).distance,
        lessThan(.000001),
      );
      expect(flying.rect.width, closeTo(lower.rect.width, .000001));
      expect(flying.rect.height, closeTo(lower.rect.height, .000001));
      final after = await _capture(
        tester,
        boundary,
        'early_flight_0ms',
        sample,
      );
      expect(after, closeTo(before, 1));
      await tester.pump(const Duration(milliseconds: 50));
      final next = motion.painter.frames.singleWhere((frame) => frame.id == 0);
      final later = await _capture(
        tester,
        boundary,
        'early_flight_50ms',
        _face_sample(next.rect),
      );
      expect(later, greaterThan(after));
      if (_export) {
        File('$_directory/reveal_flight_luminance.json').writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert({
            'before_flight': before,
            'flight_0ms': after,
            'flight_50ms': later,
            'initial_blocked_amount': amount,
          }),
        );
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
