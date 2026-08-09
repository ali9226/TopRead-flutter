// ignore_for_file: non_constant_identifier_names

import 'package:app/stores/authorized_login_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthorizedLoginStore 认证互斥锁', () {
    test('同一时间只允许一个认证流程占用', () {
      final AuthorizedLoginStore store = AuthorizedLoginStore();

      expect(store.try_start_authentication('google'), isTrue);
      expect(store.loading.value, isTrue);
      expect(store.loading_platform.value, 'google');

      expect(store.try_start_authentication('apple'), isFalse);
      expect(store.loading_platform.value, 'google');
    });

    test('非当前流程不能释放认证锁', () {
      final AuthorizedLoginStore store = AuthorizedLoginStore();

      expect(store.try_start_authentication('apple'), isTrue);
      store.finish_authentication('google');

      expect(store.loading.value, isTrue);
      expect(store.loading_platform.value, 'apple');

      store.finish_authentication('apple');
      expect(store.loading.value, isFalse);
      expect(store.loading_platform.value, isEmpty);
    });

    test('认证类型会被规范化且空类型不能占用', () {
      final AuthorizedLoginStore store = AuthorizedLoginStore();

      expect(store.try_start_authentication('  Google  '), isTrue);
      expect(store.loading_platform.value, 'google');
      store.finish_authentication(' GOOGLE ');

      expect(store.loading.value, isFalse);
      expect(store.try_start_authentication('  '), isFalse);
    });
  });
}
