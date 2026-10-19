// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/style.dart';
import 'package:app/pages/tile_quest/widgets/atmosphere.dart';
import 'package:app/pages/tile_quest/widgets/board_canvas.dart';
import 'package:app/pages/tile_quest/widgets/powerup_icon.dart';
import 'package:app/pages/tile_quest/widgets/playfield.dart';
import 'package:app/pages/tile_quest/widgets/quest_controls.dart';
import 'package:app/pages/tile_quest/widgets/quest_scene.dart';
import 'package:app/pages/tile_quest/widgets/scene_assets.dart';
import 'package:app/pages/tile_quest/widgets/tile_card.dart';
import 'package:app/pages/tile_quest/widgets/tile_skin.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _export_assets = bool.fromEnvironment('TILE_QUEST_EXPORT_ASSETS');

/// 从正式翻译加载其余文案，只对道具名注入更长的翻译来验证可用空间。
class _AssetTranslations extends AssetLoader {
  const _AssetTranslations(this.long_labels);
  final bool long_labels;

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final translations = Map<String, dynamic>.from(
      jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
          as Map,
    );
    if (long_labels) {
      final quest = Map<String, dynamic>.from(
        translations['tile_quest'] as Map,
      );
      quest.addAll({
        'undo': 'Rudisha hatua iliyotangulia',
        'shuffle': 'Changanya kadi zote zilizobaki',
        'remove': 'Hamisha kadi kwenda hifadhini',
      });
      translations['tile_quest'] = quest;
    }
    return translations;
  }
}

/// 使用正式引擎与事务动画，确保次数变化覆盖真实按钮而非静态样例。
class _AssetsScene extends StatefulWidget {
  const _AssetsScene({super.key, required this.initial});
  final TileQuestState initial;

  @override
  State<_AssetsScene> createState() => _AssetsSceneState();
}

class _AssetsSceneState extends State<_AssetsScene> {
  late final engine = TileQuestEngine(widget.initial);
  final actions = <TileQuestActionResult>[];

  void record(TileQuestActionResult result) {
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
    can_undo: engine.can_undo,
    on_back: () {},
    on_restart: () {},
    on_sound: () {},
    on_tile: (id) => record(engine.tap_tile(id)),
    on_reserve: (id) => record(engine.return_reserve(id)),
    on_tool: (tool) => record(switch (tool) {
      TileQuestTool.undo => engine.undo(),
      TileQuestTool.shuffle => engine.shuffle(seed: 9127),
      TileQuestTool.remove => engine.remove(),
    }),
  );
}

