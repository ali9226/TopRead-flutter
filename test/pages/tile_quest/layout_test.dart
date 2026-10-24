// ignore_for_file: non_constant_identifier_names
import 'dart:io';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/index.dart';
import 'package:app/pages/tile_quest/logic.dart';
import 'package:app/pages/tile_quest/services/feedback_service.dart';
import 'package:app/pages/tile_quest/services/save_service.dart';
import 'package:app/pages/tile_quest/services/work_service.dart';
import 'package:app/pages/tile_quest/widgets/atmosphere.dart';
import 'package:app/pages/tile_quest/widgets/quest_result.dart';
import 'package:app/pages/tile_quest/widgets/quest_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'scene_probe.dart';

class _LocaleAssets extends AssetLoader {
  const _LocaleAssets();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
}

class _MemoryStore implements TileQuestSaveStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
  }
}

class _TestWork implements TileQuestWorkService {
  @override
  Future<TileQuestState> generate({
    required int level,
    required int seed,
    required int unlocked_level,
    String? challenge_id,
    int? layout_seed,
    num? difficulty,
  }) async => TileQuestGenerator.generate(
    level: level,
    seed: seed,
    unlocked_level: unlocked_level,
    challenge_id: challenge_id,
    layout_seed: layout_seed,
    difficulty: difficulty,
  );
  @override
  Future<TileQuestPreparedShuffle> shuffle(
    Map<String, dynamic> engine_json, {
    required int seed,
  }) async {
    final engine = TileQuestEngine.restore(engine_json);
    return TileQuestPreparedShuffle(
      engine: engine,
      result: engine.shuffle(seed: seed),
    );
  }
}

