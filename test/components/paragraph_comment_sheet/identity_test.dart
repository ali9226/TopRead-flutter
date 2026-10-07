// ignore_for_file: non_constant_identifier_names

import 'package:app/components/paragraph_comment_sheet/api.dart';
import 'package:app/components/paragraph_comment_sheet/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 记录弹窗真正发出的查询身份，防止只验证逻辑层而遗漏 UI 传参。
class _IdentityRepository extends ParagraphCommentRepository {
  final List<({int novel_id, int paragraph_id})> requests = [];

  @override
  Future<ParagraphCommentListResponse> inquire({
    required int novel_id,
    required int paragraph_id,
    int? parent_id,
    int page = 1,
  }) async {
    requests.add((novel_id: novel_id, paragraph_id: paragraph_id));
    return const ParagraphCommentListResponse(
      list: [],
      total: 0,
      page: 1,
      page_size: 20,
      has_more: false,
    );
  }
}

void main() {
  for (final is_dark in [false, true]) {
    testWidgets('段评弹窗传递所属小说 ID：is_dark=$is_dark', (tester) async {
      final repository = _IdentityRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParagraphCommentDetailSheet(
              novel_id: 42,
              paragraph_id: 7,
              paragraph_text: '测试段落',
              initial_comment_count: 0,
              is_dark: is_dark,
              is_cjk: true,
              repository: repository,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(repository.requests, [(novel_id: 42, paragraph_id: 7)]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
