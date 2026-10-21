import 'package:app/components/app_wrapper/widgets/system_ui_region/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('页面自定义状态栏可覆盖全局，返回与主题切换时恢复默认', (tester) async {
    tester.view.padding = const FakeViewPadding(top: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    final theme_mode = ValueNotifier(ThemeMode.light);
    addTearDown(theme_mode.dispose);

    await tester.pumpWidget(
      ValueListenableBuilder<ThemeMode>(
        valueListenable: theme_mode,
        builder: (context, mode, _) => MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: mode,
          builder: (context, child) => AppSystemUiRegion(child: child!),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  key: const ValueKey('open_hero'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          AnnotatedRegion<SystemUiOverlayStyle>(
                            value: SystemUiOverlayStyle.light,
                            child: Scaffold(
                              body: Center(
                                child: TextButton(
                                  key: const ValueKey('close_hero'),
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Back'),
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.dark);
    expect(SystemChrome.latestStyle?.statusBarBrightness, Brightness.light);

    await tester.tap(find.byKey(const ValueKey('open_hero')));
    await tester.pumpAndSettle();
    expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.light);
    expect(SystemChrome.latestStyle?.statusBarBrightness, Brightness.dark);

    await tester.tap(find.byKey(const ValueKey('close_hero')));
    await tester.pumpAndSettle();
    expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.dark);
    expect(SystemChrome.latestStyle?.statusBarBrightness, Brightness.light);

    theme_mode.value = ThemeMode.dark;
    await tester.pumpAndSettle();
    expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.light);
    expect(SystemChrome.latestStyle?.statusBarBrightness, Brightness.dark);
    expect(tester.takeException(), isNull);
  });
}
