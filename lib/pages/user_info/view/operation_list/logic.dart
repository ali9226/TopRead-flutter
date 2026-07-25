import 'package:app/api/post_request.dart';
import 'package:app/config/constant.dart';
import 'package:app/models/login.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/encryption/index.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/util/router/router_util.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:app/util/string/to_string.dart';
import 'package:get/get.dart';

// TODO 类似js的逻辑处理
class Logic {
  final BuildContext context;

  Logic(this.context);

  /// 打开“修改密码”页面。
  Future<void> updatePassword() async {
    routerUtil(path: '/change_password');
  }

  /// 提交新密码。
  // ignore: non_constant_identifier_names
  Future<bool> submit_password_update(String inputText) async {
    if (inputText.trim().isEmpty) {
      showBottomTip(easy.tr('UserInfo.error_02'));
      return false;
    }
    final Map<String, dynamic> parameter = <String, dynamic>{
      'password': passwordEncryption(removeSpaces(inputText)),
    };
    final results = await postRequest<Login>(
      path: 'user/update_password',
      parameter: parameter,
      fromJson: (json) => Login.fromJson(json),
    );
    if (!results.status) return false;
    if (results.content == null) return false;
    final String token = results.content?.token.toString() ?? '';
    if (token.isEmpty) return false;
    await StorageUtil.saveData(Constant.tokenKey, token);

    // TODO 保存 userInfo
    final userController = Get.put(UserInformation());
    if (results.content?.userInfo != null) {
      userController.saveUserInfo(results.content!.userInfo);
    }

    // TODO 密码更改成功
    showBottomTip(easy.tr('UserInfo.success_03'));
    return true;
  }
}
