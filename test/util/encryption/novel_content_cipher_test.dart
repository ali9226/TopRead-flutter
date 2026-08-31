// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';

import 'package:app/models/novel_content_payload.dart';
import 'package:app/util/encryption/novel_content_cipher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('正文混合加密数据可以通过运行期私钥完成解密和完整性校验', () async {
    const String protocol = 'novel-content-v1';
    const String algorithm = 'RSA-OAEP-256+A256GCM';
    const String content_type = 'chapter';
    const String content_id = '123';
    const String plaintext = '第一章\n这是需要保护的小说正文。';
    final NovelContentCipher cipher = NovelContentCipher.instance;
    final Map<String, String> public_parameters = await cipher
        .get_public_key_parameters();
    final RSAPublicKey public_key = RSAPublicKey(
      _decode_base64_url_big_int(public_parameters['public_key_n']!),
      _decode_base64_url_big_int(public_parameters['public_key_e']!),
    );
    final Uint8List aes_key = Uint8List.fromList(
      List<int>.generate(32, (int index) => index + 1),
    );
    final Uint8List iv = Uint8List.fromList(
      List<int>.generate(12, (int index) => index + 11),
    );
    final Uint8List aad = Uint8List.fromList(
      utf8.encode('$protocol:$content_type:$content_id'),
    );
    final GCMBlockCipher aes_cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(aes_key), 128, iv, aad));
    final Uint8List ciphertext_with_tag = aes_cipher.process(
      Uint8List.fromList(utf8.encode(plaintext)),
    );
    final int auth_tag_start = ciphertext_with_tag.length - 16;
    final Uint8List ciphertext = Uint8List.sublistView(
      ciphertext_with_tag,
      0,
      auth_tag_start,
    );
    final Uint8List auth_tag = Uint8List.sublistView(
      ciphertext_with_tag,
      auth_tag_start,
    );
    final OAEPEncoding rsa_cipher = OAEPEncoding.withSHA256(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(public_key));
    final Uint8List encrypted_key = rsa_cipher.process(aes_key);
    final NovelContentPayload payload = NovelContentPayload(
      protocol: protocol,
      algorithm: algorithm,
      content_type: content_type,
      content_id: content_id,
      encrypted_key: base64Encode(encrypted_key),
      iv: base64Encode(iv),
      auth_tag: base64Encode(auth_tag),
      ciphertext: base64Encode(ciphertext),
    );

    expect(await cipher.decrypt(payload), plaintext);
  });
}

/// 把无填充 Base64URL 编码的 JWK 参数还原为大整数。
BigInt _decode_base64_url_big_int(String value) {
  final String padded = value.padRight(
    value.length + ((4 - value.length % 4) % 4),
    '=',
  );
  final Uint8List bytes = Uint8List.fromList(base64Url.decode(padded));
  return BigInt.parse(
    bytes.map((int byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
    radix: 16,
  );
}
