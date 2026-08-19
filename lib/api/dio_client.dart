import 'package:dio/dio.dart';
import 'package:app/config/constant.dart';

/// 全局 Dio 单例。
///
/// 复用同一个 Dio 实例的连接池（HttpClient），
/// 避免每次请求 new Dio 造成 TCP 握手重复、无统一超时配置。
class DioClient {
  /// 私有构造，保证单例。
  DioClient._();

  /// 单例。
  static final DioClient _instance = DioClient._();
  factory DioClient() => _instance;

  /// 连接超时（毫秒）。
  static const int _connectTimeoutMs = 12000;

  /// 发送超时（毫秒）。
  static const int _sendTimeoutMs = 12000;

  /// 接收超时（毫秒）。
  static const int _receiveTimeoutMs = 15000;

  /// 全局唯一 Dio 实例（baseUrl 为默认域名）。
  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Constant.requestUrl,
      validateStatus: (int? status) => status != null,
      connectTimeout: const Duration(milliseconds: _connectTimeoutMs),
      sendTimeout: const Duration(milliseconds: _sendTimeoutMs),
      receiveTimeout: const Duration(milliseconds: _receiveTimeoutMs),
    ),
  );

  /// 获取全局 Dio 实例。
  Dio get instance => _dio;

  /// 创建指定域名的 Dio（复用全局超时配置）。
  ///
  /// [baseUrl] - 自定义请求域名，用于 Telegram 登录等特殊域名场景。
  Dio create({String? baseUrl}) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl ?? Constant.requestUrl,
        validateStatus: (int? status) => status != null,
        connectTimeout: const Duration(milliseconds: _connectTimeoutMs),
        sendTimeout: const Duration(milliseconds: _sendTimeoutMs),
        receiveTimeout: const Duration(milliseconds: _receiveTimeoutMs),
      ),
    );
  }
}
