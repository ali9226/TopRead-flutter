// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/api/ad_free.dart';
import 'package:app/api/results_type.dart';
import 'package:app/models/ad_verify_result.dart';
import 'package:app/models/user_info.dart';
import 'package:app/stores/read_ad_free_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Harness harness;
  setUp(() => harness = _Harness());
  tearDown(() async {
    harness.close();
    Get.reset();
  });

  test('服务器有效权益按剩余秒数恢复，不受设备时钟偏差影响', () async {
    harness.set_server_seconds(0, 1799);
    harness.now = DateTime.utc(2036, 1, 1);
    final ReadAdFreeStore store = harness.create_store();
    await store.refresh();
    expect(store.is_status_ready, isTrue);
    expect(store.is_ad_free, isTrue);
    expect(store.expire_time, harness.now.add(const Duration(seconds: 1799)));
  });

  test('跨小说共用同一权益，重建应用后服务器与缓存恢复剩余时长', () async {
    harness.set_server_seconds(0, 1800);
    final ReadAdFreeStore first = harness.create_store();
    await first.refresh();
    final DateTime? first_expire = first.expire_time;
    harness.stop(first);
    harness.network_available = false;
    final ReadAdFreeStore restarted = harness.create_store();
    await restarted.refresh();
    expect(restarted.is_ad_free, isTrue);
    expect(restarted.expire_time, first_expire);
  });

  test('访客与登录用户独立；同设备 A 到 B 到 A 恢复 A 剩余权益', () async {
    harness.set_server_seconds(0, 1800);
    harness.set_server_seconds(1, 1200);
    final ReadAdFreeStore store = harness.create_store();
    await store.refresh();
    expect(store.is_ad_free, isTrue);
    harness.login(1);
    await store.refresh();
    expect(store.expire_time, harness.now.add(const Duration(seconds: 1200)));
    harness.login(2);
    await store.refresh();
    expect(store.is_ad_free, isFalse);
    harness.login(1);
    await store.refresh();
    expect(store.expire_time, harness.now.add(const Duration(seconds: 1200)));
    harness.logout();
    await store.refresh();
    expect(store.expire_time, harness.now.add(const Duration(seconds: 1800)));
  });

  test('同一账号换设备不继承旧设备缓存', () async {
    harness.login(1);
    harness.set_server_seconds(1, 1800);
    final ReadAdFreeStore first = harness.create_store();
    await first.refresh();
    harness.stop(first);
    harness.device = 'second-device';
    final ReadAdFreeStore second = harness.create_store();
    await second.refresh();
    expect(second.is_status_ready, isTrue);
    expect(second.is_ad_free, isFalse);
  });

  test('首次网络失败不放行广告；后续重查可恢复服务器权益', () async {
    harness.network_available = false;
    final ReadAdFreeStore store = harness.create_store();
    await store.refresh();
    expect(store.is_status_ready, isFalse);
    harness.network_available = true;
    harness.set_server_seconds(0, 1800);
    await store.refresh();
    expect(store.is_ad_free, isTrue);
  });

  test('旧账号查询迟到响应不能覆盖新账号，也不能回写旧 SDK 奖励', () async {
    harness.login(1);
    final Completer<ResultsType<AdFreeStatus>> delayed =
        Completer<ResultsType<AdFreeStatus>>();
    harness.status_override = (_) => delayed.future;
    final ReadAdFreeStore store = harness.create_store();
    final Future<void> old_request = store.refresh();
    await _flush();
    final AdFreeRequestIdentity old_identity = harness.identity();
    harness.status_override = null;
    harness.login(2);
    await store.refresh();
    delayed.complete(_success(harness.status_for(old_identity, seconds: 1800)));
    await old_request;
    expect(store.is_ad_free, isFalse);
    expect(
      await store.record_reward(
        identity: old_identity,
        uuid: 'old',
        duration_minutes: 30,
      ),
      isFalse,
    );
    expect(store.is_ad_free, isFalse);
  });

  test('SDK 奖励按 UUID 持久化，页面销毁和应用重启后继续等待 SSV', () async {
    final ReadAdFreeStore first = harness.create_store();
    await first.refresh();
    final AdFreeRequestIdentity identity = (await first
        .capture_reward_identity())!;
    expect(
      await first.record_reward(
        identity: identity,
        uuid: 'pending',
        duration_minutes: 30,
      ),
      isTrue,
    );
    final DateTime? expire = first.expire_time;
    // 页面不持有 store；模拟页面退出后第二次相同 SDK 回调也不能多给时长。
    expect(
      await first.record_reward(
        identity: identity,
        uuid: 'pending',
        duration_minutes: 30,
      ),
      isTrue,
    );
    expect(first.expire_time, expire);
    harness.stop(first);
    final ReadAdFreeStore restarted = harness.create_store();
    await restarted.refresh();
    expect(restarted.is_ad_free, isTrue);
    expect(restarted.expire_time, expire);
    expect(harness.waits.length, 2);
  });

  test('已确认 UUID 重复回调不会再次叠加，同一时刻多个奖励确认不重复发放', () async {
    final ReadAdFreeStore store = harness.create_store();
    await store.refresh();
    final AdFreeRequestIdentity identity = (await store
        .capture_reward_identity())!;
    await store.record_reward(
      identity: identity,
      uuid: 'first',
      duration_minutes: 30,
    );
    await store.record_reward(
      identity: identity,
      uuid: 'second',
      duration_minutes: 30,
    );
    harness.set_server_seconds(0, 3600);
    harness.verified = true;
    final List<Completer<void>> initial_waits = List<Completer<void>>.from(
      harness.waits,
    );
    for (final Completer<void> wait in initial_waits) {
      wait.complete();
    }
    await _flush();
    // 同帧确认时过时的状态查询可以复核，权益仍严格等于服务端总时长。
    for (final Completer<void> wait
        in harness.waits.skip(initial_waits.length).toList()) {
      wait.complete();
    }
    await _flush();
    expect(store.expire_time, harness.now.add(const Duration(hours: 1)));
    await store.record_reward(
      identity: identity,
      uuid: 'first',
      duration_minutes: 30,
    );
    expect(store.expire_time, harness.now.add(const Duration(hours: 1)));
  });

  test('SSV 未确认的乐观权益到等待窗口后失效，服务器确认后恢复', () async {
    final ReadAdFreeStore store = harness.create_store();
    await store.refresh();
    final AdFreeRequestIdentity identity = (await store
        .capture_reward_identity())!;
    await store.record_reward(
      identity: identity,
      uuid: 'pending',
      duration_minutes: 30,
    );
    harness.now = harness.now.add(const Duration(minutes: 6));
    await store.refresh();
    expect(store.is_ad_free, isFalse);
    harness.set_server_seconds(0, 1440);
    harness.verified = true;
    harness.waits.first.complete();
    await _flush();
    expect(store.is_ad_free, isTrue);
    expect(store.expire_time, harness.now.add(const Duration(minutes: 24)));
  });

  test('第二个奖励先获得 SSV 确认时保留两次观看的累计乐观时长', () async {
    final ReadAdFreeStore store = harness.create_store();
    await store.refresh();
    final AdFreeRequestIdentity identity = (await store
        .capture_reward_identity())!;
    await store.record_reward(
      identity: identity,
      uuid: 'first',
      duration_minutes: 30,
    );
    await store.record_reward(
      identity: identity,
      uuid: 'second',
      duration_minutes: 30,
    );
    harness.set_server_seconds(0, 1800);
    harness.verified_uuids.add('second');
    harness.waits[1].complete();
    await _flush();
    expect(store.expire_time, harness.now.add(const Duration(hours: 1)));
    await store.record_reward(
      identity: identity,
      uuid: 'second',
      duration_minutes: 30,
    );
    expect(store.expire_time, harness.now.add(const Duration(hours: 1)));
    harness.set_server_seconds(0, 3600);
    harness.verified_uuids.add('first');
    harness.waits[0].complete();
    await _flush();
    expect(store.expire_time, harness.now.add(const Duration(hours: 1)));
  });

  test('SSV 已在广告关闭前同步时 SDK 本地奖励不重复叠加', () async {
    final ReadAdFreeStore store = harness.create_store();
    await store.refresh();
    final AdFreeRequestIdentity identity = (await store
        .capture_reward_identity())!;
    final AdFreeStatus before_ad = harness.status_for(identity);
    final DateTime received_at = harness.now;
    harness.set_server_seconds(0, 1800);
    await store.refresh();
    await store.record_reward(
      identity: identity,
      uuid: 'already-on-server',
      duration_minutes: 30,
      server_status: before_ad,
      server_status_received_at: received_at,
    );
    expect(store.expire_time, harness.now.add(const Duration(minutes: 30)));
  });

  test('播放前剩余时间以响应收到时间计算，不把观看耗时额外叠加', () async {
    harness.set_server_seconds(0, 600);
    final ReadAdFreeStore store = harness.create_store();
    await store.refresh();
    final AdFreeRequestIdentity identity = (await store
        .capture_reward_identity())!;
    final AdFreeStatus before_ad = harness.status_for(identity);
    final DateTime received_at = harness.now;
    harness.now = harness.now.add(const Duration(minutes: 1));
    await store.record_reward(
      identity: identity,
      uuid: 'new-reward',
      duration_minutes: 30,
      server_status: before_ad,
      server_status_received_at: received_at,
    );
    expect(store.expire_time, received_at.add(const Duration(minutes: 40)));
  });

  test('服务器明确无权益会清除确认缓存；网络失败会保留有效缓存', () async {
    harness.set_server_seconds(0, 1800);
    final ReadAdFreeStore store = harness.create_store();
    await store.refresh();
    harness.network_available = false;
    await store.refresh();
    expect(store.is_ad_free, isTrue);
    harness.network_available = true;
    harness.set_server_seconds(0, 0);
    await store.refresh();
    expect(store.is_ad_free, isFalse);
  });

  test('未知归属、其他设备和其他账号的服务器权益不能生效', () async {
    harness.login(1);
    final ReadAdFreeStore store = harness.create_store();
    await store.refresh();
    for (final AdFreeStatus invalid in <AdFreeStatus>[
      const AdFreeStatus(is_ad_free: true, remaining_seconds: 1800),
      const AdFreeStatus(
        is_ad_free: true,
        remaining_seconds: 1800,
        user_id: 1,
        device_token: 'other',
      ),
      const AdFreeStatus(
        is_ad_free: true,
        remaining_seconds: 1800,
        user_id: 2,
        device_token: 'first-device',
      ),
    ]) {
      harness.status_override = (_) async => _success(invalid);
      await store.refresh();
      expect(store.is_ad_free, isFalse);
    }
  });

  test('自动登录前能用服务器返回的用户归属恢复，不能误写访客缓存', () async {
    harness.token = 'user-1';
    harness.set_server_seconds(1, 1800);
    final ReadAdFreeStore store = harness.create_store();
    await store.refresh();
    expect(store.is_ad_free, isTrue);
    expect(
      harness.cache.keys.any((key) => key == 'read_ad_free_v1:first-device:0'),
      isFalse,
    );
    harness.stop(store);
    harness.network_available = false;
    final ReadAdFreeStore restarted = harness.create_store();
    await restarted.refresh();
    expect(restarted.is_ad_free, isTrue);
  });
}

