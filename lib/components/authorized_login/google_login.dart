// ignore_for_file: non_constant_identifier_names

// 【临时注释】Google 登录因 CocoaPods GTMSessionFetcher 依赖冲突暂时禁用。
// 根因：GoogleSignIn SDK 依赖 GTMSessionFetcher ~> 3.3，但 Google 已从 GitHub 删除 3.x 全部 git tag。
// 恢复步骤：
//   1. 在 pubspec.yaml 中取消注释 firebase_core、firebase_auth、google_sign_in
//   2. 恢复 main.dart 中的 Firebase.initializeApp()
//   3. 恢复本文件原始实现（见 git 历史）
//   4. 运行 flutter pub get && cd ios && pod install

import 'package:app/stores/authorized_login_store.dart';
import 'package:app/util/log_util.dart';
import 'package:get/get.dart';

/// Google 登录 - 暂时禁用，返回 null。
Future<dynamic> google_login() async {
  final AuthorizedLoginStore authorized_login_store = Get.find<AuthorizedLoginStore>();

  if (authorized_login_store.loading.value) {
    logUtil(msg: "谷歌登录正在进行中，请勿重复操作");
    return null;
  }

  logUtil(msg: "谷歌登录功能暂时禁用（Firebase CocoaPods 依赖冲突）");
  return null;
}
