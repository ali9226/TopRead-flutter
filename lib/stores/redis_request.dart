import 'dart:async';

import 'package:get/get.dart';
import 'package:app/api/post_request.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/language_util/language_change_handler.dart';
import 'package:app/models/redis_get_data.dart';
import 'package:app/models/rotation.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/stores/home_store.dart';
import 'package:app/stores/customer_service_store.dart';
import 'package:app/stores/authorized_login_store.dart';
import 'package:app/stores/preference_store.dart';
import 'package:app/stores/share_store.dart';
import 'package:app/stores/project_config_store.dart';

/// TODO: Redis 数据请求中心控制器
class RedisRequestStore extends GetxController {
  /// TODO: 防止重复请求
  final RxBool _is_fetching = false.obs;

  /// 请求期间是否收到了一次新的刷新请求。
  bool _has_pending_fetch = false;

  /// 合并后的后续请求是否需要展示错误提示。
  bool _pending_show_tips = false;

  /// 等待合并请求完成的调用方。
  Completer<bool>? _pending_completer;

  /// redis/get 接口是否正在请求中。
  bool get is_fetching => _is_fetching.value;

  /// 是否已经执行过至少一次 redis/get 请求。
  bool _has_fetched_once = false;

  /// 静默重试最大次数。
  static const int _max_retry_count = 3;

  /// 静默重试间隔（秒）。
  static const int _retry_delay_seconds = 5;

  /// 当前静默重试计数器。
  int _retry_count = 0;

  /// TODO: 全量拉取 Redis 配置并同步到各子 Store
  Future<bool> fetch_redis_data({bool showTips = false}) async {
    /// 请求进行中时不丢弃新请求，而是合并为下一轮请求。
    if (_is_fetching.value) {
      _has_pending_fetch = true;
      _pending_show_tips = _pending_show_tips || showTips;
      _pending_completer ??= Completer<bool>();
      return _pending_completer!.future;
    }

    _is_fetching.value = true;
    logUtil(msg: '开始执行中心化 redis/get 接口请求');
    _set_loading(true);

    /// 非语种切换场景仍沿用原有刷新态。
    if (Get.isRegistered<PreferenceStore>()) {
      final PreferenceStore preference_store = Get.find<PreferenceStore>();
      if (preference_store.loaded.value) {
        preference_store.is_loading.value = true;
      }
    }

    /// 通知首页分类数据开始刷新（仅非首次加载时展示骨架屏）。
    if (Get.isRegistered<HomeBannerStore>()) {
      final HomeBannerStore home_store = Get.find<HomeBannerStore>();
      if (home_store.has_cached_data && _has_fetched_once) {
        home_store.is_loading.value = true;
      }
      _has_fetched_once = true;
    }

    bool latest_result = false;
    bool current_show_tips = showTips;

    try {
      do {
        _has_pending_fetch = false;
        current_show_tips = current_show_tips || _pending_show_tips;
        _pending_show_tips = false;

        latest_result = await _fetch_once(show_tips: current_show_tips);
        current_show_tips = false;
      } while (_has_pending_fetch);
    } finally {
      _is_fetching.value = false;
      _set_loading(false);
      final Completer<bool>? completer = _pending_completer;
      _pending_completer = null;
      if (completer != null && !completer.isCompleted) {
        completer.complete(latest_result);
      }
    }

    return latest_result;
  }

