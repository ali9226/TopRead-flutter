// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/auth_page/style.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/font_config.dart';
import 'package:app/models/language_info.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/language_store.dart';

/// 认证页顶部品牌区（Logo + 标语）。
class AuthBrandSection extends StatelessWidget {
  const AuthBrandSection({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceInfo = Get.find<DeviceInfo>();

    return Obx(() {
      final bool isDark = deviceInfo.dark.value;
      final Color logoColor = AuthPageStyle.primaryTextColor(isDark);

      return Column(
        children: [
          const SizedBox(height: AuthPageStyle.brandTopSpacing),
          const SizedBox(height: 30),
          Center(
            child: SvgIcon(
              name: 'logo',
              color: logoColor,
              width: AuthPageStyle.logoSize,
              height: AuthPageStyle.logoHeightSize,
            ),
          ),
          const Center(child: AuthSlogan()),
          const SizedBox(height: 30),
        ],
      );
    });
  }
}

/// 认证页口号。
class AuthSlogan extends StatelessWidget {
  const AuthSlogan({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceInfo = Get.find<DeviceInfo>();

    return Obx(() {
      final bool isDark = deviceInfo.dark.value;
      final Color textColor = AuthPageStyle.primaryTextColor(isDark);

      final LanguageStore languageStore = Get.find<LanguageStore>();
      final LanguageInfo? currentLanguageInfo =
          languageStore.find_supported_language_by_code(
        context.locale.languageCode,
      );
      final String sloganText = (currentLanguageInfo != null &&
              currentLanguageInfo.remark.isNotEmpty)
          ? currentLanguageInfo.remark
          : context.tr('login.slogan');

      return SizedBox(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: AuthPageStyle.sloganWidth,
              height: AuthPageStyle.sloganHeight,
              decoration: AuthPageStyle.sloganGradientBar(
                isDark: isDark,
                reverse: false,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                sloganText,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: AuthPageStyle.sloganWidth,
              height: AuthPageStyle.sloganHeight,
              decoration: AuthPageStyle.sloganGradientBar(
                isDark: isDark,
                reverse: true,
              ),
            ),
          ],
        ),
      );
    });
  }
}
