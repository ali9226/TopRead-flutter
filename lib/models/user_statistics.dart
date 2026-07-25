/* TODO
 * 用户统计数据模型。
 * 对应后端 /user/user_info_statistics 接口返回的 user_statistics 字段。
 */
class UserStatistics {
  /// TODO 用户ID。
  final int userId;

  /// TODO 关注数量。
  final int followCount;

  /// TODO 粉丝数量。
  final int fansCount;

  /// TODO 获赞数量。
  final int likesCount;

  /// TODO 统计更新时间（UTC 字符串）。
  final String updateTime;

  UserStatistics({
    this.userId = 0,
    this.followCount = 0,
    this.fansCount = 0,
    this.likesCount = 0,
    this.updateTime = '',
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      userId: int.tryParse('${json['user_id'] ?? 0}') ?? 0,
      followCount: int.tryParse('${json['follow_count'] ?? 0}') ?? 0,
      fansCount: int.tryParse('${json['fans_count'] ?? 0}') ?? 0,
      likesCount: int.tryParse('${json['likes_count'] ?? 0}') ?? 0,
      updateTime: '${json['update_time'] ?? ''}',
    );
  }
}
