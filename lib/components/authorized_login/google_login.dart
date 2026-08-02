// ignore_for_file: non_constant_identifier_names

import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/log_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google 登录结果数据。
class GoogleLoginResult {
  /// Firebase 用户信息。
  final User user;

  /// Firebase ID Token（用于后端验证）。
  final String firebaseIdToken;

  GoogleLoginResult({
    required this.user,
    required this.firebaseIdToken,
  });
}

/// 执行 Google 授权登录逻辑（通过 Firebase）。
///
/// 流程：
/// 1. 调用 GoogleSignIn 获取 Google 授权凭证
/// 2. 使用 GoogleAuthProvider 创建 Firebase 凭证
/// 3. 调用 FirebaseAuth 进行登录
/// 返回登录结果，若用户取消或失败则返回 null。
Future<GoogleLoginResult?> google_login() async {
  try {
    logUtil(msg: "开始 Google 授权登录");

    /// 调用 Google 登录授权接口。
    final GoogleSignInAccount google_user =
        await GoogleSignIn.instance.authenticate();

    /// 获取 Google 授权凭证。
    final GoogleSignInAuthentication google_auth = google_user.authentication;

    /// 打印 Google 返回的所有字段，用于调试。
    logUtil(msg: "===== Google 授权返回信息 =====");
    logUtil(msg: "idToken: ${google_auth.idToken}");
    logUtil(msg: "email: ${google_user.email}");
    logUtil(msg: "displayName: ${google_user.displayName}");
    logUtil(msg: "photoUrl: ${google_user.photoUrl}");
    logUtil(msg: "===== Google 授权返回信息结束 =====");

    /// 创建 Firebase Google 凭证。
    final OAuthCredential firebase_credential = GoogleAuthProvider.credential(
      idToken: google_auth.idToken,
    );

    /// 使用 Firebase 进行登录。
    logUtil(msg: "开始 Firebase Google 登录");
    final UserCredential user_credential =
        await FirebaseAuth.instance.signInWithCredential(firebase_credential);

    /// 打印 Firebase 返回的用户信息。
    final User? user = user_credential.user;
    if (user == null) {
      logUtil(msg: "Firebase 登录失败，未获取到用户信息", type: 'e');
      showBottomTip(tr('AuthorizedLogin.google_auth_failed'));
      return null;
    }

    logUtil(msg: "===== Firebase 登录成功 =====");
    logUtil(msg: "uid: ${user.uid}");
    logUtil(msg: "email: ${user.email}");
    logUtil(msg: "displayName: ${user.displayName}");
    logUtil(msg: "photoURL: ${user.photoURL}");
    logUtil(msg: "emailVerified: ${user.emailVerified}");

    /// 获取 Firebase ID Token，用于后端验证。
    final String? firebase_id_token = await user.getIdToken();
    logUtil(msg: "firebaseIdToken: $firebase_id_token");
    logUtil(msg: "===== Firebase 登录信息结束 =====");

    if (firebase_id_token == null || firebase_id_token.isEmpty) {
      logUtil(msg: "获取 Firebase ID Token 失败", type: 'e');
      showBottomTip(tr('AuthorizedLogin.google_auth_failed'));
      return null;
    }

    return GoogleLoginResult(
      user: user,
      firebaseIdToken: firebase_id_token,
    );
  } on GoogleSignInException catch (error) {
    /// 处理 Google 登录特有的异常。
    if (error.code == GoogleSignInExceptionCode.canceled) {
      logUtil(msg: "用户取消了 Google 登录");
    } else {
      logUtil(msg: "Google 登录失败: ${error.code} - ${error.description}", type: 'e');
      showBottomTip(tr('AuthorizedLogin.google_auth_failed'));
    }
    return null;
  } on FirebaseAuthException catch (error) {
    /// 处理 Firebase 认证异常。
    logUtil(msg: "Firebase Google 登录失败: ${error.code} - ${error.message}", type: 'e');
    showBottomTip(tr('AuthorizedLogin.google_auth_failed'));
    return null;
  } catch (error) {
    /// 处理其他未预期的异常。
    logUtil(msg: "Google 登录异常: $error", type: 'e');
    showBottomTip(tr('AuthorizedLogin.google_auth_failed'));
    return null;
  }
}
