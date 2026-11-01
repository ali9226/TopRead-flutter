// ignore_for_file: non_constant_identifier_names

import 'package:app/models/project_config.dart';
import 'package:app/util/device/app_environment.dart';

/* TODO
 * 拼图闯关游戏配置模型。
 *
 * 对应 `redis/get` 接口返回的 `tile_quest_config` 字段，
 * 数据源是后端 `tile_quest_config` 表（单行 id = 1）。
 *
 * 与 ProjectConfig 的关系：
 * - ProjectConfig 管 App 级开关（广告 / 评论 / 分享 / 创作者中心等）。
 * - TileQuestConfig 只管拼图闯关这一个游戏的参数与入口露出。
 * - 游戏入口开关的取值语义与 ProjectConfig 的 *_switch 完全一致
 *   （1 都不开启 / 2 都开启 / 3 仅安卓 / 4 仅 iOS / 5 仅网页），
 *   因此直接复用 SwitchValue 与 is_enabled_for_environment，
 *   不为游戏单独写一套平台判断。
 */
class TileQuestConfig {
  /// 配置行 ID（固定为 1）。
  final int id;

  /// 难度（1.00-10.00，两位小数）。
  ///
  /// 通关率 = (10 - difficulty) × 10%，数值越大越难。
  final double difficulty;

  /// 游戏入口开关。
  ///
  /// 取值见 [SwitchValue]：1 都不开启 / 2 都开启 / 3 仅安卓 / 4 仅 iOS / 5 仅网页。
  final int game_switch;

  const TileQuestConfig({
    required this.id,
    required this.difficulty,
    required this.game_switch,
  });

  /// 空配置兜底。
  ///
  /// 默认值刻意取「全部平台开启」：当 `redis/get` 没返回该字段（旧版本后端、
  /// 网络异常、缓存丢失）时，游戏入口保持原样显示，不会因为一次配置缺失
  /// 就把线上游戏藏没。
  const TileQuestConfig.empty()
    : id = 0,
      difficulty = 8,
      game_switch = SwitchValue.on;

  /// 从 JSON 解析。
  factory TileQuestConfig.from_json(Map<String, dynamic> json) {
    return TileQuestConfig(
      id: _parse_int(json['id']),
      difficulty: _parse_double(json['difficulty']),
      game_switch: _parse_switch(json['game_switch']),
    );
  }

  /// 安全解析 int 类型。
  static int _parse_int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// 安全解析 double 类型。
  static double _parse_double(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  /// 安全解析开关值。
  ///
  /// 非法值（不在 1-5 区间内）一律回退 [SwitchValue.on]，保证游戏默认可见。
  static int _parse_switch(dynamic value) {
    final int parsed = _parse_int(value);
    if (parsed < SwitchValue.off || parsed > SwitchValue.web_only) {
      return SwitchValue.on;
    }
    return parsed;
  }

  /// 当前平台是否显示游戏入口。
  ///
  /// 复用 [ProjectConfig.is_enabled_for_environment] 的平台判断，
  /// 保证与 App 其它入口开关（创作者中心、分享、客服等）行为完全一致。
  bool get is_game_enabled => ProjectConfig.is_enabled_for_environment(
    game_switch,
    currentEnvironment,
  );

  /// 判断指定开关在当前运行环境是否启用。
  ///
  /// [switch_value] 为后端开关值（1-5）。
  /// 暴露成静态方法便于在不构造实例的地方复用。
  static bool is_enabled(int switch_value) {
    return ProjectConfig.is_enabled_for_environment(
      switch_value,
      currentEnvironment,
    );
  }
}
