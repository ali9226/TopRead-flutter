// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/fcm/fcm_service.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel messaging_channel = MethodChannel(
    'plugins.flutter.io/firebase_messaging',
  );
  final FcmService service = FcmService();
  Map<String, dynamic>? initial_message;
  Completer<dynamic>? initial_completer;

  Future<void> emit(String method, dynamic arguments) async {
    final Completer<void> completed = Completer<void>();
    binding.defaultBinaryMessenger.handlePlatformMessage(
      messaging_channel.name,
      messaging_channel.codec.encodeMethodCall(MethodCall(method, arguments)),
      (_) => completed.complete(),
    );
    await completed.future;
    await Future<void>.delayed(Duration.zero);
  }

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
  });

  setUp(() {
    // 桌面/浏览器分支无需移动端本地通知插件。
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    initial_message = null;
    initial_completer = null;
    service.dispose();
    service.on_message_tap = null;
    service.on_foreground_data = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(messaging_channel, (
      call,
    ) async {
      if (call.method == 'Messaging#getInitialMessage') {
        return initial_completer?.future ?? initial_message;
      }
      return null;
    });
  });

  tearDown(() {
    service.dispose();
    debugDefaultTargetPlatformOverride = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      messaging_channel,
      null,
    );
  });

  test('Token 注册未结束仍接收前台推送和通知点击', () async {
    final Completer<void> registration = Completer<void>();
    int foreground_count = 0;
    int tap_count = 0;
    service.on_foreground_data = (_) => foreground_count++;
    service.on_message_tap = (_) => tap_count++;
    await service.init(synchronize_token: (_) => registration.future);

    await emit('Messaging#onMessage', {
      'data': <String, dynamic>{'id': '1'},
    });
    await emit('Messaging#onMessageOpenedApp', {
      'data': <String, dynamic>{'id': '1'},
    });
    expect(foreground_count, 1);
    expect(tap_count, 1);
    registration.complete();
  });

  test('并发及重复初始化只订阅和同步一次', () async {
    initial_completer = Completer<dynamic>();
    int registration_count = 0;
    int foreground_count = 0;
    service.on_foreground_data = (_) => foreground_count++;
    final first = service.init(
      synchronize_token: (_) async => registration_count++,
    );
    final second = service.init(
      synchronize_token: (_) async => registration_count++,
    );
    initial_completer!.complete(null);
    await Future.wait([first, second]);
    await service.init(synchronize_token: (_) async => registration_count++);
    await emit('Messaging#onMessage', {'data': <String, dynamic>{}});

    expect(registration_count, 1);
    expect(foreground_count, 1);
  });

  test('刷新直接同步短 Token，不重新读取或截取越界', () async {
    final List<String?> tokens = [];
    await service.init(synchronize_token: (token) async => tokens.add(token));
    await emit('Messaging#onTokenRefresh', 'short');

    expect(tokens, [null, 'short']);
  });

  testWidgets('释放服务取消启动通知延迟跳转', (tester) async {
    initial_message = {
      'data': <String, dynamic>{'id': '1'},
    };
    int tap_count = 0;
    service.on_message_tap = (_) => tap_count++;
    await service.init(synchronize_token: (_) async {});
    service.dispose();
    await tester.pump(const Duration(seconds: 3));

    expect(tap_count, 0);
    debugDefaultTargetPlatformOverride = null;
  });

  test('关闭后迟到启动消息不重新订阅或跳转', () async {
    initial_completer = Completer<dynamic>();
    int tap_count = 0;
    service.on_message_tap = (_) => tap_count++;
    final pending = service.init(synchronize_token: (_) async {});
    service.dispose();
    initial_completer!.complete({
      'data': <String, dynamic>{'id': '1'},
    });
    await pending;
    await emit('Messaging#onMessageOpenedApp', {'data': <String, dynamic>{}});

    expect(tap_count, 0);
  });

  test('Token 同步异常不会终止消息监听', () async {
    int foreground_count = 0;
    service.on_foreground_data = (_) => foreground_count++;
    await service.init(
      synchronize_token: (_) async => throw StateError('offline'),
    );
    await emit('Messaging#onMessage', {'data': <String, dynamic>{}});

    expect(foreground_count, 1);
  });

  test('本地通知插件保留的回调在服务关闭后不触发旧导航', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    final previous_platform = FlutterLocalNotificationsPlatform.instance;
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'initialize' ? true : null,
    );
    addTearDown(() {
      FlutterLocalNotificationsPlatform.instance = previous_platform;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });
    int tap_count = 0;
    service.on_message_tap = (_) => tap_count++;
    await service.init(synchronize_token: (_) async {});

    Future<void> tap() async {
      final Completer<void> completed = Completer();
      binding.defaultBinaryMessenger.handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(
          const MethodCall('didReceiveNotificationResponse', {
            'notificationId': 1,
            'notificationResponseType': 0,
            'payload': '{"id":"1"}',
          }),
        ),
        (_) => completed.complete(),
      );
      await completed.future;
    }

    await tap();
    expect(tap_count, 1);
    service.dispose();
    await tap();
    expect(tap_count, 1);
  });

  testWidgets('本地通知在终止状态启动 App 时恢复点击 payload', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'initialize') return true;
      if (call.method == 'getNotificationAppLaunchDetails') {
        return {
          'notificationLaunchedApp': true,
          'notificationResponse': {
            'notificationId': 1,
            'notificationResponseType': 0,
            'payload': '{"id":"1"}',
          },
        };
      }
      return null;
    });
    addTearDown(
      () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final List<Map<String, dynamic>> taps = [];
    service.on_message_tap = taps.add;
    await service.init(synchronize_token: (_) async {});
    await tester.pump(const Duration(seconds: 2));

    expect(taps, [
      {'id': '1'},
    ]);
    service.dispose();
    debugDefaultTargetPlatformOverride = null;
  });
}
