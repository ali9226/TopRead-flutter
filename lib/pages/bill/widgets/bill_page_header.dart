import 'package:flutter/material.dart';
import 'package:app/components/language_selection/index.dart';

import '../style.dart';

/// 账单页固定头部。
class BillPageHeader extends StatelessWidget {
  final bool isDark;
  final Color backgroundColor;

  const BillPageHeader({
    super.key,
    required this.isDark,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              backgroundColor.withValues(
                alpha: Style.headerGradientStartOpacity,
              ),
              backgroundColor.withValues(
                alpha: Style.headerGradientMiddleOpacity,
              ),
              backgroundColor.withValues(alpha: 0),
            ],
          ),
        ),
        child: LanguageSelection(
          darkBackground: isDark,
        ),
      ),
    );
  }
}
