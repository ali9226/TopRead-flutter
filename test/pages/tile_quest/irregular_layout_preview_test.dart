// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/widgets/atmosphere.dart';
import 'package:app/pages/tile_quest/widgets/playfield.dart';
import 'package:app/pages/tile_quest/widgets/quest_scene.dart';
import 'package:app/pages/tile_quest/widgets/scene_assets.dart';
import 'package:app/pages/tile_quest/widgets/scene_layout.dart';
import 'package:app/pages/tile_quest/widgets/tile_card.dart';
import 'package:app/pages/tile_quest/widgets/tile_skin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 只比较形状，不让图案类型或题目 id 掩盖实际布局是否不同。
String _geometry_signature(List<TileQuestTile> tiles) =>
    tiles.map((tile) => '${tile.layer}:${tile.x}:${tile.y}').join(';');

/// 真正随机生成的几何样本；不依赖固定模板编号或 seed 到母形的映射。
const _preview_seeds = <int>[1, 3, 11, 0, 5, 13];

Map<int, TileQuestState> _layout_variants() {
  final variants = <int, TileQuestState>{
    for (var index = 0; index < _preview_seeds.length; index++)
      index: TileQuestGenerator.generate(
        level: 2,
        seed: _preview_seeds[index],
        difficulty: TileQuestConfig.gameDifficulty,
      ),
  };
  expect(
    variants.values.map((state) => _geometry_signature(state.tiles)).toSet(),
    hasLength(_preview_seeds.length),
  );
  return variants;
}

Future<void> _load_preview_fonts() async {
  final fonts = Directory(
    '${Directory.current.path}/.fvm/flutter_sdk/bin/cache/artifacts/material_fonts',
  );
  if (!fonts.existsSync()) return;
  final roboto = FontLoader('Roboto')
    ..addFont(
      Future<ByteData>.value(
        ByteData.sublistView(
          File('${fonts.path}/Roboto-Regular.ttf').readAsBytesSync(),
        ),
      ),
    );
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(
      Future<ByteData>.value(
        ByteData.sublistView(
          File('${fonts.path}/MaterialIcons-Regular.otf').readAsBytesSync(),
        ),
      ),
    );
  await icons.load();
}

