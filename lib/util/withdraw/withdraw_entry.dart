import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:get/get.dart';
import 'package:app/stores/app_global_config.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/show_message.dart';
import 'package:app/util/number_util.dart';
import 'package:app/util/router/router_util.dart';

/// 将金额格式化为提现弹窗与提现页摘要一致的展示（带 `$` 与千分位）。
String withdrawEntryDisplayAmount(double value) {
  final String formatted = formatNumberValue(value);
  final double parsed = double.tryParse(formatted) ?? value;
  return '\$${thousandsSeparator(parsed)}';
}

/// 个人中心等入口：用 [UserInformation] 里当前展示的余额与全局最低提现门槛比较。
///
/// - 满足 [balance >= minWithdrawal && minWithdrawal > 0] 时跳转 `/withdraw`。
/// - 不满足时弹出余额不足说明：左侧「提现记录」跳转 `/withdraw_record`，右侧「知道了」关闭。
///
/// 全局配置未加载时会先 [AppGlobalConfigStore.loadConfig]。
Future<void> openWithdrawIfBalanceAllows() async {
  final UserInformation userInformation = Get.find<UserInformation>();
  final AppGlobalConfigStore appGlobalConfigStore =
      Get.find<AppGlobalConfigStore>();

  if (!appGlobalConfigStore.configLoaded.value) {
    await appGlobalConfigStore.loadConfig();
  }

  final double minWithdrawal =
      appGlobalConfigStore.businessConfig.minWithdrawal;
  final double balance = userInformation.userInfo.value?.balance ?? 0;

  if (balance >= minWithdrawal && minWithdrawal > 0) {
    routerUtil(path: '/withdraw');
    return;
  }

  await showMessage(
    message: easy.tr(
      'withdraw_page.insufficient_message',
      namedArgs: {
        'balance': withdrawEntryDisplayAmount(balance),
        'min': withdrawEntryDisplayAmount(minWithdrawal),
      },
    ),
    showHelperText: false,
    leftButtonText: easy.tr('withdraw_page.insufficient_dialog_records'),
    rightButtonText: easy.tr('withdraw_page.insufficient_acknowledged'),
    onLeftPressed: () async {
      /// 从个人中心拦截，当前不在 `/withdraw`，直接 push 进入提现记录即可。
      routerUtil(path: '/withdraw_record');
    },
    onRightPressed: () async {},
  );
}
