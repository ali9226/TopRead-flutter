import 'package:app/pages/work_editor/_shared/widgets/editor_step_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('切换步骤的每帧保持步骤栏和下方内容位置稳定：dark=$dark', (tester) async {
      var step = 0;
      late StateSetter update;
      const contentKey = ValueKey('editor_content');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return Column(
                  children: [
                    EditorStepIndicator(
                      current_step: step,
                      labels: const ['资料', '分类', '正文', '发布'],
                      is_dark: dark,
                      error_steps: const {0},
                    ),
                    const Expanded(child: SizedBox(key: contentKey)),
                  ],
                );
              },
            ),
          ),
        ),
      );
      final initialBar = tester.getRect(find.byType(EditorStepIndicator));
      final initialContent = tester.getRect(find.byKey(contentKey));
      // TODO 包括快速跳步打断动画；只检查初末帧无法发现动画中途的高度收缩。
      for (final target in [1, 3, 0, 2, 1]) {
        update(() => step = target);
        await tester.pump();
        for (var frame = 0; frame < 6; frame++) {
          await tester.pump(const Duration(milliseconds: 20));
          expect(tester.getRect(find.byType(EditorStepIndicator)), initialBar);
          expect(tester.getRect(find.byKey(contentKey)), initialContent);
        }
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
