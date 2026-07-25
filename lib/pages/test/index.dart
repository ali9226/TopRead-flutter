import 'package:flutter/material.dart';
import 'logic.dart';

/// 测试页面模板。
///
/// 当前页面只保留最基础的脚手架结构，
/// 主要用于临时验证组件或交互，不承载正式业务逻辑。
class Test extends StatefulWidget {
  const Test({super.key});

  @override
  State<Test> createState() => _TestState();
}

class _TestState extends State<Test> {
  /// 页面逻辑层。
  late Logic logic;

  @override
  void initState() {
    super.initState();

    /// 初始化测试页逻辑层。
    logic = Logic(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// 顶部测试标题。
      appBar: AppBar(title: Text('测试')),

      /// 页面主体目前只放一段占位测试文本。
      body: Stack(children: [Text('测试内容', style: TextStyle(fontSize: 24))]),
    );
  }
}
