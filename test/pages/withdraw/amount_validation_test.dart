// ignore_for_file: non_constant_identifier_names

import 'package:app/models/app_global_config.dart';
import 'package:app/models/transaction_inquire_type.dart';
import 'package:app/models/user_info.dart';
import 'package:app/pages/withdraw/logic.dart';
import 'package:app/stores/app_global_config.dart';
import 'package:app/stores/user_information.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final config = Get.put(AppGlobalConfigStore());
    config.configLoaded.value = true;
    Get.put(UserInformation())
        .saveUserInfo(UserInfo.fromJson({'id': 1}));
    // 统一固定：最低提现 10，余额 300，便于断言边界。
    config.saveConfig(
      AppGlobalConfig(
        payTypeList: [
          TransactionInquireTypeItem(id: 1, label: 'USDT', languageVariables: ''),
        ],
        payAmountList: const [],
        businessConfig: const BusinessConfig(minWithdrawal: 10),
      ),
    );
  });
  tearDown(Get.reset);

  /// 创建已加载余额的提现逻辑，后续直接驱动金额输入。
  Future<WithdrawLogic> ready_logic({double balance = 300}) async {
    final logic = WithdrawLogic(
      user_info_loader: () async => UserInfo.fromJson({
        'id': 1,
        'balance': balance,
      }),
    );
    addTearDown(logic.dispose);
    expect(await logic.refreshData(), isTrue);
    return logic;
  }

  test('低于最低提现额时抬升到最低额', () async {
    final logic = await ready_logic();
    logic.amountController.text = '3';
    logic.commitAmountInput();
    expect(logic.selectedAmount, 10);
    expect(logic.amountController.text, '10');
  });

  test('超出可提现余额时压到余额上限', () async {
    final logic = await ready_logic();
    logic.amountController.text = '999';
    logic.commitAmountInput();
    expect(logic.selectedAmount, 300);
    expect(logic.amountController.text, '300');
  });

  test('非法输入回退到最低提现额', () async {
    final logic = await ready_logic();
    for (final raw in <String>['abc', '', '12.3.4', '--']) {
      logic.amountController.text = raw;
      logic.commitAmountInput();
      expect(logic.selectedAmount, 10, reason: '输入「$raw」应视为非法');
    }
  });

  test('合法输入保留两位小数内的金额', () async {
    final logic = await ready_logic();
    logic.amountController.text = '123.45';
    logic.commitAmountInput();
    expect(logic.selectedAmount, 123.45);
    expect(logic.amountController.text, '123.45');
  });

  test('余额低于最低提现额时禁止提现且滑块范围兜底', () async {
    final logic = await ready_logic();
    // 加载成功后把余额压到最低额以下，模拟可提现余额不足。
    logic.balance = 5;
    expect(logic.canWithdraw, isFalse);
    expect(logic.sliderMin, 0);
    expect(logic.sliderMax, 1);
    // 不可提现时金额强制清零。
    logic.amountController.text = '50';
    logic.commitAmountInput();
    expect(logic.selectedAmount, 0);
    expect(logic.amountController.text, '');
  });

  test('快捷金额三分之一/一半/全部与选中态同步', () async {
    final logic = await ready_logic();
    expect(logic.canWithdraw, isTrue);
    expect(logic.canUseOneThirdShortcut, isTrue);
    expect(logic.canUseHalfShortcut, isTrue);
    expect(logic.oneThirdAmount(), 100);
    expect(logic.halfAmount(), 150);

    logic.onTapShortcut(1 / 3);
    expect(logic.selectedAmount, 100);
    expect(logic.isShortcutSelected(WithdrawShortcut.oneThird), isTrue);

    logic.onTapShortcut(0.5);
    expect(logic.selectedAmount, 150);
    expect(logic.isShortcutSelected(WithdrawShortcut.half), isTrue);

    logic.onTapWithdrawAll();
    expect(logic.selectedAmount, 300);
    expect(logic.isShortcutSelected(WithdrawShortcut.all), isTrue);
  });

  test('展示金额补美元符号并按千分位格式化', () async {
    final logic = await ready_logic();
    expect(logic.displayAmount(0), r'$0');
    expect(logic.displayAmount(12.3), r'$12.3');
    expect(logic.displayAmount(1766.38), r'$1,766.38');
  });

  test('滑块改动写入选中金额并落在合法区间', () async {
    final logic = await ready_logic();
    logic.onSliderChanged(250);
    expect(logic.selectedAmount, 250);

    // 超出区间的滑块值同样被压缩到余额内。
    logic.onSliderChanged(500);
    expect(logic.selectedAmount, 300);
  });
}
