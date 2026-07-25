import 'dart:convert';
import 'dart:ui';

import 'package:app/api/results_type.dart';
import 'package:app/config/constant.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/encryption/get_encryption.dart';
import 'package:app/util/log_util.dart';

/* TODO
 * 解密后端返回的加密数据。
 *
 * [showTips] 解密失败时是否展示提示。
 * [encryption] 服务端返回的加密字符串。
 * [fromJson] 业务模型解析函数。
 */
ResultsType<T> decryptData<T>({
  bool showTips = true,
  required String encryption,
  T Function(Map<String, dynamic> json)? fromJson,
}) {
  final ResultsType<T> results = ResultsType<T>();

  late final Map<String, dynamic> dataMap;
  try {
    dataMap = jsonDecode(encryption) as Map<String, dynamic>;
  } catch (error) {
    results.message = _decryptMessage(_DecryptMessageKey.invalidJson);
    logUtil(msg: 'TODO JSON 解析失败: $error', type: 'e');
    if (showTips) {
      showBottomTip(results.message);
    }
    return results;
  }

  if (!dataMap.containsKey('encryption')) {
    results.message = _decryptMessage(_DecryptMessageKey.error02);
    logUtil(msg: 'TODO 返回数据缺少 encryption 字段', type: 'e');
    if (showTips) {
      showBottomTip(results.message);
    }
    return results;
  }

  final dynamic responseData = decryptEncryption(
    dataMap['encryption'],
    encryptionKey: Constant.decryptionKey,
  );

  results.status = true;
  results.message = '';
  results.count = 0;

  outputLog(text: jsonEncode(responseData));
  if (responseData is Map<String, dynamic> && fromJson != null) {
    try {
      results.content = fromJson(responseData);
    } catch (error) {
      logUtil(msg: 'TODO fromJson 转换失败: $error', type: 'e');
      results.content = null;
      results.status = false;
      results.message = _decryptMessage(_DecryptMessageKey.error02);
    }
  }

  return results;
}

enum _DecryptMessageKey { invalidJson, error02 }

String _decryptMessage(_DecryptMessageKey key) {
  final bool isZh = PlatformDispatcher.instance.locale.languageCode == 'zh';
  switch (key) {
    case _DecryptMessageKey.invalidJson:
      return isZh
          ? '数据解析失败，请稍后重试'
          : 'Failed to parse data. Please try again later';
    case _DecryptMessageKey.error02:
      return isZh
          ? '网络请求错误,请联系管理员'
          : 'Network request error, please contact the administrator';
  }
}
