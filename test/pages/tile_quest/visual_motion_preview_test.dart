// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/style.dart';
import 'package:app/pages/tile_quest/widgets/atmosphere.dart';
import 'package:app/pages/tile_quest/widgets/quest_scene.dart';
import 'package:app/pages/tile_quest/widgets/scene_layout.dart';
import 'package:app/pages/tile_quest/widgets/tile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'shuffle_probe.dart';
import 'scene_probe.dart';

const _export_motion = bool.fromEnvironment('TILE_QUEST_EXPORT_MOTION');
const _size = Size(390, 844);
const _frame_step_ms = 70;
const _preview_directory = '/tmp/tile_quest_shuffle_preview';

/// 显式选择导出时才运行；普通全量回归不会重复编码三十余张 PNG。
class _VisualHarness extends StatefulWidget {
  const _VisualHarness({super.key, required this.engine});
  final TileQuestEngine engine;

  @override
  State<_VisualHarness> createState() => _VisualHarnessState();
}

class _VisualHarnessState extends State<_VisualHarness> {
  final List<TileQuestActionResult> actions = <TileQuestActionResult>[];

  void shuffle() {
    final result = widget.engine.shuffle(seed: 9127);
    expect(result.accepted, isTrue, reason: result.reason);
    setState(() => actions.add(result));
  }

  @override
  Widget build(BuildContext context) => TileQuestScene(
    state: widget.engine.state,
    action: actions.lastOrNull,
    recent_actions: actions,
    animate_entry: false,
    sound_enabled: false,
    busy: false,
    can_undo: widget.engine.can_undo,
    on_back: () {},
    on_restart: () {},
    on_sound: () {},
    on_tile: (_) {},
    on_reserve: (_) {},
    on_tool: (_) {},
  );
}

Future<void> _load_fonts() async {
  if (!_export_motion) return;
  final fonts = Directory(
    '${Directory.current.path}/.fvm/flutter_sdk/bin/cache/artifacts/material_fonts',
  );
  if (!fonts.existsSync()) return;
  for (final font in <(String, String)>[
    ('Roboto', 'Roboto-Regular.ttf'),
    ('MaterialIcons', 'MaterialIcons-Regular.otf'),
  ]) {
    final loader = FontLoader(font.$1)
      ..addFont(
        Future<ByteData>.value(
          ByteData.sublistView(
            File('${fonts.path}/${font.$2}').readAsBytesSync(),
          ),
        ),
      );
    await loader.load();
  }
}

