// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app/pages/customer_service_chat/widgets/message_bubble.dart';
import 'package:app/util/utc_time_util.dart';

void main() {
  test('消息气泡在手机和宽屏设备上都保持可读宽度', () {
    expect(MessageBubble.calc_max_width(400), 288);
    expect(MessageBubble.calc_max_width(1200), 460);
  });

  test('无时区后缀的后端时间始终按 UTC 解析', () {
    final DateTime? local_time = parse_utc_time_to_local('2026-07-19 00:30:00');

    expect(local_time, isNotNull);
    expect(local_time!.toUtc(), DateTime.utc(2026, 7, 19, 0, 30));
    expect(local_time.isUtc, isFalse);
  });

  test('格式化结果使用设备本地时区', () {
    final DateTime local_time = DateTime.utc(2026, 7, 19, 0, 30).toLocal();
    final DateTime local_now = DateTime(
      local_time.year,
      local_time.month,
      local_time.day,
      20,
    );

    expect(
      format_message_local_time('2026-07-19T00:30:00.000Z', now: local_now),
      '${local_time.hour.toString().padLeft(2, '0')}:30',
    );
  });

  testWidgets('消息气泡内展示本地时间', (WidgetTester tester) async {
    final DateTime message_time = DateTime.now().toUtc().subtract(
      const Duration(minutes: 2),
    );
    final String raw_time = message_time.toIso8601String();
    final String expected_time = format_message_local_time(raw_time);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            is_admin: true,
            message_type: 1,
            content: '测试消息',
            create_time: raw_time,
            is_dark: false,
          ),
        ),
      ),
    );

    expect(find.text('测试消息'), findsOneWidget);
    expect(find.text(expected_time), findsOneWidget);
  });

  testWidgets('图片上传完成后切换到服务端图片且保留本地预览', (WidgetTester tester) async {
    const String remote_url = 'https://example.com/uploaded-image.jpg';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            is_admin: false,
            message_type: 3,
            content: '/tmp/local-preview.jpg',
            server_content: remote_url,
            create_time: DateTime.now().toUtc().toIso8601String(),
            is_dark: false,
          ),
        ),
      ),
    );

    final CachedNetworkImage image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, remote_url);
    expect(image.placeholder, isNotNull);
    expect(image.errorWidget, isNotNull);
  });
}
