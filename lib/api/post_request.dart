// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:app/api/dio_client.dart';
import 'package:app/api/results_type.dart';
import 'package:app/config/constant.dart';
import 'package:app/util/device/app_environment.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/encryption/get_encryption.dart';
import 'package:app/util/encryption/set_encryption.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/storage_util/index.dart';

/* TODO
 * 封装项目统一的 POST 请求。
 *
 * [prefix] 请求路径前缀。
 * [baseUrl] 自定义域名，不传时使用全局配置。
 * [showTips] 是否在失败时自动展示提示。
 * [path] 接口路径。
 * [parameter] 原始业务参数。
 * [fromJson] content 为对象时的解析函数。
 * [fromJsonList] content 为数组时的解析函数。
 */
Future<ResultsType<T>> postRequest<T>({
  String prefix = Constant.prefix,
  String? baseUrl,
  bool showTips = true,
  required String path,
  Map<String, dynamic>? parameter,
  T Function(Map<String, dynamic> json)? fromJson,
  T Function(List<dynamic> json)? fromJsonList,
}) async {
  final ResultsType<T> results = ResultsType<T>();
  String message = _resolvePostRequestMessage(
    locale: LanguageUtil.get_fallback_language_code(),
    key: _PostRequestMessageKey.defaultError,
  );

  try {
    /// 复用全局 Dio 单例连接池；特殊域名（如 Telegram 登录）单独创建。
    final Dio dio = (baseUrl == null)
        ? DioClient().instance
        : DioClient().create(baseUrl: baseUrl);
    final String language = await LanguageUtil.get_language();
    final int languageId = await LanguageUtil.get_language_id();
    final String locale = LanguageUtil.resolve_locale_code_by_language(
      language,
    );
    message = _resolvePostRequestMessage(
      locale: language,
      key: _PostRequestMessageKey.defaultError,
    );
    final String? token = await StorageUtil.getData(Constant.tokenKey);
    final String authorization = token != null ? 'Bearer $token' : '';
    final int timezone = DateTime.now().timeZoneOffset.inHours;
    final String requestTime = _buildUtcRequestTime(DateTime.now().toUtc());

    final Map<String, dynamic> requestData = <String, dynamic>{
      ...?parameter,
      'language_id': languageId, // TODO 语种id
      'device_environment': currentEnvironment.value, // TODO 设备环境
      'timezone': '$timezone', // TODO 时区
      'request_time': requestTime, // TODO 请求时间
    };

    final Map<String, String> encryptedRequestData = encryptData(
      requestData,
      encryptionKey: Constant.encryptionKey,
    );

    final Map<String, dynamic> requestHeaders = _buildRequestHeaders(
      timezone: timezone,
      requestTime: requestTime,
      locale: locale,
      authorization: authorization,
      languageId: languageId,
    );

    final Response<dynamic> response = await dio.post(
      '$prefix$path',
      data: encryptedRequestData,
      options: Options(headers: requestHeaders),
    );

    if (response.statusCode == null ||
        response.statusCode! < 200 ||
        response.statusCode! >= 300) {
      results.message = message;
      logUtil(
        msg:
            'TODO postRequest 非 2xx 响应: path=$path, statusCode=${response.statusCode}',
        type: 'w',
      );
      if (showTips) {
        showBottomTip(message);
      }
      return results;
    }

    if (response.data is! Map<String, dynamic>) {
      results.message = message;
      if (showTips) {
        showBottomTip(message);
      }
      return results;
    }

    final Map<String, dynamic> dataMap = response.data as Map<String, dynamic>;
    if (!dataMap.containsKey('encryption')) {
      message = _resolvePostRequestMessage(
        locale: locale,
        key: _PostRequestMessageKey.error02,
      );
      results.message = message;
      logUtil(msg: 'TODO 返回数据缺少 encryption 字段', type: 'e');
      if (showTips) {
        showBottomTip(message);
      }
      return results;
    }

    final dynamic responseData = decryptEncryption(
      dataMap['encryption'] as String,
      encryptionKey: Constant.decryptionKey,
    );

    if (responseData is! Map<String, dynamic>) {
      results.message = message;
      if (showTips) {
        showBottomTip(message);
      }
      return results;
    }

    final Map<String, dynamic> data = responseData;
    results.status = _parse_post_request_bool(data['status']);
    results.message = data['message']?.toString() ?? '';
    results.count = _parse_post_request_int(data['count']);

    if (!results.status) {
      if (showTips) {
        showBottomTip(results.message);
      }
      return results;
    }

    if (!data.containsKey('content') || data['content'] == null) {
      if (showTips && results.message.isNotEmpty) {
        showBottomTip(results.message);
      }
      return results;
    }

    final dynamic contentData = data['content'];

    if (kDebugMode && Constant.enableHttpRequestVerboseLog) {
      logUtil(msg: 'TODO 请求接口:$path, content 数据预览');
      debugPrint(contentData.toString(), wrapWidth: 1024);
    }

    // TODO 解密后的 content 有时是 Map<dynamic, dynamic>，严格 is Map<String, dynamic> 会解析失败。
    if (fromJson != null && contentData is Map) {
      try {
        results.content = fromJson(Map<String, dynamic>.from(contentData));
      } catch (error) {
        logUtil(msg: 'TODO fromJson 转换失败: $error', type: 'e');
        results.content = null;
        results.status = false;
        results.message = _resolvePostRequestMessage(
          locale: locale,
          key: _PostRequestMessageKey.error02,
        );
      }
    } else if (fromJsonList != null && contentData is List<dynamic>) {
      try {
        results.content = fromJsonList(contentData);
      } catch (error) {
        logUtil(msg: 'TODO fromJsonList 转换失败: $error', type: 'e');
        results.content = null;
        results.status = false;
        results.message = _resolvePostRequestMessage(
          locale: locale,
          key: _PostRequestMessageKey.error02,
        );
      }
    } else {
      results.content = null;
    }

    if (!results.status) {
      if (results.message.isEmpty) {
        results.message = _resolvePostRequestMessage(
          locale: locale,
          key: _PostRequestMessageKey.error02,
        );
      }
      if (showTips) {
        showBottomTip(results.message);
      }
    }

    return results;
  } on DioException catch (error) {
    logUtil(
      msg:
          'postRequest Dio 异常: 请求地址:$baseUrl, 请求路径=$path, 错误类型=${error.type}, 错误消息=${error.message}',
      type: 'e',
    );
    results.message = message;
    if (showTips) {
      showBottomTip(message);
    }
    return results;
  } catch (error) {
    logUtil(msg: 'TODO postRequest 捕获异常: path=$path, error=$error', type: 'e');
    results.message = message;
    if (showTips) {
      showBottomTip(message);
    }
    return results;
  }
}

