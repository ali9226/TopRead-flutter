import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/components/bottom_sheet_drag_handle/index.dart';

void main() {
  testWidgets('拖动统一把手可以下滑关闭 ModalBottomSheet', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return Center(
                child: TextButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      enableDrag: true,
                      showDragHandle: false,
                      builder: (_) {
                        return const SizedBox(
                          height: 420,
                          child: Column(
                            children: <Widget>[
                              BottomSheetDragHandle(is_dark: false),
                              Expanded(child: SizedBox()),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final Finder drag_handle = find.byType(BottomSheetDragHandle);
    expect(drag_handle, findsOneWidget);

    await tester.drag(drag_handle, const Offset(0, 360));
    await tester.pumpAndSettle();
    expect(drag_handle, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
