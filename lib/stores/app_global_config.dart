import 'package:get/get.dart';
import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/models/app_global_config.dart';
import 'package:app/models/transaction_inquire_type.dart';

/* TODO
 * 全局配置状态控制器。
 *
 * 统一缓存应用启动时的 `redis/get` 结果，避免充值、提现等页面重复请求。
 */
class AppGlobalConfigStore extends GetxController {
  AppGlobalConfigStore({
    Future<ResultsType<AppGlobalConfig>> Function(bool show_tips)?
    config_loader,
  }) : _config_loader = config_loader ?? _request_config;

  /// 网络入口，允许回归测试控制成功、失败和请求完成顺序。
  final Future<ResultsType<AppGlobalConfig>> Function(bool show_tips)
  _config_loader;

  /// 所有调用方共同等待本次配置加载，不能把尚未完成当成请求失败。
  Future<bool>? _config_request;

  final Rx<AppGlobalConfig> config = AppGlobalConfig.empty().obs;
  final RxBool loading = false.obs;
  final RxBool configLoaded = false.obs;

  /// TODO 读取当前充值/提现类型列表。
  List<TransactionInquireTypeItem> get payTypeList => config.value.payTypeList;

  /// TODO 读取当前充值金额列表。
  List<double> get payAmountList => config.value.payAmountList;

  /// TODO 读取业务配置。
  BusinessConfig get businessConfig => config.value.businessConfig;

  /// TODO 启动时或业务需要时刷新一次全局配置。
  ///
  /// 参数 [showTips]：
  /// 是否在失败时显示错误提示。
  Future<bool> loadConfig({bool showTips = false}) async {
    final Future<bool>? active_request = _config_request;
    if (active_request != null) return active_request;

    final Future<bool> request = _load_config_once(show_tips: showTips);
    _config_request = request;
    try {
      return await request;
    } finally {
      if (identical(_config_request, request)) {
        _config_request = null;
      }
    }
  }

  /// 单次加载失败保留原配置和加载标记，首次断网后仍能重新请求。
  Future<bool> _load_config_once({required bool show_tips}) async {
    loading.value = true;
    try {
      final results = await _config_loader(show_tips);

      if (!results.status || results.content == null) {
        return false;
      }

      saveConfig(results.content!);
      configLoaded.value = true;
      return true;
    } finally {
      loading.value = false;
    }
  }

  /// TODO 把接口结果保存到全局状态。
  ///
  /// 参数 [data]：
  /// 已经解析完成的全局配置对象。
  void saveConfig(AppGlobalConfig data) {
    config.value = data;
  }

  /// 统一解析 redis/get 返回的支付业务配置。
  static Future<ResultsType<AppGlobalConfig>> _request_config(bool show_tips) {
    return postRequest<AppGlobalConfig>(
      path: 'redis/get',
      showTips: show_tips,
      fromJson: (Map<String, dynamic> json) => AppGlobalConfig.fromJson(json),
    );
  }
}
