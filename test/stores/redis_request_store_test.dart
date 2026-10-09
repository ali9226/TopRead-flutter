// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/stores/authorized_login_store.dart';
import 'package:app/stores/redis_request.dart';
import 'package:app/util/language_util/language_change_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(AuthorizedLoginStore());
    LanguageChangeHandler.sync_initial_language('en');
  });
  tearDown(() {
    Get.reset();
    LanguageChangeHandler.sync_initial_language('en');
  });

  test('写缓存期间切换语言不能分发旧语言配置，合并刷新使用最新语言', () async {
    final Completer<void> first_write = Completer<void>();
    final Completer<void> write_started = Completer<void>();
    int request_count = 0;
    int write_count = 0;
    final store = RedisRequestStore(
      raw_json_loader: () async =>
          _configuration(++request_count == 1 ? 'old' : 'new'),
      cache_writer: (_) {
        if (++write_count != 1) return Future<void>.value();
        write_started.complete();
        return first_write.future;
      },
    );
    addTearDown(store.onClose);
    final Future<bool> first = store.fetch_redis_data();
    await write_started.future;
    LanguageChangeHandler.sync_initial_language('zh');
    final Future<bool> second = store.fetch_redis_data();
    final List<String> displayed_titles = [];
    final Worker watcher = ever(
      Get.find<AuthorizedLoginStore>().rotation_list,
      (_) => displayed_titles.addAll(
        Get.find<AuthorizedLoginStore>().rotation_list.map(
          (item) => item.title,
        ),
      ),
    );
    addTearDown(watcher.dispose);
    first_write.complete();

    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(request_count, 2);
    expect(displayed_titles, isNot(contains('old')));
    expect(Get.find<AuthorizedLoginStore>().rotation_list.single.title, 'new');
  });

  test('关闭控制器后缓存写入完成不能分发旧配置', () async {
    final Completer<void> cache_write = Completer<void>();
    final Completer<void> write_started = Completer<void>();
    final store = RedisRequestStore(
      raw_json_loader: () async => _configuration('old'),
      cache_writer: (_) {
        write_started.complete();
        return cache_write.future;
      },
    );
    final Future<bool> request = store.fetch_redis_data();
    await write_started.future;
    store.onClose();
    cache_write.complete();

    expect(await request, isFalse);
    expect(Get.find<AuthorizedLoginStore>().rotation_list, isEmpty);
    expect(await store.fetch_redis_data(), isFalse);
  });

  testWidgets('请求成功取消原失败重试定时器', (tester) async {
    int count = 0;
    final store = RedisRequestStore(
      raw_json_loader: () async =>
          ++count == 1 ? null : _configuration('ready'),
      cache_writer: (_) async {},
    );
    await store.fetch_redis_data();
    expect(await store.fetch_redis_data(), isTrue);
    await tester.pump(const Duration(seconds: 6));
    store.onClose();

    expect(count, 2);
  });

  testWidgets('关闭控制器取消失败重试和等待合并刷新', (tester) async {
    int count = 0;
    final Completer<Map<String, dynamic>?> first_response = Completer();
    final store = RedisRequestStore(
      raw_json_loader: () {
        count++;
        return first_response.future;
      },
    );
    final Future<bool> first = store.fetch_redis_data();
    final Future<bool> pending = store.fetch_redis_data();
    store.onClose();
    expect(await pending, isFalse);
    first_response.complete(null);
    expect(await first, isFalse);
    await tester.pump(const Duration(seconds: 6));

    expect(count, 1);
  });
}

Map<String, dynamic> _configuration(String title) => {
  'rotation_list': [
    {'id': 1, 'type': 23, 'title': title},
  ],
};
