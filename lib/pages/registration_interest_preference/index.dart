// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

import 'package:app/pages/interest_preference/widgets/preference_content/index.dart';
import 'package:app/util/router/router_util.dart';

/// 注册完成后的兴趣偏好页面。
///
/// 路由路径：/registration_interest_preference
/// 返回、放弃修改、保存成功和点击“跳过”都会结束注册引导并进入首页。
class RegistrationInterestPreferencePage extends StatelessWidget {
  const RegistrationInterestPreferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return InterestPreferenceContent(
      interceptSystemBack: true,
      onExit: _go_to_home,
      onSkip: _go_to_home,
    );
  }

  /// 结束注册引导并替换到首页，避免返回注册页。
  void _go_to_home() {
    routerUtil(path: '/', type: 'replace');
  }
}
