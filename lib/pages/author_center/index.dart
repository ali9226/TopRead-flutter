import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/router/router_util.dart';

import 'author_view.dart';

/// 创作者中心页面（已认证作者）。
///
/// author == 2 时展示创作工作台；若未认证则自动跳转申请页。
class AuthorCenterPage extends StatelessWidget {
  const AuthorCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userInformation = Get.find<UserInformation>();

    return Obx(() {
      final int author = userInformation.userInfo.value?.author ?? 1;

      if (author != 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          routerUtil(path: '/author_apply', type: 'replace');
        });
        return const SizedBox.shrink();
      }

      return const AuthorView();
    });
  }
}
