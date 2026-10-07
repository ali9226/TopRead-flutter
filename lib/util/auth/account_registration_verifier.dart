// ignore_for_file: non_constant_identifier_names

import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/util/string/to_string.dart';

/// 登录和注册共用的账号查询入口，可替换以验证请求乱序与网络失败。
typedef AccountRegistrationRequest =
    Future<ResultsType<Map<String, dynamic>>> Function(String account);

/// 账号验证状态只接受当前输入、最新请求且页面仍存活时的响应。
class AccountRegistrationVerifier {
  AccountRegistrationVerifier({
    AccountRegistrationRequest? verify_account_request,
  }) : _verify_account_request =
           verify_account_request ?? _request_account_registration;

  /// 查询网关，默认通过项目统一的 POST 请求访问服务端。
  final AccountRegistrationRequest _verify_account_request;

  /// 当前输入的账号原文，提交时沿用项目既有的空白清理规则。
  String _account = '';

  /// 输入变化的版本；即使账号改回原文，先前的请求也不会重新有效。
  int _account_revision = 0;

  /// 查询序号，防止同一账号的旧响应覆盖更新的验证结果。
  int _request_revision = 0;

  /// 页面关闭后停止更新验证状态。
  bool _is_active = true;

  /// null 表示尚未确认，网络失败不能据此认定账号未注册。
  bool? isAccountRegistered;

  String get account => _account;
  int get account_revision => _account_revision;
  bool get is_active => _is_active;

  set account(String value) {
    if (_account == value) return;
    _account = value;
    _account_revision++;
    isAccountRegistered = null;
  }

  /// 查询注册状态；失败、无有效布尔结果或过期响应均返回 false。
  Future<bool> verifyAccount() async {
    if (!_is_active) return false;
    final String requested_account = removeSpaces(_account);
    final int input_revision = _account_revision;
    final int request_revision = ++_request_revision;
    if (requested_account.isEmpty) {
      isAccountRegistered = null;
      return false;
    }
    // 同一输入再次失焦查询时保留已确认状态，避免请求期间提交模式与文案不一致。

    bool? registered;
    try {
      final result = await _verify_account_request(requested_account);
      final dynamic status = result.content?['status'];
      if (result.status && status is bool) registered = status;
    } catch (_) {
      // 查询失败保持“未确认”，保留页面原有的默认提交模式。
    }

    if (!_is_active ||
        input_revision != _account_revision ||
        request_revision != _request_revision) {
      return false;
    }
    isAccountRegistered = registered;
    return registered ?? false;
  }

  /// 失效化页面关闭前的所有验证请求。
  void dispose() {
    _is_active = false;
    _request_revision++;
  }

  static Future<ResultsType<Map<String, dynamic>>>
  _request_account_registration(String account) =>
      postRequest<Map<String, dynamic>>(
        path: 'user/register_verify',
        parameter: {'account': account},
        showTips: false,
        fromJson: (json) => json,
      );
}
