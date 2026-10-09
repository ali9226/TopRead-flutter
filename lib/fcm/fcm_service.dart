// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app/fcm/register_token.dart';
import 'package:app/fcm/fcm_handler.dart';
import 'package:app/fcm/fcm_auth.dart';
import 'package:app/stores/user_information.dart';
import 'package:get/get.dart';
import 'package:app/util/device/app_environment.dart';
import 'package:app/util/log_util.dart';

/// 推送通知服务。
///
/// 负责：
/// 1. 获取 FCM Token 并注册到后端（不绑定用户）
/// 2. 处理前台/后台/终止状态的推送消息
/// 3. 本地通知展示（前台收到推送时）
///
/// 注意：
/// - Android 和 iOS 的通知权限都由登录、收藏等业务触发点统一处理。
/// - FCM 初始化本身不触发系统权限弹窗，避免与 UMP/ATT 启动流程连续弹窗。
class FcmService {
  /// 单例。
  static final FcmService _instance = FcmService._();
  factory FcmService() => _instance;
  FcmService._();

  /// Firebase Messaging 实例。
  ///
  /// 延迟获取，避免仅注册前台回调时提前访问尚未初始化的 Firebase。
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  /// 本地通知插件。
  final FlutterLocalNotificationsPlugin _local_notifications =
      FlutterLocalNotificationsPlugin();

  /// iOS 原生 App 图标角标通道。
  static const MethodChannel _badge_channel = MethodChannel(
    'com.topread.app/badge',
  );

