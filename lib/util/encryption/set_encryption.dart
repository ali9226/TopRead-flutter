import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:app/util/log_util.dart';

/* TODO 生成固定长度随机数字串。 */
String accessNumber(int length) {
  const String chars = '0123456789';
  final Random random = Random.secure();
  return List<String>.generate(
    length,
    (_) => chars[random.nextInt(chars.length)],
  ).join();
}

/* TODO
 * 把业务数据加密为服务端约定格式。
 *
 * [data] 原始业务参数。
 * [encryptionKey] 可选自定义密钥。
 */
Map<String, String> encryptData(
  Map<String, dynamic> data, {
  String? encryptionKey,
}) {
  String encryptionKeyStr = '';

  if (encryptionKey == null) {
    final List<String> encryptionKeyCopy = <String>[
      'W',
      'l',
      'c',
      '1',
      'a',
      'm',
      'N',
      'u',
      'b',
      'H',
      'd',
      'k',
      'R',
      '2',
      'x',
      '2',
      'Y',
      'm',
      'w',
      '5',
      'c',
      'l',
      'p',
      'Y',
      'b',
      'G',
      'Z',
      'Z',
      'V',
      '3',
      'h',
      'w',
      'W',
      'D',
      'N',
      's',
      'a',
      'G',
      'J',
      't',
      'c',
      'D',
      'F',
      'i',
      'b',
      'X',
      'A',
      'x',
      'Y',
      'm',
      'c',
      '9',
      'P',
      'Q',
      '=',
      '=',
    ];

    try {
      final Uint8List firstDecode = base64Decode(encryptionKeyCopy.join(''));
      final String firstDecodeString = utf8.decode(firstDecode);
      final Uint8List secondDecode = base64Decode(firstDecodeString);
      encryptionKeyStr = utf8.decode(secondDecode);
    } catch (error) {
      logUtil(msg: 'TODO 默认密钥解码失败: $error', type: 'e');
      return <String, String>{};
    }
  } else {
    encryptionKeyStr = encryptionKey;
  }

  if (data.isEmpty) return <String, String>{};

  final Map<String, dynamic> encryptionData = Map<String, dynamic>.from(data);

  late final String jwtEncrypted;
  try {
    final JWT jwt = JWT(encryptionData);
    jwtEncrypted = jwt.sign(
      SecretKey(encryptionKeyStr),
      expiresIn: const Duration(days: 1),
    );
  } catch (error) {
    logUtil(msg: 'TODO JWT 加密失败: $error', type: 'e');
    return <String, String>{};
  }

  final String milliseconds = DateTime.now().millisecondsSinceEpoch.toString();
  final StringBuffer dateEncryption = StringBuffer();
  for (final String char in milliseconds.split('')) {
    dateEncryption.write('${accessNumber(2)}$char');
  }
  dateEncryption.write(accessNumber(2));

  return <String, String>{
    'encryption': '${dateEncryption.toString()} $jwtEncrypted',
  };
}
