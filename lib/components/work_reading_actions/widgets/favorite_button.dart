import 'package:app/config/color_config.dart';
import 'package:flutter/material.dart';
import '../style.dart';

/// 收藏沿用独立加载/选中状态，半透明小块在金色主按钮旁保持次要层级。
class WorkFavoriteButton extends StatelessWidget {
  const WorkFavoriteButton({
    super.key,
    required this.label,
    required this.on_pressed,
    required this.favorited,
    required this.loading,
    required this.on_hero,
    required this.is_dark,
    this.action_key,
    this.compact = false,
  });

  final String label;
  final VoidCallback on_pressed;
  final bool favorited;
  final bool loading;
  final bool on_hero;
  final bool is_dark;
  final Key? action_key;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      compact
          ? WorkReadingActionsStyle.compact_favorite_radius
          : WorkReadingActionsStyle.favorite_radius,
    );
    return SizedBox.square(
      dimension: compact
          ? WorkReadingActionsStyle.compact_height
          : WorkReadingActionsStyle.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: WorkReadingActionsStyle.secondary_gradient(
            on_hero,
            is_dark,
          ),
          borderRadius: radius,
          border: Border.all(
            color: WorkReadingActionsStyle.secondary_border(on_hero, is_dark),
            width: WorkReadingActionsStyle.border_width,
          ),
        ),
        child: Semantics(
          toggled: favorited,
          child: IconButton(
            key: action_key,
            onPressed: loading ? null : on_pressed,
            tooltip: label,
            style: IconButton.styleFrom(
              minimumSize: Size.square(
                compact
                    ? WorkReadingActionsStyle.compact_height
                    : WorkReadingActionsStyle.height,
              ),
              shape: RoundedRectangleBorder(borderRadius: radius),
              foregroundColor: favorited
                  ? ColorConstants.dangerColor
                  : WorkReadingActionsStyle.secondary_foreground(
                      on_hero,
                      is_dark,
                    ),
            ),
            icon: loading
                ? SizedBox.square(
                    dimension: compact
                        ? WorkReadingActionsStyle.compact_spinner_size
                        : WorkReadingActionsStyle.spinner_size,
                    child: CircularProgressIndicator(
                      strokeWidth: WorkReadingActionsStyle.spinner_stroke,
                      color: ColorConstants.dangerColor,
                    ),
                  )
                : Icon(
                    favorited
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: compact
                        ? WorkReadingActionsStyle.compact_icon_size
                        : WorkReadingActionsStyle.icon_size,
                  ),
          ),
        ),
      ),
    );
  }
}
