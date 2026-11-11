import 'package:app/services/patch/patch_boot_window.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('首帧前的等待不能计作健康观察时间', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    bool ready = false;
    final window = PatchBootWindow.wait(const Duration(seconds: 5));
    window.then((_) => ready = true);
    // TODO 这次 pump 才渲染首帧，之前经过的时间不能关闭观察窗口。
    await tester.pumpWidget(const SizedBox());
    expect(ready, isFalse);
    await tester.pump(const Duration(seconds: 6));
    expect(ready, isTrue);
    await window;
  });

  testWidgets('后台停留不会把未完成的前台观察标成健康', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    bool ready = false;
    final window = PatchBootWindow.wait(const Duration(seconds: 5));
    window.then((_) => ready = true);
    await tester.pumpWidget(const SizedBox());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 20));
    expect(ready, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 6));
    expect(ready, isTrue);
    await window;
  });

  testWidgets('观察错误保留原处理链并在结束后还原，不误报健康', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final original_handler = FlutterError.onError;
    int forwarded = 0;
    void prior_handler(FlutterErrorDetails details) => forwarded++;
    FlutterError.onError = prior_handler;
    try {
      final window = PatchBootWindow.wait(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
      FlutterError.reportError(
        FlutterErrorDetails(exception: StateError('boot failure')),
      );
      await tester.pump(const Duration(seconds: 6));
      expect(await window, isFalse);
      expect(forwarded, 1);
      expect(FlutterError.onError, same(prior_handler));
    } finally {
      FlutterError.onError = original_handler;
    }
  });
}
