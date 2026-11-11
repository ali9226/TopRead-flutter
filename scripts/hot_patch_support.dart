import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// TODO 发布前即可验证的补丁目标；file_name 始终保持 SDK 的规范名称。
class PatchTarget {
  PatchTarget({
    required this.platform,
    required this.abi,
    required this.version_code,
    this.flavor = 'default',
    this.channel = 'production',
  });

  final String platform;
  final String abi;
  final int version_code;
  final String flavor;
  final String channel;

  String get file_name => flavor == 'default' && channel == 'production'
      ? '$version_code-$abi.fptc'
      : '$version_code-$flavor-$channel-$abi.fptc';

  /// TODO 与后端使用相同的宿主锁，避免多个上传入口分配相同热更版本。
  String lock_name(String fingerprint) =>
      'app_patch:${sha256.convert(utf8.encode(jsonEncode([platform, abi, version_code.toString(), flavor, channel, fingerprint]))).toString().substring(0, 48)}';
}

/// TODO 校验 SDK 规范文件名，不接受省略 channel 的歧义命名。
PatchTarget parse_patch_target(String file_name) {
  const abi_names = [
    'ios-simulator-arm64',
    'ios-arm64e',
    'ios-arm64',
    'arm64-v8a',
    'armeabi-v7a',
    'x86_64',
    'x86',
  ];
  if (!file_name.endsWith('.fptc')) {
    throw const FormatException('补丁必须以 .fptc 结尾');
  }
  final name = file_name.substring(0, file_name.length - 5);
  final abi = abi_names.firstWhere(
    (item) => name.endsWith('-$item'),
    orElse: () => throw FormatException('无法识别补丁 ABI：$file_name'),
  );
  final parts = name.substring(0, name.length - abi.length - 1).split('-');
  if ((parts.length != 1 && parts.length != 3) ||
      !RegExp(r'^[1-9]\d*$').hasMatch(parts.first) ||
      (int.tryParse(parts.first) ?? 0x100000000) > 0xffffffff ||
      parts
          .skip(1)
          .any((part) => !RegExp(r'^[A-Za-z0-9_]{1,32}$').hasMatch(part))) {
    throw FormatException('不符合 SDK 目标命名：$file_name');
  }
  final target = PatchTarget(
    platform: abi.startsWith('ios') ? 'ios' : 'android',
    abi: abi,
    version_code: int.parse(parts.first),
    flavor: parts.length == 3 ? parts[1] : 'default',
    channel: parts.length == 3 ? parts[2] : 'production',
  );
  if (target.file_name != file_name) {
    throw const FormatException('补丁文件名不是 SDK 规范名称');
  }
  return target;
}

/// TODO FPTC 头只用于登记元数据；宿主仍须通过 Ed25519 验签后才能安装。
class PatchEnvelope {
  PatchEnvelope(
    this.fingerprint,
    this.seq,
    this.payload_length,
    this.sha256_hex,
  );
  final String fingerprint;
  final int seq;
  final int payload_length;
  final String sha256_hex;
  int get patch_type => payload_length == 0 ? 2 : 1;
}

/// TODO 在网络操作前校验长度、序号、签名存在性和 payload 哈希。
PatchEnvelope parse_patch_envelope(Uint8List bytes) {
  const header_size = 146;
  if (bytes.length < header_size || bytes.length > 320 * 1024 * 1024) {
    throw const FormatException('FPTC 文件长度无效');
  }
  final data = ByteData.sublistView(bytes);
  if (data.getUint32(0) != 0x46505443 || data.getUint16(4) != 1) {
    throw const FormatException('只支持 FPTC v1');
  }
  final seq = data.getUint32(38);
  final payload_length = data.getUint64(42);
  if (seq == 0 || payload_length != bytes.length - header_size) {
    throw const FormatException('FPTC 序号或 payload 长度无效');
  }
  if (bytes.sublist(82, 146).every((value) => value == 0)) {
    throw const FormatException('拒绝登记未签名补丁');
  }
  final actual = sha256.convert(bytes.sublist(header_size)).bytes;
  if (List.generate(
    32,
    (index) => actual[index] == bytes[50 + index],
  ).contains(false)) {
    throw const FormatException('FPTC payload SHA256 不匹配');
  }
  final fingerprint = bytes
      .sublist(6, 38)
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return PatchEnvelope(
    fingerprint,
    seq,
    payload_length,
    sha256.convert(bytes).toString(),
  );
}

