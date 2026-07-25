import 'package:flutter/material.dart';
import 'package:app/util/dialog/pop_up_input.dart';
import 'package:app/util/dialog/show_message.dart';

/**
 * TODO 个人中心弹窗预热调度器。
 * 作用：
 * 1. 统一管理“修改昵称 / 修改密码 / 退出登录”这类弹窗的后台预热时机。
 * 2. 避免页面里分别调用多个预热函数，导致维护分散。
 * 3. 后续如果还要预热其他个人中心弹层，只需要继续收口到这里。
 */
class UserInfoDialogWarmUp {
  static bool _hasStarted = false;

  static Future<void> warmUp({required BuildContext context}) async {
    if (_hasStarted) return;
    _hasStarted = true;

    await PopUpInputWarmUp.warmUp(context: context);
    await ShowMessageWarmUp.warmUp(context: context);
  }
}
