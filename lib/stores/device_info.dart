import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:app/util/device/save_theme_mode.dart';
import 'package:app/util/log_util.dart';

class DeviceInfo extends GetxController {
  /* TODO
   * 当前设备主题。
   *
   * light: 亮色
   * dark: 深色
   */
  var theme = ThemeMode.light.obs;

  // TODO 是否是深色主题
  var dark = false.obs;

  /* TODO
   * 网络状态编码。
   *
   * 0: 没有网络
   * 1: 移动网络
   * 2: WiFi
   * 3: 有线网络
   * 4: VPN
   * 5: 蓝牙网络
   * 6: 其它网络
   */
  var networkStatus = 0.obs;

  // TODO 设置网络状态
  Future<void> setNetworkStatus() async {
    logUtil(msg: "设置网络状态");
    final List<ConnectivityResult> connectivityResult = await (Connectivity()
        .checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      networkStatus.value = 1;
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      networkStatus.value = 2;
    } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
      networkStatus.value = 3;
    } else if (connectivityResult.contains(ConnectivityResult.vpn)) {
      networkStatus.value = 4;
    } else if (connectivityResult.contains(ConnectivityResult.bluetooth)) {
      networkStatus.value = 5;
    } else if (connectivityResult.contains(ConnectivityResult.other)) {
      networkStatus.value = 6;
    } else if (connectivityResult.contains(ConnectivityResult.none)) {
      networkStatus.value = 0;
    }
  }

  // TODO 改变主题
  void changeTheme(ThemeMode themeMode) {
    theme.value = themeMode;

    dark.value = theme.value == ThemeMode.dark;

    // TODO 把主题保存到本地
    saveThemeMode(themeMode);
  }
}
