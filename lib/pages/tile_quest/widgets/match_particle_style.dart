// ignore_for_file: constant_identifier_names

/// 碎粒材质的消散参数；解析多项式避免每粒逐帧求解贝塞尔和幂函数。
class QuestMatchParticleStyle {
  const QuestMatchParticleStyle._();

  static const double fade_linear = .48;
  static const double fade_quadratic = .78;
  static const double fade_cubic = -.26;
  static const double shrink_fraction = .94;
}