class _QuietFeedback implements TileQuestFeedbackService {
  @override
  Future<void> play(TileQuestFeedbackEvent event) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
    final sdk_fonts = Directory(
      '${Directory.current.path}/.fvm/flutter_sdk/bin/cache/artifacts/material_fonts',
    );
    if (sdk_fonts.existsSync()) {
      final roboto = FontLoader('Roboto')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File('${sdk_fonts.path}/Roboto-Regular.ttf').readAsBytesSync(),
            ),
          ),
        );
      await roboto.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File(
                '${sdk_fonts.path}/MaterialIcons-Regular.otf',
              ).readAsBytesSync(),
            ),
          ),
        );
      await icons.load();
    }
  });

  for (final size in [
    const Size(320, 568),
    const Size(430, 932),
    const Size(1024, 1366),
    const Size(844, 390),
  ]) {
    testWidgets(
      'responsive board fits ${size.width}x${size.height} and keeps geometric hit targets',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final state = TileQuestGenerator.generate(level: 2, seed: 730);
        int? tapped;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'Roboto'),
            home: Scaffold(
              body: SafeArea(
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: QuestAtmosphere(is_dark: true),
                    ),
                    Positioned.fill(
                      child: TileQuestScene(
                        state: state,
                        action: null,
                        sound_enabled: true,
                        busy: false,
                        on_back: () {},
                        on_restart: () {},
                        on_sound: () {},
                        on_tile: (id) => tapped = id,
                        on_reserve: (_) {},
                        on_tool: (_) {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final id = state.clickable_tiles.first.id;
        final rect = quest_scene_frames(tester)[id]!.rect;
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
        await tester.tapAt(rect.center);
        expect(tapped, id);
      },
    );
  }

  testWidgets(
    'native tool counts update, restart confirms, sound and back respond',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var back = false;
      final logic = TileQuestLogic(
        save_service: TileQuestSaveService(
          encode_snapshot: encode_tile_quest_snapshot,
          store: _MemoryStore(),
        ),
        work_service: _TestWork(),
        feedback_service: _QuietFeedback(),
        enable_timer: false,
        next_seed: () => 27,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Roboto'),
          home: TileQuestPage(logic: logic, on_back: () => back = true),
        ),
      );
      await tester.pumpAndSettle();
      expect(logic.state, isNotNull);
      expect(logic.state!.level, 1);
      expect(
        find.byKey(const ValueKey('tile_quest_tool_remove')),
        findsNothing,
      );
      // 第一关只提供教学牌局；工具交互必须先经真实胜利入口进入第二关。
      for (final id in logic.state!.certified_solution.toList()) {
        expect((await logic.tap_tile(id))!.accepted, isTrue);
      }
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tile_quest_result_primary')));
      await tester.pumpAndSettle();
      expect(logic.state!.level, 2);
      final id = logic.state!.clickable_tiles.first.id;
      await tester.tapAt(quest_scene_frames(tester)[id]!.rect.center);
      await tester.pumpAndSettle();
      expect(logic.state!.tray.length, 1);
      await tester.tap(find.byKey(const ValueKey('tile_quest_tool_remove')));
      await tester.pumpAndSettle();
      expect(logic.state!.reserve.length, 1);
      expect(logic.state!.tools[TileQuestTool.remove], 1);
      final reserve_id = logic.state!.reserve.first;
      await tester.tapAt(quest_scene_frames(tester)[reserve_id]!.rect.center);
      await tester.pumpAndSettle();
      expect(logic.state!.reserve, isEmpty);
      await tester.tap(find.byKey(const ValueKey('tile_quest_settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tile_quest_sound')));
      await tester.pumpAndSettle();
      expect(logic.sound_enabled, isFalse);
      final challenge = logic.state!.challenge_id;
      await tester.tap(find.byKey(const ValueKey('tile_quest_restart')));
      await tester.pumpAndSettle();
      expect(logic.state!.challenge_id, challenge);
      await tester.tap(
        find.byKey(const ValueKey('tile_quest_confirm_restart')),
      );
      await tester.pumpAndSettle();
      expect(logic.state!.challenge_id, isNot(challenge));
      expect(logic.state!.level, 1);
      expect(
        find.byKey(const ValueKey('tile_quest_tool_remove')),
        findsNothing,
      );
      expect(logic.state!.tools, <TileQuestTool, int>{
        for (final tool in TileQuestTool.values)
          tool: TileQuestConfig.initial_tool_uses(tool),
      });
      await tester.tap(find.byKey(const ValueKey('tile_quest_back')));
      await tester.pumpAndSettle();
      expect(back, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('win and loss result layouts fit short landscape', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final status in [TileQuestStatus.won, TileQuestStatus.lost]) {
      final state = TileQuestGenerator.generate(
        level: 2,
        seed: 730,
      ).copy_with(status: status);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Roboto'),
          home: Scaffold(
            body: QuestResult(
              state: state,
              coming_soon: false,
              busy: false,
              on_next: () {},
              on_restart: () {},
              on_back: () {},
              on_undo: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.text(
          status == TileQuestStatus.won ? 'Level Complete!' : 'Game Over',
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets(
    'same-frame taps animate every transaction and undo supersedes a flight',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final logic = TileQuestLogic(
        save_service: TileQuestSaveService(
          encode_snapshot: encode_tile_quest_snapshot,
          store: _MemoryStore(),
        ),
        work_service: _TestWork(),
        feedback_service: _QuietFeedback(),
        enable_timer: false,
        next_seed: () => 27,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Roboto'),
          home: TileQuestPage(logic: logic),
        ),
      );
      await tester.pumpAndSettle();
      final first = logic.state!.clickable_tiles.first.id;
      final first_action = logic.tap_tile(first);
      final second = logic.state!.clickable_tiles.first.id;
      final second_action = logic.tap_tile(second);
      await Future.wait([first_action, second_action]);
      // Deliberately render only after both accepted actions committed.
      await tester.pump();
      expect(quest_scene_frames(tester)[first]!.zone, QuestTileZone.flight);
      expect(quest_scene_frames(tester)[second]!.zone, QuestTileZone.flight);
      await logic.undo();
      await tester.pump();
      expect(quest_scene_frames(tester)[second]!.zone, QuestTileZone.flight);
      expect(logic.state!.tile_by_id(second).is_removed, isFalse);
      // Dispose while animation controllers are live: no setState after dispose.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('notched small display preserves tray and all tool hit areas', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = TileQuestGenerator.generate(level: 2, seed: 730);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Roboto'),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            padding: EdgeInsets.only(top: 44, bottom: 34),
          ),
          child: Scaffold(
            body: SafeArea(
              child: TileQuestScene(
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
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final tool in TileQuestTool.values) {
      final rect = tester.getRect(
        find.byKey(ValueKey('tile_quest_tool_${tool.name}')),
      );
      expect(rect.top, greaterThan(44));
      expect(rect.bottom, lessThanOrEqualTo(534));
      expect(rect.height, greaterThanOrEqualTo(44));
    }
  });

  testWidgets(
    'a superseded page starts fresh when explicitly taking over the session',
    (tester) async {
      final saves = TileQuestSaveService(
        encode_snapshot: encode_tile_quest_snapshot,
        store: _MemoryStore(),
      );
      TileQuestLogic controller() => TileQuestLogic(
        save_service: saves,
        work_service: _TestWork(),
        feedback_service: _QuietFeedback(),
        enable_timer: false,
        next_seed: () => 27,
      );
      final first = controller();
      final second = controller();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Roboto'),
          home: TileQuestPage(logic: first),
        ),
      );
      await tester.pumpAndSettle();
      final id = first.state!.clickable_tiles.first.id;
      final first_challenge = first.state!.challenge_id;
      await first.tap_tile(id);
      await second.initialize();
      await second.toggle_sound();
      final second_challenge = second.state!.challenge_id;
      await tester.pumpAndSettle();
      expect(first.session_suspended, isTrue);
      expect(
        find.byKey(const ValueKey('tile_quest_resume_session')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('tile_quest_resume_session')));
      await tester.pumpAndSettle();
      expect(first.session_suspended, isFalse);
      expect(first.state!.tray, isEmpty);
      expect(first.state!.challenge_id, isNot(first_challenge));
      expect(first.state!.challenge_id, isNot(second_challenge));
      expect(first.state!.elapsed_ms, 0);
      expect(first.sound_enabled, isFalse);
      expect(second.session_suspended, isTrue);
      expect(
        find.byKey(const ValueKey('tile_quest_resume_session')),
        findsNothing,
      );
      second.onDelete();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  for (final scenario in [
    (locale: 'fr', dark: false),
    (locale: 'zh', dark: true),
  ]) {
    testWidgets(
      'localized small notched game and dialogs fit ${scenario.locale} at 1.3 scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 568));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final logic = TileQuestLogic(
          save_service: TileQuestSaveService(
            encode_snapshot: encode_tile_quest_snapshot,
            store: _MemoryStore(),
          ),
          work_service: _TestWork(),
          feedback_service: _QuietFeedback(),
          enable_timer: false,
          next_seed: () => 27,
        );
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: [Locale(scenario.locale)],
            startLocale: Locale(scenario.locale),
            saveLocale: false,
            path: 'assets/i18n',
            assetLoader: const _LocaleAssets(),
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                theme: ThemeData(
                  fontFamily: 'Roboto',
                  brightness: scenario.dark
                      ? Brightness.dark
                      : Brightness.light,
                ),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: const EdgeInsets.only(top: 44, bottom: 34),
                    textScaler: const TextScaler.linear(1.3),
                  ),
                  child: child!,
                ),
                home: TileQuestPage(logic: logic),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // 标题区只保留 logo 与工具按钮；设置展开后才出现重开。
        expect(find.byKey(const ValueKey('tile_quest_back')), findsOneWidget);
        expect(find.byKey(const ValueKey('tile_quest_settings')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('tile_quest_settings')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('tile_quest_restart')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('tile_quest_restart')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final cancel = scenario.locale == 'fr' ? 'Continuer' : '继续游戏';
        await tester.tap(find.text(cancel));
        await tester.pumpAndSettle();
        final solution = List<int>.from(logic.state!.certified_solution);
        for (final id in solution) {
          await logic.tap_tile(id);
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.text(scenario.locale == 'fr' ? 'Niveau terminé !' : '关卡完成！'),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey('tile_quest_result_primary')),
        );
        await tester.pumpAndSettle();
        expect(logic.state!.level, 2);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets('export game visual previews', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final level in [1, 2]) {
      final key = GlobalKey();
      final state = TileQuestGenerator.generate(level: level, seed: 730);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Roboto'),
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              body: Stack(
                children: [
                  const Positioned.fill(child: QuestAtmosphere(is_dark: true)),
                  Positioned.fill(
                    child: TileQuestScene(
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '/tmp/tile_quest_level_${level}_preview.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
