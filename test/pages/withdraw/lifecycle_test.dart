// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/models/user_info.dart';
import 'package:app/models/app_global_config.dart';
import 'package:app/pages/withdraw/logic.dart';
import 'package:app/stores/app_global_config.dart';
import 'package:app/stores/user_information.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late UserInformation user;
  setUp(() {
    final config = Get.put(AppGlobalConfigStore());
    config.configLoaded.value = true;
    user = Get.put(UserInformation())
      ..saveUserInfo(UserInfo.fromJson({'id': 1}));
  });
  tearDown(Get.reset);

  test('提现页面销毁后余额响应不访问已释放输入控制器', () async {
    final pending = Completer<UserInfo?>();
    final logic = WithdrawLogic(user_info_loader: () => pending.future);
    final refresh = logic.refreshData();
    logic.dispose();
    pending.complete(UserInfo.fromJson({'id': 1, 'balance': 300}));
    expect(await refresh, isFalse);
    expect(logic.balance, 0);
    expect(user.userInfo.value!.balance, 0);
  });

  test('提现余额请求中切换账号后不能覆盖新账号资料或余额', () async {
    final pending = Completer<UserInfo?>();
    final logic = WithdrawLogic(user_info_loader: () => pending.future);
    addTearDown(logic.dispose);
    final refresh = logic.refreshData();
    user.saveUserInfo(UserInfo.fromJson({'id': 2, 'balance': 100}));
    pending.complete(UserInfo.fromJson({'id': 1, 'balance': 300}));
    expect(await refresh, isFalse);
    expect(user.userInfo.value!.id, 2);
    expect(user.userInfo.value!.balance, 100);
    expect(logic.balance, 0);
  });

  test('提现余额请求失败不弹出余额不足误提示且允许重试', () async {
    int requests = 0;
    final pending = Completer<UserInfo?>();
    final logic = WithdrawLogic(
      user_info_loader: () {
        requests++;
        return pending.future;
      },
    );
    addTearDown(logic.dispose);
    final first = logic.refreshData();
    expect(await logic.refreshData(), isFalse);
    pending.complete(null);
    expect(await first, isFalse);
    expect(logic.hasShownInsufficientDialog, isFalse);
    expect(logic.loading, isFalse);
    expect(requests, 1);
    expect(await logic.refreshData(), isFalse);
    expect(requests, 2);
  });

  test('已成功加载的提现余额在换号后不能继续作为新账号的可提现余额', () async {
    Get.find<AppGlobalConfigStore>().saveConfig(
      const AppGlobalConfig(
        payTypeList: [],
        payAmountList: [],
        businessConfig: BusinessConfig(minWithdrawal: 10),
      ),
    );
    final logic = WithdrawLogic(
      user_info_loader: () async =>
          UserInfo.fromJson({'id': 1, 'balance': 300}),
    );
    addTearDown(logic.dispose);
    expect(await logic.refreshData(), isTrue);
    expect(logic.canWithdraw, isTrue);
    user.saveUserInfo(UserInfo.fromJson({'id': 2, 'balance': 1}));
    expect(logic.canWithdraw, isFalse);
  });
}
