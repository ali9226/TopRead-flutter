import 'package:flutter_test/flutter_test.dart';

import 'package:app/pages/read/utils/can_process_read_ads.dart';

void main() {
  test('免广告状态未初始化时屏蔽所有阅读页广告逻辑', () {
    expect(
      can_process_read_ads(is_ad_free_status_ready: false, is_ad_free: false),
      isFalse,
    );
  });

  test('有效期内屏蔽原生广告和免时长弹窗', () {
    expect(
      can_process_read_ads(is_ad_free_status_ready: true, is_ad_free: true),
      isFalse,
    );
  });

  test('状态已初始化且不在有效期时允许广告逻辑', () {
    expect(
      can_process_read_ads(is_ad_free_status_ready: true, is_ad_free: false),
      isTrue,
    );
  });
}
