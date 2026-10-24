// ignore_for_file: non_constant_identifier_names

import 'package:app/api/ad_free.dart';
import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/util/log_util.dart';

/// 游戏配置（tile_quest/inquire_config）。
class TileQuestGameConfig {
  /// 难度（1.00–10.00，两位小数，如 8.25）。
  final double difficulty;

  /// 题目日期（YYYY-MM-DD，UTC）。
  final String layout_date;

  /// 当日共享布局种子。
  final int layout_seed;

  const TileQuestGameConfig({
    required this.difficulty,
    required this.layout_date,
    required this.layout_seed,
  });

  /// 从接口返回的 json 中解析业务对象。
  factory TileQuestGameConfig.from_json(Map<String, dynamic> json) {
    return TileQuestGameConfig(
      difficulty: _parse_double(json['difficulty']),
      layout_date: json['layout_date']?.toString() ?? '',
      layout_seed: _parse_int(json['layout_seed']),
    );
  }

  /// 把接口返回的数字字段解析为 int。
  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  /// 把接口返回的数字字段解析为 double。
  static double _parse_double(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

/// 查询游戏配置与当日共享题目种子。
Future<TileQuestGameConfig?> fetch_tile_quest_config() async {
  try {
    final ResultsType<TileQuestGameConfig> results =
        await postRequest<TileQuestGameConfig>(
          path: 'tile_quest/inquire_config',
          parameter: <String, dynamic>{},
          showTips: false,
          fromJson: TileQuestGameConfig.from_json,
        );
    return results.status ? results.content : null;
  } catch (error, stack_trace) {
    logUtil(
      msg: '[TileQuestReporter] 获取配置异常: $error\n$stack_trace',
      type: 'w',
    );
    return null;
  }
}

/// 对局开始上报（静默遥测，失败只写日志不抛）。
Future<void> report_tile_quest_session_start({
  required String challenge_id,
  required int level,
  required double difficulty,
  required String layout_date,
  required int layout_seed,
  required int run_seed,
  required int tiles_total,
}) async {
  try {
    final identity = await capture_ad_free_request_identity();
    if (identity == null) return;
    final ResultsType<void> results = await postRequest<void>(
      path: 'tile_quest/record_start',
      parameter: <String, dynamic>{
        'challenge_id': challenge_id,
        'level': level,
        'difficulty': difficulty,
        'layout_date': layout_date,
        'layout_seed': layout_seed,
        'run_seed': run_seed,
        'device_token': identity.device_token,
        'tiles_total': tiles_total,
      },
      showTips: false,
    );
    if (!results.status) {
      logUtil(
        msg:
            '[TileQuestReporter] 开局上报失败: challenge_id=$challenge_id, '
            'message=${results.message}',
        type: 'w',
      );
    }
  } catch (error, stack_trace) {
    logUtil(
      msg:
          '[TileQuestReporter] 开局上报异常: challenge_id=$challenge_id, '
          'error=$error\n$stack_trace',
      type: 'w',
    );
  }
}

/// 对局结束上报（静默遥测，失败只写日志不抛）。
///
/// [status] 1=胜 2=败 3=弃。无 record_start 的 end 由后端静默丢弃。
Future<void> report_tile_quest_session_end({
  required String challenge_id,
  required int level,
  required double difficulty,
  required String layout_date,
  required int layout_seed,
  required int run_seed,
  required int status,
  required int duration_ms,
  required int undo_used,
  required int shuffle_used,
  required int remove_used,
  required int tap_count,
  required int matched_count,
}) async {
  try {
    final identity = await capture_ad_free_request_identity();
    if (identity == null) return;
    final ResultsType<void> results = await postRequest<void>(
      path: 'tile_quest/record_end',
      parameter: <String, dynamic>{
        'challenge_id': challenge_id,
        'level': level,
        'difficulty': difficulty,
        'layout_date': layout_date,
        'layout_seed': layout_seed,
        'run_seed': run_seed,
        'device_token': identity.device_token,
        'status': status,
        'duration_ms': duration_ms,
        'undo_used': undo_used,
        'shuffle_used': shuffle_used,
        'remove_used': remove_used,
        'tap_count': tap_count,
        'matched_count': matched_count,
      },
      showTips: false,
    );
    if (!results.status) {
      logUtil(
        msg:
            '[TileQuestReporter] 终局上报失败: challenge_id=$challenge_id, '
            'message=${results.message}',
        type: 'w',
      );
    }
  } catch (error, stack_trace) {
    logUtil(
      msg:
          '[TileQuestReporter] 终局上报异常: challenge_id=$challenge_id, '
          'error=$error\n$stack_trace',
      type: 'w',
    );
  }
}

/// 对局遥测上报载荷。[status] 为空表示开局上报，否则为终局。
class TileQuestSessionReport {
  const TileQuestSessionReport({
    required this.challenge_id,
    required this.level,
    required this.difficulty,
    required this.layout_date,
    required this.layout_seed,
    required this.run_seed,
    required this.tiles_total,
    this.status,
    this.duration_ms,
    this.undo_used,
    this.shuffle_used,
    this.remove_used,
    this.tap_count,
    this.matched_count,
  });

  final String challenge_id;
  final int level;
  final double difficulty;
  final String layout_date;
  final int layout_seed;
  final int run_seed;
  final int tiles_total;

  /// 1=胜 2=败 3=弃；null=开局上报。
  final int? status;
  final int? duration_ms;
  final int? undo_used;
  final int? shuffle_used;
  final int? remove_used;
  final int? tap_count;
  final int? matched_count;
}

/// 统一入口：按 status 是否为空分派 record_start / record_end。
Future<void> report_tile_quest_session(TileQuestSessionReport report) {
  if (report.status == null) {
    return report_tile_quest_session_start(
      challenge_id: report.challenge_id,
      level: report.level,
      difficulty: report.difficulty,
      layout_date: report.layout_date,
      layout_seed: report.layout_seed,
      run_seed: report.run_seed,
      tiles_total: report.tiles_total,
    );
  }
  return report_tile_quest_session_end(
    challenge_id: report.challenge_id,
    level: report.level,
    difficulty: report.difficulty,
    layout_date: report.layout_date,
    layout_seed: report.layout_seed,
    run_seed: report.run_seed,
    status: report.status!,
    duration_ms: report.duration_ms ?? 0,
    undo_used: report.undo_used ?? 0,
    shuffle_used: report.shuffle_used ?? 0,
    remove_used: report.remove_used ?? 0,
    tap_count: report.tap_count ?? 0,
    matched_count: report.matched_count ?? 0,
  );
}
