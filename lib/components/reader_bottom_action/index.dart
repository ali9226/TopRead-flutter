// ignore_for_file: non_constant_identifier_names

import 'package:app/components/reader_action_icon/index.dart';
import 'package:app/components/reader_bottom_action/style.dart';
import 'package:flutter/material.dart';

/// TODO 底部等分操作项：相同图标尺寸、文字基线与完整点击区域，支持调用方保留点赞动画。
class ReaderBottomAction extends StatelessWidget {
  const ReaderBottomAction({
    super.key,
    required this.label,
    required this.color,
    required this.on_pressed,
    this.icon_name,
    this.icon_widget,
  }) : assert(icon_name != null || icon_widget != null);
  final String label;
  final Color color;
  final VoidCallback? on_pressed;
  final String? icon_name;
  final Widget? icon_widget;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      button: true,
      enabled: on_pressed != null,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: on_pressed,
          borderRadius: BorderRadius.circular(ReaderBottomActionStyle.radius),
          child: SizedBox(
            width: double.infinity,
            height: ReaderBottomActionStyle.row_height(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ReaderBottomActionStyle.horizontal_padding,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox.square(
                    dimension: ReaderBottomActionStyle.icon_size,
                    child:
                        icon_widget ??
                        ReaderActionIcon(
                          name: icon_name!,
                          color: color,
                          size: ReaderBottomActionStyle.icon_size,
                        ),
                  ),
                  const SizedBox(height: ReaderBottomActionStyle.label_gap),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontSize: ReaderBottomActionStyle.label_size(context),
                      height: ReaderBottomActionStyle.label_line_height,
                      fontWeight: ReaderBottomActionStyle.label_weight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
