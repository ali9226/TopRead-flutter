// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:app/pages/comics/reader/logic.dart';
import 'package:app/pages/comics/reader/style.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';

/// TODO 与小说相同的逐帧自动阅读：0..1速度映射20..300逻辑像素/秒，手动操作立即停止。
class ComicAutoRead extends ChangeNotifier {
  ComicAutoRead({
    required TickerProvider vsync,
    required this.logic,
    required this.speed,
    required this.on_next,
  }) {
    _ticker = vsync.createTicker(_tick);
  }
  final ComicReaderLogic logic;
  final double Function() speed;
  final Future<bool> Function() on_next;
  late final Ticker _ticker;
  Duration? _last;
  bool running = false;
  bool _waiting = false;
  bool _closed = false;
  int _generation = 0;

  void start() {
    if (_closed || running || logic.loading || logic.reading == null) return;
    running = true;
    _last = null;
    _ticker.start();
    notifyListeners();
  }

  void stop() {
    _generation++;
    _waiting = false;
    _last = null;
    if (_ticker.isActive) _ticker.stop();
    if (running) {
      running = false;
      if (!_closed) notifyListeners();
    }
  }

  void pause() {
    if (_ticker.isActive) _ticker.stop();
    _last = null;
  }

  void resume() {
    if (!_closed && running && !_ticker.isActive) {
      _last = null;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    if (!running || _waiting || !logic.scroll.hasClients) return;
    final previous = _last;
    _last = elapsed;
    if (previous == null || logic.loading || logic.is_reflowing) return;
    final seconds = ((elapsed - previous).inMicroseconds / 1000000).clamp(
      0.0,
      ComicReaderStyle.auto_delta_limit,
    );
    final velocity =
        ComicReaderStyle.auto_min_speed +
        speed().clamp(0.0, 1.0) * ComicReaderStyle.auto_speed_range;
    final end = logic.chapter_scroll_extent.clamp(
      0.0,
      logic.scroll.position.maxScrollExtent,
    );
    final next = logic.scroll.offset + velocity * seconds;
    if (next >= end) {
      logic.scroll.jumpTo(end);
      _waiting = true;
      unawaited(_advance(_generation));
    } else {
      logic.scroll.jumpTo(next);
    }
  }

  Future<void> _advance(int generation) async {
    var moved = false;
    try {
      moved = await on_next();
    } catch (_) {
      moved = false;
    }
    if (_closed || generation != _generation) return;
    _waiting = false;
    _last = null;
    if (!moved) stop();
  }

  @override
  void dispose() {
    _closed = true;
    stop();
    _ticker.dispose();
    super.dispose();
  }
}
