import 'dart:async';

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

  /// 各广告实例的媒体素材类型监听器。
  static final Map<String, void Function(bool is_video, int token)>
  _media_type_listeners = <String, void Function(bool is_video, int token)>{};

  /// 各广告实例的视频播放状态监听器。
  static final Map<
    String,
    void Function(String playback_state, bool? is_muted, int token)
  >
  _video_playback_listeners =
      <
        String,
        void Function(String playback_state, bool? is_muted, int token)
      >{};

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
    void Function(double height, int token) listener, {
    void Function(bool is_video, int token)? media_type_listener,
    void Function(String playback_state, bool? is_muted, int token)?
    video_playback_listener,
  }) {
    _ensure_initialized();
    _listeners[slot_id] = listener;
    if (media_type_listener != null) {
      _media_type_listeners[slot_id] = media_type_listener;
    }
    if (video_playback_listener != null) {
      _video_playback_listeners[slot_id] = video_playback_listener;
    }
  }

  /// 移除已经销毁的广告槽位回调。
  static void unregister(String slot_id) {
    _listeners.remove(slot_id);
    _media_type_listeners.remove(slot_id);
    _video_playback_listeners.remove(slot_id);
    unawaited(_clear_native_media_state(slot_id));
  }

  /// 主动查询原生广告工厂缓存的素材类型。
  ///
  /// 平台视图创建和广告展示回调的先后顺序不固定，因此不能只依赖
  /// 原生端的单次推送。
  static Future<bool?> get_media_type(String slot_id, int token) async {
    try {
      return await _channel.invokeMethod<bool>(
        'getNativeAdMediaType',
        <String, Object>{'slotId': slot_id, 'layoutToken': token},
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// 仅初始化一次原生方法通道，避免多个广告实例互相覆盖回调。
  static void _ensure_initialized() {
    if (_is_initialized) return;
    _is_initialized = true;
    _channel.setMethodCallHandler((MethodCall call) async {
      final Object? raw_arguments = call.arguments;
      if (raw_arguments is! Map<Object?, Object?>) return;

      final String? slot_id = raw_arguments['slotId'] as String?;
      final num? raw_token = raw_arguments['layoutToken'] as num?;
      if (slot_id == null || raw_token == null) return;

      final int token = raw_token.toInt();
      if (call.method == 'onNativeAdMediaType') {
        final bool? is_video = raw_arguments['hasVideoContent'] as bool?;
        if (is_video == null) return;
        _media_type_listeners[slot_id]?.call(is_video, token);
        return;
      }

      if (call.method == 'onNativeAdVideoPlayback') {
        final String? playback_state =
            raw_arguments['playbackState'] as String?;
        final bool? is_muted = raw_arguments['isMuted'] as bool?;
        if (playback_state == null) return;
        _video_playback_listeners[slot_id]?.call(
          playback_state,
          is_muted,
          token,
        );
        return;
      }

      if (call.method != 'onNativeAdLayout') return;
      final num? raw_height = raw_arguments['viewHeight'] as num?;
      if (raw_height == null) return;

      final double height = raw_height.toDouble();
      if (!height.isFinite || height <= 0) return;
      _listeners[slot_id]?.call(height, token);
    });
  }

  /// 通知原生端释放已销毁广告槽位的诊断状态。
  static Future<void> _clear_native_media_state(String slot_id) async {
    try {
      await _channel.invokeMethod<void>(
        'clearNativeAdMediaState',
        <String, Object>{'slotId': slot_id},
      );
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
