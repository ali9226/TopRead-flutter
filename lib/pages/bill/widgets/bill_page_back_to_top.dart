import 'package:app/components/floating_back_to_top/index.dart';
import 'package:app/components/floating_back_to_top/style.dart';
import 'package:flutter/material.dart';

import '../style.dart';

/// 账单页回顶入口，与账单正文使用同一列宽、左右边距和安全区。
class BillPageBackToTop extends StatelessWidget {
  const BillPageBackToTop({
    super.key,
    required this.isDark,
    required this.visible,
    required this.onTap,
  });

  final bool isDark;
  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bottom_safe_area = MediaQuery.paddingOf(context).bottom;
    return FloatingBackToTop(
      show: visible,
      isDark: isDark,
      onTap: onTap,
      horizontalPadding: Style.pageHorizontalPadding,
      visibleBottom: FloatingBackToTopStyle.page_bottom + bottom_safe_area,
      hiddenBottom: FloatingBackToTopStyle.hidden_offset + bottom_safe_area,
    );
  }
}
