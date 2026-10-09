import 'package:app/api/creator_workspace.dart';
import 'package:app/pages/work_editor/workspace/creation_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('创建结果未知时复用原标识和快照，不能重复创建改名后的作品', () async {
    final requests = <Map<String, dynamic>>[];
    final creation = WorkspaceCreationRequest(
      call: (_, parameters) async {
        requests.add(parameters);
        if (requests.length == 1) throw const CreatorWorkspaceException('超时');
        return {'novel_id': 1};
      },
    );
    await expectLater(
      creation.create(title: '原作品', work_type: 1, language_id: 10),
      throwsA(isA<CreatorWorkspaceException>()),
    );
    expect(creation.has_pending, isTrue);
    await creation.create(title: '后续输入', work_type: 2, language_id: 20);
    expect(requests[1], requests[0]);
    expect(creation.has_pending, isFalse);
  });

  test('明确拒绝后解锁表单，修正参数使用新创建标识', () async {
    final requests = <Map<String, dynamic>>[];
    final creation = WorkspaceCreationRequest(
      call: (_, parameters) async {
        requests.add(parameters);
        if (requests.length == 1) {
          throw const CreatorWorkspaceException('标题无效', serverRejected: true);
        }
        return {'novel_id': '2'};
      },
    );
    await expectLater(
      creation.create(title: '', work_type: 1, language_id: 10),
      throwsA(isA<CreatorWorkspaceException>()),
    );
    expect(creation.has_pending, isFalse);
    await creation.create(title: '修正', work_type: 2, language_id: 20);
    expect(requests[1]['request_key'], isNot(requests[0]['request_key']));
    expect(requests[1]['title'], '修正');
    expect(requests[1]['work_language_id'], 20);
  });

  test('成功响应缺少作品ID时不进入空工作台，保留请求重试确认身份', () async {
    final keys = <Object?>[];
    final creation = WorkspaceCreationRequest(
      call: (_, parameters) async {
        keys.add(parameters['request_key']);
        return keys.length == 1 ? {} : {'novel_id': 3};
      },
    );
    await expectLater(
      creation.create(title: '作品', work_type: 1, language_id: 10),
      throwsA(isA<CreatorWorkspaceException>()),
    );
    expect(creation.has_pending, isTrue);
    final result = await creation.create(
      title: '作品',
      work_type: 1,
      language_id: 10,
    );
    expect(result['novel_id'], 3);
    expect(keys[1], keys[0]);
  });
}
