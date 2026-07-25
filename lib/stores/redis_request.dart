import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app/api/post_request.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:app/models/redis_get_data.dart';
import 'package:app/models/rotation.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/stores/home_store.dart';
import 'package:app/stores/customer_service_store.dart';
import 'package:app/stores/authorized_login_store.dart';
import 'package:app/stores/preference_store.dart';
import 'package:app/stores/share_store.dart';

/// TODO: Redis 数据请求中心控制器
class RedisRequestStore extends GetxController {

  /// TODO: 防止重复请求
  final RxBool _is_fetching = false.obs;

  /// redis/get 接口是否正在请求中。
  bool get is_fetching => _is_fetching.value;

  /// 是否已经执行过至少一次 redis/get 请求（用于区分首次加载和语种切换刷新）。
  bool _has_fetched_once = false;

  /// 静默重试最大次数。
  static const int _max_retry_count = 3;

  /// 静默重试间隔（秒）。
  static const int _retry_delay_seconds = 5;

  /// 当前静默重试计数器。
  int _retry_count = 0;

  /// TODO: 全量拉取 Redis 配置并同步到各子 Store
  Future<void> fetch_redis_data({bool showTips = false}) async {
    if (_is_fetching.value) return;
    _is_fetching.value = true;

    logUtil(msg: '开始执行中心化 redis/get 接口请求');
    _set_loading(true);


    /// 通知偏好数据开始刷新（仅非首次加载时展示骨架屏）。
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
        /// 语种切换时清空短篇列表，避免展示旧语种内容。
        home_store.short_story_list.clear();
      }
      _has_fetched_once = true;
    }

    try {
      final results = await postRequest<RedisGetData>(
        path: 'redis/get',
        showTips: showTips,
        fromJson: (Map<String, dynamic> json) => RedisGetData.from_json(json),
      );

      if (results.status && results.content != null) {
        final RedisGetData data = results.content!;

        // 重试计数器归零（请求成功）。
        _retry_count = 0;

        // 1. 语种列表同步
        if (data.language_list.isNotEmpty) {
          if (Get.isRegistered<LanguageStore>()) {
            Get.find<LanguageStore>().save_language_list(data.language_list);
          }
        }

        // 2. 旋转列表数据分发 (Type 20, 21, 23)
        if (data.rotation_list.isNotEmpty) {
          _distribute_rotation_data(data.rotation_list);
        }

        // 3. 偏好列表同步
        if (data.preference_list.isNotEmpty) {
          if (Get.isRegistered<PreferenceStore>()) {
            Get.find<PreferenceStore>().save_preference_list(data.preference_list);
          }
        }

        // 4. 首页分类列表同步
        if (data.home_classification_list.isNotEmpty) {
          if (Get.isRegistered<HomeBannerStore>()) {
            Get.find<HomeBannerStore>().save_home_classification_list(
              data.home_classification_list,
            );
          }
        }

        // 5. 榜单分类列表同步
        if (data.rankings.isNotEmpty) {
          if (Get.isRegistered<HomeBannerStore>()) {
            Get.find<HomeBannerStore>().save_rankings_list(
              data.rankings,
            );
          }
        }

        // 6. 搜索栏关键词列表同步
        if (data.search_list.isNotEmpty) {
          if (Get.isRegistered<HomeBannerStore>()) {
            Get.find<HomeBannerStore>().save_search_list(
              data.search_list,
            );
          }
        }

        // 7. 不喜欢理由列表同步
        if (data.dislike_list.isNotEmpty) {
          if (Get.isRegistered<HomeBannerStore>()) {
            Get.find<HomeBannerStore>().save_dislike_list(
              data.dislike_list,
            );
          }
        }

        // 8. 热门搜索标签列表同步
        if (data.popular_searches.isNotEmpty) {
          if (Get.isRegistered<HomeBannerStore>()) {
            Get.find<HomeBannerStore>().save_popular_searches(
              data.popular_searches,
            );
          }
        }

        logUtil(msg: 'redis/get 数据全量分发完成');
      } else if (!results.status) {
        logUtil(msg: 'redis/get 接口业务失败: ${results.message}', type: 'w');
        _schedule_retry();
      }
    } catch (error) {
      logUtil(msg: 'redis/get 接口系统异常: $error', type: 'e');
      _schedule_retry();
    } finally {
      _is_fetching.value = false;
      _set_loading(false);
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
    logUtil(msg: 'redis/get 将在 $_retry_delay_seconds 秒后进行第 $_retry_count 次静默重试');

    Future<void>.delayed(const Duration(seconds: _retry_delay_seconds), () {
      fetch_redis_data(showTips: false);
    });
  }

  /// TODO: 执行语种切换并刷新数据
  Future<void> update_language_and_fetch(BuildContext context, String languageCode) async {
    logUtil(msg: '触发语种切换流程: $languageCode');
    await StorageUtil.saveData(LanguageStore.language_key, languageCode);
    if (context.mounted) {
      await context.setLocale(Locale(languageCode));
    }
    await fetch_redis_data(showTips: false);
  }

  /// TODO: 旋转数据分类分发
  void _distribute_rotation_data(List<Rotation> allRotations) {

    // 分发客服 (Type 21)
    final List<Rotation> serviceList = allRotations.where((e) => e.type == 21).toList();
    if (Get.isRegistered<CustomerServiceStore>()) {
      Get.find<CustomerServiceStore>().save_customer_service_list(serviceList);
    }

    // 分发第三方授权 (Type 23)
    final List<Rotation> authList = allRotations.where((e) => e.type == 23).toList();
    if (Get.isRegistered<AuthorizedLoginStore>()) {
      Get.find<AuthorizedLoginStore>().save_authorized_login_list(authList);
    }
    _handle_authorized_login_data(authList);

    // 分发分享渠道 (Type 24)
    final List<Rotation> shareList = allRotations.where((e) => e.type == ShareStore.share_type).toList();
    if (Get.isRegistered<ShareStore>()) {
      Get.find<ShareStore>().save_share_list(shareList);
    }
  }

  void _handle_authorized_login_data(List<Rotation> authList) {
    if (authList.isEmpty) return;
    logUtil(msg: '收到第三方授权数据共 ${authList.length} 条');
  }
}
