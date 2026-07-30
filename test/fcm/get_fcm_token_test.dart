// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/fcm/get_fcm_token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FCM Token 原生调用不返回时按时结束', () async {
    final Completer<String?> token_completer = Completer<String?>();

    final String? token = await get_fcm_token(
      load_token: () => token_completer.future,
      timeout: const Duration(milliseconds: 10),
    );

    expect(token, isNull);
  });

  test('FCM Token 正常返回时保留结果', () async {
    final String? token = await get_fcm_token(
      load_token: () async => 'device-token',
      timeout: const Duration(milliseconds: 10),
    );

    expect(token, 'device-token');
  });
}
