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
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/permission_request/admob_consent_permission_request.dart';
import 'package:app/permission_request/notification_permission_request.dart';
import 'package:app/stores/bottom_navigation_info.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/project_config_store.dart';

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
    // 广告开关关闭时跳过 UMP 初始化。
    final ProjectConfigStore projectConfigStore = Get.find<ProjectConfigStore>();
    if (!projectConfigStore.current.is_ads_enabled) {
      // 仅检查通知权限。
      await NotificationPermissionRequest.request_on_app_start_if_needed();
      return;
    }

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

    if (!mounted ||
        did_present_system_prompt ||
        !privacy_result.can_continue_to_notification_permission) {
      return;
    }
    await NotificationPermissionRequest.request_on_app_start_if_needed();
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_handleRouterDelegateChanged);
    AppRouter.clearBackHandler();
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
          return smartDialogChild;
        },
      ),
    );
  }
}
