import 'package:app/util/percentage_probability.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('0% 永不命中且 100% 永远命中', () {
    expect(PercentageProbability.is_hit(0, roll: 0), isFalse);
    expect(PercentageProbability.is_hit(100, roll: 99), isTrue);
  });

  test('百分比使用 0～99 的左闭右开区间判断', () {
    expect(PercentageProbability.is_hit(35, roll: 34), isTrue);
    expect(PercentageProbability.is_hit(35, roll: 35), isFalse);
  });

  test('越界配置会被安全限制到 0～100', () {
    expect(PercentageProbability.is_hit(-1, roll: 0), isFalse);
    expect(PercentageProbability.is_hit(101, roll: 99), isTrue);
  });
}
