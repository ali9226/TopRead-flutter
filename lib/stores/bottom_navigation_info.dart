import 'package:get/get.dart';

/// 底部导航栏展开/收起状态管理。
class BottomNavigationInfo extends GetxController {
  /// 是否处于展开状态。
  var expandedState = false.obs;

  /// 确认/取消弹窗是否显示（点击后退时是否需要关闭弹窗）。
  var showMessageState = false.obs;

  /// 操作按钮区域的高度。
  var actionButtonsHeight = 55.0.obs;

  /// 切换展开状态。
  ///
  /// [status] 目标展开状态。
  void changeExpandedState(bool status) {
    expandedState.value = status;
  }

  /// 切换确认/取消弹窗的显示状态。
  ///
  /// [status] 目标显示状态。
  void changeShowMessageState(bool status) {
    showMessageState.value = status;
  }
}
