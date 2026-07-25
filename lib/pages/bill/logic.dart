import 'package:app/api/post_request.dart';
import 'package:app/models/user_bill.dart';

/// 账单页逻辑层。
///
/// 这里专门负责和账单接口交互，
/// 让页面文件只处理状态和界面，不直接关心接口细节。
class Logic {
  Logic();

  /// 获取账单列表。
  ///
  /// [noIds] 用来告诉后端“这些记录前端已经拿到了，不要重复返回”。
  /// [pageSize] 用来限制单次返回条数，避免一次性拉太多数据。
  ///
  /// [requestOk] 为 false 表示请求失败（与「成功但无数据」的空列表区分），
  /// 供下拉刷新决定是否提示「刷新成功」、以及失败时不覆盖当前列表。
  Future<({List<UserBillItem> items, bool requestOk})> getBillList({
    List<int> noIds = const [],
    int pageSize = 20,
  }) async {
    /// 通过统一请求入口调用账单接口。
    final results = await postRequest<UserBillListResponse>(
      /// 账单列表接口路径。
      path: 'user_bill/get',

      /// 账单页加载时不额外弹全局错误提示，避免分页时频繁打断阅读。
      showTips: false,

      /// 把分页相关参数交给后端。
      parameter: {'no_ids': noIds, 'page_size': pageSize},

      /// 指定列表响应模型的反序列化方式。
      fromJsonList: (json) => UserBillListResponse.fromJsonList(json),
    );

    /// 接口失败：不冒充成功空列表，避免误提示刷新成功、误清空展示。
    if (!results.status || results.content == null) {
      return (items: <UserBillItem>[], requestOk: false);
    }

    /// 成功：返回列表（可能为空，表示当前确实没有账单）。
    return (items: results.content!.list, requestOk: true);
  }
}
