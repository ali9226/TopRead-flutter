// TODO 用户信息
class UserInfo {
  final int id;
  final String account;
  final String invitationCode;
  final String name;
  final int type;
  final double balance;
  final int onlineStatus;
  final String onlineStatusUpdateTime;
  final double shareRatio;
  final String avatarUrl;
  final String memberExpiryTime;
  final String roleName;
  final int notViewed;

  /// TODO 关注数量。
  final int followCount;

  /// TODO 粉丝数量。
  final int fansCount;

  /// TODO 获赞数量。
  final int likesCount;

  /// 调试标识：1=普通用户，2=开发者。
  final int debug;

  UserInfo({
    required this.id,
    required this.account,
    required this.invitationCode,
    required this.name,
    required this.type,
    required this.avatarUrl,
    required this.balance,
    required this.onlineStatus,
    required this.onlineStatusUpdateTime,
    required this.shareRatio,
    required this.memberExpiryTime,
    required this.roleName,
    required this.notViewed,
    required this.followCount,
    required this.fansCount,
    required this.likesCount,
    this.debug = 1,
  });

  /// 安全解析 double 类型字段
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// 安全解析字符串字段。
  ///
  /// 当后端返回 `null` 时，统一按空字符串处理，避免模型解析时报错。
  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      account: _parseString(json['account']),
      avatarUrl: _parseString(json['avatar_url']),
      invitationCode: _parseString(json['invitation_code']),
      name: _parseString(json['name']),
      type: json['type'] is int
          ? json['type']
          : int.tryParse(json['type'].toString()) ?? 0,
      balance: _parseDouble(json['balance']),
      onlineStatus: json['online_status'] is int
          ? json['online_status']
          : int.tryParse(json['online_status'].toString()) ?? 0,
      onlineStatusUpdateTime: _parseString(json['online_status_update_time']),
      shareRatio: _parseDouble(json['share_ratio']),
      memberExpiryTime: _parseString(json['member_expiry_time']),
      roleName: json['role_name']?.toString() ?? '',
      notViewed: json['not_viewed'] is int
          ? json['not_viewed']
          : int.tryParse(json['not_viewed']?.toString() ?? '0') ?? 0,
      followCount: json['follow_count'] is int
          ? json['follow_count']
          : int.tryParse(json['follow_count']?.toString() ?? '0') ?? 0,
      fansCount: json['fans_count'] is int
          ? json['fans_count']
          : int.tryParse(json['fans_count']?.toString() ?? '0') ?? 0,
      likesCount: json['likes_count'] is int
          ? json['likes_count']
          : int.tryParse(json['likes_count']?.toString() ?? '0') ?? 0,
      debug: json['debug'] is int
          ? json['debug']
          : int.tryParse(json['debug']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account': account,
      'invitation_code': invitationCode,
      'avatar_url': avatarUrl,
      'name': name,
      'type': type,
      'balance': balance,
      'online_status': onlineStatus,
      'online_status_update_time': onlineStatusUpdateTime,
      'share_ratio': shareRatio,
      'member_expiry_time': memberExpiryTime,
      'role_name': roleName,
      'not_viewed': notViewed,
      'follow_count': followCount,
      'fans_count': fansCount,
      'likes_count': likesCount,
      'debug': debug,
    };
  }
}
