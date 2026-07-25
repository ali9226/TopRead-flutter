// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/auth_page/style.dart';
import 'package:app/components/language_selection/index.dart';
import 'package:app/components/page_top_gradient_overlay/index.dart';
import 'package:app/stores/device_info.dart';

/// 认证页顶部栏（渐变遮罩 + 语种切换）。
///
/// 包含：
/// - 顶部渐变遮罩
/// - 语种切换组件
class AuthTopBar extends StatelessWidget {
  const AuthTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceInfo = Get.find<DeviceInfo>();

    return Obx(() {
      final bool isDark = deviceInfo.dark.value;
      final List<Color> backgroundColors = AuthPageStyle.backgroundGradient(
        isDark,
      );

      return Stack(
        children: [
          PageTopGradientOverlay(
            background_color: backgroundColors.first,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LanguageSelection(
              showLeftIcon: true,
              darkBackground: isDark,
              useSafeAreaTop: true,
              topOffset: 10,
              horizontalPadding: AuthPageStyle.fieldHorizontalPadding,
            ),
          ),
        ],
      );
    });
  }
}
