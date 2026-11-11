import 'package:app/models/patch_check_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppPatchCheckResult.from_json', () {
    test('未知动作与无效序号不能触发下载安装', () {
      for (final payload in <Map<String, dynamic>>[
        {'action': 'unexpected', 'patch_id': 1, 'seq': 1},
        {'action': 'patch', 'patch_id': 1, 'seq': 0},
        {'action': 'withdraw', 'patch_id': 1, 'seq': -1},
      ]) {
        expect(AppPatchCheckResult.from_json(payload).has_update, isFalse);
      }
    });
    test('解析补丁决策字段', () {
      final AppPatchCheckResult result =
          AppPatchCheckResult.from_json(<String, dynamic>{
            'action': 'patch',
            'patch_id': 7,
            'file_name': '24-arm64-v8a.fptc',
            'seq': 1712345678,
          });

      expect(result.action, 'patch');
      expect(result.patch_id, 7);
      expect(result.file_name, '24-arm64-v8a.fptc');
      expect(result.seq, 1712345678);
      expect(result.has_update, isTrue);
    });

    test('回滚文件同样视为可更新', () {
      final AppPatchCheckResult result =
          AppPatchCheckResult.from_json(<String, dynamic>{
            'action': 'withdraw',
            'patch_id': 9,
            'file_name': '24-arm64-v8a.fptc',
            'seq': 1712345679,
          });

      expect(result.has_update, isTrue);
    });

    test('无补丁时 has_update 为 false', () {
      final AppPatchCheckResult result = AppPatchCheckResult.from_json(
        <String, dynamic>{'action': 'none'},
      );

      expect(result.action, 'none');
      expect(result.patch_id, 0);
      expect(result.seq, 0);
      expect(result.has_update, isFalse);
    });

    test('缺少字段时回落默认值', () {
      final AppPatchCheckResult result = AppPatchCheckResult.from_json(
        <String, dynamic>{},
      );

      expect(result.action, 'none');
      expect(result.patch_id, 0);
      expect(result.file_name, '');
      expect(result.seq, 0);
      expect(result.has_update, isFalse);
    });

    test('数值类型兼容 int 与 double', () {
      final AppPatchCheckResult result =
          AppPatchCheckResult.from_json(<String, dynamic>{
            'action': 'patch',
            'patch_id': 3.0,
            'file_name': '1-ios-arm64.fptc',
            'seq': 1712345678.0,
          });

      expect(result.patch_id, 3);
      expect(result.seq, 1712345678);
    });

    test('BIGINT 序列化成字符串数字时仍可解析', () {
      final AppPatchCheckResult result =
          AppPatchCheckResult.from_json(<String, dynamic>{
            'action': 'patch',
            'patch_id': '7',
            'file_name': '24-arm64-v8a.fptc',
            'seq': '1712345678',
            'hotfix_version': '3',
          });

      expect(result.patch_id, 7);
      expect(result.seq, 1712345678);
      expect(result.hotfix_version, 3);
      expect(result.has_update, isTrue);
    });

    test('热更版本字段解析与默认值', () {
      final AppPatchCheckResult result = AppPatchCheckResult.from_json(
        <String, dynamic>{
          'action': 'patch',
          'patch_id': 7,
          'seq': 1712345678,
          'hotfix_version': 2,
        },
      );
      expect(result.hotfix_version, 2);

      final AppPatchCheckResult missing = AppPatchCheckResult.from_json(
        <String, dynamic>{'action': 'none'},
      );
      expect(missing.hotfix_version, 0);
    });
  });
}
