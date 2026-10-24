import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app/components/expandable_synopsis/toggle_button.dart';
import 'package:app/components/work_about_section/index.dart';
import 'package:app/components/work_hero_stats/index.dart';
import 'package:app/models/short_story_item.dart';
import 'package:app/models/short_story_read_data.dart';
import 'package:app/pages/short_story_read/utils/reading_start_scroll_offset.dart';
import 'package:app/pages/short_story_read/widgets/introduction/index.dart';
import 'package:app/pages/short_story_read/widgets/introduction/style.dart';
import 'package:app/stores/user_information.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

const _preview_dir = String.fromEnvironment('SHORT_SYNOPSIS_PREVIEW_DIR');
const _english_description =
    'Mira returns to a city that has forgotten the morning. Every street '
    'leads to a different promise, and every door holds a memory. Beyond '
    'the harbor, a new journey begins beneath the last remaining star. '
    'To bring the sunrise home, she must find the people who still '
    'remember its name and follow a trail of letters across the sea.';
const _chinese_description =
    '米拉回到一座遗忘了清晨的城市。每条街道都通往不同的承诺，每一扇门后都藏着一段回忆。'
    '港口之外，最后一颗星辰下，一场新的旅程悄然开始。为了找回消失的日出，'
    '她要沿着漂洋过海的信件，寻找那些依然记得晨光的人。';

class _Assets extends AssetLoader {
  const _Assets();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
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
    if (_preview_dir.isNotEmpty) {
      for (final entry in {
        'Roboto': 'Arial Unicode',
        'Georgia': 'Times New Roman',
      }.entries) {
        final file = File(
          '/System/Library/Fonts/Supplemental/${entry.value}.ttf',
        );
        if (file.existsSync()) {
          await (FontLoader(entry.key)..addFont(
                Future.value(ByteData.sublistView(file.readAsBytesSync())),
              ))
              .load();
        }
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });
  setUp(() {
    Get.testMode = true;
    Get.put(UserInformation());
  });
  tearDown(Get.reset);

