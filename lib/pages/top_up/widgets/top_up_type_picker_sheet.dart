import 'package:app/config/layout_config.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/transaction_inquire_type.dart';
import 'package:app/config/font_config.dart';

import '../style.dart';
import '../utils/get_top_up_type_display_text.dart';

/// 充值类型底部弹层。
///
/// 页面中最重的一段 JSX 风格 UI 原本直接堆在 `index.dart` 内，
/// 维护时很难快速看出它和页面主体的边界。
/// 拆成独立组件后，页面只需要决定“何时打开”和“选中了谁”。
class TopUpTypePickerSheet extends StatelessWidget {
  final bool isDark;
  final List<TransactionInquireTypeItem> dataList;
  final TransactionInquireTypeItem? selectedType;
  final ValueChanged<TransactionInquireTypeItem> onSelected;

  const TopUpTypePickerSheet({
    super.key,
    required this.isDark,
    required this.dataList,
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? ColorConstants.pages_top_up_record_index_tone : ColorConstants.whiteColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(LayoutConfig.radius_28),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          LayoutConfig.space_18,
          LayoutConfig.space_18,
          LayoutConfig.space_18,
          LayoutConfig.space_24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            buildDragHandle(),
            const SizedBox(height: LayoutConfig.space_18),
            buildTitle(),
            const SizedBox(height: LayoutConfig.space_12),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: Style.typeDropdownMenuMaxHeight,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: dataList.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: LayoutConfig.space_10),
                itemBuilder: (BuildContext context, int index) {
                  final TransactionInquireTypeItem item = dataList[index];
                  final bool isSelected = selectedType?.id == item.id;

                  return buildTypeTile(
                    context: context,
                    item: item,
                    isSelected: isSelected,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDragHandle() {
    return Container(
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.components_reading_banner_slide_index_tone_29ffffff
            : ColorConstants.pages_short_story_read_widgets_collapse_button_tone_1a222222,
        borderRadius: BorderRadius.circular(LayoutConfig.radius_pill),
      ),
    );
  }

  Widget buildTitle() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        easy.tr('top_up_page.type_title'),
        style: TextStyle(
          color: isDark
              ? ColorConstants.whiteColor
              : ColorConstants.lightTextColor,
          fontSize: Style.sectionTitleSize,
          fontWeight: Style.sectionTitleWeight,
        ),
      ),
    );
  }

  Widget buildTypeTile({
    required BuildContext context,
    required TransactionInquireTypeItem item,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        onSelected(item);
        Navigator.of(context).pop();
      },
      child: Container(
        height: Style.typeSelectorHeight,
        padding: Style.typeTilePadding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? <Color>[
                    Style.accentColor.withValues(alpha: isDark ? 0.22 : 0.16),
                    Style.accentColor.withValues(alpha: isDark ? 0.12 : 0.05),
                  ]
                : (isDark
                      ? const <Color>[ColorConstants.night_sheet_gradient_start, ColorConstants.night_sheet_gradient_end]
                      : const <Color>[ColorConstants.pages_change_password_style_tone_fffffcf2, ColorConstants.pages_top_up_widgets_top_up_type_picker_sheet_tone_fff7f6ef]),
          ),
          borderRadius: BorderRadius.circular(Style.typeTileRadius),
          border: Border.all(
            width: Style.typeTileBorderWidth,
            color: isSelected
                ? Style.accentColor
                : (isDark
                      ? ColorConstants.util_dialog_show_upgrade_dialog_tone_fffffff
                      : ColorConstants.components_home_top_search_entry_index_tone),
          ),
        ),
        child: Row(
          children: <Widget>[
            buildIconWrap(isSelected: isSelected),
            const SizedBox(width: LayoutConfig.space_12),
            Expanded(
              child: Text(
                getTopUpTypeDisplayText(item),
                style: TextStyle(
                  color: isDark
                      ? ColorConstants.whiteColor
                      : ColorConstants.lightTextColor,
                  fontSize: 15,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
                ),
              ),
            ),
            SvgIcon(
              name: isSelected ? 'check_03' : 'check_02',
              width: 18,
              height: 18,
              color: isSelected
                  ? Style.accentColor
                  : (isDark
                        ? ColorConstants.pages_top_up_widgets_top_up_type_picker_sheet_tone
                        : ColorConstants.hintColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildIconWrap({required bool isSelected}) {
    return Container(
      width: Style.typeIconWrapSize,
      height: Style.typeIconWrapSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? Style.accentColor.withValues(alpha: 0.18)
            : (isDark
                  ? ColorConstants.util_dialog_show_upgrade_dialog_tone_fffffff
                  : ColorConstants.components_paragraph_comment_sheet_widgets_comment_item_tone),
      ),
      child: Center(
        child: SvgIcon(
          name: 'usdt',
          width: Style.typeIconSize,
          height: Style.typeIconSize,
          color: isSelected ? Style.accentColor : ColorConstants.successColor,
        ),
      ),
    );
  }
}