Future<void> _export_preview(
  WidgetTester tester,
  TileQuestState state,
  String path, {
  MediaQueryData? media,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(fontFamily: 'Roboto'),
      home: RepaintBoundary(
        key: key,
        child: Scaffold(
          body: Stack(
            children: <Widget>[
              const Positioned.fill(child: QuestAtmosphere(is_dark: true)),
              Positioned.fill(
                child: Builder(
                  builder: (context) {
                    final scene = TileQuestScene(
                      key: ValueKey(state.challenge_id),
                      state: state,
                      action: null,
                      sound_enabled: true,
                      busy: false,
                      on_back: () {},
                      on_restart: () {},
                      on_sound: () {},
                      on_tile: (_) {},
                      on_reserve: (_) {},
                      on_tool: (_) {},
                    );
                    return media == null
                        ? scene
                        : MediaQuery(
                            data: media,
                            child: QuestPlayfield(child: scene),
                          );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  // 图片解码运行在真实异步队列；只 pumpAndSettle 会把尚未解码的首批牌
  // 导出成纯色 backing。使用与 QuestTileCard 相同的缓存键尺寸等待完成。
  await tester.runAsync(() async {
    final context = key.currentContext!;
    final types = state.tiles.map((tile) => tile.type).toSet();
    await Future.wait<void>(<Future<void>>[
      precacheImage(QuestTileSkin.provider, context),
      precacheImage(QuestSceneAssets.background, context),
      for (final image in QuestSceneAssets.powerups.values)
        precacheImage(image, context),
      for (final type in types)
        precacheImage(
          ResizeImage.resizeIfNeeded(
            192,
            null,
            AssetImage(quest_tile_asset_path(type)),
          ),
          context,
        ),
    ]);
  });
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
  expect(File(path).lengthSync(), greaterThan(0));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_load_preview_fonts);

  testWidgets(
    'export actual Duo closed half-open and open game scenes',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = TileQuestGenerator.generate(level: 2, seed: 730);
      final poses = <String, MediaQueryData>{
        'closed': const MediaQueryData(
          size: Size(466, 678),
          padding: EdgeInsets.only(right: 84, bottom: 34),
        ),
        'half_open': const MediaQueryData(
          size: Size(951, 669),
          padding: EdgeInsets.only(right: 84, bottom: 34),
          displayFeatures: [
            ui.DisplayFeature(
              bounds: Rect.fromLTWH(455.5, 0, 40, 669),
              type: ui.DisplayFeatureType.hinge,
              state: ui.DisplayFeatureState.postureHalfOpened,
            ),
            ui.DisplayFeature(
              bounds: Rect.fromLTWH(867, 0, 84, 124),
              type: ui.DisplayFeatureType.cutout,
              state: ui.DisplayFeatureState.unknown,
            ),
          ],
        ),
        'open': const MediaQueryData(
          size: Size(951, 669),
          padding: EdgeInsets.only(right: 84, bottom: 34),
        ),
      };
      final metrics = <String, Object>{};
      for (final pose in poses.entries) {
        await tester.binding.setSurfaceSize(pose.value.size);
        await _export_preview(
          tester,
          state,
          '/tmp/tile_quest_duo_v23_${pose.key}.png',
          media: pose.value,
        );
        final scene = find.byType(TileQuestScene);
        final layout = QuestSceneLayout(
          tester.getSize(scene),
          state,
          display_features: MediaQuery.displayFeaturesOf(tester.element(scene)),
        );
        metrics[pose.key] = <String, Object>{
          'window': [pose.value.size.width, pose.value.size.height],
          'scene': [layout.size.width, layout.size.height],
          'board_tile_width': layout.unit,
          'tray_tile_width': layout.tray_tile(0).width,
          'folded': layout.folded,
          'landscape': layout.landscape,
        };
      }
      File(
        '/tmp/tile_quest_duo_v23_geometry.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(metrics));
    },
    skip: !const bool.fromEnvironment('TILE_QUEST_EXPORT_DUO'),
  );

  testWidgets('export six seeded structured layouts and difficulty ten', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _export_preview(
      tester,
      TileQuestGenerator.generate(level: 1, seed: 730),
      '/tmp/tile_quest_tutorial_preview.png',
    );
    final variants = _layout_variants();
    for (var pattern = 0; pattern < _preview_seeds.length; pattern++) {
      final state = variants[pattern]!;
      final path = '/tmp/tile_quest_layout_variant_$pattern.png';
      await _export_preview(tester, state, path);
      debugPrint(
        'Structured layout variant $pattern: difficulty ${state.difficulty}, '
        'seed ${state.seed}, $path',
      );
    }
    final hardest = TileQuestGenerator.generate(
      level: 2,
      seed: 730,
      difficulty: 10,
    );
    await _export_preview(
      tester,
      hardest,
      '/tmp/tile_quest_difficulty10_preview.png',
    );
    // 再用真实规则移出两批，供视觉核对上下槽尺寸及每列两张的堆叠层级。
    final stacked = TileQuestEngine(variants[0]!);
    for (var batch = 0; batch < 2; batch++) {
      for (var pick = 0; pick < TileQuestConfig.remove_batch_size; pick++) {
        final tile = stacked.state.clickable_tiles.firstWhere(
          (tile) =>
              stacked.state.tray
                  .where((id) => stacked.state.tile_by_id(id).type == tile.type)
                  .length <
              2,
        );
        expect(stacked.tap_tile(tile.id).accepted, isTrue);
      }
      expect(stacked.remove().accepted, isTrue);
    }
    expect(stacked.state.reserve, hasLength(6));
    await _export_preview(
      tester,
      stacked.state,
      '/tmp/tile_quest_stacked_reserve_preview.png',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
