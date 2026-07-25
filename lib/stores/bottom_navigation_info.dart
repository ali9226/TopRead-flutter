import 'package:get/get.dart';

class BottomNavigationInfo extends GetxController {
  // TODO 是否展示
  var expandedState = false.obs;

  // TODO 确定取消的弹窗，点击后退是否要关闭
  var showMessageState = false.obs;

  // TODO 操作按钮的高度
  var actionButtonsHeight = 55.0.obs;

  // TODO 改变展开状态
  void changeExpandedState(bool status) {
    expandedState.value = status; // TODO 自动通知界面更新
  }

  // TODO 改变取消/确定的弹窗状态
  void changeShowMessageState(bool status) {
    showMessageState.value = status;
  }
}
