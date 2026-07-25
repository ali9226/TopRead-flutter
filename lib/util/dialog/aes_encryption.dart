import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

const String _aesKey = 'HoldEmApp@2025!!';
const String _aesIv = 'AESInitVector123';

Uint8List _createUint8ListFromString(String value) {
  return Uint8List.fromList(utf8.encode(value));
}

/* TODO
 * 使用 AES-CBC 加密字符串。
 *
 * [plainText] 需要加密的明文。
 */
String aesEncryption(String plainText) {
  if (plainText.isEmpty) return '';

  try {
    final Uint8List key = _createUint8ListFromString(_aesKey);
    final Uint8List iv = _createUint8ListFromString(_aesIv);

    final CBCBlockCipher cipher = CBCBlockCipher(AESEngine())
      ..init(true, ParametersWithIV<KeyParameter>(KeyParameter(key), iv));

    final Uint8List input = _pad(Uint8List.fromList(utf8.encode(plainText)));
    final Uint8List output = Uint8List(input.length);

    int offset = 0;
    while (offset < input.length) {
      offset += cipher.processBlock(input, offset, output, offset);
    }

    return base64Encode(output);
  } catch (_) {
    return '';
  }
}

/* TODO
 * 使用 AES-CBC 解密字符串。
 *
 * [base64CipherText] Base64 编码后的密文。
 */
String aesDecryption(String base64CipherText) {
  if (base64CipherText.isEmpty) return '';

  try {
    final Uint8List key = _createUint8ListFromString(_aesKey);
    final Uint8List iv = _createUint8ListFromString(_aesIv);

    final CBCBlockCipher cipher = CBCBlockCipher(AESEngine())
      ..init(false, ParametersWithIV<KeyParameter>(KeyParameter(key), iv));

    final Uint8List input = base64Decode(base64CipherText);
    final Uint8List output = Uint8List(input.length);

    int offset = 0;
    while (offset < input.length) {
      offset += cipher.processBlock(input, offset, output, offset);
    }

    return utf8.decode(_unpad(output));
  } catch (_) {
    return '';
  }
}

/* TODO PKCS7 填充。 */
Uint8List _pad(Uint8List data) {
  final int padLength = 16 - (data.length % 16);
  final Uint8List padded = Uint8List(data.length + padLength)..setAll(0, data);
  for (int index = data.length; index < padded.length; index++) {
    padded[index] = padLength;
  }
  return padded;
}

/* TODO 移除 PKCS7 填充。 */
Uint8List _unpad(Uint8List padded) {
  final int padLength = padded.last;
  return padded.sublist(0, padded.length - padLength);
}
