import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

/* TODO
 * 显示图标+文本 toast。
 *
 * [msg] 弹窗文案。
 * [icon] 可选图标。
 * [backgroundColor] 背景色。
 * [textColor] 文字色。
 * [duration] 展示时长。
 * [position] 展示位置。
 */
void toastUtil({
  required String msg,
  IconData? icon,
  Color backgroundColor = Colors.black87,
  Color textColor = Colors.white,
  Duration duration = const Duration(milliseconds: 2000),
  ToastPosition position = ToastPosition.center,
}) {
  showToastWidget(
    _buildToastWidget(
      msg: msg,
      icon: icon,
      backgroundColor: backgroundColor,
      textColor: textColor,
    ),
    duration: duration,
    position: position,
    dismissOtherToast: true,
  );
}

/* TODO 构建 toast 组件。 */
Widget _buildToastWidget({
  required String msg,
  IconData? icon,
  required Color backgroundColor,
  required Color textColor,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 40),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: backgroundColor.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(icon, color: textColor, size: 20),
          ),
        Flexible(
          child: Text(
            msg,
            style: TextStyle(color: textColor, fontSize: 16),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    ),
  );
}
