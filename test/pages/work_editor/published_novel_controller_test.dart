// ignore_for_file: non_constant_identifier_names
import 'package:app/api/creator_workspace.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/published_long_novel_editor/logic.dart';
import 'package:flutter_test/flutter_test.dart';

CreatorWorkDraft work() => CreatorWorkDraft(
  local_id: '1',
  novel_id: 1,
  novel_language_id: 2,
  revision_id: 3,
  language_id: 1,
  title: 'Original',
  introduction: 'Intro',
  work_type: CreatorWorkType.long,
  is_completed: false,
  language_code: 'zh',
  category_ids: [120],
  short_content: '',
  chapters: [],
  status: CreatorWorkStatus.published,
  release_mode: CreatorReleaseMode.immediate,
  scheduled_publish_time: null,
  update_time: DateTime(2026),
  preferences: {
    '2': [120],
    '4': [115],
  },
);

void main() {
  test('loads all metadata in one request and sorts both directions', () async {
    final requests = <Map<String, dynamic>>[];
    final model = PublishedNovelController(
      1,
      load_work: (_) async => work(),
      call: (path, params) async {
        expect(path, 'creator_chapter/directory');
        requests.add(params);
        return {
          'list': [
            {'chapter_id': 1, 'chapter_no': 1, 'title': '1'},
            {'revision_id': 5, 'title': 'Unpublished draft'},
            {
              'chapter_id': 2,
              'chapter_no': 2,
              'title': 'Unsaved',
              'published_title': '2',
            },
            {
              'revision_id': 6,
              'chapter_no': 0,
              'title': 'Scheduled',
              'is_scheduled': 1,
            },
          ],
        };
      },
    );
    addTearDown(model.dispose);
    await model.load();
    expect(requests.length, 1);
    expect(requests.single['all'], true);
    expect(requests.single.containsKey('page'), false);
    expect(model.visible_chapters.map((r) => r['title']), [
      'Scheduled',
      '2',
      '1',
    ]);
    model.descending = false;
    expect(model.visible_chapters.map((r) => r['title']), [
      '1',
      '2',
      'Scheduled',
    ]);
  });

  test(
    'dragging submits complete order once and retains request on timeout',
    () async {
      final requests = <Map<String, dynamic>>[];
      final model = PublishedNovelController(
        1,
        load_work: (_) async => work(),
        call: (path, params) async {
          if (path.endsWith('directory'))
            return {
              'list': [
                {'chapter_id': 1, 'chapter_no': 1},
                {'chapter_id': 2, 'chapter_no': 2},
                {'chapter_id': 3, 'chapter_no': 3},
                {'revision_id': 9, 'is_scheduled': true},
              ],
            };
          expect(path, 'creator_chapter/reorder');
          requests.add(Map.of(params));
          if (requests.length == 1)
            throw const CreatorWorkspaceException('timeout');
          return {};
        },
      );
      addTearDown(model.dispose);
      await model.load();
      model.toggle_ordering();
      expect(model.visible_chapters.length, 3);
      model.reorder(0, 2);
      expect(model.visible_chapters.map((r) => r['chapter_id']), [2, 3, 1]);
      expect(model.dirty, true);
      await expectLater(
        model.update_order(),
        throwsA(isA<CreatorWorkspaceException>()),
      );
      expect(model.locked, true);
      expect(model.pending_section, 2);
      await model.update_order();
      expect(requests[0]['chapter_ids'], [2, 3, 1]);
      expect(requests[0]['base_order'], [1, 2, 3]);
      expect(requests[1], requests[0]);
      expect(model.order_dirty, false);
    },
  );

  test(
    'each update isolates unsaved input in the other tab and advances version',
    () async {
      final requests = <Map<String, dynamic>>[];
      var server = work();
      final model = PublishedNovelController(
        1,
        load_work: (_) async => server,
        call: (path, params) async {
          if (path.endsWith('directory')) return {'list': []};
          requests.add(Map.of(params));
          server = server.copy_with(
            title: params['title'],
            revision_id: server.revision_id! + 1,
            category_ids: (params['category_snapshot'] as List)
                .map<int>((r) => r['category_id'] as int)
                .toList(),
          );
          return {};
        },
      );
      addTearDown(model.dispose);
      await model.load();
      model.title.text = 'New title';
      model.preferences[2] = {121};
      model.settings_dirty = true;
      await model.update_section(0);
      expect(requests[0]['category_snapshot'], [
        {'category_id': 120},
      ]);
      expect(model.preferences[2], {121});
      expect(model.settings_dirty, true);
      await model.update_section(1);
      expect(requests[1]['title'], 'New title');
      expect(requests[1]['base_revision_id'], 4);
      expect(requests[1]['category_snapshot'], [
        {'category_id': 121},
      ]);
    },
  );

  test(
    'unknown network outcome retries identical snapshot and request key',
    () async {
      final requests = <Map<String, dynamic>>[];
      final model = PublishedNovelController(
        1,
        load_work: (_) async => work(),
        call: (path, params) async {
          if (path.endsWith('directory')) return {'list': []};
          requests.add(Map.of(params));
          if (requests.length == 1) {
            throw const CreatorWorkspaceException('Network timeout');
          }
          return {};
        },
      );
      addTearDown(model.dispose);
      await model.load();
      model.title.text = 'New title';
      await expectLater(
        model.update_section(0),
        throwsA(isA<CreatorWorkspaceException>()),
      );
      expect(model.locked, true);
      await model.update_section(1);
      expect(requests.length, 1);
      await model.update_section(0);
      expect(requests[1], requests[0]);
      expect(model.locked, false);
    },
  );
}
