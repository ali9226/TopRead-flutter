// TODO 使用假接口验证刷新与旧请求的竞态，不访问真实服务。
import 'dart:convert';
import 'dart:io';

import 'package:app/api/dio_client.dart';
import 'package:app/components/recommend_book_card/animated_waterfall.dart';
import 'package:app/components/recommend_book_card/book_list_item.dart';
import 'package:app/models/home_classification.dart';
import 'package:app/models/recommend_ranking_item.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/index.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/home_store.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/stores/recommend_waterfall_store.dart';
import 'package:app/util/language_util/language_change_handler.dart';
import 'package:app/util/encryption/get_encryption.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';

class _Assets extends AssetLoader {
  const _Assets();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
}

// TODO 保留请求回调，测试明确控制新旧响应的到达顺序。
class _PendingRequest {
  _PendingRequest(this.options, this.handler);

  final RequestOptions options;
  final RequestInterceptorHandler handler;

  Map<String, dynamic> get parameters => Map<String, dynamic>.from(
    decryptEncryption(options.data['encryption'] as String) as Map,
  );

  void respond(List<int> ids) {
    final String payload = base64Url
        .encode(
          utf8.encode(
            jsonEncode(<String, dynamic>{
              'status': true,
              'content': ids
                  .map(
                    (int id) => <String, dynamic>{
                      'id': id,
                      'title': 'Book $id',
                      'cover_url': '',
                      'category_list': <String>[],
                    },
                  )
                  .toList(),
            }),
          ),
        )
        .replaceAll('=', '');
    handler.resolve(
      Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: <String, dynamic>{'encryption': 'e30.$payload.signature'},
      ),
    );
  }
}

BookListItem _item(int id) => BookListItem(
  id: 'recommend_$id',
  story_id: id,
  type: BookListItemType.book,
  title: 'Book $id',
  description: '',
  cover_url: '',
  cover_badge: '',
  cover_meta_text: '',
  tag_list: const <BookListTagItem>[],
  ad_image_url_list: const <String>[],
);

