import 'package:flutter/material.dart';

import '../style.dart';

/// 账单页二次加载遮罩。
///
/// 仅在页面已经有内容时显示，避免用户误以为分页或刷新没有响应。
class BillPageLoadingOverlay extends StatelessWidget {
  final bool isDark;

  const BillPageLoadingOverlay({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        color: Colors.black.withValues(alpha: Style.loadingMaskOpacity),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.all(Style.loadingCardPadding),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1A1D2B)
                : Colors.white.withValues(alpha: Style.loadingCardOpacity),
            borderRadius: BorderRadius.circular(Style.loadingCardRadius),
          ),
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
