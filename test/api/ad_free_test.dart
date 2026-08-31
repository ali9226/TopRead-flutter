import 'package:app/api/ad_free.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdFreeStatus.fromJson', () {
    test('解析标准布尔值和数字秒数', () {
      final AdFreeStatus status = AdFreeStatus.fromJson(<String, dynamic>{
        'is_ad_free': true,
        'expire_time': '2026-08-30T15:30:00Z',
        'remaining_seconds': 1800,
      });

      expect(status.is_ad_free, isTrue);
      expect(status.expire_time, '2026-08-30T15:30:00Z');
      expect(status.remaining_seconds, 1800);
    });

    test('兼容数据库驱动返回的字符串数值', () {
      final AdFreeStatus status = AdFreeStatus.fromJson(<String, dynamic>{
        'is_ad_free': '1',
        'expire_time': '2026-08-30T15:30:00Z',
        'remaining_seconds': '1799',
      });

      expect(status.is_ad_free, isTrue);
      expect(status.remaining_seconds, 1799);
    });
  });

  test('解锁响应解析为强类型广告配置', () {
    final UnlockAdFreeResult result = UnlockAdFreeResult.fromJson(
      <String, dynamic>{
        'ad_config': <String, dynamic>{
          'id': 10,
          'ads_id': 'ca-app-pub-test/rewarded',
          'show_number': 9,
          'notification_number': 0,
          'ads_type': 9,
          'advertisers': 1,
          'weight': 100,
          'ads_type_str': '长篇激励视频',
          'advertisers_str': '谷歌广告商',
          'uuid': 'reward-uuid',
        },
        'ad_free_status': <String, dynamic>{
          'is_ad_free': false,
          'expire_time': null,
          'remaining_seconds': 0,
        },
        'duration_minutes': '30',
      },
    );

    expect(result.ad_config?.adsId, 'ca-app-pub-test/rewarded');
    expect(result.ad_config?.uuid, 'reward-uuid');
    expect(result.ad_free_status?.is_ad_free, isFalse);
    expect(result.duration_minutes, 30);
  });
}
