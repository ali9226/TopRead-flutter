import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:app/components/app_wrapper/router/route_config.dart';
import 'package:app/components/app_wrapper/router/back_button_dispatcher.dart';
import 'package:app/components/app_wrapper/back_handler/back_handler.dart';
import 'package:app/components/app_wrapper/auto_login/auto_login.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/components/app_wrapper/utils/get_app_title.dart';
import 'package:app/components/app_wrapper/utils/route_page_warm_up.dart';
import 'package:app/components/app_wrapper/utils/route_asset_warm_up.dart';
import 'package:app/components/splash_screen/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/permission_request/admob_consent_permission_request.dart';
import 'package:app/permission_request/app_tracking_transparency_permission_request.dart';
import 'package:app/permission_request/notification_permission_request.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/util/device/app_environment.dart';
import 'package:app/stores/bottom_navigation_info.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/ad_display_policy.dart';

/// AppWrapper 是整个应用的根容器。
///
/// 职责：
/// 1. 初始化 GoRouter 路由树。
/// 2. 注册统一后退处理器到 AppRouter。
/// 3. 通过系统级分发器和页面级包装器，让所有后退动作汇总到同一处判断。
class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  /// 应用全局唯一的 GoRouter。
  late final GoRouter _router;

  /// 系统级后退分发器。
  late final AppBackButtonDispatcher _backButtonDispatcher;

  /// 底部导航的状态控制器。
  final bottomNavigationInfo = Get.find<BottomNavigationInfo>();

  /// 设备主题等运行时信息。
  final deviceInfo = Get.find<DeviceInfo>();

  /// 是否显示开屏页面
  bool _show_splash = true;

  /// 监听 RouterDelegate 的真实路由变化。
  ///
  /// 覆盖 iOS 左缘侧滑返回、系统默认 pop 等未经过 AppRouter 门面的路由变化。
  void _handleRouterDelegateChanged() {
    AppRouter.syncRouteChange();
  }

  @override
  void initState() {
    super.initState();

    // Web：让地址栏反映 push / replace 等命令式导航到的顶层路由。
    if (kIsWeb) {
      GoRouter.optionURLReflectsImperativeAPIs = true;
    }

    // 配置应用完整路由表。
    _router = RouteConfig.createRouter();

    // 把 GoRouter 暴露给全局门面。
    AppRouter.setRouter(_router);
    _router.routerDelegate.addListener(_handleRouterDelegateChanged);

    // 注册统一后退处理器。
    AppRouter.setBackHandler(
      () => BackHandler.handleBack(bottomNavigationInfo),
    );

    // 系统返回统一走 Router 级别分发器。
    _backButtonDispatcher = AppBackButtonDispatcher(
      onBackPressed: () => BackHandler.handleBack(bottomNavigationInfo),
      onDefaultBack: () {
        if (_router.canPop()) {
          AppRouter.pop();
          return true;
        }
        return false;
      },
    );

    // 第一帧渲染完成后再做自动登录。
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // 启动权限 UI 串行调度：UMP/IDFA/ATT 本次有实际弹窗就结束；
      // 若都没有弹窗，再检查并按需请求通知权限。
      unawaited(_run_startup_permission_flow());

      unawaited(RouteAssetWarmUp.warmUpAfterFirstFrame(context));
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 420), () async {
          if (!mounted) return;
          await RoutePageWarmUp.warmUpAfterFirstFrame();
        }),
      );
      autoLogin();
    });
  }

  Future<void> _run_startup_permission_flow() async {
    // 等待远端广告平台配置加载完成。
    final bool can_show_ads = await AdDisplayPolicy.wait_until_resolved();
    if (!mounted) return;

    final ProjectConfigStore config_store = Get.find<ProjectConfigStore>();
    final bool is_review_mode =
        config_store.is_config_loaded.value &&
        config_store.current.is_apple_review_mode;

    // ---- 广告关闭 + 非审核模式：跳过所有隐私流程 ----
    if (!can_show_ads && !is_review_mode) {
      await NotificationPermissionRequest.request_on_app_start_if_needed();
      return;
    }

    // ---- 广告关闭 + 审核模式 + iOS：仅请求 ATT ----
    // 审核期间必须展示 ATT 弹窗，即使广告开关关闭也不能跳过。
    if (!can_show_ads && is_review_mode && isIOSApp) {
      await _request_att_if_needed();
      if (!mounted) return;
      await NotificationPermissionRequest.request_on_app_start_if_needed();
      return;
    }

    // ---- 广告开启 + 审核模式：跳过 UMP，iOS 直接请求 ATT ----
    if (can_show_ads && is_review_mode) {
      if (isIOSApp) {
        await _request_att_if_needed();
        if (!mounted) return;
      }
      // Android 审核模式走正常 UMP 流程（UMP 会展示同意表单）。
      if (!isIOSApp) {
        final bool can_continue = await _run_ump_flow();
        if (!mounted || !can_continue) return;
      }
      await NotificationPermissionRequest.request_on_app_start_if_needed();
      return;
    }

    // ---- 广告开启 + 非审核模式：正常 UMP 流程 ----
    final bool can_continue = await _run_ump_flow();
    if (!mounted || !can_continue) return;
    await NotificationPermissionRequest.request_on_app_start_if_needed();
  }

  /// iOS ATT 弹窗：仅在未决定时请求，已决定则跳过。
  Future<void> _request_att_if_needed() async {
    final AppTrackingAuthorizationStatus att_status =
        await AppTrackingTransparencyPermissionRequest.get_authorization_status();
    if (att_status == AppTrackingAuthorizationStatus.not_determined) {
      await AppTrackingTransparencyPermissionRequest.request_tracking_authorization();
    }
  }

  /// UMP 流程：展示法规表单，iOS 上可能链式触发 ATT。
  ///
  /// 返回 true 表示本次没有出现系统弹窗，可以继续检查通知权限；
  /// 返回 false 表示已有弹窗出现，应跳过通知权限。
  Future<bool> _run_ump_flow() async {
    bool did_present_system_prompt = false;
    final AppLifecycleListener lifecycle_listener = AppLifecycleListener(
      onStateChange: (AppLifecycleState state) {
        if (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused) {
          did_present_system_prompt = true;
        }
      },
    );

    late final AdMobStartupPrivacyResult privacy_result;
    try {
      privacy_result =
          await AdMobConsentPermissionRequest.initialize_on_app_start_with_result();
    } finally {
      lifecycle_listener.dispose();
    }

    if (did_present_system_prompt ||
        !privacy_result.can_continue_to_notification_permission) {
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_handleRouterDelegateChanged);
    AppRouter.clearBackHandler();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => MaterialApp.router(
        title: getAppTitle(context),
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: FontConfig.platformFontFamily,
          textTheme: FontConfig.adjustedTextTheme(ThemeData.light().textTheme),
          colorScheme: ColorScheme.fromSeed(
            seedColor: ColorConstants.themeColor,
            primary: ColorConstants.themeColor,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: ColorConstants.whiteColor,
          canvasColor: ColorConstants.whiteColor,
        ),
        darkTheme: ThemeData(
          fontFamily: FontConfig.platformFontFamily,
          textTheme: FontConfig.adjustedTextTheme(ThemeData.dark().textTheme),
          colorScheme: ColorScheme.dark(
            brightness: Brightness.dark,
            primary: ColorConstants.themeColor,
            secondary: ColorConstants.themeColor,
            surface: Color(0xFF1E1E1E),
            onPrimary: ColorConstants.whiteColor,
            onSecondary: ColorConstants.nightBackgroundColor,
            onSurface: ColorConstants.whiteColor,
          ),
          scaffoldBackgroundColor: ColorConstants.nightBackgroundColor,
          appBarTheme: AppBarTheme(
            backgroundColor: ColorConstants.themeColor,
            foregroundColor: ColorConstants.whiteColor,
          ),
          inputDecorationTheme: InputDecorationTheme(
            hintStyle: TextStyle(color: Colors.white54),
            labelStyle: TextStyle(color: ColorConstants.whiteColor),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white54),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: ColorConstants.whiteColor),
            ),
          ),
          iconTheme: IconThemeData(color: Colors.white),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: ColorConstants.themeColor,
            foregroundColor: ColorConstants.nightBackgroundColor,
          ),
        ),
        themeMode: deviceInfo.theme.value,
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        routeInformationProvider: _router.routeInformationProvider,
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        backButtonDispatcher: _backButtonDispatcher,
        builder: (context, child) {
          final smartDialogBuilder = FlutterSmartDialog.init();
          final smartDialogChild = smartDialogBuilder(context, child);

          // 如果需要显示开屏页面，使用 Stack 将开屏页面覆盖在最上层
          if (_show_splash) {
            return Stack(
              children: [
                smartDialogChild,
                SplashScreen(
                  on_complete: () {
                    // 开屏完成后隐藏开屏页面
                    setState(() {
                      _show_splash = false;
                    });
                  },
                ),
              ],
            );
          }

          return smartDialogChild;
        },
      ),
    );
  }
}
