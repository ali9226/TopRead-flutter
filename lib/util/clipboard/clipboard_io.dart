import 'package:flutter/services.dart';

Future<bool> copyToClipboard(String text) async {
  try {
    await Clipboard.setData(ClipboardData(text: text));
    return true;
  } catch (e) {
    return false;
  }
}
