import 'package:get_storage/get_storage.dart';

/* TODO
 * 本地存储工具。
 *
 * 该工具是对 `GetStorage` 的轻量封装，统一项目里的读写入口。
 */
class StorageUtil {
  const StorageUtil._();

  /* TODO 保存字符串到本地。
   *
   * [key] 存储键。
   * [value] 存储值。
   */
  static Future<bool> saveData(String key, String value) async {
    final GetStorage storage = GetStorage();
    await storage.write(key, value);
    return true;
  }

  /* TODO 读取本地字符串。
   *
   * [key] 要读取的存储键。
   */
  static Future<String?> getData(String key) async {
    final GetStorage storage = GetStorage();
    return storage.read<String>(key);
  }

  /* TODO 删除本地数据。
   *
   * [key] 需要删除的存储键。
   */
  static Future<void> removeData(String key) async {
    final GetStorage storage = GetStorage();
    await storage.remove(key);
  }

  /* TODO 保存任意可序列化对象。 */
  static Future<void> saveList(String key, List<dynamic> value) async {
    final GetStorage storage = GetStorage();
    await storage.write(key, value);
  }

  /* TODO 读取列表数据。 */
  static List<dynamic>? getList(String key) {
    final GetStorage storage = GetStorage();
    return storage.read<List<dynamic>>(key);
  }
}