Future<GlobalKey<_AssetsSceneState>> _mount(
  WidgetTester tester,
  GlobalKey boundary,
  TileQuestState state, {
  required bool dark,
  String locale = 'en',
  bool long_labels = false,
  double text_scale = 1,
  EdgeInsets window_padding = EdgeInsets.zero,
}) async {
  final host = GlobalKey<_AssetsSceneState>();
  await tester.pumpWidget(
    EasyLocalization(
      key: UniqueKey(),
      supportedLocales: [Locale(locale)],
      startLocale: Locale(locale),
      saveLocale: false,
      path: 'assets/i18n',
      assetLoader: _AssetTranslations(long_labels),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          theme: ThemeData(
            fontFamily: 'Roboto',
            brightness: dark ? Brightness.dark : Brightness.light,
          ),
          home: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(text_scale),
              padding: window_padding,
            ),
            child: RepaintBoundary(
              key: boundary,
              child: Scaffold(
                body: Stack(
                  children: [
                    Positioned.fill(child: QuestAtmosphere(is_dark: dark)),
                    Positioned.fill(
                      child: QuestPlayfield(
                        child: _AssetsScene(key: host, initial: state),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await Future.wait([
      for (final provider in <ImageProvider>[
        QuestSceneAssets.background,
        ...QuestSceneAssets.powerups.values,
        QuestTileSkin.provider,
        for (final type in state.tiles.map((tile) => tile.type).toSet())
          ResizeImage(
            AssetImage(quest_tile_asset_path(type)),
            width: TileQuestStyle.tile_cache_width,
          ),
      ])
        precacheImage(
          provider,
          boundary.currentContext!,
          onError: (error, stack) => fail('Failed to decode $provider: $error'),
        ),
    ]);
  });
  // toImage() 在真实异步队列生成图集；实际图片解码后再等它完成，
  // 防止导出的截图只拍到临时向量底面。
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pumpAndSettle();
    final painter = tester
        .widget<QuestBoardCanvas>(find.byType(QuestBoardCanvas))
        .painter;
    if (painter.textures.ready) break;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  expect(
    tester
        .widget<QuestBoardCanvas>(find.byType(QuestBoardCanvas))
        .painter
        .textures
        .ready,
    isTrue,
  );
  expect(tester.takeException(), isNull);
  return host;
}

/// errorBuilder 可能吞掉加载错误；必须检查真正交付给绘制层的位图。
void _expect_decoded_assets(WidgetTester tester) {
  final background = tester
      .widget<RawImage>(
        find.descendant(
          of: find.byType(QuestAtmosphere),
          matching: find.byType(RawImage),
        ),
      )
      .image;
  expect(background, isNotNull);
  expect(
    Size(background!.width.toDouble(), background.height.toDouble()),
    const Size(1024, 1536),
  );
  for (final tool in TileQuestTool.values) {
    final icon = find.byWidgetPredicate(
      (widget) => widget is QuestPowerupIcon && widget.tool == tool,
    );
    expect(icon, findsOneWidget);
    final bitmap = tester
        .widget<RawImage>(
          find.descendant(of: icon, matching: find.byType(RawImage)),
        )
        .image;
    expect(bitmap, isNotNull, reason: '${tool.name} must use the supplied PNG');
    expect(bitmap!.width, TileQuestStyle.tool_icon_cache_width);
    expect(
      find.descendant(of: icon, matching: find.byType(Icon)),
      findsNothing,
    );
  }
}

Future<void> _capture(GlobalKey boundary, String name) async {
  final render =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await render.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final directory = Directory('build/tile_quest')..createSync(recursive: true);
  File(
    '${directory.path}/$name.png',
  ).writeAsBytesSync(bytes!.buffer.asUint8List());
  image.dispose();
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (call) async => call.method == 'getAll' ? <String, Object>{} : true,
    );
    await EasyLocalization.ensureInitialized();
    final font_directory = Directory(
      '.fvm/flutter_sdk/bin/cache/artifacts/material_fonts',
    );
    if (!font_directory.existsSync()) return;
    for (final font in [
      ('Roboto', 'Roboto-Regular.ttf'),
      ('MaterialIcons', 'MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(font.$1)..addFont(
            Future.value(
              ByteData.sublistView(
                File('${font_directory.path}/${font.$2}').readAsBytesSync(),
              ),
            ),
          ))
          .load();
    }
  });

  testWidgets(
    'supplied backgrounds and powerups decode while real tool actions update their counts',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final engine = TileQuestEngine(
        TileQuestGenerator.generate(level: 2, seed: 730),
      );
      final host = await _mount(tester, GlobalKey(), engine.state, dark: true);
      host.currentState!.record(
        host.currentState!.engine.tap_tile(
          engine.state.certified_solution.first,
        ),
      );
      await tester.pumpAndSettle();
      _expect_decoded_assets(tester);
      for (final tool in TileQuestTool.values) {
        if (tool == TileQuestTool.remove) {
          host.currentState!.record(
            host.currentState!.engine.tap_tile(
              host.currentState!.engine.state.clickable_tiles.first.id,
            ),
          );
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(ValueKey('tile_quest_tool_${tool.name}')));
        await tester.pumpAndSettle();
        final button = tester.widget<QuestToolButton>(
          find.byWidgetPredicate(
            (widget) => widget is QuestToolButton && widget.tool == tool,
          ),
        );
        expect(button.remaining, tool == TileQuestTool.remove ? 1 : 0);
        expect(
          find.descendant(
            of: find.byWidgetPredicate(
              (widget) => widget is QuestToolButton && widget.tool == tool,
            ),
            matching: find.text(tool == TileQuestTool.remove ? '1/2' : '0/1'),
          ),
          findsOneWidget,
        );
        _expect_decoded_assets(tester);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'actual textured scene keeps new tools visible in both themes with long text and two-times system fonts',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = TileQuestGenerator.generate(level: 2, seed: 730);
      for (final size in [
        const Size(320, 568),
        const Size(382, 644),
        const Size(568, 320),
        const Size(390, 844),
        const Size(844, 390),
      ]) {
        await tester.binding.setSurfaceSize(size);
        for (final dark in [false, true]) {
          await _mount(
            tester,
            GlobalKey(),
            state,
            dark: dark,
            locale: dark ? 'zh' : 'sw',
            long_labels: !dark,
            text_scale: 2,
          );
          _expect_decoded_assets(tester);
          for (final tool in TileQuestTool.values) {
            final button = find.byKey(ValueKey('tile_quest_tool_${tool.name}'));
            final rect = tester.getRect(button);
            expect(rect.height, greaterThanOrEqualTo(44));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(size.width));
            expect(rect.bottom, lessThanOrEqualTo(size.height));
          }
          expect(tester.takeException(), isNull, reason: '$size dark=$dark');
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      }
    },
  );

  testWidgets(
    'export real portrait and landscape scenes with supplied new artwork',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = TileQuestGenerator.generate(level: 2, seed: 730);
      for (final scenario in [
        (const Size(390, 844), 'new_assets_portrait', EdgeInsets.zero),
        (const Size(844, 390), 'new_assets_landscape', EdgeInsets.zero),
        (
          const Size(466, 678),
          'duo_compact_playfield',
          const EdgeInsets.only(right: 84, bottom: 34),
        ),
        (
          const Size(951, 669),
          'duo_expanded_playfield',
          const EdgeInsets.only(right: 84, bottom: 34),
        ),
        (
          const Size(669, 951),
          'duo_expanded_portrait_playfield',
          EdgeInsets.zero,
        ),
      ]) {
        await tester.binding.setSurfaceSize(scenario.$1);
        final boundary = GlobalKey();
        await _mount(
          tester,
          boundary,
          state,
          dark: false,
          window_padding: scenario.$3,
        );
        _expect_decoded_assets(tester);
        await tester.runAsync(() => _capture(boundary, scenario.$2));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    },
    skip: !_export_assets,
  );
}
