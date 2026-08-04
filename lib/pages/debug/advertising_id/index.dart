import 'package:app/util/clipboard/clipboard.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:flutter/material.dart';

import '../utils/platform.dart';
import '../widgets/debug_action_item.dart';
import 'logic.dart';

/// 设备广告 ID 调试按钮。
class AdvertisingIdDebugItem extends StatefulWidget {
  const AdvertisingIdDebugItem({required this.isDark, super.key});

  final bool isDark;

  @override
  State<AdvertisingIdDebugItem> createState() => _AdvertisingIdDebugItemState();
}

class _AdvertisingIdDebugItemState extends State<AdvertisingIdDebugItem> {
  final AdvertisingIdLogic _logic = AdvertisingIdLogic();
  bool _isLoading = false;

  Future<void> _handleTap() async {
    if (!isAndroidOrIOS) {
      showBottomTip('当前设备不是安卓或苹果设备');
      return;
    }
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final String? advertisingId = await _logic.getAdvertisingId();
      if (advertisingId == null || advertisingId.isEmpty) {
        showBottomTip('获取设备广告 ID 失败');
        return;
      }

      final bool copied = await copyToClipboard(advertisingId);
      showBottomTip(copied ? '设备广告 ID 已复制到粘贴板' : '复制设备广告 ID 失败');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DebugActionItem(
      title: '获取设备广告id',
      isDark: widget.isDark,
      isLoading: _isLoading,
      onTap: _handleTap,
    );
  }
}
