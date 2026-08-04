import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:flutter/material.dart';

import '../utils/platform.dart';
import '../widgets/debug_action_item.dart';
import 'logic.dart';

/// 限制广告跟踪状态调试按钮。
class LimitAdTrackingDebugItem extends StatefulWidget {
  const LimitAdTrackingDebugItem({required this.isDark, super.key});

  final bool isDark;

  @override
  State<LimitAdTrackingDebugItem> createState() =>
      _LimitAdTrackingDebugItemState();
}

class _LimitAdTrackingDebugItemState extends State<LimitAdTrackingDebugItem> {
  final LimitAdTrackingLogic _logic = LimitAdTrackingLogic();
  bool _isLoading = false;

  Future<void> _handleTap() async {
    if (!isAndroidOrIOS) {
      showBottomTip('当前设备不是安卓或苹果设备');
      return;
    }
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final bool? isEnabled = await _logic.isEnabled();
      if (isEnabled == null) {
        showBottomTip('获取限制广告跟踪状态失败');
        return;
      }

      showBottomTip(isEnabled ? '用户已启用限制广告跟踪功能' : '用户未启用限制广告跟踪功能');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DebugActionItem(
      title: '用户是否启用限制广告跟踪功能',
      isDark: widget.isDark,
      isLoading: _isLoading,
      onTap: _handleTap,
    );
  }
}
