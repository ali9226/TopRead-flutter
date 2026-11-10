import 'package:flutter/material.dart';

/// TODO 横滑切页时保留每页的滚动位置、搜索状态和已构建的目录定位锚点。
class DirectoryKeepAlivePanel extends StatefulWidget {
  const DirectoryKeepAlivePanel({super.key, required this.child});
  final Widget child;
  @override
  State<DirectoryKeepAlivePanel> createState() =>
      _DirectoryKeepAlivePanelState();
}

class _DirectoryKeepAlivePanelState extends State<DirectoryKeepAlivePanel>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
