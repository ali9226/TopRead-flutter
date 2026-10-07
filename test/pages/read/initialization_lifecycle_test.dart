// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/api/results_type.dart';
import 'package:app/models/novel_info.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/pages/read/utils/chapter_cache.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:flutter_test/flutter_test.dart';

ResultsType<T> _success<T>(T content) => ResultsType<T>()
  ..status = true
  ..content = content;

NovelInfo _info(String language_id) => NovelInfo.from_json({
  'id': '1',
  'title': language_id,
  'language_info': {'id': language_id, 'word_count': 100},
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NovelReadingStore store;
  late Logic logic;
  late String cache_namespace;
  late Set<String> cache_ids;
  late bool is_closed;

  NovelChapterInfo chapter(String id) {
    final chapter_id = '$cache_namespace-$id';
    cache_ids.add(chapter_id);
    return NovelChapterInfo.from_json({
      'id': chapter_id,
      'novel_language_id': id,
      'chapter_no': 1,
      'title': id,
      'word_count': 100,
    });
  }

  void close_logic() {
    if (is_closed) return;
    is_closed = true;
    logic.onClose();
  }

  void initialize({
    required NovelInfoLoader info_loader,
    required ChapterDirectoryLoader directory_loader,
    ChapterContentLoader? content_loader,
  }) {
    logic = Logic(
      story_id: 1,
      story_title: '测试小说',
      reading_store: store,
      initial_body_font_size: 18,
      initial_auto_read_speed: 0.2,
      novel_info_loader: info_loader,
      chapter_directory_loader: directory_loader,
      chapter_content_loader: content_loader ?? (id) async => '$id 正文',
      chapter_paragraph_metadata_loader: (_, {required novel_id}) async => null,
    );
    addTearDown(() async {
      close_logic();
      for (final id in cache_ids) {
        await ChapterCache.clear(id);
      }
    });
  }

  setUp(() {
    store = NovelReadingStore();
    cache_namespace = 'read-lifecycle-${DateTime.now().microsecondsSinceEpoch}';
    cache_ids = <String>{};
    is_closed = false;
  });

  test('旧详情晚于新刷新返回时不能覆盖新详情、目录和正文', () async {
    final old_response = Completer<ResultsType<NovelInfo>>();
    var info_requests = 0;
    final directory_requests = <String>[];
    initialize(
      info_loader: (_) {
        info_requests++;
        return info_requests == 1
            ? old_response.future
            : Future.value(_success(_info('new')));
      },
      directory_loader: (id) async {
        directory_requests.add(id);
        return _success([chapter(id)]);
      },
    );

    final old_load = logic.fetch_info();
    await logic.fetch_info(force: true);
    old_response.complete(_success(_info('old')));
    await old_load;

    expect(store.novel_info.value?.title, 'new');
    expect(store.chapter_list.single.title, 'new');
    expect(store.reading_items.last.text, contains('new'));
    expect(directory_requests, ['new']);
    expect(logic.is_loading.value, isFalse);
  });

  test('旧目录晚于新刷新返回时不能替换新目录', () async {
    final old_directory = Completer<ResultsType<List<NovelChapterInfo>>>();
    final directory_started = Completer<void>();
    var info_requests = 0;
    initialize(
      info_loader: (_) async =>
          _success(_info(++info_requests == 1 ? 'old' : 'new')),
      directory_loader: (id) async {
        if (id == 'old') {
          directory_started.complete();
          return old_directory.future;
        }
        return _success([chapter(id)]);
      },
    );

    final old_load = logic.fetch_info();
    await directory_started.future;
    await logic.fetch_info(force: true);
    old_directory.complete(_success([chapter('old')]));
    await old_load;

    expect(store.novel_info.value?.title, 'new');
    expect(store.chapter_list.single.title, 'new');
    expect(store.reading_items.last.text, contains('new'));
  });

  test('旧首章晚于新刷新返回时不能重建旧阅读窗口', () async {
    final old_content = Completer<String>();
    final content_started = Completer<void>();
    var info_requests = 0;
    final loaded_chapters = <int>[];
    initialize(
      info_loader: (_) async =>
          _success(_info(++info_requests == 1 ? 'old' : 'new')),
      directory_loader: (id) async => _success([chapter(id)]),
      content_loader: (id) async {
        if (id.endsWith('-old')) {
          content_started.complete();
          return old_content.future;
        }
        return '新正文';
      },
    );
    logic.on_chapter_loaded = loaded_chapters.add;

    final old_load = logic.fetch_info();
    await content_started.future;
    await logic.fetch_info(force: true);
    old_content.complete('旧正文');
    await old_load;

    expect(store.reading_items.last.text, '新正文');
    expect(store.get_cached_chapter_content(0), '新正文');
    expect(loaded_chapters, [0]);
    expect(logic.is_error.value, isFalse);
  });

  test('旧请求结束时不能关闭仍在加载的新刷新的骨架屏', () async {
    final old_response = Completer<ResultsType<NovelInfo>>();
    final new_response = Completer<ResultsType<NovelInfo>>();
    var info_requests = 0;
    initialize(
      info_loader: (_) =>
          ++info_requests == 1 ? old_response.future : new_response.future,
      directory_loader: (id) async => _success([chapter(id)]),
    );

    final old_load = logic.fetch_info();
    final new_load = logic.fetch_info(force: true);
    old_response.complete(ResultsType<NovelInfo>());
    await old_load;
    expect(logic.is_loading.value, isTrue);
    expect(logic.is_error.value, isFalse);

    new_response.complete(_success(_info('new')));
    await new_load;
    expect(logic.is_loading.value, isFalse);
  });

  test('刷新等待期间启动的旧窗口拼接不能污染已提交的新窗口', () async {
    final refresh_info = Completer<ResultsType<NovelInfo>>();
    final mutation_started = Completer<void>();
    final mutation_allowed = Completer<void>();
    var info_requests = 0;
    initialize(
      info_loader: (_) => ++info_requests == 1
          ? Future.value(_success(_info('old')))
          : refresh_info.future,
      directory_loader: (id) async => _success([
        chapter('$id-first'),
        if (id == 'old') chapter('old-second'),
      ]),
    );
    await logic.fetch_info();
    logic.wait_until_chapter_mutation_allowed = () {
      mutation_started.complete();
      return mutation_allowed.future;
    };

    final refresh = logic.fetch_info(force: true, show_loading: false);
    final old_append = logic.load_next_chapter();
    await mutation_started.future;
    refresh_info.complete(_success(_info('new')));
    await refresh;
    mutation_allowed.complete();
    await old_append;

    expect(store.chapter_list.single.title, 'new-first');
    expect(store.reading_items.map((item) => item.chapter_index).toSet(), {0});
    expect(store.reading_items.last.text, contains('new-first'));
    expect(logic.loaded_chapter_index, 0);
  });

  test('刷新提交后同章节旧请求不能覆盖重新预加载的缓存', () async {
    final refresh_info = Completer<ResultsType<NovelInfo>>();
    final old_content = Completer<String>();
    final old_content_started = Completer<void>();
    var info_requests = 0;
    var second_chapter_requests = 0;
    final chapters = [chapter('first'), chapter('second')];
    initialize(
      info_loader: (_) => ++info_requests == 1
          ? Future.value(_success(_info('old')))
          : refresh_info.future,
      directory_loader: (_) async => _success(chapters),
      content_loader: (id) async {
        if (id == chapters.first.id) return '首章正文';
        second_chapter_requests++;
        if (second_chapter_requests == 1) return '';
        if (second_chapter_requests == 2) {
          old_content_started.complete();
          return old_content.future;
        }
        return '刷新后的第二章正文';
      },
    );
    await logic.fetch_info();
    // 等首次预加载的空结果结束，再让刷新期间的第二章请求保持未完成。
    await logic.load_next_chapter();
    final refresh = logic.fetch_info(
      force: true,
      show_loading: false,
      bypass_chapter_cache: true,
    );
    final old_append = logic.load_next_chapter();
    await old_content_started.future;
    refresh_info.complete(_success(_info('new')));
    await refresh;
    final jump_generation = await logic.jump_to_chapter(1);
    logic.complete_chapter_jump(jump_generation!);
    expect(store.get_cached_chapter_content(1), '刷新后的第二章正文');

    old_content.complete('刷新之前的第二章正文');
    await old_append;

    expect(store.get_cached_chapter_content(1), '刷新后的第二章正文');
    expect(store.reading_items.last.text, '刷新后的第二章正文');
  });

  for (final pending_stage in ['info', 'directory', 'content']) {
    test('页面关闭后未完成的 $pending_stage 请求不能继续写入阅读状态', () async {
      final pending_info = Completer<ResultsType<NovelInfo>>();
      final pending_directory =
          Completer<ResultsType<List<NovelChapterInfo>>>();
      final pending_content = Completer<String>();
      final stage_started = Completer<void>();
      var directory_requests = 0;
      var content_requests = 0;
      var loaded_callbacks = 0;
      initialize(
        info_loader: (_) async {
          if (pending_stage == 'info') {
            stage_started.complete();
            return pending_info.future;
          }
          return _success(_info('language'));
        },
        directory_loader: (id) async {
          directory_requests++;
          if (pending_stage == 'directory') {
            stage_started.complete();
            return pending_directory.future;
          }
          return _success([chapter(id)]);
        },
        content_loader: (_) async {
          content_requests++;
          stage_started.complete();
          return pending_content.future;
        },
      );
      logic.on_chapter_loaded = (_) => loaded_callbacks++;

      final load = logic.fetch_info();
      await stage_started.future;
      final previous_info = store.novel_info.value;
      final previous_chapters = store.chapter_list.toList();
      close_logic();
      if (pending_stage == 'info') {
        pending_info.complete(_success(_info('language')));
      } else if (pending_stage == 'directory') {
        pending_directory.complete(_success([chapter('language')]));
      } else {
        pending_content.complete('不能显示的正文');
      }
      await load;
      await logic.fetch_info(force: true);

      expect(store.novel_info.value, same(previous_info));
      expect(store.chapter_list, previous_chapters);
      expect(store.reading_items, isEmpty);
      expect(store.get_cached_chapter_content(0), isNull);
      expect(loaded_callbacks, 0);
      expect(directory_requests, pending_stage == 'info' ? 0 : 1);
      expect(content_requests, pending_stage == 'content' ? 1 : 0);
    });
  }

  test('首章加载抛出异常时结束骨架屏并允许重新加载', () async {
    var content_requests = 0;
    initialize(
      info_loader: (_) async => _success(_info('language')),
      directory_loader: (id) async => _success([chapter(id)]),
      content_loader: (_) async {
        if (++content_requests == 1) throw StateError('离线');
        return '重新加载成功';
      },
    );

    await logic.fetch_info();
    expect(logic.is_loading.value, isFalse);
    expect(logic.is_error.value, isTrue);
    expect(store.reading_items, isEmpty);

    await logic.fetch_info();
    expect(logic.is_error.value, isFalse);
    expect(store.reading_items.last.text, '重新加载成功');
  });

  test('首章返回空正文时不能显示只有章节标题的成功页面', () async {
    initialize(
      info_loader: (_) async => _success(_info('language')),
      directory_loader: (id) async => _success([chapter(id)]),
      content_loader: (_) async => '',
    );

    await logic.fetch_info();

    expect(logic.is_loading.value, isFalse);
    expect(logic.is_error.value, isTrue);
    expect(store.reading_items, isEmpty);
  });

  test('静默刷新目录失败时不重用旧目录或重置当前阅读章节', () async {
    var content_requests = 0;
    initialize(
      info_loader: (_) async => _success(_info('language')),
      directory_loader: (_) async => ResultsType<List<NovelChapterInfo>>(),
      content_loader: (_) async {
        content_requests++;
        return '不应加载';
      },
    );
    final old_chapter = chapter('old');
    store.set_chapter_list([old_chapter]);
    store.set_initial_content('旧章节', 1, 0, 0, 100, '原有正文');
    logic.current_chapter_db_id = 321;

    await logic.fetch_info(force: true, show_loading: false);

    expect(content_requests, 0);
    expect(store.reading_items.last.text, '原有正文');
    expect(logic.current_chapter_db_id, 321);
    expect(logic.is_loading.value, isFalse);
    expect(logic.is_error.value, isFalse);
  });

  for (final failure_kind in ['empty', 'exception']) {
    test('静默刷新首章 $failure_kind 时完整保留旧详情、目录、缓存和进度', () async {
      final new_content = Completer<String>();
      final new_content_started = Completer<void>();
      var info_requests = 0;
      final old_chapters = [chapter('old-first'), chapter('old-second')];
      final new_chapter = chapter('new-first');
      initialize(
        info_loader: (_) async =>
            _success(_info(++info_requests == 1 ? 'old' : 'new')),
        directory_loader: (id) async =>
            _success(id == 'old' ? old_chapters : [new_chapter]),
        content_loader: (id) async {
          if (id == new_chapter.id) {
            new_content_started.complete();
            return new_content.future;
          }
          return '$id 原有正文';
        },
      );
      await logic.fetch_info();
      final jump_generation = await logic.jump_to_chapter(1);
      logic.complete_chapter_jump(jump_generation!);
      logic.current_chapter_db_id = 321;
      logic.update_chapter_progress(50);
      final old_info = store.novel_info.value;
      final old_items = store.reading_items.toList();
      final old_cache = store.get_cached_chapter_content(0);

      void expect_original_window() {
        expect(store.novel_info.value, same(old_info));
        expect(store.chapter_list, old_chapters);
        expect(store.reading_items, old_items);
        expect(store.get_cached_chapter_content(0), old_cache);
        expect(store.get_cached_chapter_content(1), contains('old-second'));
        expect(logic.current_chapter_index.value, 1);
        expect(logic.current_chapter_db_id, 321);
        expect(logic.loaded_chapter_index, 1);
        expect(logic.min_loaded_chapter_index, 0);
        expect(logic.total_word_count, 200);
        expect(logic.calculate_reading_progress(0, 0), 75);
      }

      final refresh = logic.fetch_info(
        force: true,
        show_loading: false,
        bypass_chapter_cache: true,
      );
      await new_content_started.future;
      expect_original_window();

      if (failure_kind == 'empty') {
        new_content.complete('');
      } else {
        new_content.completeError(StateError('首章网络失败'));
      }
      await refresh;

      expect_original_window();
      expect(logic.is_loading.value, isFalse);
      expect(logic.is_error.value, isFalse);
    });
  }
}