/// 兼容接口把 bool 字段以数字或字符串返回的情况。
bool _parse_post_request_bool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }

  final String normalized_value = value?.toString().trim().toLowerCase() ?? '';
  if (normalized_value == 'true' || normalized_value == '1') {
    return true;
  }
  if (normalized_value == 'false' || normalized_value == '0') {
    return false;
  }
  return false;
}

/// 兼容接口把整数字段以字符串返回的情况。
int _parse_post_request_int(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

enum _PostRequestMessageKey { defaultError, error02 }

/* TODO
 * 生成请求所需的 UTC 时间字符串。
 *
 * 这里不用 `intl.DateFormat`，原因是应用启动早期可能尚未完成 locale 数据初始化，
 * 如果此时立刻发起网络请求，会抛出 `LocaleDataException`。
 */
String _buildUtcRequestTime(DateTime utcTime) {
  final String year = utcTime.year.toString().padLeft(4, '0');
  final String month = utcTime.month.toString().padLeft(2, '0');
  final String day = utcTime.day.toString().padLeft(2, '0');
  final String hour = utcTime.hour.toString().padLeft(2, '0');
  final String minute = utcTime.minute.toString().padLeft(2, '0');
  final String second = utcTime.second.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute:$second';
}

String _resolvePostRequestMessage({
  required String locale,
  required _PostRequestMessageKey key,
}) {
  final bool isZh = locale.toLowerCase().startsWith('zh');
  switch (key) {
    case _PostRequestMessageKey.defaultError:
      return isZh
          ? '网络异常，请检查网络后再次重试'
          : 'The network is abnormal. Please check the network and try again';
    case _PostRequestMessageKey.error02:
      return isZh
          ? '网络请求错误,请联系管理员'
          : 'Network request error, please contact the administrator';
  }
}

/* TODO 构建请求头。 */
Map<String, dynamic> _buildRequestHeaders({
  required int timezone,
  required String requestTime,
  required String locale,
  required String authorization,
  required int languageId,
}) {
  try {
    String host = '';
    bool isLocalWeb = false;

    if (kIsWeb) {
      host = Uri.base.host;
      if (host == 'localhost' ||
          host == '127.0.0.1' ||
          host == '0.0.0.0' ||
          host.startsWith('192.168.')) {
        isLocalWeb = true;
      }
    }

    if (isLocalWeb) {
      final Map<String, dynamic> requestHeaders = <String, dynamic>{
        'Content-Type': 'application/json;charset=UTF-8',
        'language_id': languageId,
      };
      if (authorization.isNotEmpty) {
        requestHeaders['Authorization'] = authorization;
      }
      return requestHeaders;
    }
  } catch (error) {
    logUtil(msg: 'TODO 构建请求头时读取 host 失败: $error', type: 'w');
  }

  final Map<String, dynamic> requestHeaders = <String, dynamic>{
    'timezone': '$timezone',
    'environment': currentEnvironment.value,
    'request_time': requestTime,
    'language_id': languageId,
    'Content-Type': 'application/json;charset=UTF-8',
    'Accept-Language': locale,
    'locale': locale,
  };
  if (authorization.isNotEmpty) {
    requestHeaders['Authorization'] = authorization;
  }
  return requestHeaders;
}
