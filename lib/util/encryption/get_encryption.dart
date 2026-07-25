import 'dart:convert';
import 'package:app/util/log_util.dart';
import 'package:jwt_decode/jwt_decode.dart';

/* TODO
 * 解密 JWT 包裹的加密数据。
 *
 * [encryption] 服务端返回的加密字符串。
 * [encryptionKey] 可选密钥；当前实现仅在默认流程下做双层 Base64 解码。
 */
dynamic decryptEncryption(String encryption, {String? encryptionKey}) {
  String encryptionKeyStr = '';

  if (encryptionKey == null) {
    final List<String> encryptionKeyCopy = <String>[
      'W',
      'V',
      'd',
      '4',
      'c',
      'F',
      'g',
      'z',
      'Q',
      'm',
      'h',
      'l',
      'V',
      'j',
      'l',
      '5',
      'W',
      'l',
      'h',
      'S',
      'M',
      'W',
      'N',
      't',
      'N',
      'W',
      'Z',
      'a',
      'R',
      '0',
      'Y',
      'w',
      'W',
      'V',
      'Y',
      '5',
      'c',
      'l',
      'p',
      'Y',
      'a',
      'z',
      '0',
      '=',
    ];

    try {
      encryptionKeyStr = encryptionKeyCopy.join('');
      final String firstDecode = utf8.decode(base64.decode(encryptionKeyStr));
      encryptionKeyStr = utf8.decode(base64.decode(firstDecode));
    } catch (error) {
      logUtil(msg: 'TODO Base64 解码失败: $error', type: 'e');
    }
  } else {
    encryptionKeyStr = encryptionKey;
  }

  try {
    return Jwt.parseJwt(encryption);
  } catch (error) {
    logUtil(msg: 'TODO JWT 解码失败: $error', type: 'e');
    return encryption;
  }
}