/// TODO 使用北京时间而非机器本地时区，随机尾缀避免同秒同名覆盖。
String publication_id({DateTime? now, String? nonce}) {
  final beijing = (now ?? DateTime.now()).toUtc().add(const Duration(hours: 8));
  String pad(int value, int width) => value.toString().padLeft(width, '0');
  final stamp =
      '${pad(beijing.year, 4)}${pad(beijing.month, 2)}${pad(beijing.day, 2)}_${pad(beijing.hour, 2)}${pad(beijing.minute, 2)}${pad(beijing.second, 2)}';
  final suffix =
      nonce ??
      List.generate(
        12,
        (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
  if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(suffix)) {
    throw const FormatException('唯一后缀无效');
  }
  return '${stamp}_$suffix';
}

/// TODO 对象名称带时间与唯一尾缀，SDK file_name 单独保存，不从对象名推断目标。
String patch_object_key(
  PatchTarget target,
  PatchEnvelope envelope,
  String id, {
  bool local = true,
}) =>
    'flutter_patcher/${local ? 'verification/patches' : 'patches'}/${target.version_code}/${target.platform}/${envelope.seq}/${target.file_name.substring(0, target.file_name.length - 5)}_$id.fptc';

/// TODO 默认同时处理双端；未知参数应立即报错，不能悄悄写入错误环境。
List<String> target_platforms(String? os) => switch (os ?? 'both') {
  'both' => ['android', 'ios'],
  'android' => ['android'],
  'ios' => ['ios'],
  _ => throw const FormatException('--os 只支持 android|ios|both'),
};

/// TODO 仅接受本次命令的精确输出目录，缺少任何端产物都视为失败。
Future<List<File>> collect_patch_outputs(
  Directory output, {
  required String platform,
  required int version_code,
}) async {
  if (!await output.exists()) {
    throw FormatException('缺少本次 $platform 输出目录：${output.path}');
  }
  final files = await output
      .list(followLinks: false)
      .where((entry) => entry is File && entry.path.endsWith('.fptc'))
      .cast<File>()
      .toList();
  if (files.isEmpty) throw FormatException('本次 $platform 构建没有补丁产物');
  for (final file in files) {
    final target = parse_patch_target(file.uri.pathSegments.last);
    if (target.platform != platform || target.version_code != version_code) {
      throw FormatException('输出目标不匹配：${file.path}');
    }
  }
  return files;
}

/// TODO 不创建目录即可解析最近的既有父目录，消除 macOS /tmp 等软链。
String canonical_baseline_store(String value) {
  final uri = Uri.parse(value);
  if (uri.scheme == 's3' &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      !uri.hasQuery &&
      !uri.hasFragment) {
    return value;
  }
  if (uri.scheme != 'file' ||
      uri.host.isNotEmpty ||
      !uri.path.startsWith('/') ||
      uri.hasQuery ||
      uri.hasFragment) {
    throw const FormatException(
      'baseline-store 必须为 s3://bucket/路径 或绝对 file:///路径',
    );
  }
  var parent = Directory(uri.toFilePath()).absolute;
  final missing = <String>[];
  while (!parent.existsSync()) {
    if (File(parent.path).existsSync()) {
      throw const FormatException('baseline 路径包含普通文件');
    }
    missing.add(
      parent.uri.pathSegments.where((segment) => segment.isNotEmpty).last,
    );
    parent = parent.parent;
  }
  var canonical = Directory(parent.resolveSymbolicLinksSync());
  for (final segment in missing.reversed) {
    canonical = Directory('${canonical.path}/$segment');
  }
  return canonical.uri.toString();
}

/// TODO 此宿主策略由SDK写入隔离构建副本，源工程残留会使iOS出包失败。
Future<void> require_generated_ios_host_trust(File plist) async {
  if (!await plist.exists()) {
    return;
  }
  final source = await plist.readAsString();
  if (RegExp(r'<key>\s*FlutterPatcherHostTrust\s*</key>').hasMatch(source)) {
    throw FormatException(
      'iOS源Info.plist残留SDK保留键FlutterPatcherHostTrust，请先备份并移除该旧键，勿手动维护其内容；脚本未递增版本、未修改源文件：${plist.path}',
    );
  }
}