  /// Android 通知渠道。
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'topread_push',
    'TopRead 推送通知',
    description: '接收小说更新、系统消息等推送通知',
    importance: Importance.high,
    playSound: true,
  );

  /// Token 刷新订阅（存引用以便取消，避免重复初始化导致回调执行两次）。
  StreamSubscription<String>? _token_refresh_sub;

  /// 前台消息订阅。
  StreamSubscription<RemoteMessage>? _on_message_sub;

  /// 点击通知打开 App 订阅。
  StreamSubscription<RemoteMessage>? _on_message_opened_sub;

  /// 合并并发初始化，关闭后通过代次废弃尚未完成的原生调用。
  Future<void>? _initialization;
  int _generation = 0;
  bool _initialized = false;

  /// 终止状态通知延迟导航的定时器，释放服务时同步取消。
  Timer? _initial_message_timer;

  /// 消息回调（外部可注册，处理点击推送后的页面跳转等逻辑）。
  void Function(Map<String, dynamic> data)? on_message_tap;

  /// 前台收到推送时的数据回调，用于补拉数据库权威未读数。
  void Function(Map<String, dynamic> data)? on_foreground_data;

  /// 初始化推送服务。
  ///
  /// 应在 main.dart 中 Firebase.initializeApp() 之后调用。
  /// 无论是否登录都会注册 Token（用于全量广播推送）。
  Future<void> init({
    @visibleForTesting Future<void> Function(String? token)? synchronize_token,
  }) {
    final Future<void>? pending = _initialization;
    if (pending != null) return pending;
    if (_initialized) return Future<void>.value();

    final int generation = ++_generation;
    final Future<void> initialization = _initialize(
      generation,
      synchronize_token,
    );
    _initialization = initialization;
    return initialization.whenComplete(() {
      if (identical(_initialization, initialization)) _initialization = null;
    });
  }

  Future<void> _initialize(
    int generation,
    Future<void> Function(String? token)? synchronize_token,
  ) async {
    // 设置默认的消息点击处理回调。
    on_message_tap ??= FcmHandler.onMessageTap;

    // 浏览器没有移动端本地通知插件；插件异常也不应阻止推送消息订阅。
    if (isNativeMobileApp) {
      try {
        await _init_local_notifications(generation);
      } catch (error) {
        logUtil(msg: 'FCM: 初始化本地通知失败: $error', type: 'e');
      }
    }
    if (generation != _generation) return;

    // 配置 iOS 前台通知展示方式。该调用不会触发系统权限弹窗。
    if (isIOSApp) {
      try {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (error) {
        logUtil(msg: 'FCM: 设置前台通知失败: $error', type: 'e');
      }
    }
    if (generation != _generation) return;

    // 监听 Token 刷新。
    _token_refresh_sub = _messaging.onTokenRefresh.listen(
      (String new_token) {
        if (generation != _generation) return;
        // 使用回调中的真实新 Token，避免重新读取时错过这一次刷新。
        unawaited(_synchronize_token(generation, new_token, synchronize_token));
      },
      onError: (Object error) {
        logUtil(msg: 'FCM: Token 刷新监听失败: $error', type: 'e');
      },
    );

    // 监听前台消息。
    _on_message_sub = FirebaseMessaging.onMessage.listen(
      _on_foreground_message,
    );

    // 监听后台消息点击（用户点击通知打开 App）。
    _on_message_opened_sub = FirebaseMessaging.onMessageOpenedApp.listen(
      _on_message_opened,
    );
    _initialized = true;

    // Token 获取和注册属于后台同步，不能阻塞消息接收或通知点击。
    unawaited(_synchronize_token(generation, null, synchronize_token));

    // 检查 App 是否通过点击通知启动（终止状态，始终触发导航）。
    RemoteMessage? initial_message;
    try {
      initial_message = await _messaging.getInitialMessage().timeout(
        const Duration(seconds: 10),
      );
    } catch (error) {
      logUtil(msg: 'FCM: 读取启动通知失败: $error', type: 'w');
    }
    if (generation != _generation) return;
    Map<String, dynamic>? launch_data = initial_message?.data;
    // 前台 FCM 生成的本地通知在 App 终止后启动，不会进入 Firebase
    // getInitialMessage，必须读取本地通知插件保留的启动 payload。
    if (launch_data == null && isNativeMobileApp) {
      try {
        final NotificationAppLaunchDetails? details = await _local_notifications
            .getNotificationAppLaunchDetails()
            .timeout(const Duration(seconds: 10));
        if (details?.didNotificationLaunchApp == true) {
          final String? payload = details?.notificationResponse?.payload;
          if (payload != null) {
            final dynamic decoded = jsonDecode(payload);
            if (decoded is Map)
              launch_data = Map<String, dynamic>.from(decoded);
          }
        }
      } catch (error) {
        logUtil(msg: 'FCM: 读取本地启动通知失败: $error', type: 'w');
      }
    }
    if (generation != _generation) return;
    if (launch_data != null) {
      final Map<String, dynamic> data = launch_data;
      _initial_message_timer = Timer(const Duration(seconds: 2), () {
        if (generation != _generation) return;
        logUtil(msg: 'FCM: 通过通知启动 App, data: $data');
        on_message_tap?.call(data);
      });
    }

    logUtil(msg: 'FCM: 推送通知服务初始化完成');
  }

  /// 注册新 Token 后重新绑定当前用户；身份操作仍由 FcmAuth 串行执行。
  Future<void> _synchronize_token(
    int generation,
    String? token,
    Future<void> Function(String? token)? synchronize_token,
  ) async {
    try {
      if (synchronize_token != null) {
        await synchronize_token(token);
        return;
      }
      await FcmRegisterToken.execute(token: token);
      if (generation != _generation || !Get.isRegistered<UserInformation>()) {
        return;
      }
      await FcmAuth.onLoginSuccess();
    } catch (error) {
      logUtil(msg: 'FCM: Token 同步失败: $error', type: 'e');
    }
  }

  /// 初始化本地通知插件。
  Future<void> _init_local_notifications(int generation) async {
    // Android 初始化设置。
    const AndroidInitializationSettings android_settings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 初始化设置。
    const DarwinInitializationSettings ios_settings =
        DarwinInitializationSettings(
          requestAlertPermission: false, // 由业务触发点通过 Firebase 统一请求
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings init_settings = InitializationSettings(
      android: android_settings,
      iOS: ios_settings,
    );

    await _local_notifications.initialize(
      settings: init_settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (generation != _generation) return;
        // 用户点击本地通知。
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = json.decode(response.payload!);
            on_message_tap?.call(data);
          } catch (e) {
            logUtil(msg: 'FCM: 解析通知 payload 失败: $e', type: 'e');
          }
        }
      },
    );

    // 创建 Android 通知渠道，启动阶段不主动请求通知权限。
    if (isAndroidApp) {
      final AndroidFlutterLocalNotificationsPlugin? android_plugin =
          _local_notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await android_plugin?.createNotificationChannel(_channel);
    }
  }

  /// 处理前台收到的推送消息。
  ///
  /// iOS 使用 Firebase 的系统前台展示能力，Android 使用本地通知展示。
  Future<void> _on_foreground_message(RemoteMessage message) async {
    logUtil(msg: 'FCM: 前台收到推送: ${message.messageId}');
    on_foreground_data?.call(message.data);

    // Web 不使用移动端本地通知插件。
    if (isWebBrowser) {
      return;
    }

    final RemoteNotification? notification = message.notification;
    final Map<String, dynamic> data = message.data;
    final String title =
        notification?.title ?? _read_notification_text(data, 'title');
    final String body =
        notification?.body ?? _read_notification_text(data, 'body');

    // iOS 的 notification 消息已由系统展示，此处不再重复创建通知。
    // data-only 消息没有 notification，继续使用本地通知兜底展示。
    if (isIOSApp && notification != null) {
      logUtil(msg: 'FCM: iOS 前台通知已交由系统展示: ${message.messageId}');
      return;
    }

    // notification-only 与 data-only 推送都缺少可展示内容时直接跳过。
    if (title.isEmpty && body.isEmpty) {
      logUtil(msg: 'FCM: 前台推送缺少 title/body，无法展示通知', type: 'w');
      return;
    }

    // 获取角标数量（从 data 中读取，默认为 1）。
    final int badge = _parse_badge(data);

    try {
      // Android 以及 iOS data-only 消息需要主动创建本地通知。
      await _local_notifications.show(
        id: _notification_id(message),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: isAndroidApp
              ? AndroidNotificationDetails(
                  _channel.id,
                  _channel.name,
                  channelDescription: _channel.description,
                  icon: '@mipmap/ic_launcher',
                  importance: Importance.high,
                  priority: Priority.high,
                  number: badge, // Android 角标数量
                )
              : null,
          iOS: isIOSApp
              ? DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                  badgeNumber: badge,
                )
              : null,
        ),
        payload: json.encode(data),
      );
      logUtil(msg: 'FCM: 前台本地通知展示成功: ${message.messageId}');
    } catch (e) {
      logUtil(msg: 'FCM: 前台本地通知展示失败: $e', type: 'e');
    }

    // 前台收到消息只负责展示本地通知。
    // 页面导航必须等待用户点击通知后，由通知点击回调触发。
  }

  /// 从 data-only 推送数据中读取通知文字。
  ///
  /// [data] FCM 自定义数据。
  /// [key] 需要读取的字段名，例如 title 或 body。
  String _read_notification_text(Map<String, dynamic> data, String key) {
    final dynamic value = data[key];
    return value is String ? value.trim() : '';
  }

  /// 生成 Android 本地通知 ID。
  ///
  /// 优先使用 FCM messageId，确保同一条消息拥有稳定 ID；
  /// messageId 缺失时使用消息对象的 hashCode。
  int _notification_id(RemoteMessage message) {
    final String? message_id = message.messageId;
    if (message_id == null || message_id.isEmpty) {
      return message.hashCode;
    }
    return message_id.hashCode;
  }

  /// 解析角标数量。
  ///
  /// 从推送数据中获取角标数量，默认为 1。
  int _parse_badge(Map<String, dynamic> data) {
    try {
      final dynamic badge_value = data['badge'];
      if (badge_value is int) return badge_value;
      if (badge_value is String) return int.tryParse(badge_value) ?? 1;
      return 1;
    } catch (e) {
      return 1;
    }
  }

  /// 处理用户点击通知打开 App（后台/终止状态）。
  ///
  /// Firebase 仅会在用户点击后台通知时触发 onMessageOpenedApp，
  /// 因此这里直接处理点击数据，不再通过生命周期状态二次判断。
  void _on_message_opened(RemoteMessage message) {
    logUtil(msg: 'FCM: 用户点击后台通知, data: ${message.data}');
    final Map<String, dynamic> data = message.data;
    on_message_tap?.call(data);
  }

  /// 释放全部推送订阅（App 退出或重新初始化前调用）。
  void dispose() {
    _generation++;
    _initialized = false;
    _initialization = null;
    _initial_message_timer?.cancel();
    _initial_message_timer = null;
    _token_refresh_sub?.cancel();
    _on_message_sub?.cancel();
    _on_message_opened_sub?.cancel();
    _token_refresh_sub = null;
    _on_message_sub = null;
    _on_message_opened_sub = null;
  }

  /// 取消所有本地通知。
  Future<void> cancel_all() async {
    await _local_notifications.cancelAll();
  }

  /// 更新 App 图标角标数量。
  ///
  /// [count] 未读消息数。0 表示清除角标。
  /// iOS 通过 UNUserNotificationCenter 直接同步角标。
  Future<void> update_badge(int count) async {
    if (isWebBrowser) return;

    final int normalized_count = count < 0 ? 0 : count;
    try {
      if (isNativeMobileApp) {
        await _badge_channel.invokeMethod<void>('setBadgeCount', <String, int>{
          'count': normalized_count,
        });
        logUtil(msg: 'FCM: App 图标角标已更新为 $normalized_count');
      }
      if (isAndroidApp && normalized_count == 0) {
        await _local_notifications.cancelAll();
      }
    } catch (e) {
      logUtil(msg: 'FCM: 更新角标失败: $e', type: 'w');
    }
  }
}
