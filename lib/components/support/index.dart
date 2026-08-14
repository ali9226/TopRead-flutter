import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/customer_service/index.dart';
import 'package:app/stores/project_config_store.dart';

/// 联系客服组件。
///
/// 根据 project_config 的 contact_customer_service_switch 字段判断是否展示。
class Support extends StatefulWidget {
  const Support({super.key});

  @override
  State<Support> createState() => _SupportState();
}

class _SupportState extends State<Support> with WidgetsBindingObserver {
  /// 项目配置仓库。
  final projectConfigStore = Get.find<ProjectConfigStore>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 联系客服开关关闭时隐藏组件。
    if (!projectConfigStore.current.is_contact_customer_service_enabled) {
      return const SizedBox.shrink();
    }

    return CustomerServiceView();
  }
}
