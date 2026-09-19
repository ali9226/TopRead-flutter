// ignore_for_file: non_constant_identifier_names

import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'style.dart';

/// 使用 Flutter 选区锚点定位的段落操作浮层，屏幕顶部空间不足时自动下移。
class ParagraphSelectionToolbar extends StatelessWidget {
  const ParagraphSelectionToolbar({
    super.key,
    required this.anchors,
    required this.is_dark,
    required this.on_comment,
  });

  final TextSelectionToolbarAnchors anchors;
  final bool is_dark;
  final VoidCallback on_comment;

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final double font_size = is_cjk
        ? ParagraphSelectionStyle.menu_font_size_cjk
        : ParagraphSelectionStyle.menu_font_size_alphabetic;
    final double line_height = is_cjk
        ? ParagraphSelectionStyle.menu_line_height_cjk
        : ParagraphSelectionStyle.menu_line_height_alphabetic;
    final double top_padding =
        MediaQuery.paddingOf(context).top +
        ParagraphSelectionStyle.menu_screen_margin;
    final double menu_height =
        ParagraphSelectionStyle.menu_vertical_padding * 2 +
        ParagraphSelectionStyle.menu_icon_size +
        ParagraphSelectionStyle.menu_icon_spacing +
        MediaQuery.textScalerOf(context).scale(font_size) * line_height +
        ParagraphSelectionStyle.menu_arrow_height;
    final Offset adjustment = Offset(
      ParagraphSelectionStyle.menu_screen_margin,
      top_padding,
    );
    final Offset anchor_above =
        anchors.primaryAnchor -
        adjustment -
        const Offset(0, ParagraphSelectionStyle.menu_anchor_gap);
    final Offset anchor_below =
        (anchors.secondaryAnchor ?? anchors.primaryAnchor) -
        adjustment +
        const Offset(0, ParagraphSelectionStyle.menu_anchor_gap);
    final bool is_above = anchor_above.dy >= menu_height;
    final Color background = ParagraphSelectionStyle.menu_background(is_dark);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        ParagraphSelectionStyle.menu_screen_margin,
        top_padding,
        ParagraphSelectionStyle.menu_screen_margin,
        MediaQuery.paddingOf(context).bottom +
            ParagraphSelectionStyle.menu_screen_margin,
      ),
      child: CustomSingleChildLayout(
        delegate: TextSelectionToolbarLayoutDelegate(
          anchorAbove: anchor_above,
          anchorBelow: anchor_below,
          fitsAbove: is_above,
        ),
        child: TextFieldTapRegion(
          child: Column(
            key: const ValueKey<String>('paragraph_selection_toolbar'),
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (!is_above) _build_arrow(background, true),
              Material(
                color: background,
                elevation: ParagraphSelectionStyle.menu_elevation,
                borderRadius: BorderRadius.circular(
                  ParagraphSelectionStyle.menu_radius,
                ),
                clipBehavior: Clip.antiAlias,
                child: IntrinsicWidth(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: _build_action(
                          context: context,
                          icon: Icons.mode_comment_outlined,
                          label: 'paragraph_comment.write'.tr(),
                          is_cjk: is_cjk,
                          font_size: font_size,
                          line_height: line_height,
                          on_pressed: on_comment,
                        ),
                      ),
                      Flexible(
                        child: _build_action(
                          context: context,
                          icon: Icons.ios_share_outlined,
                          label: 'paragraph_comment.share'.tr(),
                          is_cjk: is_cjk,
                          font_size: font_size,
                          line_height: line_height,
                          on_pressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (is_above) _build_arrow(background, false),
            ],
          ),
        ),
      ),
    );
  }

  /// 操作图标位于文字上方；最小宽度根据文字语系分别配置。
  Widget _build_action({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool is_cjk,
    required double font_size,
    required double line_height,
    required VoidCallback on_pressed,
  }) => InkWell(
    onTap: on_pressed,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: is_cjk
            ? ParagraphSelectionStyle.menu_min_width_cjk
            : ParagraphSelectionStyle.menu_min_width_alphabetic,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ParagraphSelectionStyle.menu_horizontal_padding,
          vertical: ParagraphSelectionStyle.menu_vertical_padding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: ParagraphSelectionStyle.menu_icon_size,
              color: ParagraphSelectionStyle.menu_foreground(is_dark),
            ),
            const SizedBox(height: ParagraphSelectionStyle.menu_icon_spacing),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ParagraphSelectionStyle.menu_foreground(is_dark),
                fontSize: font_size,
                height: line_height,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _build_arrow(Color color, bool points_up) => CustomPaint(
    size: const Size(
      ParagraphSelectionStyle.menu_arrow_width,
      ParagraphSelectionStyle.menu_arrow_height,
    ),
    painter: _ToolbarArrowPainter(color: color, points_up: points_up),
  );
}

/// 三角形随菜单上下位置翻转，保留 tooltip 的视觉连接。
class _ToolbarArrowPainter extends CustomPainter {
  const _ToolbarArrowPainter({required this.color, required this.points_up});

  final Color color;
  final bool points_up;

  @override
  void paint(Canvas canvas, Size size) {
    final double edge_y = points_up ? size.height : 0;
    final double tip_y = points_up ? 0 : size.height;
    final Path path = Path()
      ..moveTo(0, edge_y)
      ..lineTo(size.width / 2, tip_y)
      ..lineTo(size.width, edge_y)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ToolbarArrowPainter old_delegate) =>
      old_delegate.color != color || old_delegate.points_up != points_up;
}
