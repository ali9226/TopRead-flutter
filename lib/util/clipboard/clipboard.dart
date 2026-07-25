// 跨平台剪贴板封装程序
import 'clipboard_io.dart' if (dart.library.html) 'clipboard_web.dart' as impl;

/// 将 [文本] 复制到剪贴板。成功返回 true，失败返回 false。
Future<bool> copyToClipboard(String text) => impl.copyToClipboard(text);
