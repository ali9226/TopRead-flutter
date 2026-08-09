// ignore_for_file: non_constant_identifier_names

/// 广告观看验证结果（由后端接口 novel_ads/search_results 返回）。
class AdVerifyResult {
  /// 广告未完整观看。
  static const int status_not_completed = 1;

  /// 广告已完整观看。
  static const int status_completed = 2;

  /// 验证状态：[status_not_completed] 或 [status_completed]。
  final int status;

  AdVerifyResult({required this.status});

  factory AdVerifyResult.fromJson(Map<String, dynamic> json) {
    return AdVerifyResult(
      status: json['status'] is int
          ? json['status'] as int
          : int.tryParse(json['status']?.toString() ?? '0') ?? 0,
    );
  }
}
