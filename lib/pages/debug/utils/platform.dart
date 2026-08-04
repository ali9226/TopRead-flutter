import 'package:flutter/foundation.dart';

/// 当前运行平台是否为 Android 或 iOS。
bool get isAndroidOrIOS {
  if (kIsWeb) return false;

  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}
