// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app/fcm/register_token.dart';
import 'package:app/fcm/fcm_handler.dart';
import 'package:app/util/log_util.dart';

/// 推送通知服务。
///
/// 负责：
/// 1. 请求通知权限
/// 2. 获取 FCM Token 并注册到后端（不绑定用户）
/// 3. 处理前台/后台/终止状态的推送消息
/// 4. 本地通知展示（前台收到推送时）
class FcmService {
  /// 单例。
  static final FcmService _instance = FcmService._();
  factory FcmService() => _instance;
  FcmService._();

  /// Firebase Messaging 实例。
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// 本地通知插件。
  final FlutterLocalNotificationsPlugin _local_notifications =
      FlutterLocalNotificationsPlugin();

  /// Android 通知渠道。
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'topread_push',
    'TopRead 推送通知',
    description: '接收小说更新、系统消息等推送通知',
    importance: Importance.high,
    playSound: true,
  );

  /// 消息回调（外部可注册，处理点击推送后的页面跳转等逻辑）。
  void Function(Map<String, dynamic> data)? on_message_tap;

  /// 初始化推送服务。
  ///
  /// 应在 main.dart 中 Firebase.initializeApp() 之后调用。
  /// 无论是否登录都会注册 Token（用于全量广播推送）。
  Future<void> init() async {
    // 设置默认的消息点击处理回调。
    on_message_tap = FcmHandler.onMessageTap;

    // 请求通知权限。
    await _request_permission();

    // 初始化本地通知。
    await _init_local_notifications();

    // 获取 FCM Token 并注册到后端（不绑定用户）。
    await FcmRegisterToken.execute();

    // 监听 Token 刷新。
    _messaging.onTokenRefresh.listen((String new_token) {
      logUtil(msg: 'FCM Token 刷新: ${new_token.substring(0, 20)}...');
      FcmRegisterToken.execute();
    });

    // 监听前台消息。
    FirebaseMessaging.onMessage.listen(_on_foreground_message);

    // 监听后台消息点击（用户点击通知打开 App）。
    FirebaseMessaging.onMessageOpenedApp.listen(_on_message_opened);

    // 检查 App 是否通过点击通知启动（终止状态，始终触发导航）。
    final RemoteMessage? initial_message = await _messaging.getInitialMessage();
    if (initial_message != null) {
      Future.delayed(const Duration(seconds: 2), () {
        logUtil(msg: 'FCM: 通过通知启动 App, data: ${initial_message.data}');
        on_message_tap?.call(initial_message.data);
      });
    }

    logUtil(msg: 'FCM: 推送通知服务初始化完成');
  }

  /// 请求通知权限。
  Future<void> _request_permission() async {
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    logUtil(msg: 'FCM: 通知权限状态: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      logUtil(msg: 'FCM: 用户已授权通知');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      logUtil(msg: 'FCM: 用户已授予临时通知权限');
    } else {
      logUtil(msg: 'FCM: 用户拒绝了通知权限', type: 'w');
    }

    // iOS 由系统直接展示前台通知，点击行为仍交给 Firebase 处理。
    if (!kIsWeb && Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// 初始化本地通知插件。
  Future<void> _init_local_notifications() async {
    // Android 初始化设置。
    const AndroidInitializationSettings android_settings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 初始化设置。
    const DarwinInitializationSettings ios_settings =
        DarwinInitializationSettings(
          requestAlertPermission: false, // 已通过 Firebase 请求过
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

    // 创建 Android 通知渠道。
    if (!kIsWeb && Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? android_plugin =
          _local_notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      // Android 13+ 的本地通知权限需要由本地通知插件显式确认。
      final bool notifications_enabled =
          await android_plugin?.areNotificationsEnabled() ?? false;
      if (!notifications_enabled) {
        final bool permission_granted =
            await android_plugin?.requestNotificationsPermission() ?? false;
        logUtil(msg: 'FCM: Android 本地通知权限: $permission_granted');
      }

      await android_plugin?.createNotificationChannel(_channel);
    }
  }

  /// 处理前台收到的推送消息。
  ///
  /// iOS 使用 Firebase 的系统前台展示能力，Android 使用本地通知展示。
  Future<void> _on_foreground_message(RemoteMessage message) async {
    logUtil(msg: 'FCM: 前台收到推送: ${message.messageId}');

    // Web 不使用移动端本地通知插件。
    if (kIsWeb) {
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
    if (Platform.isIOS && notification != null) {
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
          android: Platform.isAndroid
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
          iOS: Platform.isIOS
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

  /// 取消所有本地通知。
  Future<void> cancel_all() async {
    await _local_notifications.cancelAll();
  }

  /// 更新 App 图标角标数量。
  ///
  /// [count] 未读消息数。0 表示清除角标。
  /// iOS 通过本地通知的 badge 字段更新；Android 部分启动器支持。
  Future<void> update_badge(int count) async {
    try {
      if (count <= 0) {
        await _local_notifications.cancelAll();
        return;
      }
      // iOS: 通过一个静默通知更新角标（不显示内容）
      if (!kIsWeb && Platform.isIOS) {
        await _local_notifications.show(
          id: 0,
          title: '',
          body: '',
          notificationDetails: NotificationDetails(
            iOS: DarwinNotificationDetails(
              presentAlert: false,
              presentBadge: true,
              presentSound: false,
              badgeNumber: count,
            ),
          ),
        );
      }
      // Android: 角标由系统通知渠道自动管理，无需手动更新
    } catch (e) {
      logUtil(msg: 'FCM: 更新角标失败: $e', type: 'w');
    }
  }
}
