// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/api/results_type.dart';
import 'package:app/pages/login/logic.dart' as login;
import 'package:app/pages/register/logic.dart' as register;
import 'package:app/util/auth/account_registration_verifier.dart';
import 'package:flutter_test/flutter_test.dart';

ResultsType<Map<String, dynamic>> _response(dynamic registered) =>
    ResultsType<Map<String, dynamic>>()
      ..status = true
      ..content = {'status': registered};

void main() {
  final factories =
      <
        String,
        AccountRegistrationVerifier Function(AccountRegistrationRequest)
      >{
        '登录页': (request) => login.Logic(verify_account_request: request),
        '注册页': (request) => register.Logic(verify_account_request: request),
      };

  for (final entry in factories.entries) {
    group(entry.key, () {
      test('验证失败保持未知状态，避免错误切换提交模式', () async {
        final logic = entry.value(
          (_) async => ResultsType<Map<String, dynamic>>(),
        );
        addTearDown(logic.dispose);
        logic.account = 'reader';
        logic.isAccountRegistered = true;

        expect(await logic.verifyAccount(), isFalse);
        expect(logic.isAccountRegistered, isNull);
      });

      test('明确的未注册结果才切换为未注册状态', () async {
        final logic = entry.value((_) async => _response(false));
        addTearDown(logic.dispose);
        logic.account = 'reader';

        expect(await logic.verifyAccount(), isFalse);
        expect(logic.isAccountRegistered, isFalse);
      });

      test('同一账号再次查询期间保留已确认模式', () async {
        final pending = Completer<ResultsType<Map<String, dynamic>>>();
        final logic = entry.value((_) => pending.future);
        addTearDown(logic.dispose);
        logic.account = 'reader';
        logic.isAccountRegistered = false;

        final request = logic.verifyAccount();
        expect(logic.isAccountRegistered, isFalse);
        pending.complete(_response(true));
        expect(await request, isTrue);
        expect(logic.isAccountRegistered, isTrue);
      });

      test('输入变化后丢弃旧响应，即使又改回原账号', () async {
        final pending = Completer<ResultsType<Map<String, dynamic>>>();
        final logic = entry.value((_) => pending.future);
        addTearDown(logic.dispose);
        logic.account = 'reader';
        final request = logic.verifyAccount();
        logic.account = 'another';
        logic.account = 'reader';

        pending.complete(_response(false));
        await request;
        expect(logic.isAccountRegistered, isNull);
      });

      test('同账号的新查询先完成时，旧响应不得覆盖结果', () async {
        final old = Completer<ResultsType<Map<String, dynamic>>>();
        int calls = 0;
        final logic = entry.value(
          (_) => ++calls == 1 ? old.future : Future.value(_response(true)),
        );
        addTearDown(logic.dispose);
        logic.account = 'reader';
        final request = logic.verifyAccount();
        expect(await logic.verifyAccount(), isTrue);

        old.complete(_response(false));
        await request;
        expect(logic.isAccountRegistered, isTrue);
      });

      test('空白账号不请求接口，有效账号沿用清理空白规则', () async {
        final accounts = <String>[];
        final logic = entry.value((account) async {
          accounts.add(account);
          return _response(true);
        });
        addTearDown(logic.dispose);
        logic.account = ' \t\n ';
        await logic.verifyAccount();
        expect(accounts, isEmpty);
        expect(logic.isAccountRegistered, isNull);

        logic.account = ' re ader ';
        expect(await logic.verifyAccount(), isTrue);
        expect(accounts, ['reader']);
      });

      test('异常或格式错误均保持未确认状态', () async {
        int calls = 0;
        final logic = entry.value((_) async {
          if (++calls == 1) throw StateError('offline');
          return _response(null);
        });
        addTearDown(logic.dispose);
        logic.account = 'reader';

        await logic.verifyAccount();
        expect(logic.isAccountRegistered, isNull);
        await logic.verifyAccount();
        expect(logic.isAccountRegistered, isNull);
      });

      test('关闭页面后丢弃迟到响应，且不会发起新查询', () async {
        final pending = Completer<ResultsType<Map<String, dynamic>>>();
        int calls = 0;
        final logic = entry.value((_) {
          calls++;
          return pending.future;
        });
        logic.account = 'reader';
        final request = logic.verifyAccount();
        logic.dispose();
        pending.complete(_response(false));

        await request;
        expect(logic.isAccountRegistered, isNull);
        expect(await logic.verifyAccount(), isFalse);
        expect(calls, 1);
      });
    });
  }
}
