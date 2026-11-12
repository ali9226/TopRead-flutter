import 'package:app/pages/about_topread/widgets/patch_status_panel/index.dart';
import 'package:app/services/patch/patch_update_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('关闭调试权限时不展示面板，订阅状态变更后即时显示真实进度', (tester) async {
    final status = ValueNotifier(
      const PatchUpdateStatus(
        stage: 'downloading',
        detail: '补丁 ID：7',
        received: 50,
        total: 100,
      ),
    );
    addTearDown(status.dispose);
    Widget app(bool enabled) => MaterialApp(
      home: Scaffold(
        body: PatchStatusPanel(
          enabled: enabled,
          is_dark: false,
          is_cjk: true,
          status: status,
        ),
      ),
    );
    await tester.pumpWidget(app(false));
    expect(find.byKey(const ValueKey('patch_status_panel')), findsNothing);
    await tester.pumpWidget(app(true));
    expect(find.textContaining('50%'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const ValueKey('patch_download_progress')),
          )
          .value,
      0.5,
    );
    status.value = const PatchUpdateStatus(
      stage: 'pending_restart',
      detail: '安装完成，下次冷启动生效',
      received: 100,
      total: 100,
    );
    await tester.pump();
    expect(find.textContaining('是否正在热更新：否'), findsOneWidget);
    expect(find.textContaining('等待下次冷启动'), findsOneWidget);
    expect(find.textContaining('100%'), findsOneWidget);
  });

  testWidgets('未知长度不伪造百分比，窄屏大字和横屏深色均无溢出', (tester) async {
    final status = ValueNotifier(
      const PatchUpdateStatus(
        stage: 'downloading',
        detail: '补丁文件：very_long_patch_filename_1234567890.fptc\n等待服务器提供总长度',
        received: 12345,
      ),
    );
    addTearDown(status.dispose);
    for (final size in [const Size(320, 640), const Size(850, 400)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: PatchStatusPanel(
                  enabled: true,
                  is_dark: true,
                  is_cjk: true,
                  status: status,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('总大小未知'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const ValueKey('patch_download_progress')),
            )
            .value,
        isNull,
      );
      expect(tester.takeException(), isNull);
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
