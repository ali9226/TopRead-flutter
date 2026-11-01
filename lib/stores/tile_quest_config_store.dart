import 'package:get/get.dart';
import 'package:app/models/tile_quest_config.dart';

/// 拼图闯关游戏配置仓库。
///
/// 统一缓存 `redis/get` 接口返回的 `tile_quest_config`，
/// 供个人中心游戏入口等模块读取「是否显示游戏」和难度配置。
///
/// 与 [ProjectConfigStore] 的分工：
/// - [ProjectConfigStore] 管 App 级开关（广告 / 评论 / 分享等）。
/// - 本仓库只管拼图闯关这一个游戏的配置。
class TileQuestConfigStore extends GetxController {
  /// 当前游戏配置。
  ///
  /// 默认值是 [TileQuestConfig.empty]，其 `game_switch` 为「全部平台开启」，
  /// 保证配置未加载完成前游戏入口不会被误隐藏。
  final Rx<TileQuestConfig> config = TileQuestConfig.empty().obs;

  /// 保存游戏配置。
  ///
  /// [new_config] 为接口返回的最新配置数据。
  void save_config(TileQuestConfig new_config) {
    config.value = new_config;
  }

  /// 获取当前配置。
  TileQuestConfig get current => config.value;

  /// 当前平台是否显示游戏入口。
  ///
  /// 组合响应式读取，配合 `Obx` 使用时，
  /// 后端开关变更（配置下发）会自动触发入口的显隐刷新。
  bool get is_game_enabled => config.value.is_game_enabled;
}
