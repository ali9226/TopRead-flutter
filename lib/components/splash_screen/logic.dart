// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/stores/device_info.dart';
import 'style.dart';

/// 开屏页面逻辑控制器
class SplashScreenLogic extends GetxController {
  /// 当前设备信息
  final DeviceInfo _device_info = Get.find<DeviceInfo>();

  /// 淡出动画控制器
  AnimationController? _fade_controller;

  /// 是否已完成开屏
  final RxBool _is_completed = false.obs;

  /// 是否已完成开屏
  bool get is_completed => _is_completed.value;

  /// 获取当前开屏图片路径
  ///
  /// 根据横竖屏和日夜间模式返回对应的图片路径
  String get_splash_image(BuildContext context) {
    // 判断是否是横屏
    final bool is_landscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // 判断是否是夜间模式
    final bool is_dark = _device_info.dark.value;

    // 根据横竖屏和日夜间模式返回对应的图片路径
    if (is_landscape) {
      return is_dark
          ? SplashScreenStyle.landscape_dark_image
          : SplashScreenStyle.landscape_light_image;
    } else {
      return is_dark
          ? SplashScreenStyle.vertical_screen_dark_image
          : SplashScreenStyle.vertical_screen_light_image;
    }
  }

  /// 初始化淡出动画控制器
  ///
  /// [controller] 动画控制器
  void init_fade_controller(AnimationController controller) {
    _fade_controller = controller;
  }

  /// 开始开屏流程
  ///
  /// 展示指定时长后淡出，完成后标记为已完成
  Future<void> start_splash() async {
    if (_is_completed.value) return;

    // 等待展示时长
    await Future.delayed(
      Duration(milliseconds: SplashScreenStyle.display_duration_ms),
    );

    // 执行淡出动画
    if (_fade_controller != null) {
      await _fade_controller!.forward();
    }

    // 标记为已完成
    _is_completed.value = true;
  }

  @override
  void onClose() {
    _fade_controller?.dispose();
    super.onClose();
  }
}
