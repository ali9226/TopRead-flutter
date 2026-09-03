import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/auth_page/index.dart';
import 'package:app/pages/user_info/logic.dart' as user_info_logic;
import 'package:app/stores/user_information.dart';
import 'package:app/util/router/router_util.dart';

import 'apply_view.dart';
import 'author_view.dart';
import 'style.dart';

/// 创作者中心页面。
///
/// 根据用户的 author 状态展示不同内容：
/// - author == 1：展示申请表单（ApplyView）
/// - author == 2：展示作者主页（AuthorView）
class InstallationPage extends StatefulWidget {
  const InstallationPage({super.key});

  @override
  State<InstallationPage> createState() => _InstallationPageState();
}

class _InstallationPageState extends State<InstallationPage> {
  final userInformation = Get.find<UserInformation>();

  /// 提交成功后刷新用户信息再返回用户中心。
  Future<void> _onApplySuccess() async {
    if (!mounted) return;
    final logic = user_info_logic.Logic();
    await logic.refreshUserInfo(showSuccessTip: false);
    if (mounted) {
      routerUtil(path: '/user_info', type: 'replace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final int author = userInformation.userInfo.value?.author ?? 1;

      /// 已认证作者进入独立创作工作台，不复用申请页的窄表单滚动容器。
      if (author == 2) {
        return const AuthorView();
      }

      final String mail = userInformation.userInfo.value?.mail ?? '';
      return AuthPageScaffold(
        backgroundBubbles: Style.pageBubbles,
        children: <Widget>[
          ApplyView(onSuccess: _onApplySuccess, initialEmail: mail),
        ],
      );
    });
  }
}
