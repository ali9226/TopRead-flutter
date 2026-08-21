import 'package:flutter/services.dart';

/// 接收原生端按实际广告文案测量出的短篇阅读广告高度。
class ShortStoryNativeAdLayoutBridge {
  ShortStoryNativeAdLayoutBridge._();

  /// Android 与 iOS 共用的原生广告布局通道。
  static const MethodChannel _channel = MethodChannel(
    'com.topread.novel/short_story_native_ad_layout',
  );

  /// 各广告实例的高度监听器。
  static final Map<String, void Function(double height, int token)> _listeners =
      <String, void Function(double height, int token)>{};

  /// 下一个广告实例序号。
  static int _next_slot_sequence = 0;

  /// 通道是否已经注册全局回调。
  static bool _is_initialized = false;

  /// 创建当前进程内唯一的广告槽位标识。
  static String create_slot_id() {
    return 'short_story_native_ad_${_next_slot_sequence++}';
  }

  /// 注册指定广告槽位的高度回调。
  static void register(
    String slot_id,
    void Function(double height, int token) listener,
  ) {
    _ensure_initialized();
    _listeners[slot_id] = listener;
  }

  /// 移除已经销毁的广告槽位回调。
  static void unregister(String slot_id) {
    _listeners.remove(slot_id);
  }

  /// 仅初始化一次原生方法通道，避免多个广告实例互相覆盖回调。
  static void _ensure_initialized() {
    if (_is_initialized) return;
    _is_initialized = true;
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method != 'onNativeAdLayout') return;
      final Object? raw_arguments = call.arguments;
      if (raw_arguments is! Map<Object?, Object?>) return;

      final String? slot_id = raw_arguments['slotId'] as String?;
      final num? raw_height = raw_arguments['viewHeight'] as num?;
      final num? raw_token = raw_arguments['layoutToken'] as num?;
      if (slot_id == null || raw_height == null || raw_token == null) return;

      final double height = raw_height.toDouble();
      if (!height.isFinite || height <= 0) return;
      _listeners[slot_id]?.call(height, raw_token.toInt());
    });
  }
}
