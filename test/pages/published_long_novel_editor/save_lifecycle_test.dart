import 'dart:async';

import 'package:app/api/creator_workspace.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/published_long_novel_editor/logic.dart';
import 'package:app/pages/published_long_novel_editor/style.dart';
import 'package:app/stores/preference_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

CreatorWorkDraft _work() => CreatorWorkDraft(
  local_id: 'work_1',
  novel_id: 1,
  revision_id: 10,
  novel_language_id: 20,
  language_id: 30,
  title: '原始标题',
  introduction: '简介',
  work_type: CreatorWorkType.long,
  is_completed: false,
  language_code: 'zh',
  category_ids: [1],
  short_content: '',
  chapters: [],
  status: CreatorWorkStatus.published,
  release_mode: CreatorReleaseMode.immediate,
  scheduled_publish_time: null,
  update_time: DateTime(2026),
);

/// 模拟每次发布生成新公开修订，目录与设置必须排在资料确认之后。
class _Backend {
  CreatorWorkDraft cloud = _work();
  final requests = <({String path, Map<String, dynamic> parameters})>[];
  Future<void> Function(String, Map<String, dynamic>)? before_call;
  final chapters = <Map<String, dynamic>>[
    {'chapter_id': 1, 'chapter_no': 1},
    {'chapter_id': 2, 'chapter_no': 2},
  ];

  Future<Map<String, dynamic>> call(
    String path,
    Map<String, dynamic> parameters,
  ) async {
    requests.add((path: path, parameters: Map.of(parameters)));
    await before_call?.call(path, parameters);
    if (path.endsWith('publish_long')) {
      cloud = cloud.copy_with(
        title: parameters['title'] as String,
        introduction: parameters['introduction'] as String,
        revision_id: cloud.revision_id! + 1,
        is_completed: parameters['serialization_status'] == 2,
      );
    }
    return path.endsWith('directory') ? {'list': chapters} : {};
  }

  Future<PublishedNovelController> create() async {
    final model = PublishedNovelController(
      1,
      call: call,
      load_work: (_) async => cloud,
    );
    await model.load();
    requests.clear();
    addTearDown(model.dispose);
    return model;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
    Get.put(PreferenceStore());
  });
  tearDown(Get.reset);

  test('保存退出串行确认资料、设置和目录，更新后的修订作为后续基线', () async {
    final backend = _Backend();
    final model = await backend.create();
    model.title.text = '修改标题';
    model.toggle_preference(
      PublishedEditorStyle.status_group,
      PublishedEditorStyle.completed_item,
    );
    model.toggle_ordering();
    model.reorder(0, 1);
    final first_save = Completer<void>();
    backend.before_call = (path, _) async {
      if (path.endsWith('publish_long') && backend.requests.length == 1)
        await first_save.future;
    };

    var finished = false;
    final saving = model.save_changes().then((value) {
      finished = value;
      return value;
    });
    await Future<void>.delayed(Duration.zero);
    expect(backend.requests, hasLength(1));
    expect(finished, isFalse);
    first_save.complete();
    expect(await saving, isTrue);

    expect(backend.requests.map((r) => r.path), [
      'creator_work/publish_long',
      'creator_work/publish_long',
      'creator_chapter/reorder',
      'creator_chapter/directory',
    ]);
    expect(backend.requests[0].parameters['base_revision_id'], 10);
    expect(backend.requests[1].parameters['base_revision_id'], 11);
    expect(backend.requests[1].parameters['title'], '修改标题');
    expect(model.dirty, isFalse);
  });

  test('保存途中失败不报告可退出，后续设置与目录及请求快照完整保留', () async {
    final backend = _Backend();
    final model = await backend.create();
    model.title.text = '修改标题';
    model.toggle_preference(
      PublishedEditorStyle.status_group,
      PublishedEditorStyle.completed_item,
    );
    model.toggle_ordering();
    model.reorder(0, 1);
    backend.before_call = (_, _) async {
      throw const CreatorWorkspaceException('超时');
    };
    await expectLater(
      model.save_changes(),
      throwsA(isA<CreatorWorkspaceException>()),
    );
    expect(backend.requests, hasLength(1));
    expect(
      model.details_dirty && model.settings_dirty && model.order_dirty,
      isTrue,
    );
    expect(model.pending_section, 0);
    final key = backend.requests.single.parameters['request_key'];

    backend.before_call = null;
    expect(await model.save_changes(), isTrue);
    expect(backend.requests[1].parameters['request_key'], key);
    expect(model.pending_section, isNull);
  });

  test('旧保存响应不能清除请求期间新输入的未保存状态', () async {
    final backend = _Backend();
    final model = await backend.create();
    model.title.text = '第一版';
    final response = Completer<void>();
    backend.before_call = (_, _) => response.future;
    final saving = model.update_section(0);
    model.title.text = '新增文字';
    response.complete();
    await saving;
    expect(model.saved!.title, '第一版');
    expect(model.title.text, '新增文字');
    expect(model.details_dirty, isTrue);
  });

  test('资料成功但设置失败时停止排序，重试从失败设置继续确认', () async {
    final backend = _Backend();
    final model = await backend.create();
    model.title.text = '修改标题';
    model.toggle_preference(
      PublishedEditorStyle.status_group,
      PublishedEditorStyle.completed_item,
    );
    model.toggle_ordering();
    model.reorder(0, 1);
    backend.before_call = (_, _) async {
      if (backend.requests.length == 2) {
        throw const CreatorWorkspaceException('设置保存超时');
      }
    };
    await expectLater(
      model.save_changes(),
      throwsA(isA<CreatorWorkspaceException>()),
    );
    expect(model.details_dirty, isFalse);
    expect(model.settings_dirty && model.order_dirty, isTrue);
    expect(model.pending_section, 1);
    expect(backend.requests, hasLength(2));
    final pending_key = backend.requests[1].parameters['request_key'];

    backend.before_call = null;
    expect(await model.save_changes(), isTrue);
    expect(backend.requests[2].parameters['request_key'], pending_key);
    expect(backend.requests[2].parameters['base_revision_id'], 11);
    expect(model.dirty, isFalse);
  });

  test('未知结果的旧请求重试成功后不能抹去后续输入，随后保存新快照', () async {
    final backend = _Backend();
    final model = await backend.create();
    model.title.text = '第一版';
    backend.before_call = (_, _) async {
      throw const CreatorWorkspaceException('超时');
    };
    await expectLater(
      model.update_section(0),
      throwsA(isA<CreatorWorkspaceException>()),
    );
    model.title.text = '后续新输入';
    backend.before_call = null;
    await model.update_section(0);
    expect(model.saved!.title, '第一版');
    expect(model.details_dirty, isTrue);
    expect(await model.save_changes(), isTrue);
    expect(model.saved!.title, '后续新输入');
  });
}
