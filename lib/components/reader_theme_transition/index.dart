// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:app/components/svg_icon/index.dart';
import 'package:app/stores/device_info.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/config/color_config.dart';

/// TODO 长篇、短篇与漫画共用的主题切换动画；由弹窗持有并在dispose时取消，避免残留遮罩。
class ReaderThemeTransition {
  ReaderThemeTransition({required TickerProvider vsync})
    : _controller = AnimationController(vsync: vsync, duration: duration) {
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  static const Duration duration = Duration(milliseconds: 1200);
  static const double icon_size = 100;
  final AnimationController _controller;
  late final Animation<double> _opacity;
  OverlayEntry? _entry;
  bool _disposed = false;

  Future<void> change(BuildContext context, {required bool to_dark}) async {
    if (_disposed || _entry != null || _controller.isAnimating) return;
    final device = Get.find<DeviceInfo>();
    final target = to_dark ? ThemeMode.dark : ThemeMode.light;
    if (device.theme.value == target) return;
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      device.changeTheme(target);
      return;
    }
    var changed = false;
    final entry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: _opacity,
        builder: (context, _) => Stack(
          children: [
            const ModalBarrier(dismissible: false, color: ColorConstants.transparent),
            Opacity(
              opacity: _opacity.value,
              child: ColoredBox(
                color: ColorConstants.lightTextColor,
                child: SizedBox.expand(
                  child: Center(
                    child: Transform.scale(
                      scale: 0.5 + 0.5 * _opacity.value,
                      child: SvgIcon(
                        name: to_dark ? 'moon' : 'sun',
                        width: icon_size,
                        height: icon_size,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    _entry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
    void on_tick() {
      if (!changed && _controller.value >= 0.5 && context.mounted) {
        changed = true;
        device.changeTheme(target);
      }
    }

    _controller.addListener(on_tick);
    try {
      await _controller.forward(from: 0).orCancel;
    } on TickerCanceled {
      // TODO 关闭弹窗或页面时允许取消，主题与遮罩不再投递到新页面。
    } finally {
      if (!_disposed) _controller.removeListener(on_tick);
      if (identical(_entry, entry)) {
        entry.remove();
        _entry = null;
      }
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _entry?.remove();
    _entry = null;
    _controller.dispose();
  }
}
