import 'package:app/util/log_util.dart';
import 'package:flutter/services.dart';

import '../utils/advertising_info_channel.dart';

/// 限制广告跟踪状态调试逻辑。
class LimitAdTrackingLogic {
  /// 查询用户是否启用限制广告跟踪。
  Future<bool?> isEnabled() async {
    try {
      return await AdvertisingInfoChannel.isLimitAdTrackingEnabled;
    } on PlatformException catch (e) {
      logUtil(msg: 'Debug: 获取限制广告跟踪状态失败: $e', type: 'e');
      return null;
    } on MissingPluginException catch (e) {
      logUtil(msg: 'Debug: 限制广告跟踪原生通道未注册: $e', type: 'e');
      return null;
    }
  }
}
