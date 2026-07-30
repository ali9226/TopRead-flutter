// ignore_for_file: non_constant_identifier_names

import 'package:app/websocket/websocket_connection_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebSocket 连接代次', () {
    test('旧连接关闭回调不能结束新连接', () {
      final WebSocketConnectionLifecycle lifecycle =
          WebSocketConnectionLifecycle();
      final int visitor_connection = lifecycle.begin();
      final int user_connection = lifecycle.begin();

      expect(lifecycle.finish(visitor_connection), isFalse);
      expect(lifecycle.is_active(user_connection), isTrue);
      expect(lifecycle.finish(user_connection), isTrue);
    });

    test('主动断开后忽略原连接迟到回调', () {
      final WebSocketConnectionLifecycle lifecycle =
          WebSocketConnectionLifecycle();
      final int connection_id = lifecycle.begin();

      lifecycle.invalidate();

      expect(lifecycle.is_active(connection_id), isFalse);
      expect(lifecycle.finish(connection_id), isFalse);
    });
  });
}
