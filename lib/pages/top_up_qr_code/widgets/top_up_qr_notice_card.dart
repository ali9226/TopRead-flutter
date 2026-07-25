import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/recharge_add_result.dart';
import '../style.dart';
import 'package:app/config/font_config.dart';

/// TODO 充值二维码页注意事项卡片。
/// 专门负责展示说明文本和订单号摘要。
class TopUpQrNoticeCard extends StatelessWidget {
  final bool isDark;
  final Color hintColor;
  final RechargeAddResult? detail;
  final bool isBottomDocked;
  final double safeBottomPadding;

  const TopUpQrNoticeCard({
    super.key,
    required this.isDark,
    required this.hintColor,
    required this.detail,
    this.isBottomDocked = false,
    this.safeBottomPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: isBottomDocked
          ? Style.bottomNoticeCardPadding.add(
              EdgeInsets.only(bottom: safeBottomPadding),
            )
          : Style.noticeCardPadding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171A27) : Colors.white,
        borderRadius: isBottomDocked
            ? const BorderRadius.vertical(
                top: Radius.circular(Style.bottomNoticeTopRadius),
              )
            : BorderRadius.circular(Style.bottomNoticeTopRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            easy.tr('top_up_qr_code_page.notice_title'),
            style: TextStyle(
              color: isDark
                  ? ColorConstants.whiteColor
                  : ColorConstants.lightTextColor,
              fontSize: Style.noticeTitleSize,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            easy.tr(
              'top_up_qr_code_page.notice_01',
              namedArgs: <String, String>{
                'amount': detail == null
                    ? '--'
                    : detail!.payPayable.toStringAsFixed(2),
                'type': detail?.typeStr ?? '--',
              },
            ),
            style: TextStyle(
              color: hintColor,
              fontSize: Style.noticeBodySize,
              height: 1.55,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            easy.tr('top_up_qr_code_page.notice_02'),
            style: TextStyle(
              color: hintColor,
              fontSize: Style.noticeBodySize,
              height: 1.55,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            easy.tr('top_up_qr_code_page.notice_03'),
            style: TextStyle(
              color: hintColor,
              fontSize: Style.noticeBodySize,
              height: 1.55,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${easy.tr('top_up_qr_code_page.serial_number')}: ${detail?.serialNumber ?? '--'}',
            style: TextStyle(
              color: isDark
                  ? ColorConstants.whiteColor.withValues(alpha: 0.68)
                  : ColorConstants.hintColor,
              fontSize: 12,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
