// ignore_for_file: non_constant_identifier_names

import 'dart:developer';

import 'package:app/api/post_request.dart';
import 'package:app/models/login.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/encryption/index.dart';
import 'package:app/util/string/to_string.dart';

/// 批量调用 `user/register` 造测试账号的汇总结果。
///
/// 字段 [successCount]：接口返回成功且带非空 token 的次数。
/// 字段 [failCount]：失败次数。
class BatchRegisterTestAccountsResult {
  /// 成功注册的账号数量。
  final int successCount;

  /// 失败次数。
  final int failCount;

  const BatchRegisterTestAccountsResult({
    required this.successCount,
    required this.failCount,
  });

  /// 是否至少成功注册过一个账号。
  bool get anySuccess => successCount > 0;
}

/// 批量注册测试账号（仅开发 / 测试库造数，勿在线上产品入口默认调用）。
///
/// **典型场景**：测试库被清空后，需要快速生成一批固定规则账号（如 `00000000001` 起连续
/// 编号、统一密码），便于自动化或手工登录验证。
///
/// **调用示例**（在注册页 [Logic] 或其它调试入口里）：
/// ```dart
/// final result = await batch_register_test_accounts(
///   invitationCode: logic.invitationCode,
/// );
/// if (result.anySuccess) { ... }
/// ```
///
/// **行为说明**：
/// - 账号名由 [startIndex] 起每次 +1，左侧补零至 [accountDigitWidth] 位（默认 11 位）。
/// - [passwordPlain] 为明文，提交前会经 [passwordEncryption]（与正式注册一致）。
/// - [invitation_code] 与单条注册相同，一般传当前页收集的邀请码，可空字符串。
/// - 每条请求使用 `showTips: false`，避免失败时连续弹全局提示；失败详情打 [log]（name: `register.batch`）。
/// - **不会**写入本地 token，**不会**切换当前登录用户。
/// - [showResultTip] 为 true 时，全部请求结束后弹一条 [showBottomTip] 汇总成功/失败数。
///
/// 参数 [count]：连续注册条数。
/// 参数 [startIndex]：第一条账号对应的数字序号（再格式化为字符串账号）。
/// 参数 [passwordPlain]：所有账号共用的注册密码明文。
/// 参数 [invitationCode]：邀请码，可空。
/// 参数 [accountDigitWidth]：账号数字部分总宽度，左侧补 `0`。
/// 参数 [showResultTip]：是否在结束时弹出汇总提示。
Future<BatchRegisterTestAccountsResult> batch_register_test_accounts({
  int count = 500,
  int startIndex = 1,
  String passwordPlain = '#z8hi31Q',
  String invitationCode = '',
  int accountDigitWidth = 11,
  bool showResultTip = true,
}) async {
  int successCount = 0;
  int failCount = 0;

  for (int i = 0; i < count; i++) {
    final int n = startIndex + i;
    final String batchAccount = n.toString().padLeft(accountDigitWidth, '0');

    final Map<String, dynamic> parameter = <String, dynamic>{
      'account': batchAccount,
      'password': passwordEncryption(removeSpaces(passwordPlain)),
      'invitation_code': invitationCode,
    };

    final results = await postRequest<Login>(
      path: 'user/register',
      showTips: false,
      parameter: parameter,
      fromJson: (Map<String, dynamic> json) => Login.fromJson(json),
    );

    if (results.status &&
        results.content != null &&
        (results.content?.token.toString() ?? '').isNotEmpty) {
      successCount++;
    } else {
      failCount++;
      log(
        'batch register fail account=$batchAccount msg=${results.message}',
        name: 'register.batch',
      );
    }
  }

  if (showResultTip) {
    showBottomTip('批量注册结束：成功 $successCount，失败 $failCount');
  }

  return BatchRegisterTestAccountsResult(
    successCount: successCount,
    failCount: failCount,
  );
}
