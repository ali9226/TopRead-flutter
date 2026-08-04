import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/stores/device_info.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'advertising_id/index.dart';
import 'fcm_token/index.dart';
import 'limit_ad_tracking/index.dart';
import 'rewarded_ad/index.dart';
import 'style.dart';

/// 调试页面。
///
/// 每个调试操作由独立目录内的组件和逻辑管理。
class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DeviceInfo deviceInfo = Get.find<DeviceInfo>();

    return Obx(() {
      final bool isDark = deviceInfo.dark.value;

      return Scaffold(
        backgroundColor: isDark
            ? ColorConstants.nightBackgroundColor
            : ColorConstants.whiteColor,
        appBar: AppBar(
          backgroundColor: isDark
              ? ColorConstants.nightBackgroundColor
              : ColorConstants.whiteColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : ColorConstants.lightTextColor,
              size: 20,
            ),
            onPressed: () => AppRouter.pop(),
          ),
          title: Text(
            easy.tr('debug.title'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
              color: isDark ? Colors.white : ColorConstants.lightTextColor,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            Style.pageHorizontalPadding,
            Style.pageTopPadding,
            Style.pageHorizontalPadding,
            MediaQuery.paddingOf(context).bottom + Style.pageBottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FcmTokenDebugItem(isDark: isDark),
              const SizedBox(height: Style.itemSpacing),
              AdvertisingIdDebugItem(isDark: isDark),
              const SizedBox(height: Style.itemSpacing),
              LimitAdTrackingDebugItem(isDark: isDark),
              const SizedBox(height: Style.itemSpacing),
              RewardedAdDebugItem(isDark: isDark),
            ],
          ),
        ),
      );
    });
  }
}
