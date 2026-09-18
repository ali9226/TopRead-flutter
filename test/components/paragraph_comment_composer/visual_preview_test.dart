// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/components/paragraph_comment_composer/index.dart';
import 'package:app/components/paragraph_comment_composer/style.dart';

/// 可选真实组件截图：fvm flutter test --no-pub
/// --dart-define=PARAGRAPH_PREVIEW_DIR=/tmp/novel-paragraph-preview
/// test/components/paragraph_comment_composer/visual_preview_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const String output_directory = String.fromEnvironment(
    'PARAGRAPH_PREVIEW_DIR',
  );
  setUpAll(() async {
    if (output_directory.isEmpty) return;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (MethodCall call) async =>
              call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
    // 仅截图模式读取系统字体；常规测试不依赖本机字体和输出目录。
    for (final entry in <String, String>{
      'PreviewLatin': const String.fromEnvironment(
        'PARAGRAPH_PREVIEW_LATIN_FONT',
        defaultValue: '/System/Library/Fonts/Supplemental/Arial.ttf',
      ),
      'PreviewChinese': const String.fromEnvironment(
        'PARAGRAPH_PREVIEW_CJK_FONT',
        defaultValue: '/System/Library/Fonts/STHeiti Light.ttc',
      ),
      'PreviewEmoji': const String.fromEnvironment(
        'PARAGRAPH_PREVIEW_EMOJI_FONT',
        defaultValue: '/System/Library/Fonts/Apple Color Emoji.ttc',
      ),
      'MaterialIcons':
          '.fvm/flutter_sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    }.entries) {
      final FontLoader loader = FontLoader(entry.key)
        ..addFont(
          Future<ByteData>.value(
            ByteData.sublistView(File(entry.value).readAsBytesSync()),
          ),
        );
      await loader.load();
    }
  });

  for (final bool is_dark in <bool>[false, true]) {
    final String language = is_dark ? 'en' : 'zh';
    testWidgets('生成 $language ${is_dark ? '夜间小屏' : '浅色'}段评截图', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = is_dark
          ? const Size(320, 640)
          : const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final GlobalKey preview_key = GlobalKey();
      final String quote = is_dark
          ? 'At the end of the quiet street, she finally saw the light in '
                'the old bookshop. All those years of waiting had led her '
                'back to this familiar door, and the story was only beginning.'
          : '她推开那扇旧木门，阳光沿着书架的缝隙落下来。多年以后，'
                '她依然记得那个午后，风翻动书页的声音，还有那句未曾说出口的告别。'
                '原来每一次重逢，都是另一个故事的开始。';
      await tester.pumpWidget(
        RepaintBoundary(
          key: preview_key,
          child: EasyLocalization(
            supportedLocales: <Locale>[Locale(language)],
            path: 'assets/i18n',
            assetLoader: const _PreviewAssetLoader(),
            startLocale: Locale(language),
            fallbackLocale: Locale(language),
            child: Builder(
              builder: (BuildContext context) => MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                theme: ThemeData(
                  brightness: is_dark ? Brightness.dark : Brightness.light,
                  fontFamily: 'PreviewLatin',
                  fontFamilyFallback: const <String>[
                    'PreviewChinese',
                    'PreviewEmoji',
                  ],
                  scaffoldBackgroundColor:
                      ParagraphCommentComposerStyle.surface(is_dark),
                ),
                home: Scaffold(
                  resizeToAvoidBottomInset: false,
                  body: Builder(
                    builder: (BuildContext context) => SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              is_dark ? 'The Old Bookshop' : '旧书店的午后',
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              quote,
                              style: const TextStyle(fontSize: 18, height: 1.8),
                            ),
                            TextButton(
                              onPressed: () => show_paragraph_comment_composer(
                                context,
                                quote: quote,
                                is_dark: is_dark,
                                on_send: (_, _) async => false,
                              ),
                              child: Text(tr('paragraph_comment.write')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('paragraph_comment_input')),
        is_dark
            ? 'This passage feels like coming home. I love the quiet detail.'
            : '这段描写好有画面感，仿佛自己也站在了那间书店里。',
      );
      // 第一帧建立按钮启用态，下一帧等待 Material 字色过渡完成。
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);
      Future<void> capture_preview(String suffix) async {
        final RenderRepaintBoundary boundary =
            preview_key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final ui.Image image = await boundary.toImage(pixelRatio: 2);
          final ByteData? png = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          final File output = File(
            '$output_directory/composer_${language}_${is_dark ? 'dark' : 'light'}$suffix.png',
          );
          await output.parent.create(recursive: true);
          await output.writeAsBytes(png!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture_preview('');
      // 先模拟已展开的软键盘，再切表情，核验等高替换及实体底部背景。
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('paragraph_comment_toggle_emoji')),
      );
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('comment_emoji_panel')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await capture_preview('_emoji');
    }, skip: output_directory.isEmpty);
  }
}

/// 直接加载项目翻译，截图同时核验真实多语种文案。
class _PreviewAssetLoader extends AssetLoader {
  const _PreviewAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
          as Map<String, dynamic>;
}
