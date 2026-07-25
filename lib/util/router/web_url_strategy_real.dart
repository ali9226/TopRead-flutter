// lib/web_url_strategy_real.dart
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

// TODO web平台，设置这个是为了去除浏览器的#符号
void setWebUrlStrategy() {
  setUrlStrategy(PathUrlStrategy());
}
