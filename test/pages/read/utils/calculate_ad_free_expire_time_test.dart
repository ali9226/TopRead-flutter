import 'package:app/pages/read/utils/calculate_ad_free_expire_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 8, 30, 12);

  test('没有有效时长时从当前时间开始计算', () {
    final DateTime result = calculate_ad_free_expire_time(
      now: now,
      duration_minutes: 30,
    );

    expect(result, DateTime.utc(2026, 8, 30, 12, 30));
  });

  test('当前页面已有有效时长时继续叠加', () {
    final DateTime result = calculate_ad_free_expire_time(
      now: now,
      current_expire_time: DateTime.utc(2026, 8, 30, 12, 20),
      duration_minutes: 30,
    );

    expect(result, DateTime.utc(2026, 8, 30, 12, 50));
  });

  test('服务端到期时间更晚时以服务端时间为叠加起点', () {
    final DateTime result = calculate_ad_free_expire_time(
      now: now,
      current_expire_time: DateTime.utc(2026, 8, 30, 12, 10),
      server_expire_time: DateTime.utc(2026, 8, 30, 13),
      duration_minutes: 60,
    );

    expect(result, DateTime.utc(2026, 8, 30, 14));
  });

  test('已过期时间不会从过去继续叠加', () {
    final DateTime result = calculate_ad_free_expire_time(
      now: now,
      current_expire_time: DateTime.utc(2026, 8, 30, 11),
      server_expire_time: DateTime.utc(2026, 8, 30, 11, 30),
      duration_minutes: 30,
    );

    expect(result, DateTime.utc(2026, 8, 30, 12, 30));
  });

  test('新版后端返回时长时使用服务端值', () {
    final int result = resolve_ad_free_reward_duration(
      requested_duration_minutes: 30,
      response_duration_minutes: 60,
    );

    expect(result, 60);
  });

  test('旧版后端缺少时长字段时回退到请求值', () {
    final int result = resolve_ad_free_reward_duration(
      requested_duration_minutes: 30,
      response_duration_minutes: 0,
    );

    expect(result, 30);
  });
}
