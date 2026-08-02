// ignore_for_file: non_constant_identifier_names

import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/log_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// 执行 Apple 授权登录逻辑。
///
/// 调用 Apple 授权接口获取用户信息，并打印所有返回字段供调试。
/// 返回授权凭证，若用户取消或失败则返回 null。
Future<AuthorizationCredentialAppleID?> apple_login() async {
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
    final AuthorizationCredentialAppleID credential =
        await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    /// 打印 Apple 返回的所有字段，用于调试和对接后端。
    logUtil(msg: "===== Apple 登录返回信息 =====");
    logUtil(msg: "identityToken: ${credential.identityToken}");
    logUtil(msg: "authorizationCode: ${credential.authorizationCode}");
    logUtil(msg: "userIdentifier: ${credential.userIdentifier}");
    logUtil(msg: "givenName: ${credential.givenName}");
    logUtil(msg: "familyName: ${credential.familyName}");
    logUtil(msg: "email: ${credential.email}");
    logUtil(msg: "state: ${credential.state}");
    logUtil(msg: "===== Apple 登录返回信息结束 =====");

    return credential;
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
  } catch (error) {
    /// 处理其他未预期的异常。
    logUtil(msg: "Apple 登录异常: $error", type: 'e');
    showBottomTip(tr('AuthorizedLogin.apple_auth_unknown'));
    return null;
  }
}
