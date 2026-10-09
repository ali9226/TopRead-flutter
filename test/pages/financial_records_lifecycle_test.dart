// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/models/top_up_record.dart';
import 'package:app/models/user_info.dart';
import 'package:app/models/withdraw_record.dart';
import 'package:app/pages/top_up_record/logic.dart';
import 'package:app/pages/withdraw_record/logic.dart';
import 'package:app/stores/app_global_config.dart';
import 'package:app/stores/user_information.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Records {
  final ChangeNotifier notifier;
  final Future<bool> Function() refresh;
  final Future<bool> Function() load_more;
  final List<int> Function() ids;
  final void Function() complete;
  final void Function() fail;
  final bool Function() has_more;

  _Records({
    required this.notifier,
    required this.refresh,
    required this.load_more,
    required this.ids,
    required this.complete,
    required this.fail,
    required this.has_more,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late UserInformation user;
  setUp(() {
    Get.put(AppGlobalConfigStore());
    user = Get.put(UserInformation())
      ..saveUserInfo(UserInfo.fromJson({'id': 1}));
  });
  tearDown(Get.reset);

  for (final bool top_up in [true, false]) {
    final String page = top_up ? '充值' : '提现';
    int requests = 0;
    _Records create() {
      requests = 0;
      if (top_up) {
        final pending = Completer<List<TopUpRecordItem>?>();
        final logic = TopUpRecordLogic(
          record_loader: ({required no_ids, required page_size}) {
            requests++;
            return pending.future;
          },
        );
        logic.records.add(const TopUpRecordItem(id: 7));
        return _Records(
          notifier: logic,
          refresh: logic.refresh,
          load_more: logic.fetchRecords,
          ids: () => logic.records.map((item) => item.id).toList(),
          complete: () => pending.complete([const TopUpRecordItem(id: 9)]),
          fail: () => pending.complete(null),
          has_more: () => logic.hasMore,
        );
      }
      final pending = Completer<List<WithdrawRecordItem>?>();
      final logic = WithdrawRecordLogic(
        record_loader: ({required no_ids, required page_size}) {
          requests++;
          return pending.future;
        },
      );
      logic.records.add(const WithdrawRecordItem(id: 7));
      return _Records(
        notifier: logic,
        refresh: logic.refresh,
        load_more: logic.fetchRecords,
        ids: () => logic.records.map((item) => item.id).toList(),
        complete: () => pending.complete([const WithdrawRecordItem(id: 9)]),
        fail: () => pending.complete(null),
        has_more: () => logic.hasMore,
      );
    }

    test('$page记录下拉刷新期间禁止重复刷新和触底分页', () async {
      final records = create();
      addTearDown(records.notifier.dispose);
      final first = records.refresh();
      expect(await records.refresh(), isFalse);
      expect(await records.load_more(), isFalse);
      expect(requests, 1);
      records.complete();
      expect(await first, isTrue);
      expect(records.ids(), [9]);
    });

    test('$page记录销毁后晚到响应不会写数据或通知已释放对象', () async {
      final records = create();
      final first = records.refresh();
      records.notifier.dispose();
      records.complete();
      expect(await first, isFalse);
      expect(records.ids(), [7]);
      expect(await records.refresh(), isFalse);
      expect(requests, 1);
    });

    test('$page记录请求中切换账号后忽略旧账号结果', () async {
      final records = create();
      addTearDown(records.notifier.dispose);
      final first = records.refresh();
      user.saveUserInfo(UserInfo.fromJson({'id': 2}));
      records.complete();
      expect(await first, isFalse);
      expect(records.ids(), [7]);
      expect(user.userInfo.value!.id, 2);
    });

    test('$page记录刷新失败保留原列表与分页能力', () async {
      final records = create();
      addTearDown(records.notifier.dispose);
      final first = records.refresh();
      records.fail();
      expect(await first, isFalse);
      expect(records.ids(), [7]);
      expect(records.has_more(), isTrue);
    });
  }
}
