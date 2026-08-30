import 'package:flutter_test/flutter_test.dart';
import 'package:app/pages/short_story_read/utils/native_ad_visibility.dart';

void main() {
  test('广告顶部刚进入屏幕底部即允许挂载', () {
    expect(
      should_attach_native_ad(
        slot_top: 776,
        slot_height: 460,
        viewport_top: 100,
        viewport_bottom: 800,
        minimum_visible_extent: 24,
      ),
      isTrue,
    );
    expect(
      should_attach_native_ad(
        slot_top: 777,
        slot_height: 460,
        viewport_top: 100,
        viewport_bottom: 800,
        minimum_visible_extent: 24,
      ),
      isFalse,
    );
  });

  test('广告在屏幕中间或从顶部部分离开时仍可挂载', () {
    expect(
      should_attach_native_ad(
        slot_top: 300,
        slot_height: 460,
        viewport_top: 100,
        viewport_bottom: 800,
        minimum_visible_extent: 24,
      ),
      isTrue,
    );
    expect(
      should_attach_native_ad(
        slot_top: -330,
        slot_height: 460,
        viewport_top: 100,
        viewport_bottom: 800,
        minimum_visible_extent: 24,
      ),
      isTrue,
    );
  });

  test('广告完全远离可视区域时不挂载', () {
    expect(
      should_attach_native_ad(
        slot_top: 900,
        slot_height: 460,
        viewport_top: 100,
        viewport_bottom: 800,
        minimum_visible_extent: 24,
      ),
      isFalse,
    );
    expect(
      should_attach_native_ad(
        slot_top: -600,
        slot_height: 460,
        viewport_top: 100,
        viewport_bottom: 800,
        minimum_visible_extent: 24,
      ),
      isFalse,
    );
  });
}
