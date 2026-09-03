import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/auth_page/index.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/pages/user_info/logic.dart' as user_info_logic;

import 'apply_view.dart';
import 'style.dart';

/// 申请成为作家页面（未认证用户）。
///
/// author == 1 时展示申请表单；若已认证则自动跳转创作中心。
class AuthorApplyPage extends StatefulWidget {
  const AuthorApplyPage({super.key});

  @override
  State<AuthorApplyPage> createState() => _AuthorApplyPageState();
}

class _AuthorApplyPageState extends State<AuthorApplyPage> {
  final userInformation = Get.find<UserInformation>();

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

      if (author == 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) routerUtil(path: '/author_center', type: 'replace');
        });
        return const SizedBox.shrink();
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
