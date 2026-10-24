// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app/components/comment_list/widgets/comment_input.dart';
import 'package:app/components/comment_list/widgets/comment_item.dart';
import 'package:app/components/comment_list/widgets/comment_skeleton.dart';
import 'package:app/models/user_info.dart';
import 'package:app/pages/comics/comments/logic.dart';
import 'package:app/pages/comics/detail/widgets/hot_comments/index.dart';
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

Map<String, dynamic> _comment(int id) => {
  'id': id,
  'user_id': 7,
  'nickname': 'Reader $id',
  'comment_content': 'A thoughtful comment about this comic $id',
  'like_count': id,
  'is_liked': false,
  'create_time': '2026-10-20T00:00:00Z',
};

Widget _host({
  required Widget child,
  String language = 'en',
  bool dark = false,
  double scale = 1,
}) => EasyLocalization(
  supportedLocales: [Locale(language)],
  startLocale: Locale(language),
  path: 'assets/i18n',
  assetLoader: const _Assets(),
  saveLocale: false,
  child: Builder(
    builder: (context) => MaterialApp(
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      theme: dark ? ThemeData.dark() : ThemeData.light(),
      home: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  ),
);

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

  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('热评仅按指定大小向服务端请求，完整评论与回复保留原分页顺序', () async {
    final requests = <Map<String, dynamic>>[];
    Future<Map<String, dynamic>> request(
      String action,
      Map<String, dynamic> params, {
      String? authorization_token,
    }) async {
      requests.add(Map.of(params));
      return {
        'list': [_comment(90), _comment(80), _comment(70)],
        'total': 100,
      };
    }

    final hot = ComicCommentsLogic(
      comic_id: 42,
      sort: 'hot',
      page_size: 3,
      requester: request,
    );
    final standard = ComicCommentsLogic(comic_id: 42, requester: request);
    addTearDown(hot.dispose);
    addTearDown(standard.dispose);
    await hot.load();
    expect(requests.single, {
      'comic_id': 42,
      'sort': 'hot',
      'page_size': 3,
      'page': 1,
    });
    expect(hot.items.map((comment) => comment.id), [90, 80, 70]);
    expect(hot.has_more, isTrue);
    await hot.replies(90);
    expect(requests.last['parent_id'], 90);
    expect(requests.last['page_size'], 20);
    expect(requests.last.containsKey('sort'), isFalse);
    await standard.load();
    expect(requests.last['page_size'], 20);
    expect(requests.last.containsKey('sort'), isFalse);
  });

  testWidgets('预览只显示前三条真实热评，点赞复用接口，全部及发表与回复都打开原弹窗', (tester) async {
    Get.put(
      UserInformation(token_writer: (_, _) async => true),
    ).saveUserInfo(UserInfo.fromJson({'id': 7, 'name': 'Reader'}));
    final queries = <Map<String, dynamic>>[];
    final likes = <Map<String, dynamic>>[];
    final counts = <int>[];
    var opened = 0;
    final logic = ComicCommentsLogic(
      comic_id: 42,
      sort: 'hot',
      page_size: 3,
      token_reader: () async => 'reader-session',
      require_login: () => true,
      requester: (action, params, {authorization_token}) async {
        if (action == 'like') {
          expect(authorization_token, 'reader-session');
          likes.add(params);
          return {'liked': true, 'like_count': 101};
        }
        queries.add(params);
        return {
          'list': [_comment(100), _comment(90), _comment(80), _comment(70)],
          'total': 25,
          'comment_count': 29,
        };
      },
    );
    addTearDown(logic.dispose);
    await tester.pumpWidget(
      _host(
        child: ComicHotComments(
          comic_id: 42,
          is_dark: false,
          controller: logic,
          on_comments: () => opened++,
          on_count_changed: counts.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CommentItem), findsNWidgets(3));
    expect(find.byType(CommentInput), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('comic 70'), findsNothing);
    expect(counts, [29]);
    expect(queries, hasLength(1));
    await tester.tap(find.byKey(const ValueKey('comment_like_100')));
    await tester.pumpAndSettle();
    expect(likes.single, {'comment_id': 100, 'liked': true});
    expect(logic.items.first.like_count, 101);
    await tester.tap(find.byKey(const ValueKey('comic_detail_comments')));
    await tester.tap(find.byKey(const ValueKey('comment_item_tap_100')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('comic_hot_comments_write')),
    );
    await tester.tap(find.byKey(const ValueKey('comic_hot_comments_write')));
    expect(opened, 3);
    expect(logic.replying, isNull);
    expect(queries, hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('失败可重试，空态能发表评论，弹窗关闭版本递增后刷新评论数', (tester) async {
    var requests = 0;
    var opened = 0;
    final counts = <int>[];
    final revision = ValueNotifier(0);
    addTearDown(revision.dispose);
    final logic = ComicCommentsLogic(
      comic_id: 42,
      sort: 'hot',
      page_size: 3,
      requester: (action, params, {authorization_token}) async {
        requests++;
        if (requests == 1) throw StateError('offline');
        return {
          'list': requests == 2 ? [] : [_comment(50)],
          'total': requests == 2 ? 0 : 1,
          'comment_count': requests == 2 ? 0 : 2,
        };
      },
    );
    addTearDown(logic.dispose);
    await tester.pumpWidget(
      _host(
        child: ValueListenableBuilder<int>(
          valueListenable: revision,
          builder: (_, value, _) => ComicHotComments(
            comic_id: 42,
            is_dark: false,
            controller: logic,
            refresh_revision: value,
            on_comments: () => opened++,
            on_count_changed: counts.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Comments could not be loaded. Please try again.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('comic_hot_comments_retry')));
    await tester.pumpAndSettle();
    expect(
      find.text('No comments yet. Share your first thought.'),
      findsOneWidget,
    );
    expect(counts, [0]);
    await tester.tap(find.byKey(const ValueKey('comic_hot_comments_write')));
    expect(opened, 1);
    revision.value++;
    await tester.pumpAndSettle();
    expect(find.byType(CommentItem), findsOneWidget);
    expect(counts, [0, 2]);
    expect(requests, 3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('切换作品后忽略旧作品请求，不向新作品回报旧总数', (tester) async {
    final pending = Completer<Map<String, dynamic>>();
    final current = ValueNotifier(1);
    final counts = <int>[];
    addTearDown(current.dispose);
    final first = ComicCommentsLogic(
      comic_id: 1,
      requester: (_, _, {authorization_token}) => pending.future,
    );
    final second = ComicCommentsLogic(
      comic_id: 2,
      requester: (_, _, {authorization_token}) async => {
        'list': [_comment(22)],
        'total': 1,
        'comment_count': 2,
      },
    );
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await tester.pumpWidget(
      _host(
        child: ValueListenableBuilder<int>(
          valueListenable: current,
          builder: (_, id, _) => ComicHotComments(
            comic_id: id,
            is_dark: false,
            controller: id == 1 ? first : second,
            on_comments: () {},
            on_count_changed: counts.add,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CommentSkeleton), findsOneWidget);
    current.value = 2;
    await tester.pumpAndSettle();
    pending.complete({
      'list': [_comment(11)],
      'total': 99,
      'comment_count': 99,
    });
    await tester.pumpAndSettle();
    expect(counts, [2]);
    expect(find.textContaining('comic 11'), findsNothing);
    expect(find.textContaining('comic 22'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('账号切换清理旧点赞并丢弃账号先前的异步响应', (tester) async {
    final user = Get.put(UserInformation(token_writer: (_, _) async => true));
    user.saveUserInfo(UserInfo.fromJson({'id': 7, 'name': 'First'}));
    final pending = Completer<Map<String, dynamic>>();
    final counts = <int>[];
    final tokens = <String?>[];
    final logic = ComicCommentsLogic(
      comic_id: 42,
      sort: 'hot',
      page_size: 3,
      token_reader: () async => 'first-session',
      requester: (_, params, {authorization_token}) {
        tokens.add(authorization_token);
        if (authorization_token == 'first-session') return pending.future;
        return Future.value({'list': [], 'total': 0});
      },
    );
    addTearDown(logic.dispose);
    await tester.pumpWidget(
      _host(
        child: ComicHotComments(
          comic_id: 42,
          is_dark: false,
          controller: logic,
          on_comments: () {},
          on_count_changed: counts.add,
        ),
      ),
    );
    await tester.pump();
    user.clearUserInfo();
    await tester.pumpAndSettle();
    pending.complete({
      'list': [
        {..._comment(1), 'is_liked': true},
      ],
      'total': 1,
    });
    await tester.pumpAndSettle();
    expect(tokens, containsAllInOrder(['first-session', '']));
    expect(find.byType(CommentItem), findsNothing);
    expect(counts, [0]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final scenario in [
    (language: 'zh', dark: false, width: 320.0, scale: 2.0),
    (language: 'en', dark: true, width: 430.0, scale: 1.0),
    (language: 'fr', dark: true, width: 320.0, scale: 2.0),
    (language: 'sw', dark: false, width: 600.0, scale: 2.0),
  ]) {
    testWidgets(
      '热评适配 ${scenario.language} 夜间${scenario.dark} 宽${scenario.width}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(scenario.width, 1200);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final logic = ComicCommentsLogic(
          comic_id: 42,
          sort: 'hot',
          page_size: 3,
          requester: (_, _, {authorization_token}) async => {
            'list': [_comment(300), _comment(200), _comment(100)],
            'total': 12345,
          },
        );
        addTearDown(logic.dispose);
        await tester.pumpWidget(
          _host(
            language: scenario.language,
            dark: scenario.dark,
            scale: scenario.scale,
            child: ComicHotComments(
              comic_id: 42,
              is_dark: scenario.dark,
              controller: logic,
              on_comments: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CommentItem), findsNWidgets(3));
        expect(
          tester
              .widgetList<CommentItem>(find.byType(CommentItem))
              .every((item) => item.is_dark == scenario.dark),
          isTrue,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
