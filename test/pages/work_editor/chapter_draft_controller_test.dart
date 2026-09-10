import 'dart:async';
import 'package:app/pages/work_editor/single_chapter/logic.dart';
import 'package:app/api/creator_workspace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('保存过程中继续输入，不误清除后来的文字和恢复副本', () async {
    final response = Completer<Map<String, dynamic>>();
    Map<String, dynamic>? backup;
    final draft = ChapterDraftController(
      revisionId: 1,
      lockVersion: 0,
      initial: {'title': '章', 'content': '旧文'},
      send: (_) => response.future,
      writeRecovery: (v) async => backup = v,
      clearRecovery: () async => backup = null,
      debounce: const Duration(days: 1),
    );
    addTearDown(draft.dispose);
    draft.update('章', '第一段');
    final saving = draft.save();
    draft.update('章', '第一段\n后续😀');
    response.complete({'lock_version': 1});
    await saving;
    await draft.flushLocal();
    expect(draft.saved['content'], '第一段');
    expect(draft.dirty, isTrue);
    expect(backup?['content'], '第一段\n后续😀');
  });
  test('本机写入失败不能声称恢复副本已经保存', () async {
    var fail = false;
    final draft = ChapterDraftController(
      revisionId: 1,
      lockVersion: 0,
      initial: {'title': '章', 'content': ''},
      send: (_) async => throw Exception('离线'),
      writeRecovery: (_) async {
        if (fail) throw Exception('磁盘不可写');
      },
      clearRecovery: () async {},
      debounce: const Duration(days: 1),
    );
    addTearDown(draft.dispose);
    draft.update('章', '甲');
    await draft.flushLocal();
    expect(draft.localBackupReady, isTrue);
    fail = true;
    draft.update('章', '甲乙');
    await draft.flushLocal();
    expect(draft.localBackupReady, isFalse);
    expect(draft.values['content'], '甲乙');
  });

  test('响应丢失重试同一请求，再保存后续输入', () async {
    final sent = <Map<String, dynamic>>[];
    final draft = ChapterDraftController(
      revisionId: 1,
      lockVersion: 0,
      initial: {'title': '章', 'content': ''},
      send: (v) async {
        sent.add(v);
        if (sent.length == 1) throw Exception('网络中断');
        return {'lock_version': sent.length - 1};
      },
      writeRecovery: (_) async {},
      clearRecovery: () async {},
      debounce: const Duration(days: 1),
    );
    addTearDown(draft.dispose);
    draft.update('章', '甲');
    await draft.save();
    draft.update('章', '乙');
    await draft.save();
    expect(sent[1], sent[0]);
    expect(draft.dirty, isTrue);
    await draft.save();
    expect(sent[2]['content'], '乙');
    expect(sent[2]['lock_version'], 1);
    expect(sent[2]['request_key'], isNot(sent[0]['request_key']));
    expect(draft.dirty, isFalse);
  });
  test('服务器明确拒绝后可修改内容，冲突必须先比较才能继续保存', () async {
    var requests = 0;
    final draft = ChapterDraftController(
      revisionId: 1,
      lockVersion: 0,
      initial: {'title': '', 'content': ''},
      send: (v) async {
        requests++;
        if (requests == 1)
          throw const CreatorWorkspaceException('标题过长', serverRejected: true);
        if (requests == 2)
          throw const CreatorWorkspaceException('版本冲突', serverRejected: true);
        expect(v['content'], '保留本机内容');
        expect(v['lock_version'], 3);
        return {'lock_version': 4};
      },
      writeRecovery: (_) async {},
      clearRecovery: () async {},
      debounce: const Duration(days: 1),
    );
    addTearDown(draft.dispose);
    draft.update('超长标题', '保留本机内容');
    await draft.save();
    draft.update('短标题', '保留本机内容');
    await draft.save();
    await draft.save();
    expect(requests, 2);
    expect(draft.conflict, isTrue);
    draft.acceptServerVersion(3, {'title': '其他设备', 'content': '云端改动'});
    await draft.save();
    expect(requests, 3);
    expect(draft.dirty, isFalse);
  });
}
