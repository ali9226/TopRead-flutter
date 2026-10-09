import 'dart:async';

import 'package:app/api/results_type.dart';
import 'package:app/models/app_global_config.dart';
import 'package:app/stores/app_global_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('多个业务页等待同一次配置请求，未完成时不返回旧加载状态', () async {
    final Completer<ResultsType<AppGlobalConfig>> response =
        Completer<ResultsType<AppGlobalConfig>>();
    int calls = 0;
    final AppGlobalConfigStore store = AppGlobalConfigStore(
      config_loader: (bool show_tips) {
        calls++;
        return response.future;
      },
    );
    final Future<bool> first = store.loadConfig();
    bool second_completed = false;
    final Future<bool> second = store.loadConfig().then((bool success) {
      second_completed = true;
      return success;
    });
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
    expect(second_completed, isFalse);
    expect(store.loading.value, isTrue);

    final AppGlobalConfig config = AppGlobalConfig.fromJson(<String, dynamic>{
      'pay_amount': <int>[10, 20],
    });
    response.complete(_result(config));
    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(store.configLoaded.value, isTrue);
    expect(store.payAmountList, <double>[10, 20]);
    expect(store.loading.value, isFalse);
  });

  test('首次配置失败保持未加载，恢复网络后可以重新请求', () async {
    int calls = 0;
    final AppGlobalConfigStore store = AppGlobalConfigStore(
      config_loader: (bool show_tips) async {
        calls++;
        return calls == 1
            ? ResultsType<AppGlobalConfig>()
            : _result(AppGlobalConfig.empty());
      },
    );
    expect(await store.loadConfig(), isFalse);
    expect(store.configLoaded.value, isFalse);
    expect(await store.loadConfig(), isTrue);
    expect(calls, 2);
  });

  test('刷新异常释放请求锁，并保留已有成功配置', () async {
    int calls = 0;
    final AppGlobalConfig config = AppGlobalConfig.fromJson(<String, dynamic>{
      'pay_amount': <int>[30],
    });
    final AppGlobalConfigStore store = AppGlobalConfigStore(
      config_loader: (bool show_tips) async {
        calls++;
        if (calls == 2) throw StateError('network failed');
        return _result(config);
      },
    );
    expect(await store.loadConfig(), isTrue);
    await expectLater(store.loadConfig(), throwsStateError);
    expect(store.loading.value, isFalse);
    expect(store.configLoaded.value, isTrue);
    expect(store.config.value, same(config));
    expect(await store.loadConfig(), isTrue);
    expect(calls, 3);
  });
}

ResultsType<AppGlobalConfig> _result(AppGlobalConfig config) {
  return ResultsType<AppGlobalConfig>()
    ..status = true
    ..content = config;
}
