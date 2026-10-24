// ignore_for_file: non_constant_identifier_names

import 'package:app/components/reader_action_icon/index.dart';
import 'package:app/components/reader_bottom_action/index.dart';
import 'package:app/components/reader_bottom_action/style.dart';
import 'package:app/pages/comics/reader/style.dart';
import 'package:app/pages/comics/style.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// TODO 沿用小说阅读工具栏的无边框图标文字项；视觉紧凑，透明命中区域至少48像素。
class ComicReaderControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? on_pressed;
  final bool prominent;
  final bool icon_only;
  final String? svg_name;
  final bool vertical;
  final bool show_icon;
  final bool reverse_icon;
  const ComicReaderControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.on_pressed,
    this.prominent = false,
    this.icon_only = false,
    this.svg_name,
    this.vertical = false,
    this.show_icon = true,
    this.reverse_icon = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = on_pressed == null
        ? ComicReaderStyle.disabled_color(context)
        : vertical
        ? ReaderBottomActionStyle.foreground(
            Theme.of(context).brightness == Brightness.dark,
          )
        : ComicReaderStyle.secondary_foreground(context);
    final picture_size = vertical
        ? ReaderBottomActionStyle.icon_size
        : ComicReaderStyle.nav_icon_size;
    Widget picture = svg_name != null
        ? ReaderActionIcon(name: svg_name!, size: picture_size, color: color)
        : Icon(icon, size: picture_size, color: color);
    if (reverse_icon) picture = RotatedBox(quarterTurns: 2, child: picture);
    if (vertical) {
      return ReaderBottomAction(
        label: label,
        color: color,
        on_pressed: on_pressed,
        icon_widget: picture,
      );
    }
    final text = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: ComicsStyle.is_cjk(context)
            ? ComicReaderStyle.control_font_cjk
            : ComicReaderStyle.control_font_alphabetic,
        fontWeight: ComicReaderStyle.weight_regular,
        height: 1.3,
      ),
    );
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        enabled: on_pressed != null,
        label: label,
        child: Material(
          color: ColorConstants.transparent,
          child: InkWell(
            onTap: on_pressed,
            borderRadius: BorderRadius.circular(
              ComicReaderStyle.control_radius,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: ComicReaderStyle.control_target,
                minWidth: ComicReaderStyle.control_target,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: icon_only ? 0 : ComicReaderStyle.control_padding,
                  vertical: ComicReaderStyle.control_vertical_padding,
                ),
                child: icon_only
                    ? Center(widthFactor: 1, heightFactor: 1, child: picture)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (show_icon) ...<Widget>[
                            picture,
                            const SizedBox(
                              width: ComicReaderStyle.control_icon_gap,
                            ),
                          ],
                          Flexible(child: text),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
