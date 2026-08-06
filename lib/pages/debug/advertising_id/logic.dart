import 'package:app/util/log_util.dart';
import 'package:flutter/services.dart';

import '../utils/advertising_info_channel.dart';

/// 设备广告 ID 调试逻辑。
class AdvertisingIdLogic {
  /// 获取设备广告 ID，失败返回 null。
  Future<String?> getAdvertisingId() async {
    logUtil(msg: 'Debug: 开始获取设备广告 ID', type: 'i');
    try {
      final String? result = await AdvertisingInfoChannel.getAdvertisingId();
      logUtil(msg: 'Debug: 获取设备广告 ID 结果: ${result ?? "null"}', type: 'i');
      return result;
    } on PlatformException catch (e) {
      logUtil(msg: 'Debug: 获取设备广告 ID PlatformException: $e', type: 'e');
      logUtil(msg: 'Debug: PlatformException 详情 - code: ${e.code}, message: ${e.message}, details: ${e.details}', type: 'e');
      return null;
    } on MissingPluginException catch (e) {
      logUtil(msg: 'Debug: 广告 ID 原生通道未注册 MissingPluginException: $e', type: 'e');
      return null;
    } catch (e) {
      logUtil(msg: 'Debug: 获取设备广告 ID 未知异常: $e', type: 'e');
      return null;
    }
  }
}
