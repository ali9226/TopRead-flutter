import 'package:app/pages/short_story_read/utils/resolve_native_ad_insert_index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('完整正文按指定百分比计算广告段落位置', () {
    expect(
      resolve_native_ad_insert_index(
        paragraph_count: 12,
        has_native_ad: true,
        display_ratio: 1 / 3,
      ),
      4,
    );
  });

  test('短正文和无广告配置时不插入广告', () {
    expect(
      resolve_native_ad_insert_index(
        paragraph_count: 3,
        has_native_ad: true,
        display_ratio: 1 / 3,
      ),
      isNull,
    );
    expect(
      resolve_native_ad_insert_index(
        paragraph_count: 12,
        has_native_ad: false,
        display_ratio: 1 / 3,
      ),
      isNull,
    );
  });

  test('正文段落检测忽略空行', () {
    expect(can_insert_native_ad('第一段\n\n第二段\n第三段\n第四段'), isTrue);
    expect(can_insert_native_ad('第一段\n\n第二段\n第三段'), isFalse);
  });
}
