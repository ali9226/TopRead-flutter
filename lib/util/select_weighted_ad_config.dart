// ignore_for_file: non_constant_identifier_names

import 'dart:math';

import 'package:app/models/ad_config.dart';

/// 按正权重从广告配置列表中选择一个配置。
///
/// [configs] 必须是已经完成业务场景和广告商筛选的候选列表。
/// [random_value] 仅用于测试固定随机结果，默认由系统生成0（含）到1（不含）的值。
/// 空列表或总权重无效时返回null。
AdConfig? select_weighted_ad_config(
  List<AdConfig> configs, {
  double? random_value,
}) {
  if (configs.isEmpty) return null;

  final int total_weight = configs.fold<int>(
    0,
    (int total, AdConfig config) => total + config.weight,
  );
  if (total_weight <= 0) return null;

  final double normalized_random = (random_value ?? Random().nextDouble())
      .clamp(0.0, 1.0)
      .toDouble();
  double target_weight = normalized_random * total_weight;

  for (final AdConfig config in configs) {
    target_weight -= config.weight;
    if (target_weight < 0) return config;
  }

  // TODO random_value等于上边界1时返回最后一个配置，避免测试注入越界值造成空结果。
  return configs.last;
}
