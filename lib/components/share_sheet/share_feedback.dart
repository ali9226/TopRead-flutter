import 'dart:async';

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'layout_style.dart';

OverlayEntry? _entry;
Timer? _timer;

/// 提示绘制到分享弹窗上方，不会被底部模态层挡住；不依赖全局设备状态。
void show_share_feedback(BuildContext context, String message_key) {
  if (!context.mounted) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _timer?.cancel();
  if (_entry?.mounted == true) _entry?.remove();
  final message = tr(message_key, context: context);
  final bottom_padding = MediaQuery.paddingOf(context).bottom;
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: LayoutConfig.space_20,
      right: LayoutConfig.space_20,
      bottom: bottom_padding + LayoutConfig.space_24,
      child: IgnorePointer(
        child: SafeArea(
          top: false,
          child: Center(
            child: Material(
              color: ColorConstants.lightTextColor,
              borderRadius: BorderRadius.circular(LayoutConfig.radius_12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LayoutConfig.space_16,
                  vertical: LayoutConfig.space_12,
                ),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ColorConstants.whiteColor,
                      fontSize: ShareLayoutStyle.feedback_font_size,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  _entry = entry;
  overlay.insert(entry);
  _timer = Timer(ShareLayoutStyle.feedback_duration, () {
    if (entry.mounted) entry.remove();
    if (identical(_entry, entry)) {
      _entry = null;
      _timer = null;
    }
  });
}
