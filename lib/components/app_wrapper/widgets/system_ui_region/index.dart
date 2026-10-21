import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 路由树的默认状态栏样式；页面自己的局部标注可覆盖，退出页面后自动恢复。
class AppSystemUiRegion extends StatelessWidget {
  const AppSystemUiRegion({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final is_dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarBrightness: is_dark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: is_dark ? Brightness.light : Brightness.dark,
      ),
      child: child,
    );
  }
}
