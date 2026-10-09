// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/api/results_type.dart';
import 'package:app/components/authorized_login/apple_login.dart';
import 'package:app/components/authorized_login/google_login.dart';
import 'package:app/components/authorized_login/logic.dart';
import 'package:app/models/login.dart';
import 'package:app/models/rotation.dart';
import 'package:app/models/user_info.dart';
import 'package:app/stores/authorized_login_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  late UserInformation user_information;
  late List<String> tokens;

  setUp(() {
    Get.testMode = true;
    tokens = [];
    user_information = Get.put(
      UserInformation(
        token_writer: (_, token) async {
          tokens.add(token);
          return true;
        },
      ),
    );
    Get.put(AuthorizedLoginStore());
  });
  tearDown(() async => Get.reset());

  for (final String provider in ['google', 'apple']) {
    Future<Logic> mount_logic(
      WidgetTester tester, {
      required Future<ResultsType<Login>> Function(Map<String, dynamic>)
      request,
      Future<void>? authorization,
      VoidCallback? completed,
    }) async {
      late Logic logic;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              logic = Logic(
                context,
                google_authorizer: () async {
                  if (authorization != null) await authorization;
                  return GoogleLoginResult(
                    user: _FirebaseUser(),
                    firebaseIdToken: 'firebase-token',
                  );
                },
                apple_authorizer: () async {
                  if (authorization != null) await authorization;
                  return AppleLoginResult(
                    user: _FirebaseUser(),
                    firebaseIdToken: 'firebase-token',
                    authorizationCode: 'apple-code',
                  );
                },
                login_request: request,
                on_login_completed: completed,
              );
              return const SizedBox();
            },
          ),
        ),
      );
      return logic;
    }

    testWidgets('$provider 后端响应到达前换账号不能覆盖新身份', (tester) async {
      final Completer<ResultsType<Login>> response = Completer();
      final Completer<void> requested = Completer();
      int completed_count = 0;
      final Logic logic = await mount_logic(
        tester,
        request: (_) {
          requested.complete();
          return response.future;
        },
        completed: () => completed_count++,
      );
      final pending = logic.handle_authorized_login_tap(_provider(provider));
      await requested.future;
      user_information.saveUserInfo(_user(2));
      response.complete(_login_result());
      await pending;

      expect(user_information.userInfo.value?.id, 2);
      expect(tokens, isEmpty);
      expect(completed_count, 0);
      expect(Get.find<AuthorizedLoginStore>().loading.value, isFalse);
    });

    testWidgets('$provider 授权期间关闭页面不再请求后端', (tester) async {
      final Completer<void> authorization = Completer();
      int request_count = 0;
      final Logic logic = await mount_logic(
        tester,
        authorization: authorization.future,
        request: (_) async {
          request_count++;
          return _login_result();
        },
      );
      final pending = logic.handle_authorized_login_tap(_provider(provider));
      await tester.pumpWidget(const SizedBox());
      authorization.complete();
      await pending;

      expect(request_count, 0);
      expect(tokens, isEmpty);
      expect(Get.find<AuthorizedLoginStore>().loading.value, isFalse);
    });

    testWidgets('$provider 后端等待期间关闭页面不提交凭证', (tester) async {
      final Completer<ResultsType<Login>> response = Completer();
      final Completer<void> requested = Completer();
      final Logic logic = await mount_logic(
        tester,
        request: (_) {
          requested.complete();
          return response.future;
        },
      );
      final pending = logic.handle_authorized_login_tap(_provider(provider));
      await requested.future;
      await tester.pumpWidget(const SizedBox());
      response.complete(_login_result());
      await pending;

      expect(user_information.userInfo.value, isNull);
      expect(tokens, isEmpty);
    });

    testWidgets('$provider 正常登录只提交一次并完成', (tester) async {
      int completed_count = 0;
      Map<String, dynamic>? parameter;
      final Logic logic = await mount_logic(
        tester,
        request: (value) async {
          parameter = value;
          return _login_result();
        },
        completed: () => completed_count++,
      );
      await logic.handle_authorized_login_tap(_provider(provider));

      expect(tokens, ['user-token']);
      expect(user_information.userInfo.value?.id, 1);
      expect(completed_count, 1);
      expect(parameter?['uuid_type'], provider == 'google' ? 4 : 3);
      expect(Get.find<AuthorizedLoginStore>().loading.value, isFalse);
    });
  }
}

Rotation _provider(String name) => Rotation.from_json({'title': name});
UserInfo _user(int id) =>
    UserInfo.fromJson({'id': id, 'account': 'reader-$id'});
ResultsType<Login> _login_result() => ResultsType<Login>()
  ..status = true
  ..content = Login(userInfo: _user(1), token: 'user-token');

class _FirebaseUser implements User {
  @override
  String get uid => 'firebase-user';
  @override
  String get email => 'reader@example.com';
  @override
  String get displayName => 'Reader';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
