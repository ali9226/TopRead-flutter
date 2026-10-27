// ignore_for_file: non_constant_identifier_names

/// 作品类型是链接的一部分，不能用同一个小说地址分享漫画或短篇。
enum WorkShareKind { novel, short_story, comic }

/// 与API调试地址分开；生成的海报和剪贴板永远不带登录令牌或设备内网地址。
const String public_base_url = String.fromEnvironment(
  'APP_PUBLIC_URL',
  defaultValue: 'https://app.read.top',
);

Uri share_work_url({
  required int work_id,
  WorkShareKind work_kind = WorkShareKind.novel,
  String? language,
}) {
  if (work_id <= 0) throw ArgumentError.value(work_id, 'work_id');
  final base = public_share_origin(public_base_url);
  return base.replace(
    path: switch (work_kind) {
      WorkShareKind.novel => '/read',
      WorkShareKind.short_story => '/short_story_read',
      WorkShareKind.comic => '/comics/detail',
    },
    queryParameters: {
      'id': '$work_id',
      if (language?.trim().isNotEmpty == true) 'language': language!.trim(),
    },
    fragment: '',
  );
}

/// 公开链接配置不可指向当前设备或局域网；避免调试地址进入剪贴板和永久海报。
Uri public_share_origin(String value) {
  final uri = Uri.parse(value);
  final host = uri.host.toLowerCase();
  final parts = host.split('.').map(int.tryParse).toList();
  final ipv4 =
      parts.length == 4 &&
      parts.every((part) => part != null && part >= 0 && part <= 255);
  final local_ipv4 =
      ipv4 &&
      (parts[0] == 0 ||
          parts[0] == 10 ||
          parts[0] == 127 ||
          parts[0] == 169 && parts[1] == 254 ||
          parts[0] == 172 && parts[1]! >= 16 && parts[1]! <= 31 ||
          parts[0] == 192 && parts[1] == 168 ||
          parts[0]! >= 224);
  final local_ipv6 =
      host.contains(':') &&
      (host == '::' ||
          host == '::1' ||
          host.startsWith('fe80:') ||
          host.startsWith('fc') ||
          host.startsWith('fd'));
  if (uri.scheme != 'https' ||
      host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      host == 'localhost' ||
      host.endsWith('.localhost') ||
      host.endsWith('.local') ||
      local_ipv4 ||
      local_ipv6) {
    throw StateError('Public sharing requires a public HTTPS origin');
  }
  return uri;
}
