import 'package:get_storage/get_storage.dart';

/// 持久化当前阅读正文字号。
///
/// [font_size] 需要保存的字号大小。
Future<void> save_body_font_size(double font_size) async {
  final storage = GetStorage();
  await storage.write('body_font_size', font_size);
}

/// 读取已保存的阅读正文字号。
///
/// 返回保存的字号大小，未保存时返回 null。
double? load_body_font_size() {
  final storage = GetStorage();
  final dynamic value = storage.read('body_font_size');
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// 持久化自动阅读速度。
///
/// [speed] 需要保存的速度值（0.0 ~ 1.0）。
Future<void> save_auto_read_speed(double speed) async {
  final storage = GetStorage();
  await storage.write('auto_read_speed', speed);
}

/// 读取已保存的自动阅读速度。
///
/// 返回保存的速度值，未保存时返回 null。
double? load_auto_read_speed() {
  final storage = GetStorage();
  final dynamic value = storage.read('auto_read_speed');
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
