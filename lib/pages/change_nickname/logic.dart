// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/api/post_request.dart';
import 'package:app/config/constant.dart';
import 'package:app/models/user_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/util/storage_util/index.dart';

/// 修改昵称页逻辑。
///
/// 该文件负责：
/// 1. 检查登录态；
/// 2. 执行昵称提交请求；
/// 3. 成功后同步用户资料缓存。
class Logic {
  /// 页面上下文。
  final BuildContext context;

  Logic(this.context);

  /// 检查本地登录态。
  ///
  /// 没有 token 时直接跳转到首页，不继续停留在表单页。
  Future<void> checkLoginStatus() async {
    final String token =
        (await StorageUtil.getData(Constant.tokenKey) ?? '').trim();
    if (token.isEmpty) {
      routerUtil(path: '/', type: 'replace');
    }
  }

  /// 提交新昵称。
  ///
  /// [inputValueMap] 包含用户输入的昵称，key 为 'nickname'。
  /// 返回 true 表示提交成功，false 表示提交失败或输入为空。
  Future<bool> submitNewNickname(Map<String, String> inputValueMap) async {
    final String inputText = inputValueMap['nickname']?.trim() ?? '';
    if (inputText.isEmpty) {
      showBottomTip(easy.tr('UserInfo.error_03'));
      return false;
    }

    final Map<String, dynamic> parameter = <String, dynamic>{
      'name': inputText.trim(),
    };
    final results = await postRequest<UserInfo>(
      path: 'user/update_name',
      parameter: parameter,
      fromJson: (json) => UserInfo.fromJson(json),
    );
    if (!results.status) return false;
    if (results.content == null) return false;

    final userController = Get.find<UserInformation>();
    userController.saveUserInfo(results.content!);
    showBottomTip(easy.tr('UserInfo.success_04'));
    return true;
  }
}
