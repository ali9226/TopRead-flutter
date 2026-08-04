import 'package:app/util/clipboard/clipboard.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import '../widgets/debug_action_item.dart';
import 'logic.dart';

/// FCM Token 调试按钮。
class FcmTokenDebugItem extends StatefulWidget {
  const FcmTokenDebugItem({required this.isDark, super.key});

  final bool isDark;

  @override
  State<FcmTokenDebugItem> createState() => _FcmTokenDebugItemState();
}

class _FcmTokenDebugItemState extends State<FcmTokenDebugItem> {
  final FcmTokenLogic _logic = FcmTokenLogic();
  bool _isLoading = false;

  Future<void> _handleTap() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final String? token = await _logic.getToken();
      if (token == null || token.isEmpty) {
        showBottomTip(easy.tr('debug.fcm_token_error'));
        return;
      }

      final bool copied = await copyToClipboard(token);
      showBottomTip(
        copied
            ? easy.tr('debug.fcm_token_success')
            : easy.tr('debug.fcm_token_error'),
      );
    } catch (_) {
      showBottomTip(easy.tr('debug.fcm_token_error'));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DebugActionItem(
      title: easy.tr('debug.fcm_token'),
      isDark: widget.isDark,
      isLoading: _isLoading,
      onTap: _handleTap,
    );
  }
}
