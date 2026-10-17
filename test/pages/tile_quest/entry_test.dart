// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:app/components/app_wrapper/router/route_config.dart';
import 'package:app/pages/user_info/widgets/tile_quest_entry/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _EntryAssets extends AssetLoader {
  const _EntryAssets();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (call) async => call.method == 'getAll' ? <String, Object>{} : true,
    );
    await EasyLocalization.ensureInitialized();
  });

  test(
    'game is a standalone named route without an authentication redirect',
    () {
      final router = RouteConfig.createRouter();
      addTearDown(router.dispose);
      final route = router.configuration.routes
          .whereType<GoRoute>()
          .singleWhere((route) => route.path == '/tile_quest');
      expect(route.name, 'tile_quest');
      expect(route.redirect, isNull);
    },
  );

  for (final locale in ['en', 'zh', 'fr', 'sw']) {
    for (final is_dark in [false, true]) {
      testWidgets('entry opens once at 320px in $locale dark=$is_dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        int openings = 0;
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: [Locale(locale)],
            startLocale: Locale(locale),
            path: 'assets/i18n',
            saveLocale: false,
            assetLoader: const _EntryAssets(),
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Scaffold(
                  body: MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(1.4)),
                    child: TileQuestEntry(
                      is_dark: is_dark,
                      on_open: () => openings++,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Tile Quest'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('tile_quest_entry')));
        await tester.pump();
        expect(openings, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
