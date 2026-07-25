import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:app/config/constant.dart';

/* TODO 对密码执行 SHA-256 加盐哈希。
 *
 * [password] 用户输入的明文密码。
 */
String passwordEncryption(String password) {
  final List<int> bytes = utf8.encode('$password${Constant.passwordKey}');
  final Digest digest = sha256.convert(bytes);
  return digest.toString();
}