Future<void> _flush() async {
  for (int turn = 0; turn < 20; turn++) {
    await Future<void>.value();
  }
}

ResultsType<AdFreeStatus> _success(AdFreeStatus status) =>
    ResultsType<AdFreeStatus>()
      ..status = true
      ..content = status;

class _Harness {
  final UserInformation user = Get.put(UserInformation());
  final Map<String, String> cache = <String, String>{};
  final Map<String, int> server_seconds = <String, int>{};
  final List<ReadAdFreeStore> stores = <ReadAdFreeStore>[];
  final List<Completer<void>> waits = <Completer<void>>[];
  DateTime now = DateTime.utc(2026, 10, 9);
  String device = 'first-device';
  String token = '';
  bool network_available = true;
  bool verified = false;
  final Set<String> verified_uuids = <String>{};
  Future<ResultsType<AdFreeStatus>> Function(AdFreeRequestIdentity)?
  status_override;

  AdFreeRequestIdentity identity() => AdFreeRequestIdentity(
    device_token: device,
    authorization_token: token,
    user_id: token.isEmpty ? 0 : user.userInfo.value?.id,
    auth_revision: user.auth_revision,
  );

  AdFreeStatus status_for(AdFreeRequestIdentity identity, {int? seconds}) {
    final int user_id = identity.authorization_token.isEmpty
        ? 0
        : int.parse(identity.authorization_token.split('-').last);
    final int remaining =
        seconds ?? server_seconds['${identity.device_token}:$user_id'] ?? 0;
    return AdFreeStatus(
      is_ad_free: remaining > 0,
      // 故意返回与设备时钟无关的 UTC 时间，确认由 remaining_seconds 计算。
      expire_time: '2026-10-09T00:30:00Z',
      remaining_seconds: remaining,
      user_id: user_id,
      device_token: identity.device_token,
    );
  }

