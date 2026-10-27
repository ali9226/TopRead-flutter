import 'dart:async';

import 'package:app/api/results_type.dart';
import 'package:app/models/novel_info.dart';
import 'package:app/components/reader_top_bar/action_button.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/pages/read/widgets/navigation_bars/top/index.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _ControlledInteractions extends Logic {
  _ControlledInteractions(NovelReadingStore store)
    : super(
        story_id: 1,
        story_title: 'State isolation',
        reading_store: store,
        initial_body_font_size: 18,
        initial_auto_read_speed: 0.2,
      );

  final requests = <String, Completer<ResultsType<Map<String, dynamic>>>>{};

  @override
  Future<ResultsType<Map<String, dynamic>>> request_read_interaction(
    String path,
  ) {
    if (requests.containsKey(path)) {
      throw StateError('Duplicate in-flight request');
    }
    return (requests[path] = Completer<ResultsType<Map<String, dynamic>>>())
        .future;
  }
}

ResultsType<Map<String, dynamic>> result({
  required bool status,
  Map<String, dynamic>? content,
}) => ResultsType<Map<String, dynamic>>()
  ..status = status
  ..content = content;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late NovelReadingStore store;
  late _ControlledInteractions logic;

  setUp(() {
    store = NovelReadingStore();
    logic = _ControlledInteractions(store);
    store.set_novel_info(
      NovelInfo.from_json({
        'id': '1',
        'title': 'State isolation',
        'like': false,
        'favorite': false,
        'like_count': '2',
        'favorite_count': '3',
      }),
    );
    logic.like_count.value = 2;
  });
  tearDown(() => logic.onClose());

  testWidgets('顶部收藏立即显示乐观星形且阻止连点，失败回退保留并发点赞', (tester) async {
    Get.put(ProjectConfigStore());
    addTearDown(Get.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Obx(
                () => ReadTopBar(
                  is_dark: false,
                  show: true,
                  on_back: () {},
                  on_favorite_tap: () => unawaited(logic.toggle_favorite()),
                  on_share: () {},
                  is_favorited: logic.is_favorited.value,
                  is_favorite_loading: logic.is_favorite_loading.value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final favorite = find.byType(ReaderTopBarAction).at(1);
    await tester.tap(favorite);
    await tester.pump();
    expect(tester.widget<ReaderTopBarAction>(favorite).selected, isTrue);
    expect(tester.widget<ReaderTopBarAction>(favorite).on_pressed, isNull);
    expect(tester.widget<ReaderTopBarAction>(favorite).ripple, isFalse);
    final favorite_button = tester.widget<IconButton>(
      find.descendant(of: favorite, matching: find.byType(IconButton)),
    );
    expect(favorite_button.style!.splashFactory, NoSplash.splashFactory);
    expect(
      favorite_button.style!.overlayColor!.resolve({WidgetState.pressed}),
      Colors.transparent,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SvgIcon && widget.name == 'user_selected',
      ),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(favorite);
    expect(logic.requests.length, 1);
    final liking = logic.toggle_like();
    logic.requests['novel_like/click']!.complete(
      result(status: true, content: {'like': true}),
    );
    await liking;
    logic.requests['novel_favorite/click']!.complete(result(status: false));
    await tester.pump();
    expect(tester.widget<ReaderTopBarAction>(favorite).selected, isFalse);
    expect(tester.widget<ReaderTopBarAction>(favorite).on_pressed, isNotNull);
    expect(store.novel_info.value!.is_liked, isTrue);
    expect(store.novel_info.value!.like_count, '3');
    expect(store.novel_info.value!.favorite_count, '3');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('收藏与点赞并发时，收藏失败只回退星形，不撤销已成功的爱心和点赞数', () async {
    final saving = logic.toggle_favorite();
    await logic.toggle_favorite();
    expect(logic.requests.length, 1, reason: '收藏在途禁止连点');
    expect(logic.is_favorited.value, isTrue);
    final liking = logic.toggle_like();
    logic.requests['novel_like/click']!.complete(
      result(status: true, content: {'like': true}),
    );
    await liking;
    logic.requests['novel_favorite/click']!.complete(result(status: false));
    expect(await saving, isNull);
    expect(logic.is_favorited.value, isFalse);
    expect(logic.is_liked.value, isTrue);
    expect(store.novel_info.value!.is_favorited, isFalse);
    expect(store.novel_info.value!.favorite_count, '3');
    expect(store.novel_info.value!.is_liked, isTrue);
    expect(store.novel_info.value!.like_count, '3');
  });

  test('收藏服务端纠正结果保留后来点赞，未实际改变收藏不重复扣减计数', () async {
    final saving = logic.toggle_favorite();
    final liking = logic.toggle_like();
    logic.requests['novel_like/click']!.complete(
      result(status: true, content: {'like': true}),
    );
    await liking;
    logic.requests['novel_favorite/click']!.complete(
      result(status: true, content: {'favorite': false}),
    );
    expect(await saving, isFalse);
    expect(store.novel_info.value!.favorite_count, '3');
    expect(store.novel_info.value!.is_favorited, isFalse);
    expect(store.novel_info.value!.is_liked, isTrue);
    expect(store.novel_info.value!.like_count, '3');
  });

  test('点赞服务器纠正保持原数量，不能修改已收藏状态', () async {
    logic.is_favorited.value = true;
    store.set_novel_info(
      store.novel_info.value!.replace_favorite(favorited: true, count: '3'),
    );
    final liking = logic.toggle_like();
    logic.requests['novel_like/click']!.complete(
      result(status: true, content: {'like': false}),
    );
    await liking;
    expect(logic.like_count.value, 2);
    expect(store.novel_info.value!.like_count, '2');
    expect(store.novel_info.value!.is_liked, isFalse);
    expect(store.novel_info.value!.is_favorited, isTrue);
  });
}
