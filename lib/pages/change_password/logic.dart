// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/api/post_request.dart';
import 'package:app/config/constant.dart';
import 'package:app/models/login.dart';
import 'package:app/pages/user_info_input/logic.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/encryption/index.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:app/util/string/to_string.dart';

/// 修改密码页逻辑。
///
/// 该文件负责：
/// 1. 提供页面固定文案；
/// 2. 执行密码更新接口；
/// 3. 成功后刷新 token 与用户资料缓存。
class Logic {
  /// 页面上下文。
  final BuildContext context;

  Logic(this.context);

  /// 返回当前页面的输入壳配置。
  UserInfoInputViewConfig build_view_config(BuildContext build_context) {
    return UserInfoInputViewConfig(
      title: build_context.tr('UserInfo.update_login_password_title'),
      description_text: '',
      submit_button_text: build_context.tr('game.action.confirm'),
      field_list: <UserInfoInputFieldConfig>[
        UserInfoInputFieldConfig(
          field_key: 'new_password',
          hint_text: build_context.tr('UserInfo.tips_02'),
          obscure_text: true,
          keyboard_type: TextInputType.visiblePassword,
          text_input_action: TextInputAction.next,
        ),
        UserInfoInputFieldConfig(
          field_key: 'confirm_password',
          hint_text: build_context.tr('UserInfo.tips_06'),
          obscure_text: true,
          keyboard_type: TextInputType.visiblePassword,
          text_input_action: TextInputAction.done,
        ),
      ],
      on_submit: submit_new_password,
    );
  }

  /// 提交新密码。
  Future<bool> submit_new_password(Map<String, String> input_value_map) async {
    final String input_text = input_value_map['new_password']?.trim() ?? '';
    final String confirm_text =
        input_value_map['confirm_password']?.trim() ?? '';
    if (input_text.isEmpty) {
      showBottomTip(easy.tr('UserInfo.error_02'));
      return false;
    }
    if (confirm_text.isEmpty) {
      showBottomTip(easy.tr('UserInfo.error_07'));
      return false;
    }
    if (input_text != confirm_text) {
      showBottomTip(easy.tr('UserInfo.error_08'));
      return false;
    }

    final Map<String, dynamic> parameter = <String, dynamic>{
      'password': passwordEncryption(removeSpaces(input_text)),
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

    final user_controller = Get.put(UserInformation());
    if (results.content?.userInfo != null) {
      user_controller.saveUserInfo(results.content!.userInfo);
    }

    showBottomTip(easy.tr('UserInfo.success_03'));
    return true;
  }
}
