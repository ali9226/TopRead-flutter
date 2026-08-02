import 'package:package_info_plus/package_info_plus.dart';

/*
  TODO 常量
 */
class Constant {

  static const String app_name = "TopRead"; // TODO App的名称

  /// TODO 应用版本号（从 pubspec.yaml 动态读取）。
  static String _appVersion = "";

  /// TODO 获取应用版本号。
  /// 首次调用会从 pubspec.yaml 读取，之后返回缓存值。
  static Future<String> getAppVersion() async {
    if (_appVersion.isEmpty) {
      try {
        final PackageInfo packageInfo = await PackageInfo.fromPlatform();
        _appVersion = packageInfo.version;
      } catch (e) {
        _appVersion = "1.0.0"; // fallback
      }
    }
    return _appVersion;
  }

  /// TODO 同步获取版本号（需要先调用 getAppVersion 初始化）。
  static String get appVersion => _appVersion.isNotEmpty ? _appVersion : "1.0.0";

  /// TODO 保存在本地的密码的key
  static const String passwordKey = "password_key";

  /// TODO 保存在本地的token的key
  static const String tokenKey = "token_key";



  /// TODO 请求加密的key
  static const String encryptionKey = "encryption_key";

  // TODO 后端返回给前端的数据需要解密用到的key
  static const String decryptionKey = "dencryption_key";

  // TODO 网络请求的域名。
  // TODO 浏览器 Debug 模式走当前页面同源地址，让本地代理处理 `/api/` 转发，避免跨域。
  // TODO 其他场景继续走正式域名，保持现有发布行为不变。
  static String get requestUrl {
    // if (kIsWeb) {
    //   if (kDebugMode) {
    //     return "http://localhost:5006";
    //   }
    //   return "https://web.caution.icu";
    // }
    // return "https://www.read.top";
    return "http://192.168.31.120:5006";
  }

  // TODO 网络请求的前缀
  static const String prefix = "/api/";

  /// 为 `true` 时 [postRequest] 在 Debug 下打印成功响应的 `content` 预览；`false` 关闭（默认）。
  static const bool enableHttpRequestVerboseLog = false;

  /// 为 `true` 时 [GameWebsocketService] 打印每条解密后的 WS 业务包；`false` 关闭（默认）。
  static const bool enableGameWebsocketVerboseLog = false;
}
