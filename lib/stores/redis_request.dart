import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart' as dio_lib;
import 'package:get/get.dart';

import 'package:app/api/dio_client.dart';
import 'package:app/config/constant.dart';
import 'package:app/models/redis_get_data.dart';
import 'package:app/models/rotation.dart';
import 'package:app/stores/authorized_login_store.dart';
import 'package:app/stores/customer_service_store.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/home_store.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/stores/preference_store.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/stores/share_store.dart';
import 'package:app/util/device/app_environment.dart';
import 'package:app/util/encryption/get_encryption.dart';
import 'package:app/util/encryption/set_encryption.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/language_util/language_change_handler.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/storage_util/index.dart';

/// Redis 数据请求中心控制器。
///
/// 负责 `redis/get` 接口的请求、重试、缓存和分发。
/// 支持断网后自动重试、本地缓存兜底、网络恢复后静默刷新。
class RedisRequestStore extends GetxController {
  /// 请求进行中标记，防止并发重复请求。
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

  /// 静默重试间隔（秒）。
  static const int _retry_delay_seconds = 5;

  /// 当前是否已安排重试定时器（防止重复安排）。
  bool _has_retry_scheduled = false;

  /// 网络状态变更监听器。
  Worker? _network_worker;

  /// 上一次网络状态（用于检测从断网到联网的变化）。
  int _last_network_status = 0;

  /// redis/get 缓存键。
  static const String _cache_key = 'redis_get_cache';

  /// 是否已从缓存恢复过数据（避免重复恢复）。
  bool _has_restored_from_cache = false;

  @override
  void onInit() {
    super.onInit();
    // 监听网络状态变化，断网恢复时自动静默重试。
    _network_worker = ever(
      Get.find<DeviceInfo>().networkStatus,
      _on_network_status_changed,
    );
  }

  @override
  void onClose() {
    _network_worker?.dispose();
    super.onClose();
  }

  /// 网络状态变更回调。
  ///
  /// 从断网（0）恢复到有网络（>0）时，静默发起一次 redis/get 请求。
  void _on_network_status_changed(int new_status) {
    final bool was_offline = _last_network_status == 0;
    _last_network_status = new_status;
    if (was_offline && new_status > 0) {
      logUtil(msg: '网络恢复，静默重试 redis/get');
      fetch_redis_data(showTips: false);
    }
  }

  /// 从本地缓存恢复 redis/get 数据并分发到各子 Store。
  ///
  /// 应用启动时调用，优先展示缓存数据，
  /// 后续网络请求成功后会静默覆盖缓存。
  Future<void> restore_from_cache() async {
    if (_has_restored_from_cache) return;
    _has_restored_from_cache = true;

    try {
      final String? cached_json_str = await StorageUtil.getData(_cache_key);
      if (cached_json_str == null || cached_json_str.isEmpty) return;

      final dynamic decoded = jsonDecode(cached_json_str);
      if (decoded is! Map) return;

      final Map<String, dynamic> json_map =
          Map<String, dynamic>.from(decoded);
      _distribute_data(json_map, is_cache: true);
      logUtil(msg: 'redis/get 已从本地缓存恢复数据');
    } catch (e) {
      logUtil(msg: 'redis/get 缓存恢复失败: $e', type: 'w');
    }
  }

