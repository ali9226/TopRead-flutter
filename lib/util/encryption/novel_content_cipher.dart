// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:app/models/novel_content_payload.dart';
import 'package:pointycastle/export.dart';

/// 小说正文运行期混合加密工具。
///
/// 应用每次启动只生成一对 RSA-2048 密钥。公钥随正文请求发送，私钥只保留在
/// 当前进程内存中，不写入磁盘，也不在安装包中保存固定正文解密私钥。
class NovelContentCipher {
  NovelContentCipher._();

  /// 单例。
  static final NovelContentCipher instance = NovelContentCipher._();

  /// 服务端正文加密协议。
  static const String _protocol = 'novel-content-v1';

  /// 服务端正文算法标识。
  static const String _algorithm = 'RSA-OAEP-256+A256GCM';

  /// AES-GCM 验证标签位数。
  static const int _gcm_tag_bits = 128;

  /// RSA 公钥位数。
  static const int _rsa_key_bits = 2048;

  /// RSA 素数检测确定性。
  static const int _rsa_certainty = 64;

  /// RSA 标准公开指数。
  static final BigInt _rsa_public_exponent = BigInt.from(65537);

  /// 当前应用进程唯一的 RSA 密钥对。
  late final Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>>
  _key_pair_future = Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>>(
    _generate_key_pair,
  );

  /// 返回正文请求所需的 RSA JWK 公钥参数。
  Future<Map<String, String>> get_public_key_parameters() async {
    final AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> key_pair =
        await _key_pair_future;
    final RSAPublicKey public_key = key_pair.publicKey;
    return <String, String>{
      'public_key_n': _base64_url_encode_big_int(public_key.modulus!),
      'public_key_e': _base64_url_encode_big_int(public_key.exponent!),
    };
  }

  /// 解密并校验服务端返回的正文。
  Future<String> decrypt(NovelContentPayload payload) async {
    if (payload.protocol != _protocol || payload.algorithm != _algorithm) {
      throw const FormatException('Unsupported novel content encryption');
    }

    final AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> key_pair =
        await _key_pair_future;
    final OAEPEncoding rsa_cipher = OAEPEncoding.withSHA256(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(key_pair.privateKey));
    final Uint8List aes_key = rsa_cipher.process(
      Uint8List.fromList(base64Decode(payload.encrypted_key)),
    );
    final Uint8List iv = Uint8List.fromList(base64Decode(payload.iv));
    final Uint8List ciphertext = Uint8List.fromList(
      base64Decode(payload.ciphertext),
    );
    final Uint8List auth_tag = Uint8List.fromList(
      base64Decode(payload.auth_tag),
    );
    final Uint8List ciphertext_with_tag =
        Uint8List(ciphertext.length + auth_tag.length)
          ..setRange(0, ciphertext.length, ciphertext)
          ..setRange(
            ciphertext.length,
            ciphertext.length + auth_tag.length,
            auth_tag,
          );
    final Uint8List aad = Uint8List.fromList(
      utf8.encode(
        '${payload.protocol}:${payload.content_type}:${payload.content_id}',
      ),
    );
    final GCMBlockCipher aes_cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(KeyParameter(aes_key), _gcm_tag_bits, iv, aad),
      );
    final Uint8List plaintext = aes_cipher.process(ciphertext_with_tag);
    return utf8.decode(plaintext);
  }

  /// 生成当前应用进程使用的 RSA-2048 密钥对。
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _generate_key_pair() {
    final Random random = Random.secure();
    final Uint8List seed = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    final SecureRandom secure_random = FortunaRandom()
      ..seed(KeyParameter(seed));
    final RSAKeyGenerator generator = RSAKeyGenerator()
      ..init(
        ParametersWithRandom<RSAKeyGeneratorParameters>(
          RSAKeyGeneratorParameters(
            _rsa_public_exponent,
            _rsa_key_bits,
            _rsa_certainty,
          ),
          secure_random,
        ),
      );
    return generator.generateKeyPair();
  }

  /// 把 RSA 大整数转换成无填充 Base64URL，格式与 JWK 一致。
  String _base64_url_encode_big_int(BigInt value) {
    String hex = value.toRadixString(16);
    if (hex.length.isOdd) hex = '0$hex';
    final Uint8List bytes = Uint8List(hex.length ~/ 2);
    for (int index = 0; index < bytes.length; index++) {
      bytes[index] = int.parse(
        hex.substring(index * 2, index * 2 + 2),
        radix: 16,
      );
    }
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
