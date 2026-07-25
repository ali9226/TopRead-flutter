import 'package:flutter/material.dart';
import 'package:app/stores/device_info.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'logic.dart';

// TODO 模版
class Test extends StatefulWidget {
  const Test({super.key});

  @override
  State<Test> createState() => _TestState();
}

class _TestState extends State<Test> {
  final deviceInfo = Get.find<DeviceInfo>();
  late Logic logic;

  @override
  void initState() {
    super.initState();
    logic = Logic(context);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      easy.tr('SelectionLanguage.done'),
      style: TextStyle(fontSize: 24),
    );
  }
}
