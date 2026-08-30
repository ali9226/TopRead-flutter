import 'dart:math' as math;

/// 全应用共用的百分比概率判断器。
class PercentageProbability {
  PercentageProbability._();

  /// 复用同一个随机数生成器，避免连续创建实例造成无意义开销。
  static final math.Random _random = math.Random();

  /// 按 [percentage]（0～100）判断本次是否命中。
  ///
  /// [roll] 仅用于测试，合法范围为 0～99；线上调用不传时自动生成。
  static bool is_hit(int percentage, {int? roll}) {
    final int safe_percentage = percentage.clamp(0, 100);
    if (safe_percentage == 0) return false;
    if (safe_percentage == 100) return true;

    final int resolved_roll = roll ?? _random.nextInt(100);
    assert(resolved_roll >= 0 && resolved_roll < 100);
    return resolved_roll < safe_percentage;
  }
}
