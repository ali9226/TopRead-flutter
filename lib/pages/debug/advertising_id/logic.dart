import 'package:app/util/log_util.dart';
import 'package:flutter/services.dart';

import '../utils/advertising_info_channel.dart';

/// 设备广告 ID 调试逻辑。
class AdvertisingIdLogic {
  /// 获取设备广告 ID，失败返回 null。
  Future<String?> getAdvertisingId() async {
    try {
      return await AdvertisingInfoChannel.getAdvertisingId();
    } on PlatformException catch (e) {
      logUtil(msg: 'Debug: 获取设备广告 ID 失败: $e', type: 'e');
      return null;
    } on MissingPluginException catch (e) {
      logUtil(msg: 'Debug: 广告 ID 原生通道未注册: $e', type: 'e');
      return null;
    }
  }
}
