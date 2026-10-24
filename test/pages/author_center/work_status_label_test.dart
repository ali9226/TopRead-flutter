// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:app/pages/author_center/models/creator_backend_models.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 复用仓库内真实多语种资源，断言比较「映射到的文案键值」而不是硬编码译文。
class _Assets extends AssetLoader {
  const _Assets();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
}

/// 读取 zh 文案中 creator_center 分组的期望值。
Map<String, String> _zh_labels() {
  final Map<String, dynamic> json = Map<String, dynamic>.from(
    jsonDecode(File('assets/i18n/zh.json').readAsStringSync()) as Map,
  );
  return Map<String, String>.from(json['creator_center'] as Map);
}

/// 组装最小作品行，只有状态相关字段可变。
Map<String, dynamic> _work_json({
  int public_status = 1,
  int work_type = 1,
  int serialization_status = 1,
  int initial_audit_status = 1,
  String? scheduled_publish_time,
  Map<String, dynamic>? pending_submission,
}) {
  return <String, dynamic>{
    'id': 1,
    'title': '作品',
    'work_type': work_type,
    'serialization_status': serialization_status,
    'public_status': public_status,
    'initial_audit_status': initial_audit_status,
    'publish_status': 1,
    'read_count': 0,
    'like_count': 0,
    'favorite_count': 0,
    'comment_count': 0,
    'create_time': '2026-01-01 00:00:00',
    'chapter_count': 1,
    'word_count': 10,
    'scheduled_publish_time': scheduled_publish_time,
    'pending_submission': pending_submission,
  };
}

/// 组装最小章节行。
Map<String, dynamic> _chapter_json({required int revision_status}) {
  return <String, dynamic>{
    'id': 1,
    'chapter_uid': 'uid',
    'revision_status': revision_status,
    'change_type': 1,
    'title': '章节',
    'word_count': 5,
    'create_time': '2026-01-01 00:00:00',
    'update_time': '2026-01-01 00:00:00',
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
  });

  /// 在 EasyLocalization 作用域内读取文案，保证模型层 tr() 能取到译文。
  ///
  /// 需要把 `context.localizationDelegates` 挂进 MaterialApp，
  /// 否则 Localization.load 不会执行，tr() 只能回退到键名。
  Future<String> label_in_context(WidgetTester tester, String Function() read) async {
    String value = '';
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale('zh')],
        path: 'assets/i18n',
        assetLoader: const _Assets(),
        startLocale: const Locale('zh'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Builder(
              builder: (context) {
                value = read();
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return value;
  }

  testWidgets('作品状态标签映射草稿/待发布/已发布/下架', (tester) async {
    final labels = _zh_labels();

    // 未公开且无排期 → 草稿。
    final draft = CreatorWorkModel.fromJson(_work_json());
    expect(
      await label_in_context(tester, () => draft.status_text),
      labels['status_draft'],
    );

    // 已公开 → 已发布。
    final published = CreatorWorkModel.fromJson(_work_json(public_status: 2));
    expect(
      await label_in_context(tester, () => published.status_text),
      labels['status_published'],
    );

    // 带定时发布时间 → 待发布。
    final scheduled = CreatorWorkModel.fromJson(
      _work_json(scheduled_publish_time: '2026-08-01 10:00:00'),
    );
    expect(
      await label_in_context(tester, () => scheduled.status_text),
      labels['pending_publish'],
    );

    // 审核单标记待发布（release_status=2）也走待发布分支。
    final pending = CreatorWorkModel.fromJson(
      _work_json(pending_submission: <String, dynamic>{'release_status': 2}),
    );
    expect(
      await label_in_context(tester, () => pending.status_text),
      labels['pending_publish'],
    );

    // 作者下架 / 平台下架 → 已下架。
    final off_shelf = CreatorWorkModel.fromJson(_work_json(public_status: 3));
    expect(
      await label_in_context(tester, () => off_shelf.status_text),
      labels['status_off_shelf'],
    );
    final platform_off = CreatorWorkModel.fromJson(_work_json(public_status: 4));
    expect(
      await label_in_context(tester, () => platform_off.status_text),
      labels['status_off_shelf'],
    );
  });

  testWidgets('作品类型与连载状态标签映射', (tester) async {
    final labels = _zh_labels();

    final long_work = CreatorWorkModel.fromJson(_work_json(work_type: 1));
    expect(long_work.is_long_novel, isTrue);
    expect(
      await label_in_context(tester, () => long_work.work_type_text),
      labels['work_type_long'],
    );

    final short_work = CreatorWorkModel.fromJson(_work_json(work_type: 2));
    expect(short_work.is_short_novel, isTrue);
    expect(
      await label_in_context(tester, () => short_work.work_type_text),
      labels['work_type_short'],
    );

    final ongoing = CreatorWorkModel.fromJson(
      _work_json(serialization_status: 1),
    );
    expect(
      await label_in_context(tester, () => ongoing.serialization_status_text),
      labels['serialization_ongoing'],
    );

    final completed = CreatorWorkModel.fromJson(
      _work_json(serialization_status: 2),
    );
    expect(
      await label_in_context(tester, () => completed.serialization_status_text),
      labels['serialization_completed'],
    );
  });

  testWidgets('章节状态标签映射草稿/待审/已发布/驳回', (tester) async {
    final labels = _zh_labels();

    final draft = CreatorChapterModel.fromJson(_chapter_json(revision_status: 1));
    expect(draft.is_draft, isTrue);
    expect(
      await label_in_context(tester, () => draft.status_text),
      labels['chapter_status_draft'],
    );

    final reviewing = CreatorChapterModel.fromJson(
      _chapter_json(revision_status: 2),
    );
    expect(reviewing.is_reviewing, isTrue);
    expect(
      await label_in_context(tester, () => reviewing.status_text),
      labels['pending_publish'],
    );

    final published = CreatorChapterModel.fromJson(
      _chapter_json(revision_status: 3),
    );
    expect(published.is_published, isTrue);
    expect(
      await label_in_context(tester, () => published.status_text),
      labels['chapter_status_published'],
    );

    // 驳回兼容为未发布草稿。
    final rejected = CreatorChapterModel.fromJson(
      _chapter_json(revision_status: 4),
    );
    expect(rejected.is_rejected, isTrue);
    expect(
      await label_in_context(tester, () => rejected.status_text),
      labels['chapter_status_draft'],
    );

    // 未知状态兜底。
    final unknown = CreatorChapterModel.fromJson(
      _chapter_json(revision_status: 9),
    );
    expect(
      await label_in_context(tester, () => unknown.status_text),
      labels['status_unknown'],
    );
  });
}