  ReadAdFreeStore create_store() {
    final ReadAdFreeStore store = ReadAdFreeStore(
      user_information: user,
      identity_reader: () async => identity(),
      status_request: (identity) async {
        if (status_override != null) return status_override!(identity);
        if (!network_available) return ResultsType<AdFreeStatus>();
        return _success(status_for(identity));
      },
      verification_request: (_, uuid) async => ResultsType<AdVerifyResult>()
        ..status = true
        ..content = AdVerifyResult(
          status: verified || verified_uuids.contains(uuid) ? 2 : 1,
        ),
      cache_reader: (key) async => cache[key],
      cache_writer: (key, value) async {
        cache[key] = value;
        return true;
      },
      clock: () => now,
      verification_waiter: (_) {
        final Completer<void> wait = Completer<void>();
        waits.add(wait);
        return wait.future;
      },
    );
    stores.add(store);
    store.onInit();
    return store;
  }

  void set_server_seconds(int user_id, int seconds) =>
      server_seconds['$device:$user_id'] = seconds;
  void login(int user_id) {
    token = 'user-$user_id';
    user.saveUserInfo(UserInfo.fromJson(<String, dynamic>{'id': user_id}));
  }

  void logout() {
    token = '';
    user.begin_logout();
  }

  void stop(ReadAdFreeStore store) {
    store.onClose();
    stores.remove(store);
  }

  void close() {
    for (final ReadAdFreeStore store in stores) {
      store.onClose();
    }
  }
}
