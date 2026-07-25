import 'package:get/get.dart';
import 'package:app/api/post_request.dart';
import 'package:app/models/app_global_config.dart';
import 'package:app/models/transaction_inquire_type.dart';

/* TODO
 * 全局配置状态控制器。
 *
 * 统一缓存应用启动时的 `redis/get` 结果，避免充值、提现等页面重复请求。
 */
class AppGlobalConfigStore extends GetxController {
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
    if (loading.value) return configLoaded.value;

    loading.value = true;
    try {
      final results = await postRequest<AppGlobalConfig>(
        path: 'redis/get',
        showTips: showTips,
        fromJson: (Map<String, dynamic> json) => AppGlobalConfig.fromJson(json),
      );

      if (!results.status || results.content == null) {
        configLoaded.value = true;
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
}
