// ignore_for_file: non_constant_identifier_names

import 'package:app/components/recommend_book_card/animated_waterfall.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('瀑布流必须同时持有稳定全局 ID 与主题状态', () {
    const AnimatedRecommendWaterfall waterfall = AnimatedRecommendWaterfall(
      waterfall_id: 'contract_test',
      is_dark: true,
    );

    expect(waterfall.waterfall_id, 'contract_test');
    expect(waterfall.is_dark, isTrue);
  });
}
