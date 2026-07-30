import 'package:app/api/post_request.dart';
import 'package:app/config/constant.dart';
import 'package:app/models/login.dart';
import 'package:app/services/post_login_sync_service.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/encryption/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/util/storage_util/index.dart';
import 'package:app/util/string/to_string.dart';
import 'package:get/get.dart';

/// 注册页逻辑控制器。
class Logic {
  Logic();

  /// 用户输入的账号。
  String account = '';

  /// 用户输入的邀请码。
  String invitationCode = '';

  /// 用户输入的密码。
  String password = '';

  /// 账号是否已注册：null 表示未验证，true 已注册，false 未注册。
  bool? isAccountRegistered;

  /// 验证账号是否已注册。
  ///
  /// 调用 user/register_verify 接口，返回 true 表示已注册，false 表示未注册。
  Future<bool> verifyAccount() async {
    if (account.isEmpty) {
      isAccountRegistered = null;
      return false;
    }

    try {
      final results = await postRequest<Map<String, dynamic>>(
        path: 'user/register_verify',
        parameter: {'account': removeSpaces(account)},
        showTips: false,
        fromJson: (json) => json,
      );

      /// 接口返回 {status: true} 表示已注册。
      if (results.status && results.content != null) {
        isAccountRegistered = results.content!['status'] == true;
      } else {
        isAccountRegistered = false;
      }
      return isAccountRegistered!;
    } catch (e) {
      isAccountRegistered = null;
      return false;
    }
  }

  /// 执行注册请求。
  Future<bool> registerFun() async {
    if (account.isEmpty) {
      showBottomTip(easy.tr('login.account_tips'));
      return false;
    }

    if (password.isEmpty) {
      showBottomTip(easy.tr('login.password_tips'));
      return false;
    }

    final Map<String, dynamic> parameter = {
      'account': removeSpaces(account),
      'password': passwordEncryption(removeSpaces(password)),
      'invitation_code': invitationCode,
    };

    final results = await postRequest<Login>(
      path: 'user/register',
      parameter: parameter,
      fromJson: (json) => Login.fromJson(json),
    );
    if (!results.status) return false;
    if (results.content == null) return false;
    final String token = results.content?.token.toString() ?? '';
    if (token.isEmpty) return false;

    await StorageUtil.saveData(Constant.tokenKey, token);

    final userController = Get.put(UserInformation());
    if (results.content?.userInfo != null) {
      userController.saveUserInfo(results.content!.userInfo);
    }

    // 注册后同步属于后台可恢复任务，不阻塞页面完成注册。
    PostLoginSyncService.start();

    showBottomTip(easy.tr('register.success_01'));
    return true;
  }

  /// 执行登录请求（当账号已注册时使用）。
  Future<bool> login() async {
    if (account.isEmpty) {
      showBottomTip(easy.tr('login.account_tips'));
      return false;
    }

    if (password.isEmpty) {
      showBottomTip(easy.tr('login.password_tips'));
      return false;
    }

    final Map<String, dynamic> parameter = {
      'account': removeSpaces(account),
      'password': passwordEncryption(removeSpaces(password)),
    };

    final results = await postRequest<Login>(
      path: 'user/login',
      parameter: parameter,
      fromJson: (json) => Login.fromJson(json),
    );
    if (!results.status) return false;
    if (results.content == null) return false;
    final String token = results.content?.token.toString() ?? '';
    if (token.isEmpty) return false;

    await StorageUtil.saveData(Constant.tokenKey, token);

    final userController = Get.put(UserInformation());
    if (results.content?.userInfo != null) {
      userController.saveUserInfo(results.content!.userInfo);
    }

    // 登录后同步属于后台可恢复任务，不阻塞页面完成登录。
    PostLoginSyncService.start();

    showBottomTip(easy.tr('login.success_01'));
    return true;
  }
}
