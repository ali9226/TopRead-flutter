// ignore_for_file: non_constant_identifier_names

/// 服务端混合加密后的小说正文数据。
class NovelContentPayload {
  /// 正文加密协议版本。
  final String protocol;

  /// 正文加密算法。
  final String algorithm;

  /// 正文类型。
  final String content_type;

  /// 章节 ID 或小说语种 ID。
  final String content_id;

  /// RSA-OAEP-256 加密后的 AES 密钥。
  final String encrypted_key;

  /// AES-GCM 随机向量。
  final String iv;

  /// AES-GCM 完整性标签。
  final String auth_tag;

  /// AES-256-GCM 加密后的正文。
  final String ciphertext;

  const NovelContentPayload({
    required this.protocol,
    required this.algorithm,
    required this.content_type,
    required this.content_id,
    required this.encrypted_key,
    required this.iv,
    required this.auth_tag,
    required this.ciphertext,
  });

  /// 从正文接口响应解析混合加密数据。
  factory NovelContentPayload.from_json(Map<String, dynamic> json) {
    return NovelContentPayload(
      protocol: json['protocol']?.toString() ?? '',
      algorithm: json['algorithm']?.toString() ?? '',
      content_type: json['content_type']?.toString() ?? '',
      content_id: json['content_id']?.toString() ?? '',
      encrypted_key: json['encrypted_key']?.toString() ?? '',
      iv: json['iv']?.toString() ?? '',
      auth_tag: json['auth_tag']?.toString() ?? '',
      ciphertext: json['ciphertext']?.toString() ?? '',
    );
  }
}
