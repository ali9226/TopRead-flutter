import 'package:package_info_plus/package_info_plus.dart';

/// 全局常量配置。
///
/// 集中管理 App 名称、版本号、本地存储 key、网络请求域名等全局常量。
class Constant {

  /// App 的显示名称。
  static const String app_name = "TopRead";

  /// 应用版本号（从 pubspec.yaml 动态读取，缓存后直接返回）。
  static String _appVersion = "";

  /// 获取应用版本号。
  ///
  /// 首次调用会从 pubspec.yaml 读取，之后返回缓存值。
  static Future<String> getAppVersion() async {
    if (_appVersion.isEmpty) {
      try {
        final PackageInfo packageInfo = await PackageInfo.fromPlatform();
        _appVersion = packageInfo.version;
      } catch (e) {
        _appVersion = "1.0.0";
      }
    }
    return _appVersion;
  }

  /// 同步获取版本号（需要先调用 [getAppVersion] 初始化）。
  static String get appVersion => _appVersion.isNotEmpty ? _appVersion : "1.0.0";

  /// 保存在本地的密码的 key。
  static const String passwordKey = "password_key";

  /// 保存在本地的 token 的 key。
  static const String tokenKey = "token_key";

  /// 请求加密的 key。
  static const String encryptionKey = "encryption_key";

  /// 后端返回给前端的数据需要解密用到的 key。
  static const String decryptionKey = "dencryption_key";

  /// 网络请求的域名。
  ///
  /// 本地调试时使用 `http://0.0.0.0:5006`，发布前需切换为正式域名。
  static String get requestUrl {
    // 本地调试地址
    return "http://0.0.0.0:5006";
    // 正式域名（发布前取消注释上面一行，注释此行）
    // return "https://www.read.top";
  }

  /// 网络请求的前缀。
  static const String prefix = "/api/";

  /// 为 `true` 时 [postRequest] 在 Debug 下打印成功响应的 `content` 预览；`false` 关闭（默认）。
  static const bool enableHttpRequestVerboseLog = false;

  /// 为 `true` 时 [GameWebsocketService] 打印每条解密后的 WS 业务包；`false` 关闭（默认）。
  static const bool enableGameWebsocketVerboseLog = false;

  /// 开屏图片展示时长（毫秒）。
  static const int splashScreenDisplayDurationMs = 1800;

  /// 开屏淡出动画时长（毫秒）。
  static const int splashScreenFadeOutDurationMs = 300;
}
