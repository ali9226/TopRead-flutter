import 'package:get/get.dart';
import 'package:app/models/user_info.dart';

class UserInformation extends GetxController {
  var userInfo = Rxn<UserInfo>(); // TODO 用户信息，默认 null
  var isLoggedIn = false.obs; // TODO 登录状态 RxBool

  @override
  void onInit() {
    super.onInit();

    // TODO 监听 userInfo 的变化，自动更新 isLoggedIn
    ever(userInfo, (_) {
      final info = userInfo.value;
      isLoggedIn.value = info != null && info.id != 0;
    });
  }

  // TODO 保存用户信息
  void saveUserInfo(UserInfo info) {
    userInfo.value = info; // 自动触发 ever 监听
  }

  // TODO 清空用户信息（登出）
  void clearUserInfo() {
    userInfo.value = null; // TODO 自动触发 ever 监听
  }
}
