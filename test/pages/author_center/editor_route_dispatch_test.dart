// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:app/api/dio_client.dart';
import 'package:app/pages/author_center/editor_route.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/long_novel_editor/index.dart';
import 'package:app/pages/published_long_novel_editor/index.dart';
import 'package:app/pages/short_novel_editor/index.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/stores/preference_store.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';

/// 复用仓库内真实多语种资源，保证编辑器构建时文案键都能取到。
class _Assets extends AssetLoader {
  const _Assets();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
}

/// 编辑器会读取设备主题，但本用例不关心网络状态，跳过原生连接订阅。
class _EditorDeviceInfo extends DeviceInfo {
  @override
  // ignore: must_call_super
  void onInit() {}
}

CreatorWorkDraft _draft({
  required CreatorWorkType work_type,
  required CreatorWorkStatus status,
  int? novel_id,
}) {
  return CreatorWorkDraft(
    local_id: 'route_work',
    novel_id: novel_id,
    title: '路由分发作品',
    introduction: '简介',
    work_type: work_type,
    is_completed: false,
    language_code: 'zh',
    category_ids: const <int>[],
    short_content: work_type == CreatorWorkType.short ? '短篇正文' : '',
    chapters: const <CreatorChapterDraft>[],
    status: status,
    release_mode: CreatorReleaseMode.immediate,
    scheduled_publish_time: null,
    update_time: DateTime(2026),
  );
}

Future<void> _pump_route(WidgetTester tester, CreatorWorkDraft work) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const <Locale>[Locale('zh')],
      path: 'assets/i18n',
      assetLoader: const _Assets(),
      startLocale: const Locale('zh'),
      saveLocale: false,
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: CreatorEditorRoute(
            work_type: work.work_type,
            novel_id: work.novel_id,
            initial_work: work,
          ),
        ),
      ),
    ),
  );
  // FutureBuilder 完成需要一帧微任务，再补一帧让编辑器完成首帧构建。
  await tester.pump();
  await tester.pump();
  // 已发布编辑器会发起读取请求，补帧让拦截器返回后清理异步回调。
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage_directory;
  late Interceptor interceptor;

  setUpAll(() async {
    // 使用独立空缓存，测试不会读写开发设备的真实登录凭证。
    storage_directory = Directory.systemTemp.createTempSync(
      'editor_route_dispatch_',
    );
    File('${storage_directory.path}/GetStorage.gs').writeAsStringSync('{}');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storage_directory.path,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (call) async => call.method == 'getAll' ? <String, Object>{} : true,
    );
    await GetStorage('GetStorage', storage_directory.path).initStorage;
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    // 在网络发送前直接返回空响应，禁止任何真实网络请求。
    interceptor = InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: <String, dynamic>{},
          ),
        );
      },
    );
    DioClient().instance.interceptors.add(interceptor);
    Get.testMode = true;
    Get.put<DeviceInfo>(_EditorDeviceInfo());
    Get.put(PreferenceStore());
    Get.put(LanguageStore(asset_language_code_list: const <String>['zh']));
  });

  tearDown(() {
    DioClient().instance.interceptors.remove(interceptor);
    Get.reset();
  });

  testWidgets('短篇作品分发到短篇编辑器', (tester) async {
    await _pump_route(
      tester,
      _draft(work_type: CreatorWorkType.short, status: CreatorWorkStatus.draft),
    );
    expect(find.byType(ShortNovelEditorPage), findsOneWidget);
    expect(find.byType(LongNovelEditorPage), findsNothing);
    expect(find.byType(PublishedLongNovelEditorPage), findsNothing);
  });

  testWidgets('未发布的长篇作品分发到长篇编辑器', (tester) async {
    await _pump_route(
      tester,
      _draft(
        work_type: CreatorWorkType.long,
        status: CreatorWorkStatus.draft,
        novel_id: 7,
      ),
    );
    expect(find.byType(LongNovelEditorPage), findsOneWidget);
    expect(find.byType(ShortNovelEditorPage), findsNothing);
    expect(find.byType(PublishedLongNovelEditorPage), findsNothing);
  });

  testWidgets('已发布长篇作品分发到已发布长篇编辑器', (tester) async {
    await _pump_route(
      tester,
      _draft(
        work_type: CreatorWorkType.long,
        status: CreatorWorkStatus.published,
        novel_id: 8,
      ),
    );
    expect(find.byType(PublishedLongNovelEditorPage), findsOneWidget);
    expect(find.byType(LongNovelEditorPage), findsNothing);
    expect(find.byType(ShortNovelEditorPage), findsNothing);
  });
}
