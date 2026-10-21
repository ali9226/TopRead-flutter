import 'package:app/components/reader_action_icon/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('共用目录和评论图标强制覆盖SVG内置填色', (tester) async {
    const color = Color(0xFF7A6A56);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              ReaderActionIcon(name: 'qr_code', color: color),
              ReaderActionIcon(name: 'customer_service', color: color),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<SvgPicture>(find.byType(SvgPicture))
          .map((icon) => icon.colorFilter),
      everyElement(const ColorFilter.mode(color, BlendMode.srcIn)),
    );
    expect(tester.takeException(), isNull);
  });
}
