import 'package:flutter/material.dart';

/// 循环切换的提示文字覆盖组件。
///
/// 文字变化时使用上下滑动动画切换展示。
class CyclingHintOverlay extends StatelessWidget {
  final String hint_text;
  final TextStyle text_style;

  const CyclingHintOverlay({
    super.key,
    required this.hint_text,
    required this.text_style,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                ),
              ),
          child: child,
        );
      },
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          clipBehavior: Clip.hardEdge,
          alignment: Alignment.centerLeft,
          children: <Widget>[...previousChildren, ?currentChild],
        );
      },
      child: Align(
        alignment: Alignment.centerLeft,
        key: ValueKey<String>(hint_text),
        child: Text(
          hint_text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text_style,
        ),
      ),
    );
  }
}
