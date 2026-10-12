// ignore_for_file: non_constant_identifier_names

import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';

/// 修改封面接口返回的封面信息。
class ReplaceCoverResult {
  /// 封面地址。
  final String cover_url;

  /// 封面宽度。
  final int cover_width;

  /// 封面高度。
  final int cover_height;

  const ReplaceCoverResult({
    required this.cover_url,
    required this.cover_width,
    required this.cover_height,
  });

  /// 从接口返回的 json 中解析业务对象。
  factory ReplaceCoverResult.from_json(Map<String, dynamic> json) {
    return ReplaceCoverResult(
      cover_url: json['cover_url']?.toString() ?? '',
      cover_width: _parse_int(json['cover_width']),
      cover_height: _parse_int(json['cover_height']),
    );
  }

  /// 把接口返回的数字字段解析为 int。
  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

/// 修改小说封面为默认封面。
///
/// [novel_id] 小说ID（对应 novel_main_language.novel_id）。
Future<ReplaceCoverResult?> update_novel_cover(int novel_id) async {
  final ResultsType<ReplaceCoverResult> results =
      await postRequest<ReplaceCoverResult>(
        path: 'novel_language/update_cover',
        parameter: {'novel_id': novel_id},
        fromJson: ReplaceCoverResult.from_json,
      );
  return results.status ? results.content : null;
}
