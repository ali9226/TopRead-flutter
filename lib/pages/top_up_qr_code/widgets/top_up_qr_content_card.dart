import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/recharge_add_result.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../style.dart';
import 'package:app/config/font_config.dart';

/// TODO 充值二维码主体卡片。
/// 负责展示充值类型、二维码、地址和完成按钮，
/// 让主页面只处理数据获取与事件分发。
class TopUpQrContentCard extends StatelessWidget {
  final bool isDark;
  final RechargeAddResult? detail;
  final Color hintColor;
  final Color qrBackgroundColor;
  final VoidCallback onCopyAddress;
  final VoidCallback onTapDone;

  const TopUpQrContentCard({
    super.key,
    required this.isDark,
    required this.detail,
    required this.hintColor,
    required this.qrBackgroundColor,
    required this.onCopyAddress,
    required this.onTapDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171A27) : Colors.white,
        borderRadius: BorderRadius.circular(Style.cardRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.06),
            blurRadius: Style.cardShadowBlur,
            offset: const Offset(0, Style.cardShadowOffsetY),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -28,
            left: -16,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorConstants.themeColor.withValues(
                  alpha: isDark ? 0.10 : 0.09,
                ),
              ),
            ),
          ),
          Positioned(
            right: -22,
            bottom: 74,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorConstants.successColor.withValues(
                  alpha: isDark ? 0.08 : 0.10,
                ),
              ),
            ),
          ),
          Padding(
            padding: Style.qrCardPadding,
            child: Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFFFF8DD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: ColorConstants.themeColor.withValues(
                            alpha: isDark ? 0.14 : 0.16,
                          ),
                        ),
                        child: Center(
                          child: SvgIcon(
                            name: 'usdt',
                            width: 18,
                            height: 18,
                            color: ColorConstants.themeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              easy.tr('top_up_page.type_title'),
                              style: TextStyle(
                                color: hintColor,
                                fontSize: 11,
                                fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              detail?.typeStr ?? '--',
                              style: TextStyle(
                                color: isDark
                                    ? ColorConstants.whiteColor
                                    : ColorConstants.lightTextColor,
                                fontSize: 15,
                                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: qrBackgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.14 : 0.05,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: detail == null
                      ? const SizedBox(
                          width: 220,
                          height: 220,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : QrImageView(
                          data: detail!.payQrCode,
                          size: 220,
                          backgroundColor: Colors.white,
                        ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: onCopyAddress,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            detail == null ? '--' : detail!.payQrCode,
                            style: TextStyle(
                              color: isDark
                                  ? ColorConstants.whiteColor
                                  : ColorConstants.lightTextColor,
                              fontSize: 14,
                              fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: onCopyAddress,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: ColorConstants.themeColor.withValues(
                                alpha: isDark ? 0.16 : 0.12,
                              ),
                            ),
                            child: Center(
                              child: SvgIcon(
                                name: 'copy',
                                width: 18,
                                height: 18,
                                color: ColorConstants.themeColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTapDone,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: ColorConstants.themeColor,
                      foregroundColor: ColorConstants.lightTextColor,
                      minimumSize: const Size.fromHeight(
                        Style.doneButtonHeight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      easy.tr('top_up_qr_code_page.done'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
