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
