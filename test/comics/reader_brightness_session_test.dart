// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:app/pages/comics/reader/widgets/reading_panels/brightness_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = ComicReaderBrightnessSession.channel;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('阅读亮度实际写原生通道，退出恢复窗口跟随系统标记', () async {
    final writes = <double>[];
    final applied = Completer<void>();
    final methods = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getBrightness') {
        return {'brightness': 0.6, 'override': -1.0};
      }
      methods.add(call.method);
      writes.add((call.arguments as Map)['value'] as double);
      if (!applied.isCompleted) applied.complete();
      return null;
    });
    final session = ComicReaderBrightnessSession();
    await session.initialize();
    expect(session.available, isTrue);
    session.set_value(0.25);
    await applied.future;
    await session.restore();
    expect(writes, [0.25, -1.0]);
    expect(methods, ['setBrightness', 'restoreBrightness']);
    await session.restore();
    expect(writes, [0.25, -1.0]);
    session.dispose();
  });

  test('初始化未完成即退出也恢复原始亮度，不发送迟到的拖动值', () async {
    final initial = Completer<Map<String, double>>();
    final writes = <double>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getBrightness') return initial.future;
      writes.add((call.arguments as Map)['value'] as double);
      return null;
    });
    final session = ComicReaderBrightnessSession();
    final loading = session.initialize();
    final restoring = session.restore();
    session.set_value(0.9);
    initial.complete({'brightness': 0.4, 'override': 0.4});
    await loading;
    await restoring;
    expect(writes, [0.4]);
    session.dispose();
  });

  test('缺失原生通道时不伪装亮度已修改', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw MissingPluginException(),
    );
    final session = ComicReaderBrightnessSession();
    await session.initialize();
    expect(session.initialized, isTrue);
    expect(session.available, isFalse);
    session.set_value(0.8);
    expect(session.value, 1);
    await session.restore();
    session.dispose();
  });

  test('重新打开读取实时亮度，退出仍恢复进入阅读器时的原值', () async {
    double current = 0.3;
    final restored = <double>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getBrightness') {
        return {'brightness': current, 'override': current};
      }
      if (call.method == 'restoreBrightness') {
        restored.add((call.arguments as Map)['value'] as double);
      }
      return null;
    });
    final session = ComicReaderBrightnessSession();
    await session.initialize();
    expect(session.value, 0.3);
    current = 1;
    await session.refresh();
    expect(session.value, 1);
    current = 0.7;
    await session.refresh();
    expect(session.value, 0.7);
    await session.restore();
    expect(restored, [0.3]);
    session.dispose();
  });

  test('仅新会话清除模拟器旧预览，面板重开保留用户调节并读取外部亮度', () async {
    var current = 0.5;
    final reset_requests = <bool>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getBrightness') {
        final reset = (call.arguments as Map?)?['reset_preview'] == true;
        reset_requests.add(reset);
        if (reset) current = 1;
        return {'brightness': current, 'override': 1.0};
      }
      if (call.method == 'setBrightness') {
        current = (call.arguments as Map)['value'] as double;
      }
      return null;
    });
    final session = ComicReaderBrightnessSession();
    await session.initialize();
    expect(session.value, 1);
    session.set_value(0.2);
    await session.refresh();
    expect(session.value, 0.2);
    current = 1;
    await session.refresh();
    expect(session.value, 1);
    expect(reset_requests, [true, false, false]);
    await session.restore();
    session.dispose();
  });
}