Future<GlobalKey<AnimatedRecommendWaterfallState>> _mount(
  WidgetTester tester, {
  Widget? child,
}) async {
  final GlobalKey<AnimatedRecommendWaterfallState> key = GlobalKey();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const <Locale>[Locale('en')],
      startLocale: const Locale('en'),
      fallbackLocale: const Locale('en'),
      path: 'assets/i18n',
      saveLocale: false,
      assetLoader: const _Assets(),
      child: Builder(
        builder: (BuildContext context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            body:
                child ??
                SingleChildScrollView(
                  child: AnimatedRecommendWaterfall(
                    key: key,
                    waterfall_id: 'home_recommend',
                    is_dark: false,
                  ),
                ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 10));
  await tester.pump(const Duration(milliseconds: 10));
  return key;
}

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage_directory;
  late Interceptor interceptor;
  late RecommendWaterfallStore store;
  final List<_PendingRequest> requests = <_PendingRequest>[];

  setUpAll(() async {
    storage_directory = Directory.systemTemp.createTempSync(
      'waterfall_refresh_',
    );
    File('${storage_directory.path}/GetStorage.gs').writeAsStringSync('{}');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storage_directory.path,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (_) async => <String, Object>{},
    );
    await GetStorage('GetStorage', storage_directory.path).initStorage;
    await EasyLocalization.ensureInitialized();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (_) async => <String>['wifi'],
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (_) async => null,
    );
  });

  setUp(() {
    Get.testMode = true;
    requests.clear();
    LanguageChangeHandler.sync_initial_language('en');
    Get.put<HomeBannerStore>(HomeBannerStore());
    Get.put<ProjectConfigStore>(ProjectConfigStore());
    store = Get.put<RecommendWaterfallStore>(RecommendWaterfallStore());
    interceptor = InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        requests.add(_PendingRequest(options, handler));
      },
    );
    DioClient().instance.interceptors.add(interceptor);
  });

  tearDown(() {
    DioClient().instance.interceptors.remove(interceptor);
    Get.reset();
  });

  tearDownAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      null,
    );
    await storage_directory.delete(recursive: true);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      null,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      null,
    );
  });

  testWidgets('刷新重取首屏并等待响应，旧分页不会追加到刷新结果', (WidgetTester tester) async {
    final RecommendWaterfallSession session = store.obtain('home_recommend');
    session.has_initialized = true;
    session.language_revision = LanguageChangeHandler.current_revision;
    session.is_initial_loading = false;
    session.items.add(_item(1));
    session.item_heights['recommend_1'] = 300;
    final key = await _mount(tester);
    expect(requests, isEmpty);

    final Future<void> old_page = key.currentState!.load_more();
    await tester.pump(const Duration(milliseconds: 10));
    expect(requests, hasLength(1));
    expect(requests[0].parameters['no_ids'], <int>[1]);

    bool refresh_completed = false;
    final Future<void> refresh = key.currentState!.refresh().then((_) {
      refresh_completed = true;
    });
    await tester.pump(const Duration(milliseconds: 10));
    expect(requests, hasLength(2));
    expect(requests[1].parameters.containsKey('no_ids'), isFalse);
    expect(session.items, isEmpty);
    expect(session.item_heights, isEmpty);
    expect(refresh_completed, isFalse);

    requests[1].respond(<int>[20]);
    await tester.pump(const Duration(milliseconds: 10));
    await refresh;
    requests[0].respond(<int>[2]);
    await tester.pump(const Duration(milliseconds: 10));
    await old_page;

    expect(refresh_completed, isTrue);
    expect(session.items.map((BookListItem item) => item.story_id), <int>[20]);
    expect(session.is_loading_more, isFalse);
    expect(session.is_initial_loading, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('首屏加载过程中下拉刷新会发起新请求并忽略旧首屏响应', (WidgetTester tester) async {
    final key = await _mount(tester);
    expect(requests, hasLength(1));
    final Future<void> refresh = key.currentState!.refresh();
    await tester.pump(const Duration(milliseconds: 10));
    expect(requests, hasLength(2));

    requests[1].respond(<int>[20]);
    await tester.pump(const Duration(milliseconds: 10));
    await refresh;
    requests[0].respond(<int>[1]);
    await tester.pump(const Duration(milliseconds: 10));

    final session = store.obtain('home_recommend');
    expect(session.items.map((BookListItem item) => item.story_id), <int>[20]);
    expect(session.is_initial_request_active, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('列表未挂载时失效缓存，下一次挂载重新加载而不恢复旧书籍', (WidgetTester tester) async {
    final session = store.obtain('home_recommend');
    session.has_initialized = true;
    session.language_revision = LanguageChangeHandler.current_revision;
    session.is_initial_loading = false;
    session.items.add(_item(1));

    store.invalidate('home_recommend');
    await _mount(tester);
    expect(requests, hasLength(1));
    expect(requests.single.parameters.containsKey('no_ids'), isFalse);
    requests.single.respond(<int>[20]);
    await tester.pump(const Duration(milliseconds: 10));

    expect(session.items.map((BookListItem item) => item.story_id), <int>[20]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('推荐页下拉同时刷新榜单与瀑布流，等待两处响应才收起刷新指示器', (WidgetTester tester) async {
    Get.put<DeviceInfo>(DeviceInfo());
    final HomeBannerStore home = Get.find<HomeBannerStore>();
    home.rankings_list.assignAll(const <HomeClassification>[
      HomeClassification(id: 148, title: 'Recommended'),
    ]);
    home.recommend_ranking_list.assignAll(<RecommendRankingItem>[
      RecommendRankingItem.from_json(<String, dynamic>{
        'id': 1,
        'title': 'Old ranking',
      }),
    ]);
    final RecommendWaterfallSession session = store.obtain('home_recommend');
    session.has_initialized = true;
    session.language_revision = LanguageChangeHandler.current_revision;
    session.is_initial_loading = false;
    session.items.addAll(
      List<BookListItem>.generate(6, (int i) => _item(i + 10)),
    );

    await _mount(tester, child: const RecommendTabContent());
    expect(requests, isEmpty);
    expect(find.byType(AnimatedRecommendWaterfall), findsOneWidget);
    final Finder scroll = find.byKey(const ValueKey('home_recommend_scroll'));
    expect(scroll, findsOneWidget);
    await tester.drag(scroll, const Offset(0, 350));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 10));

    expect(requests, hasLength(2));
    expect(
      requests.map((_PendingRequest request) => request.options.path),
      everyElement(endsWith('novel/recommend_ranking')),
    );
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);

    requests[0].respond(<int>[30]);
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 700));
    expect(home.recommend_ranking_list.single.id, 30);
    expect(session.is_initial_loading, isTrue);
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);

    requests[1].respond(<int>[40]);
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 700));
    expect(session.items.single.story_id, 40);
    expect(find.byType(RefreshProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
