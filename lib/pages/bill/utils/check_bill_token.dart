import 'package:app/config/constant.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/util/storage_util/index.dart';

/// 检查账单页访问令牌是否存在。
///
/// 这里单独抽成工具函数，而不是把逻辑直接写死在页面里，
/// 是为了让账单页后续的“首次进入校验”和“每次请求前兜底校验”
/// 都共用同一套处理逻辑，避免两处代码行为不一致。
Future<bool> checkBillToken() async {
  final String? oldToken = await StorageUtil.getData(Constant.tokenKey);

  if (oldToken == null || oldToken.isEmpty) {
    logUtil(msg: '账单页访问失败：本地 token 不存在，准备跳转登录页');
    routerUtil(path: '/login', type: 'replace');
    return false;
  }

  return true;
}
