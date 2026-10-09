// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/api/results_type.dart';
import 'package:app/models/login.dart';
import 'package:app/models/user_info.dart';
import 'package:app/pages/login/logic.dart' as login_page;
import 'package:app/pages/register/logic.dart' as register_page;
import 'package:app/stores/user_information.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Form {
  final Future<bool> Function() submit;
  final void Function() dispose;
  _Form(this.submit, this.dispose);
}

void main() {
  late UserInformation user;
  late int credential_writes;
  setUp(() {
    credential_writes = 0;
    user = Get.put(
      UserInformation(
        token_writer: (_, __) async {
          credential_writes++;
          return true;
        },
      ),
    );
  });
  tearDown(Get.reset);

  for (final int mode in [0, 1, 2, 3]) {
    final String name = ['登录页登录', '登录页注册', '注册页登录', '注册页注册'][mode];
    _Form create(Completer<ResultsType<Login>> pending) {
      if (mode < 2) {
        final logic =
            login_page.Logic(
                authentication_request: ({required path, required parameter}) =>
                    pending.future,
              )
              ..account = 'reader'
              ..password = 'password';
        return _Form(mode == 0 ? logic.login : logic.register, logic.dispose);
      }
      final logic =
          register_page.Logic(
              authentication_request: ({required path, required parameter}) =>
                  pending.future,
            )
            ..account = 'reader'
            ..password = 'password';
      return _Form(mode == 2 ? logic.login : logic.registerFun, logic.dispose);
    }

    ResultsType<Login> success() => ResultsType<Login>()
      ..status = true
      ..content = Login(
        userInfo: UserInfo.fromJson({'id': 1}),
        token: 'old-token',
      );

    test('$name页面关闭后迟到响应不能登录或保存凭证', () async {
      final pending = Completer<ResultsType<Login>>();
      final form = create(pending);
      final submission = form.submit();
      form.dispose();
      pending.complete(success());
      expect(await submission, isFalse);
      expect(user.userInfo.value, isNull);
      expect(credential_writes, 0);
    });

    test('$name期间切换账号后旧响应不能覆盖新账号或Token', () async {
      final pending = Completer<ResultsType<Login>>();
      final form = create(pending);
      addTearDown(form.dispose);
      final submission = form.submit();
      user.saveUserInfo(UserInfo.fromJson({'id': 2}));
      pending.complete(success());
      expect(await submission, isFalse);
      expect(user.userInfo.value!.id, 2);
      expect(credential_writes, 0);
    });

    test('$name期间主动退出后旧响应不能恢复登录', () async {
      final pending = Completer<ResultsType<Login>>();
      final form = create(pending);
      addTearDown(form.dispose);
      final submission = form.submit();
      user.begin_logout();
      pending.complete(success());
      expect(await submission, isFalse);
      expect(user.isLoggedIn.value, isFalse);
      expect(credential_writes, 0);
    });
  }
}