Future<GlobalKey<_VisualHarnessState>> _mount(
  WidgetTester tester,
  GlobalKey boundary,
  TileQuestEngine engine,
) async {
  final host = GlobalKey<_VisualHarnessState>();
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(fontFamily: 'Roboto'),
      home: RepaintBoundary(
        key: boundary,
        child: Scaffold(
          body: Stack(
            children: <Widget>[
              const Positioned.fill(child: QuestAtmosphere(is_dark: true)),
              Positioned.fill(
                child: _VisualHarness(key: host, engine: engine),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.runAsync(() async {
    await Future.wait<void>(<Future<void>>[
      for (final type in engine.state.tiles.map((tile) => tile.type).toSet())
        precacheImage(
          ResizeImage.resizeIfNeeded(
            192,
            null,
            AssetImage('assets/img/game/tile_${quest_tile_assets[type]}.png'),
          ),
          boundary.currentContext!,
        ),
    ]);
  });
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return host;
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundary,
  String path,
) async {
  await tester.runAsync(() async {
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Finder _flight(int id) => find.byKey(ValueKey('tile_quest_flight_$id'));

void _same_rect(Rect actual, Rect expected, {String? reason}) {
  expect(actual.left, closeTo(expected.left, .000001), reason: reason);
  expect(actual.top, closeTo(expected.top, .000001), reason: reason);
  expect(actual.width, closeTo(expected.width, .000001), reason: reason);
  expect(actual.height, closeTo(expected.height, .000001), reason: reason);
}

/// 测量真实卡片RenderBox的屏幕坐标变换，不能只检查外层Positioned尺寸。
/// 返回每张牌实际存在的图案及其透明度，用于验证同尺寸叠层换面。
Map<int, List<(int, double)>> _full_size_cards(
  WidgetTester tester,
  Map<int, Rect> original,
) {
  final result = <int, List<(int, double)>>{};
  for (final frame in quest_scene_frames(tester).values) {
    final expected = original[frame.id]!;
    expect(frame.rect.width, closeTo(expected.width, .000001));
    expect(frame.rect.height, closeTo(expected.height, .000001));
    result[frame.id] = [
      if (frame.previous_type != null &&
          frame.previous_type != frame.type &&
          frame.face_progress < 1)
        (frame.previous_type!, 1),
      if (frame.previous_type == null ||
          frame.previous_type == frame.type ||
          frame.face_progress >= 1)
        (frame.type, 1)
      else if (frame.face_progress > 0)
        (frame.type, frame.face_progress),
    ];
  }
  expect(result.keys.toSet(), original.keys.toSet());
  return result;
}

Map<int, Rect> _positioned_cards(WidgetTester tester) => {
  for (final frame in quest_scene_frames(tester).values) frame.id: frame.rect,
};

void _record_blended_faces(
  Map<int, List<(int, double)>> current,
  TileQuestActionResult result,
  Map<int, Set<int>> observed,
  Set<int> blended,
) {
  for (final entry in current.entries) {
    if (!result.moved_ids.contains(entry.key)) continue;
    final faces = entry.value;
    final old_type = result.before.tile_by_id(entry.key).type;
    final new_type = result.after.tile_by_id(entry.key).type;
    for (final face in faces) {
      if (face.$2 > .001) (observed[entry.key] ??= <int>{}).add(face.$1);
    }
    if (old_type == new_type) continue;
    final fading = faces.where(
      (face) => face.$1 == new_type && face.$2 > .001 && face.$2 < .999,
    );
    if (fading.isNotEmpty) {
      expect(
        faces.any((face) => face.$1 == old_type && face.$2 == 1),
        isTrue,
        reason:
            'the old full-size face must remain opaque beneath its replacement',
      );
      blended.add(entry.key);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_load_fonts);

  testWidgets(
    'actual expert shuffle keeps every rendered axis full size while faces blend and held cards stay fixed',
    (tester) async {
      await tester.binding.setSurfaceSize(_size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final engine = TileQuestEngine(
        TileQuestGenerator.generate(level: 2, seed: 730),
      );
      final reserved_type = engine.state
          .tile_by_id(engine.state.certified_solution.first)
          .type;
      for (final id in engine.state.certified_solution.take(2).toList()) {
        expect(engine.tap_tile(id).accepted, isTrue);
      }
      expect(engine.remove().accepted, isTrue);
      final tray_type = engine.state.clickable_tiles
          .firstWhere((tile) => tile.type != reserved_type)
          .type;
      for (var index = 0; index < 2; index++) {
        final id = engine.state.clickable_tiles
            .firstWhere((tile) => tile.type == tray_type)
            .id;
        expect(engine.tap_tile(id).accepted, isTrue);
      }
      expect(engine.state.reserve, hasLength(2));
      expect(engine.state.tray, hasLength(2));
      final boundary = GlobalKey();
      final host = await _mount(tester, boundary, engine);
      final original = _positioned_cards(tester);
      _full_size_cards(tester, original);
      final held = {...engine.state.tray, ...engine.state.reserve};
      host.currentState!.shuffle();
      final result = host.currentState!.actions.single;
      final moving = result.before.tiles
          .where((tile) => !tile.is_removed)
          .map((tile) => tile.id)
          .toSet();
      expect(result.moved_ids.toSet(), moving);
      expect(
        moving.any((id) => result.before.tile_by_id(id).is_blocked),
        isTrue,
      );
      final observed = <int, Set<int>>{};
      final blended = <int>{};
      final layout = QuestSceneLayout(_size, result.before);
      await tester.pump();
      var elapsed = 0;
      for (var frame = 0; frame <= 60; frame++) {
        final now = (TileQuestStyle.shuffle_duration_ms * frame / 60).round();
        if (now > elapsed) {
          await tester.pump(Duration(milliseconds: now - elapsed));
        }
        elapsed = now;
        final positions = _positioned_cards(tester);
        expect(positions.keys.toSet(), original.keys.toSet());
        for (final id in held) {
          _same_rect(positions[id]!, original[id]!);
        }
        final faces = _full_size_cards(tester, original);
        _record_blended_faces(faces, result, observed, blended);
        final progress = frame / 60;
        if (progress >= TileQuestStyle.shuffle_gather_fraction &&
            progress <= TileQuestStyle.shuffle_scatter_fraction) {
          double? radius;
          for (final id in moving) {
            final current =
                (positions[id]!.center - layout.board.center).distance;
            radius ??= current;
            expect(current, closeTo(radius, .000001));
          }
        }
      }
      expect(
        blended,
        isNotEmpty,
        reason:
            'picture replacements must visibly blend without narrowing the card',
      );
      final final_positions = _positioned_cards(tester);
      for (final id in moving) {
        expect(observed[id], contains(result.before.tile_by_id(id).type));
        expect(observed[id], contains(result.after.tile_by_id(id).type));
        _same_rect(final_positions[id]!, original[id]!);
        expect(_flight(id), findsNothing);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'export actual default-level shuffle frames and the new tutorial palette',
    (tester) async {
      await tester.binding.setSurfaceSize(_size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Directory(_preview_directory).createSync(recursive: true);
      final engine = TileQuestEngine(
        TileQuestGenerator.generate(level: 2, seed: 730),
      );
      expect(engine.state.total_count, 402);
      expect(engine.state.difficulty, 8);
      // 两张真实入槽牌留作参照；其余400张棋盘牌全部参与洗牌。
      for (final id in engine.state.certified_solution.take(2).toList()) {
        expect(engine.tap_tile(id).accepted, isTrue);
      }
      expect(engine.state.tray, hasLength(2));
      final boundary = GlobalKey();
      final host = await _mount(tester, boundary, engine);
      final initial_positions = <int, Rect>{
        for (final tile in engine.state.tiles.where((tile) => !tile.is_removed))
          tile.id: quest_scene_frames(tester)[tile.id]!.rect,
      };
      final tray_positions = <int, Rect>{
        for (final id in engine.state.tray)
          id: quest_scene_frames(tester)[id]!.rect,
      };
      await _capture(tester, boundary, '$_preview_directory/before.png');
      host.currentState!.shuffle();
      final result = host.currentState!.actions.single;
      expect(result.moved_ids, hasLength(400));
      expect(engine.state.tray, result.before.tray);
      final changed = result.moved_ids
          .where(
            (id) =>
                result.before.tile_by_id(id).type !=
                result.after.tile_by_id(id).type,
          )
          .toList();
      expect(changed, isNotEmpty);
      final sampled_ids = <int>{
        ...changed.take(8),
        for (var index = 0; index < result.moved_ids.length; index += 50)
          result.moved_ids[index],
      };
      final observed_faces = <int, Set<int>>{
        for (final id in sampled_ids) id: <int>{},
      };
      final blended = <int>{};
      final all_original = <int, Rect>{...initial_positions, ...tray_positions};
      await tester.pump();
      final frame_count = (TileQuestStyle.shuffle_duration_ms / _frame_step_ms)
          .ceil();
      for (var frame = 0; frame <= frame_count; frame++) {
        if (frame > 0) {
          final previous_ms = (frame - 1) * _frame_step_ms;
          final now_ms = math.min(
            frame * _frame_step_ms,
            TileQuestStyle.shuffle_duration_ms.toInt(),
          );
          await tester.pump(Duration(milliseconds: now_ms - previous_ms));
        }
        for (final entry in tray_positions.entries) {
          _same_rect(
            quest_scene_frames(tester)[entry.key]!.rect,
            entry.value,
            reason: 'held tray card ${entry.key} never joins the shuffle',
          );
        }
        if (frame < frame_count) {
          final faces = _full_size_cards(tester, all_original);
          _record_blended_faces(faces, result, observed_faces, blended);
          final positions = _positioned_cards(tester);
          for (final id in sampled_ids) {
            expect(quest_shuffle_frames(tester), contains(id));
            final visible = positions[id]!;
            expect(visible.left, greaterThanOrEqualTo(-.01));
            expect(visible.right, lessThanOrEqualTo(_size.width + .01));
            expect(visible.top, greaterThanOrEqualTo(-.01));
            expect(visible.bottom, lessThanOrEqualTo(_size.height + .01));
          }
        }
        final number = frame.toString().padLeft(3, '0');
        await _capture(
          tester,
          boundary,
          '$_preview_directory/frame_$number.png',
        );
        expect(tester.takeException(), isNull);
      }
      expect(
        blended,
        isNotEmpty,
        reason: 'picture changes must crossfade at full width and full height',
      );
      for (final id in changed.take(8)) {
        expect(observed_faces[id], contains(result.before.tile_by_id(id).type));
        expect(observed_faces[id], contains(result.after.tile_by_id(id).type));
      }
      for (final entry in initial_positions.entries) {
        expect(_flight(entry.key), findsNothing);
        final frame = quest_scene_frames(tester)[entry.key]!;
        _same_rect(
          frame.rect,
          entry.value,
          reason: 'every card returns to its exact logical destination',
        );
        expect(frame.zone, QuestTileZone.board);
        expect(frame.type, result.after.tile_by_id(entry.key).type);
      }
      await tester.pumpAndSettle();
      await _capture(tester, boundary, '$_preview_directory/after.png');

      final tutorial_boundary = GlobalKey();
      await _mount(
        tester,
        tutorial_boundary,
        TileQuestEngine(TileQuestGenerator.generate(level: 1, seed: 730)),
      );
      await _capture(
        tester,
        tutorial_boundary,
        '/tmp/tile_quest_tutorial_preview.png',
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      debugPrint(
        'Exported ${frame_count + 1} frames to $_preview_directory; '
        '400 moving cards, 2 fixed tray cards; tutorial palette preview updated.',
      );
    },
    skip: !_export_motion,
  );
}