  /// 执行单轮 Redis 配置请求。
  Future<bool> _fetch_once({required bool show_tips}) async {
    final int request_revision = LanguageChangeHandler.current_revision;
    final String request_language_code =
        LanguageChangeHandler.current_language_code;

    try {
      final results = await postRequest<RedisGetData>(
        path: 'redis/get',
        showTips: show_tips,
        fromJson: (Map<String, dynamic> json) => RedisGetData.from_json(json),
      );

      /// 切换期间到达的旧响应不能覆盖新语种数据。
      if (!LanguageChangeHandler.is_current_revision(
        request_revision,
        request_language_code,
      )) {
        logUtil(
          msg:
              '丢弃过期 redis/get 响应: '
              '$request_language_code#$request_revision',
          type: 'w',
        );
        return false;
      }

      if (!results.status || results.content == null) {
        logUtil(msg: 'redis/get 接口业务失败: ${results.message}', type: 'w');
        _finish_language_loading();
        _schedule_retry();
        return false;
      }

      final RedisGetData data = results.content!;
      _retry_count = 0;

      if (Get.isRegistered<LanguageStore>()) {
        Get.find<LanguageStore>().save_language_list(data.language_list);
      }

      _distribute_rotation_data(data.rotation_list);

      if (Get.isRegistered<PreferenceStore>()) {
        Get.find<PreferenceStore>()
          ..save_preference_list(data.preference_list)
          ..finish_language_refresh();
      }

      if (Get.isRegistered<HomeBannerStore>()) {
        Get.find<HomeBannerStore>()
          ..save_home_classification_list(data.home_classification_list)
          ..save_rankings_list(data.rankings)
          ..save_search_list(data.search_list)
          ..save_dislike_list(data.dislike_list)
          ..save_popular_searches(data.popular_searches)
          ..finish_language_refresh();
      }

      if (Get.isRegistered<ProjectConfigStore>()) {
        Get.find<ProjectConfigStore>().save_config(data.project_config);
      }

      logUtil(
        msg:
            'redis/get 数据全量分发完成: '
            '$request_language_code#$request_revision',
      );
      return true;
    } catch (error) {
      if (LanguageChangeHandler.is_current_revision(
        request_revision,
        request_language_code,
      )) {
        logUtil(msg: 'redis/get 接口系统异常: $error', type: 'e');
        _finish_language_loading();
        _schedule_retry();
      }
      return false;
    }
  }

  /// 结束基础配置刷新态。
  void _finish_language_loading() {
    if (Get.isRegistered<PreferenceStore>()) {
      Get.find<PreferenceStore>().finish_language_refresh();
    }
    if (Get.isRegistered<HomeBannerStore>()) {
      Get.find<HomeBannerStore>().finish_language_refresh();
    }
  }

  /// TODO: 设置子 Store 的加载状态
  void _set_loading(bool value) {
    if (Get.isRegistered<CustomerServiceStore>()) {
      Get.find<CustomerServiceStore>().loading.value = value;
    }
    if (Get.isRegistered<AuthorizedLoginStore>()) {
      Get.find<AuthorizedLoginStore>().is_fetching_list.value = value;
    }
  }

  /// 静默重试 redis/get 请求。
  ///
  /// 请求失败（业务失败或系统异常）时自动调用，
  /// 延迟 [_retry_delay_seconds] 秒后重新发起请求，
  /// 最多重试 [_max_retry_count] 次，超过后放弃。
  /// 重试期间不展示加载状态，不影响用户操作。
  void _schedule_retry() {
    if (_retry_count >= _max_retry_count) {
      logUtil(msg: 'redis/get 已达最大重试次数 $_max_retry_count，放弃重试', type: 'w');
      _retry_count = 0;
      return;
    }

    _retry_count++;
    logUtil(
      msg: 'redis/get 将在 $_retry_delay_seconds 秒后进行第 $_retry_count 次静默重试',
    );

    Future<void>.delayed(const Duration(seconds: _retry_delay_seconds), () {
      fetch_redis_data(showTips: false);
    });
  }

  /// TODO: 旋转数据分类分发
  void _distribute_rotation_data(List<Rotation> allRotations) {
    // 分发客服 (Type 21)
    final List<Rotation> serviceList = allRotations
        .where((e) => e.type == 21)
        .toList();
    if (Get.isRegistered<CustomerServiceStore>()) {
      Get.find<CustomerServiceStore>().save_customer_service_list(serviceList);
    }

    // 分发第三方授权 (Type 23)
    final List<Rotation> authList = allRotations
        .where((e) => e.type == 23)
        .toList();
    if (Get.isRegistered<AuthorizedLoginStore>()) {
      Get.find<AuthorizedLoginStore>().save_authorized_login_list(authList);
    }
    _handle_authorized_login_data(authList);

    // 分发分享渠道 (Type 24)
    final List<Rotation> shareList = allRotations
        .where((e) => e.type == ShareStore.share_type)
        .toList();
    if (Get.isRegistered<ShareStore>()) {
      Get.find<ShareStore>().save_share_list(shareList);
    }
  }

  void _handle_authorized_login_data(List<Rotation> authList) {
    if (authList.isEmpty) return;
    logUtil(msg: '收到第三方授权数据共 ${authList.length} 条');
  }
}
