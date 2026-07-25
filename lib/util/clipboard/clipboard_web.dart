// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

// 使用 `dart:html` API 实现 Web 功能。
import 'dart:html' as html;

Future<bool> copyToClipboard(String text) async {
  try {
    final clipboard = html.window.navigator.clipboard;
    if (clipboard != null) {
      await clipboard.writeText(text);
      return true;
    }

    final ta = html.TextAreaElement();
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.left = '-9999px';
    html.document.body?.append(ta);
    ta.select();
    final success = html.document.execCommand('copy');
    ta.remove();
    return success;
  } catch (e) {
    return false;
  }
}
