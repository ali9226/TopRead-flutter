// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/stores/user_information.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/language_util/language_change_handler.dart';
import 'package:app/util/language_util/language_permission.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// 在原有路由树上同步语种权限，切换语种不会销毁当前阅读页面。
class LanguagePermissionGuard extends StatefulWidget {
  final Widget child;

  const LanguagePermissionGuard({super.key, required this.child});

  @override
  State<LanguagePermissionGuard> createState() =>
      _LanguagePermissionGuardState();
}

class _LanguagePermissionGuardState extends State<LanguagePermissionGuard> {
  Worker? _user_permission_worker;
  bool _check_scheduled = false;
  bool _check_running = false;
  bool _initial_locale_synchronized = false;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<UserInformation>()) {
      final UserInformation user_information = Get.find<UserInformation>();
      _user_permission_worker = everAll([
        user_information.userInfo,
        user_information.isLoggedIn,
      ], (_) => _schedule_permission_check());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule_permission_check();
  }

  /// 合并同一帧内用户资料与登录状态的事件，避免重复刷新与构建期修改。
  void _schedule_permission_check() {
    if (_check_scheduled || !mounted) return;
    _check_scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _check_scheduled = false;
      if (mounted) unawaited(_enforce_permission());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// 权限撤销时使用现有协调器刷新配置和内容，同时清除旧中文偏好。
  Future<void> _enforce_permission() async {
    if (_check_running) return;
    _check_running = true;
    try {
      // EasyLocalization 的旧 locale 缓存可能绕过 startLocale，首屏统一校正。
      if (!_initial_locale_synchronized) {
        await context.deleteSaveLocale();
        if (!mounted) return;
        final String initial_code = await LanguageUtil.get_language();
        if (!mounted) return;
        await LanguageChangeHandler.change_language(context, initial_code);
        if (!mounted) return;
        setState(() => _initial_locale_synchronized = true);
      }
      if (LanguagePermission.can_use_chinese || !mounted) return;
      if (LanguagePermission.is_chinese(context.locale.languageCode) ||
          LanguagePermission.is_chinese(
            LanguageChangeHandler.current_language_code,
          )) {
        await LanguageChangeHandler.change_language(context, 'en');
        return;
      }
      await LanguageUtil.get_language();
    } finally {
      _check_running = false;
      if (mounted &&
          !LanguagePermission.can_use_chinese &&
          LanguagePermission.is_chinese(context.locale.languageCode)) {
        _schedule_permission_check();
      }
    }
  }

  @override
  void dispose() {
    _user_permission_worker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool locale_is_chinese = LanguagePermission.is_chinese(
      context.locale.languageCode,
    );
    return Obx(() {
      final bool can_use_chinese = LanguagePermission.can_use_chinese;
      return Offstage(
        // 隐藏受限旧首屏，但保留子树及路由状态，校正后原页继续显示。
        offstage:
            !_initial_locale_synchronized ||
            (locale_is_chinese && !can_use_chinese),
        child: widget.child,
      );
    });
  }
}
