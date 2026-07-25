import 'package:flutter/material.dart';
import 'package:app/api/post_request.dart';
import 'package:app/models/recharge_add_create_result.dart';
import 'package:app/models/recharge_add_result.dart';
import 'package:app/models/transaction_inquire_type.dart';
import 'package:get/get.dart';
import 'package:app/stores/app_global_config.dart';

/// 充值页逻辑层。
///
/// 负责处理充值页相关的数据入口，包括：
/// 1. 读取全局缓存的充值方式和金额配置。
/// 2. 创建充值订单。
/// 3. 查询充值订单详情。
class Logic {
  /// 构造函数里保留 `BuildContext`，方便后续如果要接入局部弹窗、
  /// 页面级提示或依赖上下文的逻辑时，不需要再改调用链。
  final BuildContext context;

  /// 全局配置仓库。
  ///
  /// 充值方式和可选金额本质上属于全局配置数据，
  /// 先从这里拿可以减少重复接口请求。
  final AppGlobalConfigStore appGlobalConfigStore =
      Get.find<AppGlobalConfigStore>();

  Logic(this.context);

  // TODO 查询当前支持的充值类型和金额列表。
  //
  // 优先读取应用启动时已经缓存的全局配置，
  // 只有全局数据为空时才返回空对象给页面兜底处理。
  Future<TransactionInquireTypeResponse?> getRechargeInquireType() async {
    /// 如果全局配置还没准备好，先主动加载一次。
    if (!appGlobalConfigStore.configLoaded.value) {
      await appGlobalConfigStore.loadConfig();
    }

    /// 当前应用支持的支付类型列表。
    final List<TransactionInquireTypeItem> payTypeList =
        appGlobalConfigStore.payTypeList;

    /// 当前应用允许用户选择的充值金额列表。
    final List<double> payAmountList = appGlobalConfigStore.payAmountList;

    /// 任一列表为空都视为当前充值能力不可用，由页面层统一兜底跳转。
    if (payTypeList.isEmpty || payAmountList.isEmpty) {
      return null;
    }

    /// 组装成页面期望的数据结构返回。
    return TransactionInquireTypeResponse(
      dataList: payTypeList,
      amountList: payAmountList,
    );
  }

  // TODO 提交充值申请，当前只拿到订单 id。
  Future<RechargeAddCreateResult?> addRecharge({
    required int payTypeId,
    required double amount,
  }) async {
    /// 提交充值创建请求。
    final results = await postRequest<RechargeAddCreateResult>(
      path: 'recharge/add',
      parameter: {
        /// 支付方式 id 由用户在充值方式弹层中选中。
        'pay_type_id': payTypeId,

        /// 金额统一保留两位小数再提交，避免接口收到浮点精度噪音。
        'amount': amount.toStringAsFixed(2),
      },
      fromJson: (json) => RechargeAddCreateResult.fromJson(json),
    );

    /// 失败或没有内容时返回 null，让页面决定如何提示。
    if (!results.status || results.content == null) {
      return null;
    }

    /// 成功时只返回新订单的基础信息。
    return results.content;
  }

  // TODO 根据充值订单 id 获取二维码页展示所需的完整充值信息。
  Future<RechargeAddResult?> getRechargeInfo({required int id}) async {
    /// 根据订单 id 查询二维码页展示所需的完整充值信息。
    final results = await postRequest<RechargeAddResult>(
      path: 'recharge/get_info',
      parameter: {'id': id},
      fromJson: (json) => RechargeAddResult.fromJson(json),
    );

    /// 请求失败时返回 null，交给页面层处理空态或返回。
    if (!results.status || results.content == null) {
      return null;
    }

    /// 返回接口解析后的完整充值详情。
    return results.content;
  }
}
