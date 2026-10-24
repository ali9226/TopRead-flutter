import 'package:flutter/material.dart';
import '../style.dart';
import 'package:app/config/color_config.dart';

/// 金色阅读按钮：左侧阅读线索、完整文案与右侧方向引导都参与自然布局。
class WorkPrimaryReadingButton extends StatelessWidget {
  const WorkPrimaryReadingButton({
    super.key,
    required this.label,
    required this.on_pressed,
    required this.enabled,
    required this.cjk,
    required this.on_hero,
    required this.is_dark,
    this.action_key,
    this.compact = false,
  });

  final String label;
  final VoidCallback on_pressed;
  final bool enabled;
  final bool cjk;
  final bool on_hero;
  final bool is_dark;
  final Key? action_key;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      compact
          ? WorkReadingActionsStyle.compact_radius
          : WorkReadingActionsStyle.radius,
    );
    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : WorkReadingActionsStyle.disabled_alpha,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: WorkReadingActionsStyle.primary_gradient,
            borderRadius: radius,
            border: Border.all(
              color: WorkReadingActionsStyle.primary_edge,
              width: WorkReadingActionsStyle.border_width,
            ),
            boxShadow: enabled
                ? WorkReadingActionsStyle.primary_shadows(on_hero, is_dark)
                : const [],
          ),
          child: Stack(
            children: [
              Material(
                color: ColorConstants.transparent,
                borderRadius: radius,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: action_key,
                  onTap: enabled ? on_pressed : null,
                  borderRadius: radius,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: compact
                          ? WorkReadingActionsStyle.compact_height
                          : WorkReadingActionsStyle.height,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final show_trailing =
                            !compact &&
                            constraints.maxWidth >=
                                WorkReadingActionsStyle.min_trailing_width;
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: show_trailing
                                ? WorkReadingActionsStyle.horizontal_padding
                                : WorkReadingActionsStyle
                                      .compact_horizontal_padding,
                            vertical: compact
                                ? WorkReadingActionsStyle
                                      .compact_vertical_padding
                                : WorkReadingActionsStyle.vertical_padding,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                size: compact
                                    ? WorkReadingActionsStyle.compact_icon_size
                                    : WorkReadingActionsStyle.icon_size,
                                color: WorkReadingActionsStyle.primary_text,
                              ),
                              SizedBox(
                                width: compact
                                    ? WorkReadingActionsStyle.compact_icon_gap
                                    : WorkReadingActionsStyle.icon_gap,
                              ),
                              Expanded(
                                child: Text(
                                  label,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    color: WorkReadingActionsStyle.primary_text,
                                    fontSize: compact
                                        ? (cjk
                                              ? WorkReadingActionsStyle
                                                    .compact_font_size_cjk
                                              : WorkReadingActionsStyle
                                                    .compact_font_size_alphabetic)
                                        : (cjk
                                              ? WorkReadingActionsStyle
                                                    .font_size_cjk
                                              : WorkReadingActionsStyle
                                                    .font_size_alphabetic),
                                    height: cjk
                                        ? WorkReadingActionsStyle
                                              .line_height_cjk
                                        : WorkReadingActionsStyle
                                              .line_height_alphabetic,
                                    fontWeight:
                                        WorkReadingActionsStyle.label_weight,
                                  ),
                                ),
                              ),
                              if (show_trailing) ...[
                                const SizedBox(
                                  width: WorkReadingActionsStyle.trailing_gap,
                                ),
                                Container(
                                  width:
                                      WorkReadingActionsStyle.trailing_extent,
                                  height:
                                      WorkReadingActionsStyle.trailing_extent,
                                  decoration: BoxDecoration(
                                    color: WorkReadingActionsStyle
                                        .trailing_background,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: WorkReadingActionsStyle
                                          .trailing_border,
                                      width:
                                          WorkReadingActionsStyle.border_width,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.chevron_right_rounded,
                                    size: WorkReadingActionsStyle
                                        .trailing_icon_size,
                                    color: WorkReadingActionsStyle
                                        .trailing_foreground,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // 顶沿仅一条细光，不覆盖文字或引入大面积发光。
              Positioned(
                top: WorkReadingActionsStyle.top_highlight_offset,
                left: compact
                    ? WorkReadingActionsStyle.compact_top_highlight_inset
                    : WorkReadingActionsStyle.top_highlight_inset,
                right: compact
                    ? WorkReadingActionsStyle.compact_top_highlight_inset
                    : WorkReadingActionsStyle.top_highlight_inset,
                height: WorkReadingActionsStyle.top_highlight_height,
                child: const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ColorConstants.transparent,
                          WorkReadingActionsStyle.top_highlight,
                          ColorConstants.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
