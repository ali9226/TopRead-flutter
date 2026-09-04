// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/services/splash_screen_ad_service.dart';
import 'logic.dart';
import 'style.dart';

/// 开屏页面组件
///
/// 根据横竖屏和日夜间模式展示对应的开屏图片。
/// 展示指定时长后淡出，不影响其他业务逻辑。
/// 如果有可用的谷歌 App Open 广告，会在开屏期间展示广告。
class SplashScreen extends StatefulWidget {
  /// 开屏完成后的回调。
  final VoidCallback? on_complete;

  const SplashScreen({super.key, this.on_complete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// 逻辑控制器。
  late final SplashScreenLogic _logic;

  /// 淡出动画控制器。
  late final AnimationController _fade_controller;

  /// 淡出动画。
  late final Animation<double> _fade_animation;

  /// 开屏广告服务。
  late final SplashScreenAdService _ad_service;

  /// 广告状态监听器。
  Worker? _ad_worker;

  @override
  void initState() {
    super.initState();

    // 初始化逻辑控制器。
    _logic = Get.put(SplashScreenLogic());

    // 初始化淡出动画控制器。
    _fade_controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: SplashScreenStyle.fade_out_duration_ms),
    );

    // 初始化淡出动画（从1.0到0.0）。
    _fade_animation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fade_controller, curve: Curves.easeOut),
    );

    // 将动画控制器传递给逻辑层。
    _logic.init_fade_controller(_fade_controller);

    // 获取开屏广告服务。
    _ad_service = Get.find<SplashScreenAdService>();

    // 监听广告加载状态，加载完成时展示广告。
    _ad_worker = ever(_ad_service.is_ad_loaded_rx, (bool is_loaded) {
      if (is_loaded && mounted) {
        _ad_service.show_ad();
      }
    });

    // 如果广告已加载，立即展示。
    if (_ad_service.is_ad_loaded) {
      _ad_service.show_ad();
    }

    // 开始开屏流程。
    _logic.start_splash().then((_) {
      // 开屏完成后触发回调。
      widget.on_complete?.call();
    });
  }

  @override
  void dispose() {
    // 释放广告状态监听器。
    _ad_worker?.dispose();
    // 释放逻辑控制器。
    Get.delete<SplashScreenLogic>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 开屏完成后不渲染任何内容。
      if (_logic.is_completed) {
        return const SizedBox.shrink();
      }

      // 获取当前开屏图片路径。
      final String image_path = _logic.get_splash_image(context);

      // 构建开屏图片层。
      return FadeTransition(
        opacity: _fade_animation,
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: Image.asset(image_path),
          ),
        ),
      );
    });
  }
}
