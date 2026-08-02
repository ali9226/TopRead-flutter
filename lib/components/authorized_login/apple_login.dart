// ignore_for_file: non_constant_identifier_names

import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/log_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Apple 登录结果数据。
class AppleLoginResult {
  /// Firebase 用户信息。
  final User user;

  /// Firebase ID Token（用于后端验证）。
  final String firebaseIdToken;

  /// Apple 授权的 authorizationCode。
  final String authorizationCode;

  /// Apple 用户的 givenName（仅首次授权时返回）。
  final String? givenName;

  /// Apple 用户的 familyName（仅首次授权时返回）。
  final String? familyName;

  AppleLoginResult({
    required this.user,
    required this.firebaseIdToken,
    required this.authorizationCode,
    this.givenName,
    this.familyName,
  });
}

/// 执行 Apple 授权登录逻辑（通过 Firebase）。
///
/// 流程：
/// 1. 调用 sign_in_with_apple 获取 Apple 授权凭证
/// 2. 使用 OAuthProvider 创建 Firebase 凭证
/// 3. 调用 FirebaseAuth 进行登录
/// 返回登录结果，若用户取消或失败则返回 null。
Future<AppleLoginResult?> apple_login() async {
  try {
    logUtil(msg: "开始 Apple 授权登录");

    /// 检查当前设备是否支持 Apple 登录。
    final bool is_available = await SignInWithApple.isAvailable();
    if (!is_available) {
      logUtil(msg: "当前设备不支持 Apple 登录", type: 'e');
      showBottomTip(tr('AuthorizedLogin.apple_auth_unavailable'));
      return null;
    }

    /// 调用 Apple 登录授权接口。
    ///
    /// scopes 参数指定需要获取的用户信息范围：
    /// - fullName: 用户姓名
    /// - email: 用户邮箱
    final AuthorizationCredentialAppleID apple_credential =
        await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );


    /// 创建 Firebase Apple 凭证。
    final OAuthCredential firebase_credential = OAuthProvider('apple.com').credential(
      idToken: apple_credential.identityToken,
      accessToken: apple_credential.authorizationCode,
    );

    /// 使用 Firebase 进行登录。
    logUtil(msg: "开始 Firebase Apple 登录");
    final UserCredential user_credential =
        await FirebaseAuth.instance.signInWithCredential(firebase_credential);

    /// 打印 Firebase 返回的用户信息。
    final User? user = user_credential.user;
    if (user == null) {
      logUtil(msg: "Firebase 登录失败，未获取到用户信息", type: 'e');
      showBottomTip(tr('AuthorizedLogin.apple_auth_failed'));
      return null;
    }


    /// 获取 Firebase ID Token，用于后端验证。
    final String? firebase_id_token = await user.getIdToken();

    if (firebase_id_token == null || firebase_id_token.isEmpty) {
      logUtil(msg: "获取 Firebase ID Token 失败", type: 'e');
      showBottomTip(tr('AuthorizedLogin.apple_auth_failed'));
      return null;
    }

    return AppleLoginResult(
      user: user,
      firebaseIdToken: firebase_id_token,
      authorizationCode: apple_credential.authorizationCode,
      givenName: apple_credential.givenName,
      familyName: apple_credential.familyName,
    );
  } on SignInWithAppleAuthorizationException catch (error) {
    /// 处理 Apple 授权特有的异常。
    switch (error.code) {
      case AuthorizationErrorCode.canceled:
        logUtil(msg: "用户取消了 Apple 登录");
        showBottomTip(tr('AuthorizedLogin.apple_auth_canceled'));
        break;
      case AuthorizationErrorCode.failed:
        logUtil(msg: "Apple 登录授权失败: ${error.message}", type: 'e');
        showBottomTip(tr('AuthorizedLogin.apple_auth_failed'));
        break;
      case AuthorizationErrorCode.invalidResponse:
        logUtil(msg: "Apple 登录响应无效: ${error.message}", type: 'e');
        showBottomTip(tr('AuthorizedLogin.apple_auth_invalid_response'));
        break;
      case AuthorizationErrorCode.notHandled:
        logUtil(msg: "Apple 登录未处理: ${error.message}", type: 'e');
        showBottomTip(tr('AuthorizedLogin.apple_auth_not_handled'));
        break;
      case AuthorizationErrorCode.unknown:
        logUtil(msg: "Apple 登录未知错误: ${error.message}", type: 'e');
        showBottomTip(tr('AuthorizedLogin.apple_auth_unknown'));
        break;
      case AuthorizationErrorCode.notInteractive:
        logUtil(msg: "Apple 登录不可交互: ${error.message}", type: 'e');
        showBottomTip(tr('AuthorizedLogin.apple_auth_failed'));
        break;
      case AuthorizationErrorCode.credentialExport:
        logUtil(msg: "Apple 凭证导出失败: ${error.message}", type: 'e');
        showBottomTip(tr('AuthorizedLogin.apple_auth_failed'));
        break;
      case AuthorizationErrorCode.credentialImport:
        logUtil(msg: "Apple 凭证导入失败: ${error.message}", type: 'e');
        showBottomTip(tr('AuthorizedLogin.apple_auth_failed'));
        break;
      case AuthorizationErrorCode.matchedExcludedCredential:
        logUtil(msg: "Apple 匹配到排除的凭证: ${error.message}", type: 'e');
        showBottomTip(tr('AuthorizedLogin.apple_auth_failed'));
        break;
    }
    return null;
  } on FirebaseAuthException catch (error) {
    /// 处理 Firebase 认证异常。
    logUtil(msg: "Firebase Apple 登录失败: ${error.code} - ${error.message}", type: 'e');
    showBottomTip(tr('AuthorizedLogin.apple_auth_failed'));
    return null;
  } catch (error) {
    /// 处理其他未预期的异常。
    logUtil(msg: "Apple 登录异常: $error", type: 'e');
    showBottomTip(tr('AuthorizedLogin.apple_auth_unknown'));
    return null;
  }
}
