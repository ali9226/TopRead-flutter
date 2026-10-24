import 'dart:async';

import 'package:app/pages/read/logic.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// 长篇自动阅读的宿主能力。
abstract class AutoReadHost {
  /// 宿主是否仍然挂载。
  bool get host_mounted;

  /// 滚动控制器。
  ScrollController get scroll_controller;

  /// 是否需要恢复滚动位置（恢复期间暂停滚动推进）。
  bool get needs_restore_scroll_position;

  /// 章节切换事务是否进行中。
  bool get is_chapter_transaction_active;

  /// 界面刷新。
  void refresh_ui();
}

/// 长篇阅读页自动阅读引擎。
///
/// 用 [Ticker] 每帧按速度推进滚动位置；到达窗口底部后等待下一章
/// 加载完成再继续。速度映射：0.0 → 20px/s，1.0 → 300px/s。
class ReadingAutoReadController {
  ReadingAutoReadController({
    required this.host,
    required this.logic,
    required TickerProvider ticker_provider,
  }) : _ticker_provider = ticker_provider;

  /// 页面能力宿主。
  final AutoReadHost host;

  /// 页面逻辑层（自动阅读状态与章节加载）。
  final Logic logic;

  final TickerProvider _ticker_provider;

  /// 自动阅读 Ticker。
  Ticker? _ticker;

  /// 上一帧时间，用于换算像素推进量。
  Duration? _last_tick;

  /// 是否正在等待下一章加载完成后继续自动阅读。
  bool _is_waiting_for_chapter = false;

  /// 开启自动阅读（用户主动操作，会标记已交互）。
  void start({required void Function() mark_user_engaged}) {
    if (logic.is_auto_reading.value) return;

    // 自动阅读由用户主动开启，后续 Ticker 的 jumpTo 不会产生手势通知。
    mark_user_engaged();
    logic.is_auto_reading.value = true;
    logic.show_navigation.value = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      begin_ticker();
    });
  }

  /// 停止自动阅读。
  void stop() {
    _is_waiting_for_chapter = false;
    if (logic.is_auto_reading.value) {
      logic.is_auto_reading.value = false;
      _ticker?.stop();
      _ticker?.dispose();
      _ticker = null;
    }
  }

  /// 启动自动阅读 Ticker（每帧根据当前速度滚动）。
  void begin_ticker() {
    if (!host.host_mounted || !logic.is_auto_reading.value) return;

    _last_tick = null;

    _ticker?.dispose();
    _ticker = _ticker_provider.createTicker((Duration elapsed) {
      final ScrollController controller = host.scroll_controller;
      if (!controller.hasClients || !logic.is_auto_reading.value) {
        _ticker?.stop();
        return;
      }
      // 折叠/展开、切章和字号重排期间的 maxScrollExtent 仍在变化。
      // 等锚点恢复后继续，不能把暂时夹到新边界的旧 offset 当成真正读到章末。
      if (host.needs_restore_scroll_position ||
          host.is_chapter_transaction_active) {
        _last_tick = elapsed;
        return;
      }

      final double delta_seconds;
      if (_last_tick == null) {
        delta_seconds = 0;
      } else {
        delta_seconds = (elapsed - _last_tick!).inMicroseconds / 1000000.0;
      }
      _last_tick = elapsed;

      // 速度映射：0.0 → 20px/s，1.0 → 300px/s。
      final double speed = logic.auto_read_speed.value;
      final double pixels_per_second = 20 + speed * 280;

      final double current = controller.offset;
      final double max_extent = controller.position.maxScrollExtent;
      final double next = current + pixels_per_second * delta_seconds;

      if (next >= max_extent) {
        controller.jumpTo(max_extent);
        _ticker?.stop();
        if (logic.loaded_chapter_index < logic.chapter_list.length - 1) {
          unawaited(resume_after_next_chapter());
        } else {
          logic.is_auto_reading.value = false;
        }
      } else {
        controller.jumpTo(next);
      }
    });

    _ticker?.start();
  }

  /// 自动阅读到达当前窗口底部后等待下一章，并在布局完成后继续。
  Future<void> resume_after_next_chapter() async {
    if (_is_waiting_for_chapter || !logic.is_auto_reading.value) {
      return;
    }

    _is_waiting_for_chapter = true;
    try {
      await logic.load_next_chapter();
      await WidgetsBinding.instance.endOfFrame;
      if (!host.host_mounted || !logic.is_auto_reading.value) return;
      final ScrollController controller = host.scroll_controller;
      if (controller.hasClients &&
          controller.offset < controller.position.maxScrollExtent) {
        begin_ticker();
      } else {
        logic.is_auto_reading.value = false;
      }
    } finally {
      _is_waiting_for_chapter = false;
    }
  }

  /// 释放 Ticker。
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
  }
}
