// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'package:app/components/comment_list/widgets/comment_item.dart';
import 'package:app/components/comment_list/widgets/comment_input.dart';
import 'package:app/models/user_info.dart';
import 'package:app/pages/comics/comments/index.dart';
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

  testWidgets('嵌入评论复用小说组件、继承协调滚动并可真正发送评论', (tester) async {
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
              body: NestedScrollView(
                headerSliverBuilder: (_, _) => [
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
                body: ComicCommentsPage(
                  comic_id: 42,
                  controller: logic,
                  embedded: true,
                  on_total_changed: reported_counts.add,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(reported_counts, [4]);
    expect(find.byType(CommentItem), findsOneWidget);
    expect(find.byType(CommentInput), findsOneWidget);
    final list = tester.widget<ListView>(
      find.byKey(const PageStorageKey<String>('comic_comments_42_0')),
    );
    expect(list.primary, isTrue);
    expect(list.controller, isNull);
    await tester.tap(
      find.byKey(const ValueKey<String>('comment_input_preview')),
    );
    await tester.pumpAndSettle();
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
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
