// TODO 真实共用评论组件的嵌入、激活与分页回归；所有接口由本地假响应替代。
import 'dart:convert';
import 'dart:io';

import 'package:app/api/dio_client.dart';
import 'package:app/components/comment_list/index.dart';
import 'package:app/components/comment_list/style.dart';
import 'package:app/components/comment_list/widgets/comment_header.dart';
import 'package:app/components/comment_list/widgets/comment_input.dart';
import 'package:app/components/comment_list/widgets/comment_item.dart';
import 'package:app/components/comment_list/widgets/comment_skeleton.dart';
import 'package:app/components/no_internet/index.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/encryption/get_encryption.dart';
import 'package:app/util/language_util/language_change_handler.dart';
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
        jsonDecode(File('$path/en.json').readAsStringSync()) as Map,
      );
}

class _Device extends DeviceInfo {
  @override
  // TODO 只测试评论组件，不连接设备网络状态插件。
  // ignore: must_call_super
  void onInit() {}
}

/// TODO 保留接口回调，明确控制分页、错误和旧请求的完成顺序。
class _PendingRequest {
  _PendingRequest(this.options, this.handler);

  final RequestOptions options;
  final RequestInterceptorHandler handler;

  Map<String, dynamic> get parameters => Map<String, dynamic>.from(
    decryptEncryption(options.data['encryption'] as String) as Map,
  );

