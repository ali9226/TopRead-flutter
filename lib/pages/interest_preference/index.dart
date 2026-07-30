import 'package:flutter/material.dart';

import 'package:app/pages/interest_preference/widgets/preference_content/index.dart';

/// 普通兴趣偏好页面。
///
/// 路由路径：/interest_preference
/// 从用户中心或其他业务入口进入时，返回、放弃修改和保存成功均维持原有 pop
/// 逻辑，不展示注册流程专用的“跳过”按钮。
class InterestPreferencePage extends StatelessWidget {
  const InterestPreferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return InterestPreferenceContent(
      onExit: () {
        Navigator.of(context).pop();
      },
    );
  }
}
