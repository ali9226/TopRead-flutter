// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'regions.dart';

/// 为整棵导航树补充系统硬件区域，页面、DialogRoute 和底部弹层共同使用。
///
/// 本组件只补充 MediaQuery；连续阅读和信息流保持原有流式布局。
/// 需要作为一个整体避让折痕的游戏可选择 DisplayFeatureSubScreen。
class WindowDisplayFeatures extends StatefulWidget {
  const WindowDisplayFeatures({
    super.key,
    required this.child,
    this.feature_stream,
    this.refresh_features,
  });

  final Widget child;

  /// 可注入的原生边界，便于测试姿态变化、迟到响应和插件不可用。
  final Stream<Object?>? feature_stream;
  final Future<Object?> Function()? refresh_features;

  static const method_channel = MethodChannel(
    'com.topread.novel/window_display_features',
  );
  static const event_channel = EventChannel(
    'com.topread.novel/window_display_features/events',
  );

  @override
  State<WindowDisplayFeatures> createState() => _WindowDisplayFeaturesState();
}

class _WindowDisplayFeaturesState extends State<WindowDisplayFeatures>
    with WidgetsBindingObserver {
  StreamSubscription<Object?>? _subscription;
  WindowReservedRegions? _regions;
  bool _refresh_scheduled = false;
  int _snapshot_revision = 0;

  bool get _enabled =>
      widget.feature_stream != null ||
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listen();
  }

  void _listen() {
    if (!_enabled) return;
    _subscription =
        (widget.feature_stream ??
                WindowDisplayFeatures.event_channel.receiveBroadcastStream())
            .listen(_receive, onError: (Object _) => _receive(null));
    unawaited(_refresh());
  }

  @override
  void didUpdateWidget(covariant WindowDisplayFeatures oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feature_stream == widget.feature_stream &&
        oldWidget.refresh_features == widget.refresh_features) {
      return;
    }
    unawaited(_subscription?.cancel());
    _subscription = null;
    _snapshot_revision++;
    _regions = null;
    _listen();
  }

  void _receive(Object? value) {
    if (!mounted) return;
    _snapshot_revision++;
    final next = WindowReservedRegions.from_platform(value);
    if (next == null && _regions == null) return;
    if (next?.has_same_geometry(_regions) ?? false) return;
    setState(() => _regions = next);
  }

  Future<void> _refresh() async {
    if (!_enabled) return;
    final revision = _snapshot_revision;
    try {
      final value =
          await (widget.refresh_features?.call() ??
              WindowDisplayFeatures.method_channel.invokeMethod<Object?>(
                'refresh',
              ));
      // 在等待期间已收到更新事件时，不让旧 refresh 覆盖较新的姿态。
      if (mounted && revision == _snapshot_revision) _receive(value);
    } on Object {
      // 旧 iOS、无原生插件的测试宿主、临时场景切换均保留原 MediaQuery。
    }
  }

  void _schedule_refresh() {
    if (!_enabled || _refresh_scheduled) return;
    _refresh_scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh_scheduled = false;
      if (mounted) unawaited(_refresh());
    });
  }

  @override
  void didChangeMetrics() => _schedule_refresh();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _schedule_refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media_query = MediaQuery.of(context);
    return MediaQuery(
      data: media_query.copyWith(
        displayFeatures: _regions?.merge_with(media_query),
      ),
      child: widget.child,
    );
  }
}
