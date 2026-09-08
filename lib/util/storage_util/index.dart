import 'package:get_storage/get_storage.dart';

/// 本地存储工具。
///
/// 对 `GetStorage` 的轻量封装，统一项目里的读写入口。
class StorageUtil {
  const StorageUtil._();

  /// GetStorage 单例，避免每次读写都创建新实例。
  static final GetStorage _storage = GetStorage();

  /// 保存字符串到本地。
  ///
  /// [key] 存储键。
  /// [value] 存储值。
  static Future<bool> saveData(String key, String value) async {
    await _storage.write(key, value);
    return true;
  }

  /// 读取本地字符串。
  ///
  /// [key] 要读取的存储键。
  static Future<String?> getData(String key) async {
    return _storage.read<String>(key);
  }

  /// 删除本地数据。
  ///
  /// [key] 需要删除的存储键。
  static Future<void> removeData(String key) async {
    await _storage.remove(key);
  }

  /// 保存任意可序列化对象。
  ///
  /// [key] 存储键。
  /// [value] 要保存的列表数据。
  static Future<void> saveList(String key, List<dynamic> value) async {
    await _storage.write(key, value);
  }

  /// 读取列表数据。
  ///
  /// [key] 要读取的存储键。
  static List<dynamic>? getList(String key) {
    return _storage.read<List<dynamic>>(key);
  }
}
