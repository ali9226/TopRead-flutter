import 'package:app/pages/short_story_read/widgets/story_unlock_gate.dart';
import 'package:app/pages/short_story_read/widgets/story_content.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
          if (method_call.method == 'getAll') {
            return <String, Object>{};
          }
          return true;
        });
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('英文解锁卡片在窄屏和夜间模式下无溢出', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _build_test_app(
        locale: const Locale('en'),
        child: StoryUnlockGate(
          content: List<String>.generate(
            120,
            (int index) => 'word$index',
          ).join(' '),
          is_dark: true,
          is_loading: false,
          is_unlocked: false,
          is_unlocking: false,
          font_size: 18,
          on_unlock: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Watch an ad to continue'), findsOneWidget);
    expect(find.byType(StoryUnlockGate), findsOneWidget);
    final StoryContent faded_content = tester.widget<StoryContent>(
      find.byKey(const ValueKey<String>('story_unlock_faded_content')),
    );
    expect(faded_content.content, contains('word87'));
    expect(faded_content.content, isNot(contains('word88')));

    final Rect faded_content_rect = tester.getRect(
      find.byKey(const ValueKey<String>('story_unlock_faded_content')),
    );
    final Rect gradient_overlay_rect = tester.getRect(
      find.byKey(const ValueKey<String>('story_unlock_gradient_overlay')),
    );
    expect(gradient_overlay_rect.top, lessThan(faded_content_rect.bottom));
    expect(
      gradient_overlay_rect.bottom,
      greaterThan(faded_content_rect.bottom),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('中文解锁卡片显示剩余字数并响应点击', (WidgetTester tester) async {
    int unlock_count = 0;
    await tester.pumpWidget(
      _build_test_app(
        locale: const Locale('zh'),
        child: StoryUnlockGate(
          content: List<String>.filled(90, '精彩').join(),
          is_dark: false,
          is_loading: false,
          is_unlocked: false,
          is_unlocking: false,
          font_size: 18,
          on_unlock: () => unlock_count++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('余下 120 字精彩内容等待解锁'), findsOneWidget);
    await tester.tap(find.text('看广告继续阅读'));
    expect(unlock_count, 1);
    expect(tester.takeException(), isNull);
  });
}

Widget _build_test_app({required Locale locale, required Widget child}) {
  return EasyLocalization(
    supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
    path: 'assets/i18n',
    assetLoader: const _StoryUnlockGateTestAssetLoader(),
    startLocale: locale,
    fallbackLocale: const Locale('en'),
    child: Builder(
      builder: (BuildContext context) {
        return MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        );
      },
    ),
  );
}

class _StoryUnlockGateTestAssetLoader extends AssetLoader {
  const _StoryUnlockGateTestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final bool is_zh = locale.languageCode == 'zh';
    return <String, dynamic>{
      'short_story_read': <String, dynamic>{
        'locked_remaining_characters': is_zh
            ? '余下 {count} 字精彩内容等待解锁'
            : '{count} characters remain — unlock the rest of the story',
        'locked_remaining_words': is_zh
            ? '余下 {count} 个单词的精彩内容等待解锁'
            : '{count} words remain — unlock the rest of the story',
        'watch_ad_to_continue': is_zh ? '看广告继续阅读' : 'Watch an ad to continue',
      },
    };
  }
}
