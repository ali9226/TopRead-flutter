// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:app/api/ad_free.dart';
import 'package:app/api/results_type.dart';
import 'package:app/models/ad_verify_result.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

typedef ReadAdFreeStatusRequest =
    Future<ResultsType<AdFreeStatus>> Function(AdFreeRequestIdentity identity);
typedef ReadAdFreeVerificationRequest =
    Future<ResultsType<AdVerifyResult>> Function(
      AdFreeRequestIdentity identity,
      String uuid,
    );

/// 应用内长篇阅读专用权益。小说页面只订阅状态，不拥有奖励或校验任务。
///
/// 缓存按设备和服务端认证用户隔离；访客固定为用户 0。SDK 奖励只在有限
/// 的 SSV 等待期内乐观生效，待校验记录持久化后可跨页面和重启继续确认。
class ReadAdFreeStore extends GetxController with WidgetsBindingObserver {
  ReadAdFreeStore({
    UserInformation? user_information,
    Future<AdFreeRequestIdentity?> Function()? identity_reader,
    ReadAdFreeStatusRequest? status_request,
    ReadAdFreeVerificationRequest? verification_request,
    Future<String?> Function(String)? cache_reader,
    Future<bool> Function(String, String)? cache_writer,
    DateTime Function()? clock,
    Future<void> Function(Duration)? verification_waiter,
    this.pending_grace = const Duration(minutes: 5),
    this.retry_delays = const <Duration>[
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
      Duration(seconds: 16),
      Duration(seconds: 30),
      Duration(seconds: 30),
    ],
    this.status_retry_delay = const Duration(seconds: 30),
    this.verification_retry_delay = const Duration(minutes: 2),
  }) : user_information = user_information ?? Get.find<UserInformation>(),
       _identity_reader = identity_reader ?? capture_ad_free_request_identity,
       _status_request =
           status_request ??
           ((identity) => check_ad_free_status(identity: identity)),
       _verification_request =
           verification_request ??
           ((identity, uuid) =>
               verify_ad_free_reward(identity: identity, uuid: uuid)),
       _cache_reader = cache_reader ?? StorageUtil.getData,
       _cache_writer = cache_writer ?? StorageUtil.saveData,
       _clock = clock ?? DateTime.now,
       _verification_waiter = verification_waiter ?? Future<void>.delayed;

  final UserInformation user_information;
  final Future<AdFreeRequestIdentity?> Function() _identity_reader;
  final ReadAdFreeStatusRequest _status_request;
  final ReadAdFreeVerificationRequest _verification_request;
  final Future<String?> Function(String) _cache_reader;
  final Future<bool> Function(String, String) _cache_writer;
  final DateTime Function() _clock;
  final Future<void> Function(Duration) _verification_waiter;
  final Duration pending_grace;
  final List<Duration> retry_delays;
  final Duration status_retry_delay;
  final Duration verification_retry_delay;

  /// 一次通知同时包含截止时间和查询就绪状态，页面不会看到中间状态。
  final RxInt state_revision = 0.obs;
  bool is_status_ready = false;
  DateTime? expire_time;
  bool get is_ad_free => expire_time?.isAfter(_clock()) ?? false;

  AdFreeRequestIdentity? _identity;
  DateTime? _confirmed_expire_time;

  /// 同批奖励的累计乐观截止时间，SSV 逆序确认时也不丢尚待确认的叠加时长。
  DateTime? _optimistic_expire_time;
  final Map<String, _PendingReadReward> _pending =
      <String, _PendingReadReward>{};

  /// 已领取 UUID 保留到对应奖励到期，确认后也不能再次叠加同一次 SDK 回调。
  final Map<String, DateTime> _rewarded_uuids = <String, DateTime>{};
  final Set<String> _verification_tasks = <String>{};
  final Map<String, Future<void>> _cache_writes = <String, Future<void>>{};
  Worker? _identity_worker;
  Timer? _expiration_timer;
  Timer? _status_retry_timer;
  Future<void>? _refresh_future;
  int _generation = 0;
  int _status_generation = 0;
  int _observed_auth_revision = -1;
  bool _closed = false;

