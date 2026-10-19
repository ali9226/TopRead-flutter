// ignore_for_file: constant_identifier_names

/// 揭开牌面只改变共享图集的混合权重，不引入逐牌图层或模糊。
class QuestRevealStyle {
  const QuestRevealStyle._();

  /// 完整遮罩退去的时长；短于入槽飞行，连点仍能看清下层逐渐亮起。
  static const double duration_ms = 220;
}
