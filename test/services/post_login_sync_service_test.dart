// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/services/post_login_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('登录后同步任务不会等待外部服务完成', () async {
    final Completer<void> websocket_completer = Completer<void>();
    final Completer<void> message_completer = Completer<void>();
    final Completer<void> fcm_completer = Completer<void>();
    int started_task_count = 0;

    PostLoginSyncService.start(
      websocket_sync: () {
        started_task_count++;
        return websocket_completer.future;
      },
      message_sync: () {
        started_task_count++;
        return message_completer.future;
      },
      fcm_sync: () {
        started_task_count++;
        return fcm_completer.future;
      },
    );

    expect(started_task_count, 3);

    websocket_completer.complete();
    message_completer.complete();
    fcm_completer.complete();
    await Future<void>.delayed(Duration.zero);
  });

  test('单个同步任务失败不会产生未处理异步异常', () async {
    PostLoginSyncService.start(
      websocket_sync: () async => throw StateError('websocket failed'),
      message_sync: () async {},
      fcm_sync: () async {},
    );

    await Future<void>.delayed(Duration.zero);
  });
}
