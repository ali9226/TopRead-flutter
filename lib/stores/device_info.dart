import 'dart:async';

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

  /// 网络状态变更流订阅。
  ///
  /// 监听系统级网络切换事件，实时更新 [networkStatus]。
  StreamSubscription<List<ConnectivityResult>>? _connectivity_subscription;

  @override
  void onInit() {
    super.onInit();
    // 初始化时先查询一次当前网络状态。
    setNetworkStatus();
    // 订阅网络状态变更流，实时响应断网/恢复。
    _connectivity_subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      _apply_connectivity_results(results);
    });
  }

  @override
  void onClose() {
    _connectivity_subscription?.cancel();
    super.onClose();
  }

  // TODO 设置网络状态（手动调用，用于初始化或需要主动刷新时）。
  Future<void> setNetworkStatus() async {
    logUtil(msg: "设置网络状态");
    final List<ConnectivityResult> connectivityResult = await (Connectivity()
        .checkConnectivity());
    _apply_connectivity_results(connectivityResult);
  }

  /// 将连接性检测结果应用到 [networkStatus]。
  void _apply_connectivity_results(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.mobile)) {
      networkStatus.value = 1;
    } else if (results.contains(ConnectivityResult.wifi)) {
      networkStatus.value = 2;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      networkStatus.value = 3;
    } else if (results.contains(ConnectivityResult.vpn)) {
      networkStatus.value = 4;
    } else if (results.contains(ConnectivityResult.bluetooth)) {
      networkStatus.value = 5;
    } else if (results.contains(ConnectivityResult.other)) {
      networkStatus.value = 6;
    } else if (results.contains(ConnectivityResult.none)) {
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
