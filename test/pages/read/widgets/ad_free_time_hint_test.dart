import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/pages/read/widgets/ad_free_time_hint/index.dart';
import 'package:app/pages/read/widgets/rewarded_ad_loading_overlay/index.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const MethodChannel preferences_channel = MethodChannel(
      'plugins.flutter.io/shared_preferences',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(preferences_channel, (
          MethodCall method_call,
        ) async {
          if (method_call.method == 'getAll') return <String, Object>{};
          return true;
        });
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('免广告生效时展示到期时间并可继续叠加', (WidgetTester tester) async {
    int tap_count = 0;

    await tester.pumpWidget(
      _build_test_app(
        AdFreeTimeHint(
          is_dark: false,
          expire_time: DateTime(2026, 8, 30, 16, 30),
          on_tap: () => tap_count++,
        ),
      ),
    );
    await tester.pump();

    final Finder active_hint = find.byWidgetPredicate((Widget widget) {
      return widget is Text &&
          widget.data?.contains('免广告至') == true &&
          widget.data?.contains('续30分钟') == true;
    });
    expect(active_hint, findsOneWidget);

    await tester.tap(active_hint);
    expect(tap_count, 1);
  });

  testWidgets('异步获得免广告时长后每个章节底部插槽立即显示续时入口', (WidgetTester tester) async {
    final ValueNotifier<DateTime?> expire_time_notifier =
        ValueNotifier<DateTime?>(null);

    await tester.pumpWidget(
      _build_test_app(
        Column(
          children: <Widget>[
            AdFreeTimeHintSlot(
              is_dark: false,
              expire_time_listenable: expire_time_notifier,
              show_inactive_hint: false,
            ),
            AdFreeTimeHintSlot(
              is_dark: false,
              expire_time_listenable: expire_time_notifier,
              show_inactive_hint: false,
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(_find_active_hint(), findsNothing);

    expire_time_notifier.value = DateTime.now().add(const Duration(hours: 1));
    await tester.pump();

    expect(_find_active_hint(), findsNWidgets(2));
    expire_time_notifier.dispose();
  });

  testWidgets('激励视频准备期间显示转圈并吸收重复点击', (WidgetTester tester) async {
    await tester.pumpWidget(
      _build_test_app(const RewardedAdLoadingOverlay(is_dark: false)),
    );
    await tester.pump();

    final Finder indicator = find.byType(CircularProgressIndicator);
    expect(indicator, findsOneWidget);
    final Finder absorbing_pointer = find.byWidgetPredicate((Widget widget) {
      return widget is AbsorbPointer && widget.absorbing;
    });
    final Finder absorbing_layer = find.ancestor(
      of: indicator,
      matching: absorbing_pointer,
    );
    expect(absorbing_layer, findsOneWidget);
    final AbsorbPointer pointer = tester.widget<AbsorbPointer>(absorbing_layer);
    expect(pointer.absorbing, isTrue);
  });
}

Finder _find_active_hint() {
  return find.byWidgetPredicate((Widget widget) {
    return widget is Text &&
        widget.data?.contains('免广告至') == true &&
        widget.data?.contains('续30分钟') == true;
  });
}

Widget _build_test_app(Widget child) {
  return EasyLocalization(
    supportedLocales: const <Locale>[Locale('zh')],
    path: 'assets/i18n',
    assetLoader: const _AdFreeTimeHintTestAssetLoader(),
    startLocale: const Locale('zh'),
    fallbackLocale: const Locale('zh'),
    child: Builder(
      builder: (BuildContext context) {
        return MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(body: Center(child: child)),
        );
      },
    ),
  );
}

class _AdFreeTimeHintTestAssetLoader extends AssetLoader {
  const _AdFreeTimeHintTestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return <String, dynamic>{
      'read': <String, dynamic>{
        'watch_video_ad_hint': '看视频免30分钟广告 >',
        'ad_free_until_continue': '免广告至 {} · 再看一个，续30分钟 >',
        'ad_loading': '广告加载中',
      },
    };
  }
}
