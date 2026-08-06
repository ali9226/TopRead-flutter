import 'package:app/pages/short_story_read/utils/resolve_next_story_preview_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolve_next_story_preview_content', () {
    test('优先展示下一篇简介', () {
      final String result = resolve_next_story_preview_content(
        description: '  这是下一篇的简介。  ',
        preloaded_content: '这是下一篇的正文。',
      );

      expect(result, '这是下一篇的简介。');
    });

    test('简介缺失时使用预加载正文兜底', () {
      final String result = resolve_next_story_preview_content(
        description: '   ',
        preloaded_content: '  The opening of the next story.  ',
      );

      expect(result, 'The opening of the next story.');
    });

    test('简介和预加载正文都缺失时返回空文字', () {
      final String result = resolve_next_story_preview_content(
        description: '',
        preloaded_content: '  ',
      );

      expect(result, isEmpty);
    });
  });
}