  for (final language in ['en', 'zh']) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.8]) {
        testWidgets('玻璃简介 $language/$dark/$scale 两行、连续动画与真实正文定位', (
          tester,
        ) async {
          final previous_shadows = debugDisableShadows;
          if (_preview_dir.isNotEmpty) debugDisableShadows = false;
          try {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = const Size(390, 1000);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPhysicalSize);
            final scroll = ScrollController();
            final body_key = GlobalKey();
            final story_id = ValueNotifier(7);
            addTearDown(scroll.dispose);
            addTearDown(story_id.dispose);
            final description = language == 'zh'
                ? _chinese_description
                : _english_description;
            await tester.pumpWidget(
              EasyLocalization(
                supportedLocales: [Locale(language)],
                startLocale: Locale(language),
                fallbackLocale: Locale(language),
                path: 'assets/i18n',
                saveLocale: false,
                assetLoader: const _Assets(),
                child: Builder(
                  builder: (context) => MaterialApp(
                    locale: context.locale,
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                    theme: ThemeData(
                      brightness: dark ? Brightness.dark : Brightness.light,
                    ),
                    home: MediaQuery(
                      data: MediaQueryData(
                        size: const Size(390, 1000),
                        textScaler: TextScaler.linear(scale),
                      ),
                      child: Scaffold(
                        body: RepaintBoundary(
                          key: const ValueKey('short_synopsis_capture'),
                          child: SingleChildScrollView(
                            controller: scroll,
                            child: Column(
                              children: [
                                ValueListenableBuilder<int>(
                                  valueListenable: story_id,
                                  builder: (_, id, _) => ShortStoryIntroduction(
                                    detail: ShortStoryReadData(
                                      id: id,
                                      title: language == 'zh'
                                          ? '在晨光消失之前'
                                          : 'Before the Morning Disappears',
                                      introduction: description,
                                      novel_language_id: '1',
                                      score: '9.6',
                                      read_count: 23000,
                                      comment_count: 531,
                                    ),
                                    catalog_entries: [
                                      ShortStoryItem(
                                        id: id,
                                        title: '',
                                        description: '',
                                        author_name: language == 'zh'
                                            ? '海边的写信人'
                                            : 'Mira Ellison',
                                        tags: const [],
                                        like_count: 0,
                                      ),
                                    ],
                                    tags: language == 'zh'
                                        ? ['奇幻', '冒险']
                                        : ['Fantasy', 'Adventure'],
                                    is_dark: dark,
                                    cover_image: const DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xff537b90),
                                            Color(0xff1f364f),
                                            Color(0xffcaab87),
                                          ],
                                        ),
                                      ),
                                    ),
                                    backdrop_image: const DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xff537b90),
                                            Color(0xff987161),
                                          ],
                                        ),
                                      ),
                                    ),
                                    on_back: () {},
                                    on_favorite: () {},
                                    on_read: () {},
                                  ),
                                ),
                                SizedBox(key: body_key, height: 0),
                                const SizedBox(height: 1600),
                              ],
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
            final viewport = find.byKey(
              const ValueKey('short_story_about_viewport'),
            );
            final toggle = find.byKey(
              const ValueKey('short_story_about_toggle'),
            );
            final text = tester.widget<Text>(find.text(description));
            expect(text.style!.color, Colors.white);
            expect(find.text(description), findsOneWidget);
            expect(find.byType(WorkAboutSection), findsNothing);
            expect(find.byType(WorkHeroStatsRow), findsNothing);
            expect(find.byType(BackdropFilter), findsOneWidget);
            expect(
              tester
                  .widget<SynopsisToggleButton>(
                    find.byType(SynopsisToggleButton),
                  )
                  .compact,
              isTrue,
            );
            final painter = TextPainter(
              text: TextSpan(text: description, style: text.style),
              textDirection: ui.TextDirection.ltr,
              textScaler: TextScaler.linear(scale),
              locale: Locale(language),
              maxLines: ShortStoryIntroductionStyle.synopsis_collapsed_lines,
            )..layout(maxWidth: tester.getSize(viewport).width);
            final collapsed_height = tester.getSize(viewport).height;
            expect(collapsed_height, closeTo(painter.height, 0.01));
            expect(painter.didExceedMaxLines, isTrue);
            painter.dispose();
            final collapsed_target = reading_start_scroll_offset(
              scroll_controller: scroll,
              body_start_key: body_key,
            )!;

            Future<void> capture(String state) async {
              if (_preview_dir.isEmpty || scale != 1) return;
              await tester.runAsync(() async {
                await Directory(_preview_dir).create(recursive: true);
                final boundary = tester.renderObject<RenderRepaintBoundary>(
                  find.byKey(const ValueKey('short_synopsis_capture')),
                );
                final image = await boundary.toImage(pixelRatio: 2);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await File(
                  '$_preview_dir/short_synopsis_${language}_${dark ? 'dark' : 'light'}_$state.png',
                ).writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }

            await capture('collapsed');
            await tester.ensureVisible(toggle);
            await tester.tap(toggle);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 80));
            final expanding_height = tester.getSize(viewport).height;
            expect(expanding_height, greaterThan(collapsed_height));
            final rotation = tester.widget<AnimatedRotation>(
              find.descendant(
                of: toggle,
                matching: find.byType(AnimatedRotation),
              ),
            );
            expect(rotation.turns, 0);
            await tester.pumpAndSettle();
            final expanded_height = tester.getSize(viewport).height;
            expect(expanding_height, lessThan(expanded_height));
            final expanded_target = reading_start_scroll_offset(
              scroll_controller: scroll,
              body_start_key: body_key,
            )!;
            expect(
              expanded_target - collapsed_target,
              closeTo(expanded_height - collapsed_height, 0.01),
            );
            scroll.jumpTo(0);
            await tester.pumpAndSettle();
            await capture('expanded');
            await tester.tapAt(
              tester.getTopLeft(viewport) + const Offset(12, 12),
            );
            await tester.tap(
              find.byKey(const ValueKey('short_story_about_header')),
            );
            await tester.pumpAndSettle();
            expect(tester.getSize(viewport).height, expanded_height);
            await tester.tap(toggle);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 80));
            final collapsing_height = tester.getSize(viewport).height;
            expect(collapsing_height, greaterThan(collapsed_height));
            expect(collapsing_height, lessThan(expanded_height));
            await tester.pumpAndSettle();
            expect(tester.getSize(viewport).height, collapsed_height);
            await tester.tap(toggle);
            await tester.pumpAndSettle();
            story_id.value = 8;
            await tester.pumpAndSettle();
            expect(tester.getSize(viewport).height, collapsed_height);
            scroll.jumpTo(
              reading_start_scroll_offset(
                scroll_controller: scroll,
                body_start_key: body_key,
              )!,
            );
            await tester.pumpAndSettle();
            expect(
              tester.getTopLeft(find.byKey(body_key)).dy,
              closeTo(0, 0.01),
            );
            expect(tester.takeException(), isNull);
          } finally {
            debugDisableShadows = previous_shadows;
          }
        });
      }
    }
  }
}