  void respond({
    List<int> ids = const <int>[],
    int total = 0,
    int? page,
    bool success = true,
  }) {
    final payload = base64Url
        .encode(
          utf8.encode(
            jsonEncode(<String, dynamic>{
              'status': success,
              'message': success ? '' : 'offline',
              'content': <String, dynamic>{
                'list': ids
                    .map(
                      (int id) => <String, dynamic>{
                        'id': id,
                        'user_id': id,
                        'avatar_url': '',
                        'nickname': 'Reader $id',
                        'comment_content': 'Comment $id. A memorable chapter.',
                        'create_time': '2026-11-05T00:00:00Z',
                        'like_count': 0,
                        'score': 5,
                        'replies': <dynamic>[],
                      },
                    )
                    .toList(),
                'total': total,
                'page': page ?? parameters['page'],
                'page_size': 20,
              },
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

/// TODO 保留同一个评论 State，模拟目录 Tab 的 keep-alive 激活切换。
class _Harness extends StatefulWidget {
  const _Harness({
    super.key,
    this.active = true,
    this.embedded = true,
    this.height = 420,
    required this.on_count_changed,
  });

  final bool active;
  final bool embedded;
  final double height;
  final ValueChanged<int> on_count_changed;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late bool active = widget.active;
  int novel_id = 1;

  void change_active(bool next) => setState(() => active = next);
  void change_novel(int next) => setState(() => novel_id = next);

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: SizedBox(
      key: const ValueKey('comment_embedded_bounds'),
      width: 320,
      height: widget.height,
      child: Align(
        alignment: Alignment.topCenter,
        child: CommentSheet(
          key: const ValueKey('shared_comment_sheet'),
          on_close: () {},
          novel_id: novel_id,
          embedded: widget.embedded,
          active: active,
          is_dark: true,
          on_count_changed: widget.on_count_changed,
        ),
      ),
    ),
  );
}

Future<_HarnessState> _mount(
  WidgetTester tester, {
  bool active = true,
  bool embedded = true,
  double height = 420,
  double scale = 1,
  required List<int> counts,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  final key = GlobalKey<_HarnessState>();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const <Locale>[Locale('en')],
      startLocale: const Locale('en'),
      fallbackLocale: const Locale('en'),
      path: 'assets/i18n',
      saveLocale: false,
      assetLoader: const _Assets(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(390, 844),
              textScaler: TextScaler.linear(scale),
            ),
            child: Scaffold(
              body: _Harness(
                key: key,
                active: active,
                embedded: embedded,
                height: height,
                on_count_changed: counts.add,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 10));
  await tester.pump(const Duration(milliseconds: 10));
  return key.currentState!;
}

Future<void> _flush_response(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 10));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 10));
}

ScrollController _list_controller(WidgetTester tester) {
  final list = find.descendant(
    of: find.byType(CommentSheet),
    matching: find.byType(ListView),
  );
  expect(list, findsOneWidget);
  return tester.widget<ListView>(list).controller!;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage_directory;
  late Interceptor interceptor;
  final requests = <_PendingRequest>[];
  final counts = <int>[];

  setUpAll(() async {
    storage_directory = Directory.systemTemp.createTempSync(
      'comment_embedded_',
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
  });

  setUp(() {
    Get.testMode = true;
    requests.clear();
    counts.clear();
    LanguageChangeHandler.sync_initial_language('en');
    Get.put<DeviceInfo>(_Device());
    Get.put<UserInformation>(UserInformation());
    interceptor = InterceptorsWrapper(
      onRequest: (options, handler) =>
          requests.add(_PendingRequest(options, handler)),
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
  });

  testWidgets('嵌入评论填满父级且不重复显示弹窗标题和关闭栏', (tester) async {
    await _mount(tester, height: 300, counts: counts);
    expect(requests, hasLength(1));
    expect(find.byType(CommentHeader), findsNothing);
    expect(tester.getSize(find.byType(CommentSheet)), const Size(320, 300));
    expect(
      tester.widget<CommentInput>(find.byType(CommentInput)).is_dark,
      isTrue,
    );
    requests.single.respond(total: 0);
    await _flush_response(tester);
    expect(
      find.text('No comments yet. Be the first to comment!'),
      findsOneWidget,
    );
    expect(counts, <int>[0]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('未激活时不请求，首次进入加载一次，切换后保留已有评论', (tester) async {
    final harness = await _mount(tester, active: false, counts: counts);
    expect(requests, isEmpty);
    harness.change_active(true);
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
    expect(requests, hasLength(1));
    requests.single.respond(ids: <int>[1], total: 1);
    await _flush_response(tester);
    expect(find.byType(CommentItem), findsOneWidget);
    expect(counts, <int>[1]);
    harness.change_active(false);
    await tester.pump();
    harness.change_active(true);
    await tester.pump(const Duration(milliseconds: 500));
    expect(requests, hasLength(1));
    expect(find.byType(CommentItem), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('分页请求只发一次，短页即停止继续分页即使total仍较大', (tester) async {
    await _mount(tester, counts: counts);
    requests.single.respond(
      ids: List<int>.generate(20, (index) => index + 1),
      total: 100,
    );
    await _flush_response(tester);
    final controller = _list_controller(tester);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump(const Duration(milliseconds: 10));
    expect(requests, hasLength(2));
    expect(requests.last.parameters['page'], 2);
    controller.jumpTo(controller.position.maxScrollExtent - 1);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump(const Duration(milliseconds: 10));
    expect(requests, hasLength(2));

    requests.last.respond(ids: <int>[21], total: 100, page: 2);
    await _flush_response(tester);
    controller.jumpTo(controller.position.maxScrollExtent - 1);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump(const Duration(seconds: 2));
    expect(requests, hasLength(2));
    expect(counts.first, 100);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('分页失败不自动循环，显式重试仍请求同一页', (tester) async {
    await _mount(tester, counts: counts);
    requests.single.respond(
      ids: List<int>.generate(20, (index) => index + 1),
      total: 100,
    );
    await _flush_response(tester);
    final controller = _list_controller(tester);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump(const Duration(milliseconds: 10));
    expect(requests, hasLength(2));
    requests.last.respond(success: false);
    await _flush_response(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(requests, hasLength(2));

    controller.jumpTo(controller.position.maxScrollExtent - 1);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump(const Duration(milliseconds: 10));
    expect(requests, hasLength(2));
    final retry = find.byKey(const ValueKey('comment_load_more_retry'));
    expect(retry, findsOneWidget);
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pump(const Duration(milliseconds: 10));
    expect(requests, hasLength(3));
    expect(requests.last.parameters['page'], 2);
    requests.last.respond(ids: <int>[21], total: 21, page: 2);
    await _flush_response(tester);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('换作品后丢弃旧请求，不覆盖新作品评论和数量', (tester) async {
    final harness = await _mount(tester, counts: counts);
    expect(requests, hasLength(1));
    harness.change_novel(2);
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
    expect(requests, hasLength(2));
    expect(requests.last.parameters['novel_id'], 2);
    requests.last.respond(ids: <int>[200], total: 1);
    await _flush_response(tester);
    requests.first.respond(ids: <int>[100], total: 50);
    await _flush_response(tester);
    expect(find.byKey(const ValueKey<int>(200)), findsOneWidget);
    expect(find.byKey(const ValueKey<int>(100)), findsNothing);
    expect(counts.last, 1);
    expect(counts, isNot(contains(50)));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('切换作品时旧分页响应不能混入新作品数据或总数', (tester) async {
    final harness = await _mount(tester, counts: counts);
    requests.single.respond(
      ids: List<int>.generate(20, (index) => index + 1),
      total: 100,
    );
    await _flush_response(tester);
    final controller = _list_controller(tester);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump(const Duration(milliseconds: 10));
    expect(requests, hasLength(2));
    expect(requests[1].parameters['novel_id'], 1);
    expect(requests[1].parameters['page'], 2);

    harness.change_novel(2);
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
    expect(requests, hasLength(3));
    expect(requests.last.parameters['novel_id'], 2);
    requests.last.respond(ids: <int>[200], total: 1);
    await _flush_response(tester);
    final counts_before_old_page = List<int>.of(counts);
    requests[1].respond(ids: <int>[21], total: 999, page: 2);
    await _flush_response(tester);

    expect(find.byKey(const ValueKey<int>(200)), findsOneWidget);
    expect(find.byKey(const ValueKey<int>(21)), findsNothing);
    expect(counts, counts_before_old_page);
    expect(counts.last, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Tab切出会关闭根Overlay编辑器和输入焦点', (tester) async {
    final harness = await _mount(tester, counts: counts);
    requests.single.respond();
    await _flush_response(tester);
    await tester.tap(find.byKey(const ValueKey('comment_input_preview')));
    await tester.pump();
    final editor = find.byType(TextField);
    expect(editor, findsOneWidget);
    expect(tester.widget<TextField>(editor).focusNode!.hasFocus, isTrue);
    expect(
      find.byKey(const ValueKey('comment_send_button_editor')).hitTestable(),
      findsOneWidget,
    );

    harness.change_active(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .every((field) => !(field.focusNode?.hasFocus ?? false)),
      isTrue,
    );
    expect(
      find.byKey(const ValueKey('comment_send_button_editor')).hitTestable(),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Tab切出也会关闭没有输入焦点的根Overlay表情面板', (tester) async {
    final harness = await _mount(tester, counts: counts);
    requests.single.respond();
    await _flush_response(tester);
    await tester.tap(
      find.byKey(const ValueKey('comment_emoji_button_preview')),
    );
    await tester.pumpAndSettle();
    final panel = find.byKey(const ValueKey('comment_emoji_panel'));
    expect(panel.hitTestable(), findsOneWidget);
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .every((field) => !(field.focusNode?.hasFocus ?? false)),
      isTrue,
    );
    harness.change_active(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(panel.hitTestable(), findsNothing);
    expect(
      find.byKey(const ValueKey('comment_send_button_editor')).hitTestable(),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final state in <String>['loading', 'empty', 'error']) {
    testWidgets('嵌入短视口180px及2倍文字下$state状态无溢出', (tester) async {
      await _mount(tester, height: 180, scale: 2, counts: counts);
      if (state == 'empty') requests.single.respond();
      if (state == 'error') requests.single.respond(success: false);
      if (state != 'loading') await _flush_response(tester);
      if (state == 'loading') {
        expect(find.byType(CommentSkeleton), findsOneWidget);
      }
      if (state == 'empty') {
        expect(
          find.text('No comments yet. Be the first to comment!'),
          findsOneWidget,
        );
      }
      if (state == 'error') expect(find.byType(NoInternet), findsOneWidget);
      expect(tester.getSize(find.byType(CommentSheet)), const Size(320, 180));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('原弹窗默认保留标题栏及屏幕比例高度', (tester) async {
    await _mount(tester, embedded: false, height: 760, counts: counts);
    expect(find.byType(CommentHeader), findsOneWidget);
    expect(
      tester.getSize(find.byType(CommentSheet)).height,
      closeTo(844 * CommentListStyle.max_height_ratio, .01),
    );
    requests.single.respond();
    await _flush_response(tester);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
