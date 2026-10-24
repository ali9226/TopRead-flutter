import 'dart:async';

import 'package:app/config/color_config.dart';
import 'package:app/pages/short_story_read/logic.dart';
import 'package:app/pages/short_story_read/widgets/auto_read_settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 短篇自动阅读的宿主能力。
abstract class StoryAutoReadHost {
  /// 宿主是否仍然挂载。
  bool get host_mounted;

  /// 弹窗上下文。
  BuildContext get host_context;

  /// 页面逻辑层。
  ShortStoryReadLogic get logic;

  /// 主滚动控制器。
  ScrollController get scroll_controller;

  /// 当前篇正文滚动范围（优先缓存值）。
  double resolve_story_extent();

  /// 视口重排是否进行中（重排期间暂停推进）。
  bool get is_viewport_resizing;

  /// 标记用户已交互。
  void mark_user_engaged();

  /// 界面刷新。
  void refresh_ui();
}

/// 短篇阅读页自动阅读引擎。
///
/// 每帧按速度推进滚动；推进期间用 [is_ticking] 屏蔽进度回写，
/// 到达当前篇末尾自动停止并恢复导航栏。
class StoryAutoReadController {
  StoryAutoReadController({
    required this.host,
    required TickerProvider ticker_provider,
  }) : _ticker_provider = ticker_provider;

  /// 页面能力宿主。
  final StoryAutoReadHost host;

  final TickerProvider _ticker_provider;

  /// 自动阅读 Ticker。
  Ticker? _ticker;

  /// 上一帧时间，用于换算像素推进量。
  Duration? _last_tick;

  /// 是否正在推进滚动（用于屏蔽进度回写）。
  bool is_ticking = false;

  /// 是否被应用生命周期暂停。
  bool paused_by_lifecycle = false;

  /// 开启自动阅读（隐藏导航栏与评论栏）。
  void start() {
    if (host.logic.is_auto_reading.value) return;

    host.mark_user_engaged();
    host.logic.is_auto_reading.value = true;

    // 隐藏导航栏和评论栏。
    host.logic.is_appbar_visible.value = false;
    host.logic.is_bottom_bar_visible.value = false;

    begin_ticker();
    host.refresh_ui();
  }

  /// 停止自动阅读并复位生命周期暂停标记。
  void stop() {
    paused_by_lifecycle = false;
    _stop_internal();
  }

  void _stop_internal() {
    if (host.logic.is_auto_reading.value) {
      host.logic.is_auto_reading.value = false;
      _ticker?.stop();
      _ticker?.dispose();
      _ticker = null;
    }
    host.refresh_ui();
  }

  /// 启动自动阅读 Ticker（每帧根据当前速度滚动）。
  void begin_ticker() {
    if (!host.host_mounted || !host.logic.is_auto_reading.value) return;

    _last_tick = null;

    _ticker?.dispose();
    _ticker = _ticker_provider.createTicker((Duration elapsed) {
      final ScrollController controller = host.scroll_controller;
      if (!controller.hasClients || !host.logic.is_auto_reading.value) {
        _ticker?.stop();
        return;
      }
      if (host.is_viewport_resizing) {
        _last_tick = elapsed;
        return;
      }

      // 计算距上一帧的时间差（秒）。
      final double delta_seconds;
      if (_last_tick == null) {
        delta_seconds = 0;
      } else {
        delta_seconds = (elapsed - _last_tick!).inMicroseconds / 1000000.0;
      }
      _last_tick = elapsed;

      // 速度映射：0.0 → 20px/s，1.0 → 300px/s。
      final double speed = host.logic.auto_read_speed.value;
      final double pixels_per_second = 20 + speed * 280;

      final double current = controller.offset;
      final double max_extent = host.resolve_story_extent();
      final double next = current + pixels_per_second * delta_seconds;

      is_ticking = true;
      if (next >= max_extent) {
        controller.jumpTo(max_extent);
        host.logic.is_auto_reading.value = false;
        host.logic.is_appbar_visible.value = true;
        host.logic.is_bottom_bar_visible.value = true;
        _ticker?.stop();
      } else {
        controller.jumpTo(next);
      }
      is_ticking = false;
    });

    _ticker?.start();
  }

  /// 显示自动阅读设置弹窗；关闭后按需恢复推进。
  Future<void> on_settings_tap() async {
    final ShortStoryReadLogic sheet_logic = host.logic;
    final bool should_resume = sheet_logic.is_auto_reading.value;
    _ticker?.stop();
    _last_tick = null;

    await showModalBottomSheet<void>(
      context: host.host_context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: false,
      backgroundColor: ColorConstants.transparent,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(host.host_context).size.width,
      ),
      builder: (BuildContext sheet_context) {
        return AutoReadSettingsSheet(
          logic: host.logic,
          on_close: () => Navigator.of(sheet_context).pop(),
          on_exit: () {
            Navigator.of(sheet_context).pop();
            stop();
          },
        );
      },
    );
    if (!host.host_mounted ||
        !should_resume ||
        !identical(host.logic, sheet_logic) ||
        !sheet_logic.is_auto_reading.value) {
      return;
    }
    begin_ticker();
  }

  /// 生命周期退到后台时暂停推进（保留自动阅读状态）。
  void pause_ticker() {
    _ticker?.stop();
    _last_tick = null;
  }

  /// 释放 Ticker。
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
  }
}