  /// 全量拉取 Redis 配置并同步到各子 Store。
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
  ///
  /// 使用 Dio 直接发起请求（复用加密/解密逻辑），
  /// 成功后缓存原始 JSON 到本地，并分发数据到各子 Store。
  Future<bool> _fetch_once({required bool show_tips}) async {
    final int request_revision = LanguageChangeHandler.current_revision;
    final String request_language_code =
        LanguageChangeHandler.current_language_code;

    try {
      final Map<String, dynamic>? raw_json = await _request_raw_json();

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

      if (raw_json == null) {
        logUtil(msg: 'redis/get 接口请求失败', type: 'w');
        _finish_language_loading();
        _schedule_retry();
        return false;
      }

      // 成功获取数据后清除重试标记。
      _has_retry_scheduled = false;

      // 缓存原始 JSON 到本地。
      _save_to_cache(raw_json);

      // 分发数据到各子 Store。
      _distribute_data(raw_json);

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

  /// 发起 redis/get 的原始 HTTP 请求，返回解密后的 JSON Map。
  ///
  /// 复用项目统一的 Dio 实例、加密和解密逻辑，
  /// 但不经过 `postRequest`，以便拿到原始 JSON 用于缓存。
  /// 请求失败时返回 null。
  Future<Map<String, dynamic>?> _request_raw_json() async {
    try {
      final dio_lib.Dio dio = DioClient().instance;
      final String language = await LanguageUtil.get_language();
      final int languageId = await LanguageUtil.get_language_id();
      final String locale = LanguageUtil.resolve_locale_code_by_language(
        language,
      );
      final String? token = await StorageUtil.getData(Constant.tokenKey);
      final String authorization = token != null ? 'Bearer $token' : '';
      final int timezone = DateTime.now().timeZoneOffset.inHours;
      final String requestTime = _buildUtcRequestTime(DateTime.now().toUtc());

      final Map<String, dynamic> requestData = <String, dynamic>{
        'language_id': languageId,
        'device_environment': currentEnvironment.value,
        'timezone': '$timezone',
        'request_time': requestTime,
      };

      final Map<String, String> encryptedRequestData = encryptData(
        requestData,
        encryptionKey: Constant.encryptionKey,
      );

      // 加密失败时返回空 Map，此时不应发起请求。
      if (encryptedRequestData.isEmpty) {
        logUtil(msg: 'redis/get 请求数据加密失败', type: 'e');
        return null;
      }

      final Map<String, dynamic> requestHeaders = <String, dynamic>{
        'timezone': '$timezone',
        'environment': currentEnvironment.value,
        'request_time': requestTime,
        'language_id': languageId,
        'Content-Type': 'application/json;charset=UTF-8',
        'Accept-Language': locale,
        'locale': locale,
      };
      if (authorization.isNotEmpty) {
        requestHeaders['Authorization'] = authorization;
      }

      final dio_lib.Response<dynamic> response = await dio.post(
        '${Constant.prefix}redis/get',
        data: encryptedRequestData,
        options: dio_lib.Options(headers: requestHeaders),
      );

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        return null;
      }

      if (response.data is! Map) {
        return null;
      }

      final Map<String, dynamic> dataMap =
          Map<String, dynamic>.from(response.data as Map);
      if (!dataMap.containsKey('encryption')) {
        return null;
      }

      final dynamic responseData = decryptEncryption(
        dataMap['encryption'] as String,
        encryptionKey: Constant.decryptionKey,
      );

      if (responseData is! Map<String, dynamic>) {
        return null;
      }

      final Map<String, dynamic> data = responseData;
      final bool status = data['status'] == true ||
          data['status'] == 1 ||
          data['status'] == '1';

      if (!status || !data.containsKey('content') || data['content'] == null) {
        return null;
      }

      final dynamic contentData = data['content'];
      if (contentData is Map) {
        return Map<String, dynamic>.from(contentData);
      }

      return null;
    } on dio_lib.DioException catch (e) {
      logUtil(
        msg:
            'redis/get 原始请求 Dio 异常: '
            'type=${e.type}, message=${e.message}',
        type: 'e',
      );
      return null;
    } catch (e) {
      logUtil(msg: 'redis/get 原始请求异常: $e', type: 'e');
      return null;
    }
  }

  /// 将原始 JSON 分发到各子 Store。
  ///
  /// [is_cache] 为 true 时标记为缓存恢复，不触发加载态变更。
  void _distribute_data(
    Map<String, dynamic> raw_json, {
    bool is_cache = false,
  }) {
    final RedisGetData data = RedisGetData.from_json(raw_json);

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

    if (is_cache) {
      _set_loading(false);
    }
  }

  /// 将原始 JSON 缓存到本地存储。
  ///
  /// 使用 jsonEncode 序列化后写入 GetStorage，
  /// 下次冷启动时可通过 [restore_from_cache] 恢复。
  Future<void> _save_to_cache(Map<String, dynamic> raw_json) async {
    try {
      final String json_str = jsonEncode(raw_json);
      await StorageUtil.saveData(_cache_key, json_str);
      logUtil(msg: 'redis/get 缓存写入成功，大小=${json_str.length} 字节');
    } catch (e) {
      logUtil(msg: 'redis/get 缓存写入失败: $e', type: 'w');
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

  /// 设置子 Store 的加载状态。
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
  /// 请求失败时自动调用，延迟 [_retry_delay_seconds] 秒后重新发起请求，
  /// 不设上限，直到请求成功或应用退出。
  /// 重试期间不展示加载状态，不影响用户操作。
  void _schedule_retry() {
    if (_has_retry_scheduled) return;
    _has_retry_scheduled = true;

    logUtil(
      msg: 'redis/get 将在 $_retry_delay_seconds 秒后静默重试',
    );

    Future<void>.delayed(const Duration(seconds: _retry_delay_seconds), () {
      _has_retry_scheduled = false;
      fetch_redis_data(showTips: false);
    });
  }

  /// 旋转数据分类分发。
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

  /// 处理第三方授权登录数据。
  ///
  /// 当前仅记录日志，后续可扩展为具体处理逻辑。
  void _handle_authorized_login_data(List<Rotation> authList) {
    if (authList.isEmpty) return;
    logUtil(msg: '收到第三方授权数据共 ${authList.length} 条');
  }

  /// 生成 UTC 请求时间字符串。
  static String _buildUtcRequestTime(DateTime utcTime) {
    final String year = utcTime.year.toString().padLeft(4, '0');
    final String month = utcTime.month.toString().padLeft(2, '0');
    final String day = utcTime.day.toString().padLeft(2, '0');
    final String hour = utcTime.hour.toString().padLeft(2, '0');
    final String minute = utcTime.minute.toString().padLeft(2, '0');
    final String second = utcTime.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }
}
