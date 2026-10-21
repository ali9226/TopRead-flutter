// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'package:app/components/comment_list/widgets/comment_item.dart';
import 'package:app/components/comment_list/widgets/comment_input.dart';
import 'package:app/models/user_info.dart';
import 'package:app/pages/comics/widgets/comment_sheet/index.dart';
import 'package:app/pages/comics/widgets/comment_sheet/feedback.dart';
import 'package:app/pages/comics/comments/logic.dart';
import 'package:app/stores/user_information.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

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
  });
  setUp(() {
    Get.testMode = true;
    Get.put(
      UserInformation(token_writer: (_, _) async => true),
    ).saveUserInfo(UserInfo.fromJson({'id': 7, 'name': 'Reader'}));
  });
  tearDown(Get.reset);

  testWidgets('漫画评论底部弹窗保持键盘前后高度并可发送评论', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final rows = <Map<String, dynamic>>[
      {
        'id': 1,
        'user_id': 7,
        'nickname': 'Reader',
        'comment_content': 'Existing comic comment',
        'create_time': '2026-10-20T00:00:00Z',
      },
    ];
    final mutations = <Map<String, dynamic>>[];
    final reported_counts = <int>[];
    final logic = ComicCommentsLogic(
      comic_id: 42,
      token_reader: () async => 'test-session',
      require_login: () => true,
      requester: (action, params, {authorization_token}) async {
        if (action == 'add') {
          expect(authorization_token, 'test-session');
          mutations.add(params);
          rows.insert(0, {
            'id': 2,
            'user_id': 7,
            'nickname': 'Reader',
            'comment_content': params['comment_content'],
            'create_time': '2026-10-20T01:00:00Z',
          });
          return {'id': 2};
        }
        return {
          'list': List<Map<String, dynamic>>.from(rows),
          'total': rows.length,
          'comment_count': rows.length + 3,
        };
      },
    );
    addTearDown(logic.dispose);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        assetLoader: const _Assets(),
        startLocale: const Locale('en'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (page_context) => Center(
                  child: TextButton(
                    onPressed: () => show_comic_comment_sheet(
                      page_context,
                      comic_id: 42,
                      controller: logic,
                      on_count_changed: reported_counts.add,
                    ),
                    child: const Text('Open comments'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open comments'));
    await tester.pumpAndSettle();
    expect(reported_counts, [4]);
    expect(find.byType(CommentItem), findsOneWidget);
    expect(find.byType(CommentInput), findsOneWidget);
    final sheet = find.byKey(const ValueKey<String>('comic_comment_sheet'));
    final initial_bounds = tester.getRect(sheet);
    await tester.tap(
      find.byKey(const ValueKey<String>('comment_input_preview')),
    );
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.getRect(sheet), initial_bounds);
    await tester.enterText(
      find.byType(TextField).hitTestable(),
      'A shared comic comment',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('comment_send_button_editor')),
    );
    await tester.pumpAndSettle();
    expect(mutations, [
      {'comic_id': 42, 'comment_content': 'A shared comic comment'},
    ]);
    expect(find.text('A shared comic comment'), findsOneWidget);
    expect(reported_counts.last, 5);
    expect(logic.comment_count, 5);
    expect(tester.takeException(), isNull);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await tester.dragFrom(
      tester.getTopLeft(sheet) + const Offset(100, 20),
      const Offset(0, 700),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ComicCommentSheet), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  for (final dark in [false, true]) {
    testWidgets('空评论面板 320px 双倍字体 ${dark ? 'dark' : 'light'} 可唤起输入', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 720);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final logic = ComicCommentsLogic(
        comic_id: 42,
        token_reader: () async => 'test-session',
        requester: (_, _, {authorization_token}) async => {
          'list': [],
          'total': 0,
          'comment_count': 0,
        },
      );
      addTearDown(logic.dispose);
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          assetLoader: const _Assets(),
          startLocale: const Locale('en'),
          saveLocale: false,
          child: Builder(
            builder: (context) => MaterialApp(
              theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light,
              ),
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => show_comic_comment_sheet(
                      context,
                      comic_id: 42,
                      controller: logic,
                    ),
                    child: const Text('Open comments'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open comments'));
      await tester.pumpAndSettle();
      expect(find.byType(ComicCommentSheetFeedback), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.descendant(
          of: find.byType(ComicCommentSheetFeedback),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ComicCommentSheetFeedback),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
