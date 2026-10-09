import 'dart:async';

import 'package:app/models/user_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<UserInformation>(UserInformation());
  });

  tearDown(() {
    Get.reset();
  });

  test('退出后丢弃退出前发出的用户资料响应', () {
    final UserInformation user_information = Get.find<UserInformation>();
    final UserInfo original_user = _build_user_info(id: 1, name: 'original');
    final UserInfo stale_user = _build_user_info(id: 1, name: 'stale');

    user_information.saveUserInfo(original_user);
    final int request_revision = user_information.auth_revision;

    final int logout_revision = user_information.begin_logout();
    final bool saved = user_information.save_user_info_if_current(
      stale_user,
      request_revision: request_revision,
    );

    expect(logout_revision, request_revision + 1);
    expect(saved, isFalse);
    expect(user_information.isLoggedIn.value, isFalse);
    expect(user_information.userInfo.value, isNull);
  });

  test('重新登录后旧会话响应不能覆盖新用户', () {
    final UserInformation user_information = Get.find<UserInformation>();
    final UserInfo old_user = _build_user_info(id: 1, name: 'old');
    final UserInfo new_user = _build_user_info(id: 2, name: 'new');

    user_information.saveUserInfo(old_user);
    final int old_request_revision = user_information.auth_revision;
    user_information.begin_logout();
    user_information.saveUserInfo(new_user);

    final bool saved = user_information.save_user_info_if_current(
      old_user,
      request_revision: old_request_revision,
    );

    expect(saved, isFalse);
    expect(user_information.isLoggedIn.value, isTrue);
    expect(user_information.userInfo.value?.id, new_user.id);
  });

  test('直接切换账号时旧账号响应不能覆盖新用户', () {
    final UserInformation user_information = Get.find<UserInformation>();
    final UserInfo old_user = _build_user_info(id: 1, name: 'old');
    final UserInfo new_user = _build_user_info(id: 2, name: 'new');

    user_information.saveUserInfo(old_user);
    final int old_request_revision = user_information.auth_revision;
    user_information.saveUserInfo(new_user);

    expect(
      user_information.save_user_info_if_current(
        old_user,
        request_revision: old_request_revision,
      ),
      isFalse,
    );
    expect(user_information.userInfo.value?.id, new_user.id);
  });

  test('清空用户并重新登录同一账号后丢弃原会话响应', () {
    final UserInformation user_information = Get.find<UserInformation>();
    final UserInfo original_user = _build_user_info(id: 1, name: 'original');
    final UserInfo fresh_user = _build_user_info(id: 1, name: 'fresh');

    user_information.saveUserInfo(original_user);
    final int old_request_revision = user_information.auth_revision;
    user_information.clearUserInfo();
    user_information.saveUserInfo(fresh_user);

    expect(
      user_information.save_user_info_if_current(
        original_user,
        request_revision: old_request_revision,
      ),
      isFalse,
    );
    expect(user_information.userInfo.value?.name, 'fresh');
  });

  test('同一用户资料刷新保留认证会话版本', () {
    final UserInformation user_information = Get.find<UserInformation>();
    user_information.saveUserInfo(_build_user_info(id: 1, name: 'original'));
    final int request_revision = user_information.auth_revision;

    user_information.saveUserInfo(_build_user_info(id: 1, name: 'fresh'));

    expect(user_information.auth_revision, request_revision);
    expect(
      user_information.can_apply_authenticated_response(request_revision),
      isTrue,
    );
  });

  test('认证身份变化时隔离用户中心滚动状态，同一用户资料刷新时保持状态', () {
    final UserInformation user_information = Get.find<UserInformation>();
    final UserInfo first_user = _build_user_info(id: 1, name: 'first');
    final UserInfo refreshed_first_user = _build_user_info(
      id: 1,
      name: 'refreshed',
    );

    final int initial_guest_revision = user_information.auth_identity_revision;

    user_information.saveUserInfo(first_user);
    final int first_login_revision = user_information.auth_identity_revision;

    user_information.saveUserInfo(refreshed_first_user);
    final int refreshed_user_revision = user_information.auth_identity_revision;

    user_information.begin_logout();
    final int logged_out_revision = user_information.auth_identity_revision;

    user_information.saveUserInfo(first_user);
    final int second_login_revision = user_information.auth_identity_revision;

    expect(first_login_revision, initial_guest_revision + 1);
    expect(refreshed_user_revision, first_login_revision);
    expect(logged_out_revision, first_login_revision + 1);
    expect(second_login_revision, logged_out_revision + 1);
  });

  test('凭证与用户同步提交，磁盘等待期间退出不会被旧登录恢复', () async {
    final Completer<bool> persistence = Completer<bool>();
    String? written_token;
    final UserInformation user_information = UserInformation(
      token_writer: (String key, String token) {
        written_token = token;
        return persistence.future;
      },
    );
    user_information.onInit();
    final int request_revision = user_information.auth_revision;
    final Future<bool> committed = user_information
        .save_auth_credentials_if_current(
          token: 'first-token',
          info: _build_user_info(id: 1, name: 'first'),
          request_revision: request_revision,
        );

    expect(written_token, 'first-token');
    expect(user_information.userInfo.value?.id, 1);
    expect(user_information.isLoggedIn.value, isTrue);
    user_information.begin_logout();
    persistence.complete(true);

    expect(await committed, isFalse);
    expect(user_information.userInfo.value, isNull);
  });

  test('持久化等待期间新登录完成后，旧提交不再覆盖凭证或身份', () async {
    final List<String> written_tokens = <String>[];
    final List<Completer<bool>> writes = <Completer<bool>>[];
    final UserInformation user_information = UserInformation(
      token_writer: (String key, String token) {
        written_tokens.add(token);
        final Completer<bool> write = Completer<bool>();
        writes.add(write);
        return write.future;
      },
    );
    user_information.onInit();
    final Future<bool> first = user_information
        .save_auth_credentials_if_current(
          token: 'first-token',
          info: _build_user_info(id: 1, name: 'first'),
          request_revision: user_information.auth_revision,
        );
    final Future<bool> second = user_information
        .save_auth_credentials_if_current(
          token: 'second-token',
          info: _build_user_info(id: 2, name: 'second'),
          request_revision: user_information.auth_revision,
        );
    writes[1].complete(true);
    expect(await second, isTrue);
    writes[0].complete(true);

    expect(await first, isFalse);
    expect(written_tokens, <String>['first-token', 'second-token']);
    expect(user_information.userInfo.value?.id, 2);
  });

  test('过期或关闭页面的凭证响应不执行任何写入', () async {
    int write_count = 0;
    final UserInformation user_information = UserInformation(
      token_writer: (String key, String token) async {
        write_count++;
        return true;
      },
    );
    final UserInfo info = _build_user_info(id: 1, name: 'first');
    final int stale_revision = user_information.auth_revision;
    user_information.begin_logout();
    expect(
      await user_information.save_auth_credentials_if_current(
        token: 'stale-token',
        info: info,
        request_revision: stale_revision,
      ),
      isFalse,
    );
    expect(
      await user_information.save_auth_credentials_if_current(
        token: 'closed-token',
        info: info,
        request_revision: user_information.auth_revision,
        is_active: () => false,
      ),
      isFalse,
    );
    expect(write_count, 0);
    expect(user_information.userInfo.value, isNull);
  });

  test('同账号更换凭证使旧认证请求失效但保持身份版本', () async {
    final UserInformation user_information = UserInformation(
      token_writer: (String key, String token) async => true,
    );
    final UserInfo info = _build_user_info(id: 1, name: 'first');
    user_information.saveUserInfo(info);
    final int old_revision = user_information.auth_revision;
    final int identity_revision = user_information.auth_identity_revision;

    expect(
      await user_information.save_auth_credentials_if_current(
        token: 'rotated-token',
        info: info,
        request_revision: old_revision,
      ),
      isTrue,
    );
    expect(user_information.auth_revision, old_revision + 1);
    expect(user_information.auth_identity_revision, identity_revision);
  });

  test('凭证持久化异常继续交给调用方处理', () async {
    final UserInformation user_information = UserInformation(
      token_writer: (String key, String token) async =>
          throw StateError('disk write failed'),
    );
    await expectLater(
      user_information.save_auth_credentials_if_current(
        token: 'token',
        info: _build_user_info(id: 1, name: 'first'),
        request_revision: user_information.auth_revision,
      ),
      throwsStateError,
    );
  });
}

UserInfo _build_user_info({required int id, required String name}) {
  return UserInfo(
    id: id,
    account: 'account_$id',
    invitationCode: 'code_$id',
    name: name,
    type: 1,
    avatarUrl: '',
    balance: 0,
    onlineStatus: 1,
    onlineStatusUpdateTime: '',
    shareRatio: 0,
    memberExpiryTime: '',
    roleName: '',
    notViewed: 0,
    followCount: 0,
    fansCount: 0,
    likesCount: 0,
  );
}
