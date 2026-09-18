// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'style.dart';

/// 键盘和表情共用底部空间，切换期间锁住占位高度，不等待键盘退场再插入面板。
class ParagraphInputPanelLogic extends ChangeNotifier {
  double _keyboard_height = 0;
  double _last_keyboard_height = 0;
  double _reserved_height = 0;
  double _view_height = 0;
  double _view_width = 0;
  bool _show_emoji = false;
  bool _restoring_keyboard = false;
  Timer? _transition_timer;

  /// 操作栏显示键盘按钮还是表情按钮，仅由用户目标决定。
  bool get show_emoji => _show_emoji;

  /// 回到键盘时仍保留底下的表情，直到系统键盘完全覆盖它。
  bool get paint_emoji => _show_emoji || _restoring_keyboard;

  /// 系统键盘包括底部安全区；表情完整复用同一个空间。
  double get height => paint_emoji
      ? math.max(_keyboard_height, _reserved_height)
      : _keyboard_height;

  /// 接收窗口真实指标；键盘关闭过程不能覆盖此前完整键盘高度。
  void update_metrics({
    required double keyboard_height,
    required double view_width,
    required double view_height,
    bool notify = true,
  }) {
    final double old_height = height;
    final bool old_paint_emoji = paint_emoji;
    final bool rotated =
        _view_width > 0 &&
        (_view_width != view_width || _view_height != view_height);
    _view_width = view_width;
    _view_height = view_height;
    _keyboard_height = math.max(0, keyboard_height);
    if (rotated) {
      _last_keyboard_height = 0;
      _reserved_height = _fallback_height;
    }
    if (!_show_emoji && !_restoring_keyboard && _keyboard_height > 0) {
      _last_keyboard_height = _keyboard_height;
    }
    if (_restoring_keyboard && _keyboard_height > 0) {
      if (_keyboard_height >= _reserved_height) {
        _complete_keyboard_transition(notify: false);
      } else {
        // 更换输入法后最终高度可能变小；仅指标稳定后采用新高度。
        _transition_timer?.cancel();
        _transition_timer = Timer(
          ParagraphCommentComposerStyle.keyboard_settle_delay,
          _complete_keyboard_transition,
        );
      }
    }
    if (notify && (old_height != height || old_paint_emoji != paint_emoji)) {
      notifyListeners();
    }
  }

  double get _fallback_height => _view_height > 0
      ? math.min(
          ParagraphCommentComposerStyle.emoji_max_height,
          _view_height * ParagraphCommentComposerStyle.panel_height_ratio,
        )
      : ParagraphCommentComposerStyle.emoji_max_height;

  /// 必须在输入框失焦前调用，让表情在键盘后方同帧挂载。
  void activate_emoji() {
    _transition_timer?.cancel();
    _reserved_height = height > 0
        ? height
        : (_last_keyboard_height > 0
              ? _last_keyboard_height
              : _fallback_height);
    _restoring_keyboard = false;
    _show_emoji = true;
    notifyListeners();
  }

  /// 键盘上升期间继续占用原表情高度，避免输入区域先落下再升起。
  void activate_keyboard() {
    if (!_show_emoji) return;
    _show_emoji = false;
    _restoring_keyboard = true;
    _transition_timer?.cancel();
    // 外接键盘不会产生非零 inset；超时后允许恢复没有软件键盘的布局。
    _transition_timer = Timer(
      ParagraphCommentComposerStyle.keyboard_restore_timeout,
      _complete_keyboard_transition,
    );
    notifyListeners();
  }

  void _complete_keyboard_transition({bool notify = true}) {
    _transition_timer?.cancel();
    if (!_restoring_keyboard) return;
    _restoring_keyboard = false;
    if (_keyboard_height > 0) _last_keyboard_height = _keyboard_height;
    if (notify) notifyListeners();
  }

  /// 关闭弹窗或打开系统相册时不再维持表情占位。
  void deactivate() {
    _transition_timer?.cancel();
    _show_emoji = false;
    _restoring_keyboard = false;
  }

  @override
  void dispose() {
    _transition_timer?.cancel();
    super.dispose();
  }
}
