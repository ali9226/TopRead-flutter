import 'package:app/util/device/app_environment.dart';

/// 当前运行平台是否为 Android 或 iOS。
bool get isAndroidOrIOS => isNativeMobileApp;
