import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

import '../style.dart';

/// 调试页面的通用操作按钮。
class DebugActionItem extends StatelessWidget {
  const DebugActionItem({
    required this.title,
    required this.isDark,
    required this.onTap,
    this.isLoading = false,
    super.key,
  });

  final String title;
  final bool isDark;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.nightHighlightColor
            : ColorConstants.components_image_source_sheet_index_tone_fff8fafd,
        borderRadius: BorderRadius.circular(Style.itemRadius),
        border: Border.all(
          color: isDark
              ? ColorConstants.util_dialog_show_upgrade_dialog_tone_fffffff
              : ColorConstants.components_image_source_sheet_index_tone_ffe7ecf3,
        ),
      ),
      child: Material(
        color: ColorConstants.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Style.itemRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Style.itemHorizontalPadding,
              vertical: Style.itemVerticalPadding,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                      color: isDark
                          ? ColorConstants.whiteColor
                          : ColorConstants.lightTextColor,
                    ),
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ColorConstants.themeColor,
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark
                        ? ColorConstants.pages_read_widgets_read_directory_sheet_index_tone
                        : ColorConstants.lightTextColor.withValues(alpha: 0.22),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
