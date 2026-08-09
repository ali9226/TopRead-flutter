// ignore_for_file: non_constant_identifier_names

import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/log_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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

/// Apple 授权阶段的统一结果。
///
/// iOS/macOS 使用系统原生授权，Android/Web 使用 Firebase 托管 OAuth，最终都转换为
/// 相同的数据结构，避免业务层感知平台差异。
class _AppleAuthorizationResult {
  final UserCredential user_credential;
  final String authorization_code;
  final String? given_name;
  final String? family_name;

  const _AppleAuthorizationResult({
    required this.user_credential,
    required this.authorization_code,
    this.given_name,
    this.family_name,
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

    final _AppleAuthorizationResult? authorization_result =
        await _authorize_with_apple();
    if (authorization_result == null) {
      return null;
    }

    final User? user = authorization_result.user_credential.user;
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
      authorizationCode: authorization_result.authorization_code,
      givenName: authorization_result.given_name,
      familyName: authorization_result.family_name,
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
    if (_is_canceled_firebase_auth_error(error.code)) {
      logUtil(msg: "用户取消了 Apple 登录");
      showBottomTip(tr('AuthorizedLogin.apple_auth_canceled'));
      return null;
    }

    logUtil(
      msg: "Firebase Apple 登录失败: ${error.code} - ${error.message}",
      type: 'e',
    );
    showBottomTip(tr('AuthorizedLogin.apple_auth_failed'));
    return null;
  } catch (error) {
    /// 处理其他未预期的异常。
    logUtil(msg: "Apple 登录异常: $error", type: 'e');
    showBottomTip(tr('AuthorizedLogin.apple_auth_unknown'));
    return null;
  }
}

/// 根据平台选择 Apple 授权实现。
Future<_AppleAuthorizationResult?> _authorize_with_apple() async {
  if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) {
    return _authorize_with_firebase_hosted_flow();
  }

  return _authorize_with_native_apple();
}

/// Android/Web 使用 Firebase 托管的完整 OAuth 流程。
///
/// Firebase 负责生成 Apple 授权地址、校验回调并返回 Firebase 用户凭证，不依赖
/// sign_in_with_apple 插件要求的自建 Android 回调服务器。
Future<_AppleAuthorizationResult> _authorize_with_firebase_hosted_flow() async {
  final AppleAuthProvider apple_provider = AppleAuthProvider()
    ..addScope('email')
    ..addScope('name');

  logUtil(msg: "开始 Firebase 托管 Apple 授权");
  final UserCredential user_credential = kIsWeb
      ? await FirebaseAuth.instance.signInWithPopup(apple_provider)
      : await FirebaseAuth.instance.signInWithProvider(apple_provider);

  final Map<String, dynamic>? profile =
      user_credential.additionalUserInfo?.profile;
  final User? user = user_credential.user;

  return _AppleAuthorizationResult(
    user_credential: user_credential,
    authorization_code:
        user_credential.additionalUserInfo?.authorizationCode ?? '',
    given_name:
        _read_apple_profile_name(profile, const <String>[
          'given_name',
          'givenName',
          'first_name',
          'firstName',
        ]) ??
        _split_display_name(user?.displayName).$1,
    family_name:
        _read_apple_profile_name(profile, const <String>[
          'family_name',
          'familyName',
          'last_name',
          'lastName',
        ]) ??
        _split_display_name(user?.displayName).$2,
  );
}

/// Apple 平台继续使用系统原生授权，并把 Apple 凭证交给 Firebase 登录。
Future<_AppleAuthorizationResult?> _authorize_with_native_apple() async {
  final bool is_available = await SignInWithApple.isAvailable();
  if (!is_available) {
    logUtil(msg: "当前设备不支持 Apple 登录", type: 'e');
    showBottomTip(tr('AuthorizedLogin.apple_auth_unavailable'));
    return null;
  }

  final AuthorizationCredentialAppleID apple_credential =
      await SignInWithApple.getAppleIDCredential(
        scopes: <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

  final OAuthCredential firebase_credential = OAuthProvider('apple.com')
      .credential(
        idToken: apple_credential.identityToken,
        accessToken: apple_credential.authorizationCode,
      );

  logUtil(msg: "开始 Firebase Apple 登录");
  final UserCredential user_credential = await FirebaseAuth.instance
      .signInWithCredential(firebase_credential);

  return _AppleAuthorizationResult(
    user_credential: user_credential,
    authorization_code: apple_credential.authorizationCode,
    given_name: apple_credential.givenName,
    family_name: apple_credential.familyName,
  );
}

/// 从 Firebase Apple OAuth profile 中读取姓名字段。
String? _read_apple_profile_name(
  Map<String, dynamic>? profile,
  List<String> keys,
) {
  if (profile == null) {
    return null;
  }

  for (final String key in keys) {
    final String value = profile[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) {
      return value;
    }
  }

  final dynamic nested_name = profile['name'];
  if (nested_name is Map) {
    final Map<String, dynamic> normalized_name = Map<String, dynamic>.from(
      nested_name,
    );
    for (final String key in keys) {
      final String value = normalized_name[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
  }

  return null;
}

/// 把 Firebase displayName 拆分为名和姓，缺失时保持 null。
(String?, String?) _split_display_name(String? display_name) {
  final String normalized_name = display_name?.trim() ?? '';
  if (normalized_name.isEmpty) {
    return (null, null);
  }

  final List<String> name_parts = normalized_name
      .split(RegExp(r'\s+'))
      .where((String item) => item.isNotEmpty)
      .toList();
  if (name_parts.length == 1) {
    return (name_parts.first, null);
  }

  return (name_parts.first, name_parts.skip(1).join(' '));
}

/// Firebase 在不同平台对用户取消使用不同错误码，统一识别为正常中断。
bool _is_canceled_firebase_auth_error(String error_code) {
  final String normalized_code = error_code.toLowerCase();
  return normalized_code.contains('cancel') ||
      normalized_code == 'web-context-cancelled';
}
