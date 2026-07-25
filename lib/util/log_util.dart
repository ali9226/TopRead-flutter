import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/* TODO
 * 输出调试日志。
 *
 * [msg] 日志正文。
 * [type] 日志级别：
 * d: debug
 * i: info
 * w: warning
 * e: error
 */
void logUtil({required String msg, String? type}) {
  if (kReleaseMode) return; // TODO release模式下直接返回
  final logger = Logger();

  switch (type) {
    case 'd':
      logger.d(msg);
      break;
    case 'w':
      logger.w(msg);
      break;
    case 'e':
      logger.e(msg);
      break;
    default:
      logger.i(msg);
  }
}

/* TODO
 * 分片输出长文本日志。
 *
 * [text] 需要完整输出的文本内容。
 */
void outputLog({String text = ''}) {
  if (kReleaseMode) return; // TODO release模式下直接返回
  const chunkSize = 1000;
  for (var i = 0; i < text.length; i += chunkSize) {
    debugPrint(
      text.substring(
        i,
        i + chunkSize > text.length ? text.length : i + chunkSize,
      ),
    );
  }
}
