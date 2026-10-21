// ignore_for_file: non_constant_identifier_names

import 'package:app/components/reader_top_bar/action_button.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/project_config.dart';
import 'package:app/pages/read/widgets/navigation_bars/top/index.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Assets extends AssetLoader {
  const _Assets();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'comics': {'collect': 'Save', 'collected': 'Saved', 'share': 'Share'},
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (_) async => <String, Object>{},
        );
    await EasyLocalization.ensureInitialized();
  });
  tearDown(Get.reset);

  testWidgets('长篇共享顶部保留无标题布局、原回调及远端分享开关，加载使用主题色', (tester) async {
    final config = Get.put(ProjectConfigStore());
    config.save_config(
      ProjectConfig.from_json({'share_switch': SwitchValue.off}),
    );
    var collected = false;
    var loading = false;
    var back = 0, favorite = 0, shares = 0;
    late StateSetter update;
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'test',
        assetLoader: const _Assets(),
        startLocale: const Locale('en'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, state) {
                  update = state;
                  return Stack(
                    children: [
                      ReadTopBar(
                        is_dark: false,
                        show: true,
                        on_back: () => back++,
                        on_favorite_tap: () => favorite++,
                        on_share: () => shares++,
                        is_favorited: collected,
                        is_loading: loading,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    List<ReaderTopBarAction> actions() => tester
        .widgetList<ReaderTopBarAction>(find.byType(ReaderTopBarAction))
        .toList();
    expect(actions().first.asset, 'right');
    expect(actions()[1].icon, Icons.favorite_border_rounded);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.textContaining('Chapter'), findsNothing);
    await tester.tap(find.byWidget(actions()[1]));
    expect(favorite, 1);
    update(() => collected = true);
    await tester.pumpAndSettle();
    expect(actions()[1].icon, Icons.favorite_rounded);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(actions()[1].color, ColorConstants.dangerColor);
    config.save_config(
      ProjectConfig.from_json({'share_switch': SwitchValue.on}),
    );
    await tester.pumpAndSettle();
    expect(actions().last.asset, 'share');
    await tester.tap(find.byWidget(actions().last));
    expect(shares, 1);
    update(() => loading = true);
    await tester.pump();
    expect(
      tester
          .widgetList<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .map((indicator) => indicator.color),
      everyElement(ColorConstants.themeColor),
    );
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    await tester.tap(find.byWidget(actions().first));
    expect(back, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
