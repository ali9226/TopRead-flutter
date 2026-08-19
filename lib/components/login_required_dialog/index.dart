import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:get/get.dart';

import 'package:app/components/svg_icon/index.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/show_message.dart';
import 'package:app/util/router/router_util.dart';

/// 公用未登录拦截弹窗。
///
/// 作用：
/// 1. 在用户未登录时弹出统一提示弹窗。
/// 2. 通过 [title] 定制不同场景的提示文案。
/// 3. 点击"去登录"跳转登录页，点击"取消"关闭弹窗。
///
/// 返回 `true` 表示用户已登录（无需弹窗），
/// 返回 `false` 表示用户未登录且已弹出提示。
Future<bool> showLoginRequiredDialog({required String title}) async {
  final UserInformation user_information = Get.find<UserInformation>();

  /// 已登录，无需弹窗。
  if (user_information.isLoggedIn.value) return true;

  /// 未登录，弹出提示弹窗。
  await showMessage(
    message: title,
    leftButtonText: easy.tr('constant.cancel'),
    rightButtonText: easy.tr('message.no_login.go_login'),
    allowMaskDismiss: true,
    iconWidget: SvgIcon(
      name: 'logo',
      width: 36,
      height: 36,
    ),
    onRightPressed: () async {
      routerUtil(path: '/login');
    },
  );

  return false;
}