  @override
  void onInit() {
    super.onInit();
    _observed_auth_revision = user_information.auth_revision;
    _identity_worker = ever(user_information.userInfo, (_) {
      if (_observed_auth_revision == user_information.auth_revision) return;
      _observed_auth_revision = user_information.auth_revision;
      _reset_identity();
      unawaited(refresh());
    });
    WidgetsBinding.instance.addObserver(this);
    unawaited(refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(refresh());
  }

  /// 重查服务器。已有同身份缓存立即生效，网络失败不会覆盖它。
  Future<void> refresh() {
    if (_closed) return Future<void>.value();
    if (_refresh_future != null) return _refresh_future!;
    late final Future<void> operation;
    operation = _refresh_identity(_generation).whenComplete(() {
      if (identical(_refresh_future, operation)) _refresh_future = null;
    });
    _refresh_future = operation;
    return operation;
  }

  Future<void> _refresh_identity(int generation) async {
    try {
      AdFreeRequestIdentity? identity = await _identity_reader();
      if (!_is_generation_current(generation)) return;
      if (identity == null) {
        _schedule_status_retry();
        return;
      }
      if (_identity == null) {
        // 自动登录尚未返回时，仅使用与当前凭证摘要绑定的已确认用户编号。
        int? user_id = identity.user_id;
        if (identity.authorization_token.isEmpty) {
          user_id = 0;
        } else if (user_id == null || user_id <= 0) {
          final String? mapping = await _cache_reader(_mapping_key(identity));
          user_id = int.tryParse(mapping ?? '');
        }
        if (!_is_generation_current(generation)) return;
        identity = _with_user_id(identity, user_id);
        _identity = identity;
        if (user_id != null) await _restore_cache(identity, generation);
      } else if (_identity!.device_token != identity.device_token ||
          _identity!.authorization_token != identity.authorization_token ||
          _identity!.auth_revision != identity.auth_revision) {
        _reset_identity();
        unawaited(refresh());
        return;
      } else {
        identity = _identity;
      }
      if (!_is_generation_current(generation) || identity == null) return;
      await _fetch_status(identity, generation);
      _resume_pending_verification(generation);
    } catch (error) {
      logUtil(msg: '[ReadAdFree] 状态恢复失败: $error', type: 'w');
      if (_is_generation_current(generation)) _schedule_status_retry();
    }
  }

  /// 广告开始前固定当前身份。归属未知时先查询服务器，不能发访客奖励。
  Future<AdFreeRequestIdentity?> capture_reward_identity() async {
    await refresh();
    final AdFreeRequestIdentity? identity = _identity;
    return is_status_ready &&
            identity != null &&
            identity.user_id != null &&
            is_identity_current(identity)
        ? identity
        : null;
  }

  /// 页面和 SDK 的迟到回调必须同时通过会话版本及设备、账号校验。
  bool is_identity_current(AdFreeRequestIdentity identity) {
    final AdFreeRequestIdentity? current = _identity;
    return !_closed &&
        user_information.is_auth_revision_current(identity.auth_revision) &&
        current != null &&
        current.auth_revision == identity.auth_revision &&
        current.device_token == identity.device_token &&
        current.user_id == identity.user_id &&
        current.authorization_token == identity.authorization_token;
  }

  /// 只有 SDK 发放奖励后才记录待确认 UUID；写盘完成后再向页面通知。
  Future<bool> record_reward({
    required AdFreeRequestIdentity identity,
    required String uuid,
    required int duration_minutes,
    AdFreeStatus? server_status,
    DateTime? server_status_received_at,
  }) async {
    if (!is_identity_current(identity) ||
        uuid.isEmpty ||
        duration_minutes <= 0) {
      return false;
    }
    if (_rewarded_uuids.containsKey(uuid)) return true;
    final DateTime now = _clock();
    // 最新 confirmed 可能已包含本次 SSV 奖励，不能再次把 duration 加到它。
    DateTime base = now;
    if (_pending.values.any(
          (reward) => reward.granted_at.add(pending_grace).isAfter(now),
        ) &&
        _optimistic_expire_time != null &&
        _optimistic_expire_time!.isAfter(base)) {
      base = _optimistic_expire_time!;
    }
    if (_status_matches(identity, server_status) &&
        server_status!.is_ad_free &&
        server_status.remaining_seconds > 0) {
      final DateTime confirmed = (server_status_received_at ?? now).add(
        Duration(seconds: server_status.remaining_seconds),
      );
      if (confirmed.isAfter(base)) base = confirmed;
    }
    _pending[uuid] = _PendingReadReward(
      uuid: uuid,
      granted_at: now,
      expire_time: base.add(Duration(minutes: duration_minutes)),
    );
    _rewarded_uuids[uuid] = _pending[uuid]!.expire_time;
    _optimistic_expire_time = _pending[uuid]!.expire_time;
    _rewarded_uuids.updateAll(
      (_, until) => until.isBefore(_optimistic_expire_time!)
          ? _optimistic_expire_time!
          : until,
    );
    final int generation = _generation;
    await _persist_cache(identity);
    if (!_is_generation_current(generation) || !is_identity_current(identity))
      return false;
    is_status_ready = true;
    _publish_state();
    _resume_pending_verification(generation);
    return true;
  }

  Future<bool> _fetch_status(
    AdFreeRequestIdentity identity,
    int generation, {
    String? completed_uuid,
  }) async {
    final int status_generation = ++_status_generation;
    final ResultsType<AdFreeStatus> result = await _status_request(identity);
    if (!_is_generation_current(generation) ||
        status_generation != _status_generation ||
        !user_information.is_auth_revision_current(identity.auth_revision))
      return false;
    final AdFreeStatus? status = result.content;
    if (!result.status ||
        status == null ||
        !_status_matches(identity, status)) {
      _publish_state();
      _schedule_status_retry();
      return false;
    }
    final int? user_id = status.user_id ?? identity.user_id;
    if (user_id == null) {
      _schedule_status_retry();
      return false;
    }
    final bool newly_resolved = _identity?.user_id == null;
    identity = _with_user_id(identity, user_id);
    _identity = identity;
    if (newly_resolved) await _restore_cache(identity, generation);
    if (!_is_generation_current(generation)) return false;
    // 剩余秒数由服务器计算，设备时钟偏差不会让尚未到期的权益提前失效。
    _confirmed_expire_time = status.is_ad_free && status.remaining_seconds > 0
        ? _clock().add(Duration(seconds: status.remaining_seconds))
        : null;
    if (completed_uuid != null) _pending.remove(completed_uuid);
    is_status_ready = true;
    _status_retry_timer?.cancel();
    _publish_state();
    await _persist_cache(identity);
    if (!_is_generation_current(generation)) return false;
    if (identity.authorization_token.isNotEmpty) {
      await _cache_writer(_mapping_key(identity), user_id.toString());
    }
    return true;
  }

  bool _status_matches(AdFreeRequestIdentity identity, AdFreeStatus? status) {
    // 旧服务端的设备汇总结果不能当作按账号隔离的权益使用。
    if (status == null || status.user_id == null || status.device_token == null)
      return false;
    if (status.device_token != identity.device_token) return false;
    if (identity.authorization_token.isEmpty &&
        status.user_id != null &&
        status.user_id != 0)
      return false;
    if (identity.authorization_token.isNotEmpty && status.user_id == 0)
      return false;
    if (identity.user_id != null &&
        status.user_id != null &&
        status.user_id != identity.user_id)
      return false;
    return true;
  }

  Future<void> _restore_cache(
    AdFreeRequestIdentity identity,
    int generation,
  ) async {
    final String? value = await _cache_reader(_scope_key(identity));
    if (!_is_generation_current(generation) || value == null) return;
    try {
      final dynamic decoded = jsonDecode(value);
      if (decoded is! Map ||
          decoded['device_token'] != identity.device_token ||
          decoded['user_id'] != identity.user_id)
        return;
      _confirmed_expire_time = DateTime.tryParse(
        decoded['confirmed_expire_time']?.toString() ?? '',
      );
      _optimistic_expire_time = DateTime.tryParse(
        decoded['optimistic_expire_time']?.toString() ?? '',
      );
      final dynamic pending = decoded['pending'];
      final dynamic rewarded = decoded['rewarded_uuids'];
      if (rewarded is Map) {
        for (final dynamic uuid in rewarded.keys) {
          final DateTime? until = DateTime.tryParse(
            rewarded[uuid]?.toString() ?? '',
          );
          if (until != null && until.isAfter(_clock()))
            _rewarded_uuids[uuid.toString()] = until;
        }
      }
      if (pending is List) {
        for (final dynamic entry in pending) {
          if (entry is! Map) continue;
          final _PendingReadReward? reward = _PendingReadReward.from_json(
            entry,
          );
          if (reward != null && reward.expire_time.isAfter(_clock())) {
            _pending[reward.uuid] = reward;
            _rewarded_uuids[reward.uuid] = reward.expire_time;
          }
        }
      }
      if ((_confirmed_expire_time?.isAfter(_clock()) ?? false) ||
          _pending.isNotEmpty) {
        is_status_ready = true;
      }
      _publish_state();
    } catch (error) {
      logUtil(msg: '[ReadAdFree] 忽略损坏的本地权益缓存: $error', type: 'w');
    }
  }

  Future<void> _persist_cache(AdFreeRequestIdentity identity) {
    if (identity.user_id == null) return Future<void>.value();
    final String key = _scope_key(identity);
    final String value = jsonEncode(<String, dynamic>{
      'device_token': identity.device_token,
      'user_id': identity.user_id,
      'confirmed_expire_time': _confirmed_expire_time?.toIso8601String(),
      'optimistic_expire_time': _optimistic_expire_time?.toIso8601String(),
      'pending': _pending.values.map((reward) => reward.to_json()).toList(),
      'rewarded_uuids': _rewarded_uuids.map(
        (uuid, until) => MapEntry(uuid, until.toIso8601String()),
      ),
    });
    // 同一身份的缓存顺序写入，旧磁盘刷新不能覆盖较新的叠加奖励。
    final Future<void> previous = _cache_writes[key] ?? Future<void>.value();
    final Future<void> write = previous
        .then((_) async {
          await _cache_writer(key, value);
        })
        .catchError((Object error) {
          logUtil(msg: '[ReadAdFree] 权益缓存保存失败: $error', type: 'w');
        });
    _cache_writes[key] = write;
    return write;
  }

  void _publish_state() {
    final DateTime now = _clock();
    DateTime? effective = _confirmed_expire_time;
    DateTime? next_transition = effective != null && effective.isAfter(now)
        ? effective
        : null;
    _pending.removeWhere((_, reward) => !reward.expire_time.isAfter(now));
    _rewarded_uuids.removeWhere((_, until) => !until.isAfter(now));
    if (_pending.isEmpty) _optimistic_expire_time = null;
    for (final _PendingReadReward reward in _pending.values) {
      final DateTime grace_end = reward.granted_at.add(pending_grace);
      if (!grace_end.isAfter(now)) continue;
      if (effective == null || reward.expire_time.isAfter(effective))
        effective = reward.expire_time;
      if (_optimistic_expire_time != null &&
          _optimistic_expire_time!.isAfter(effective)) {
        effective = _optimistic_expire_time;
      }
      final DateTime transition = grace_end.isBefore(reward.expire_time)
          ? grace_end
          : reward.expire_time;
      if (next_transition == null || transition.isBefore(next_transition))
        next_transition = transition;
    }
    expire_time = effective != null && effective.isAfter(now)
        ? effective
        : null;
    if (expire_time != null) {
      _rewarded_uuids.updateAll(
        (_, until) => until.isBefore(expire_time!) ? expire_time! : until,
      );
    }
    state_revision.value++;
    _expiration_timer?.cancel();
    if (next_transition != null) {
      _expiration_timer = Timer(next_transition.difference(now), () {
        if (_closed) return;
        _publish_state();
        unawaited(refresh());
      });
    }
  }

  void _resume_pending_verification(int generation) {
    final AdFreeRequestIdentity? identity = _identity;
    if (identity == null || identity.user_id == null) return;
    for (final String uuid in _pending.keys.toList()) {
      final String task = '$generation:$uuid';
      if (!_verification_tasks.add(task)) continue;
      unawaited(
        _verify_reward(identity, generation, uuid).whenComplete(() {
          _verification_tasks.remove(task);
        }),
      );
    }
  }

  Future<void> _verify_reward(
    AdFreeRequestIdentity identity,
    int generation,
    String uuid,
  ) async {
    int attempt = 0;
    while (_is_generation_current(generation) &&
        is_identity_current(identity) &&
        _pending.containsKey(uuid)) {
      final Duration delay = attempt < retry_delays.length
          ? retry_delays[attempt++]
          : verification_retry_delay;
      try {
        await _verification_waiter(delay);
        if (!_is_generation_current(generation) ||
            !is_identity_current(identity) ||
            !_pending.containsKey(uuid))
          return;
        final ResultsType<AdVerifyResult> result = await _verification_request(
          identity,
          uuid,
        );
        if (!_is_generation_current(generation) ||
            !is_identity_current(identity))
          return;
        if (result.status &&
            result.content?.status == AdVerifyResult.status_completed) {
          if (await _fetch_status(identity, generation, completed_uuid: uuid))
            return;
        }
      } catch (error) {
        logUtil(msg: '[ReadAdFree] 等待 SSV 确认失败: $error', type: 'w');
      }
    }
  }

  void _schedule_status_retry() {
    if (_closed || (_status_retry_timer?.isActive ?? false)) return;
    _status_retry_timer = Timer(status_retry_delay, () => unawaited(refresh()));
  }

  void _reset_identity() {
    _generation++;
    _status_generation++;
    _refresh_future = null;
    _identity = null;
    _confirmed_expire_time = null;
    _optimistic_expire_time = null;
    _pending.clear();
    _rewarded_uuids.clear();
    _expiration_timer?.cancel();
    _status_retry_timer?.cancel();
    is_status_ready = false;
    expire_time = null;
    state_revision.value++;
  }

  bool _is_generation_current(int generation) =>
      !_closed && generation == _generation;

  static AdFreeRequestIdentity _with_user_id(
    AdFreeRequestIdentity identity,
    int? user_id,
  ) => AdFreeRequestIdentity(
    device_token: identity.device_token,
    authorization_token: identity.authorization_token,
    user_id: user_id,
    auth_revision: identity.auth_revision,
  );

  static String _scope_key(AdFreeRequestIdentity identity) =>
      'read_ad_free_v1:${identity.device_token}:${identity.user_id}';

  static String _mapping_key(AdFreeRequestIdentity identity) =>
      'read_ad_free_identity_v1:${identity.device_token}:${sha256.convert(utf8.encode(identity.authorization_token))}';

  @override
  void onClose() {
    _closed = true;
    _generation++;
    _identity_worker?.dispose();
    _expiration_timer?.cancel();
    _status_retry_timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}

class _PendingReadReward {
  final String uuid;
  final DateTime granted_at;
  final DateTime expire_time;
  const _PendingReadReward({
    required this.uuid,
    required this.granted_at,
    required this.expire_time,
  });

  static _PendingReadReward? from_json(Map<dynamic, dynamic> json) {
    final String uuid = json['uuid']?.toString() ?? '';
    final DateTime? granted_at = DateTime.tryParse(
      json['granted_at']?.toString() ?? '',
    );
    final DateTime? expire_time = DateTime.tryParse(
      json['expire_time']?.toString() ?? '',
    );
    return uuid.isEmpty || granted_at == null || expire_time == null
        ? null
        : _PendingReadReward(
            uuid: uuid,
            granted_at: granted_at,
            expire_time: expire_time,
          );
  }

  Map<String, dynamic> to_json() => <String, dynamic>{
    'uuid': uuid,
    'granted_at': granted_at.toIso8601String(),
    'expire_time': expire_time.toIso8601String(),
  };
}
