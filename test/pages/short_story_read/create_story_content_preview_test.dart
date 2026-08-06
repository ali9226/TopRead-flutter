import 'package:app/pages/short_story_read/utils/create_story_content_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('create_story_content_preview', () {
    test('CJK 正文按非空白字符折叠到约三分之一', () {
      const String content = '一二三四五\n六七八九十\n甲乙丙丁戊';

      final StoryContentPreviewData result = create_story_content_preview(
        content: content,
        is_cjk: true,
        preview_ratio: 1 / 3,
      );

      expect(result.preview_content, '一二三四五');
      expect(result.remaining_count, 10);
    });

    test('字母语系正文保持完整单词并返回剩余单词数', () {
      const String content =
          'One two three four five six seven eight nine ten eleven twelve.';

      final StoryContentPreviewData result = create_story_content_preview(
        content: content,
        is_cjk: false,
        preview_ratio: 1 / 3,
      );

      expect(result.preview_content, 'One two three four');
      expect(result.remaining_count, 8);
    });

    test('字母语系跳过只包含标点的文本块', () {
      const String content = 'Hello ... world — again!';

      final StoryContentPreviewData result = create_story_content_preview(
        content: content,
        is_cjk: false,
        preview_ratio: 1 / 3,
      );

      expect(result.preview_content, 'Hello');
      expect(result.remaining_count, 2);
    });

    test('渐变尾部内容参与渲染但仍计入待解锁单词数', () {
      const String content =
          'one two three four five six seven eight nine ten eleven twelve';

      final StoryContentPreviewData result = create_story_content_preview(
        content: content,
        is_cjk: false,
        preview_ratio: 1 / 3,
        fade_tail_count: 3,
      );

      expect(result.preview_content, 'one two three four five six seven');
      expect(result.remaining_count, 8);
    });

    test('空正文返回空预览', () {
      final StoryContentPreviewData result = create_story_content_preview(
        content: '  \n ',
        is_cjk: true,
        preview_ratio: 1 / 3,
      );

      expect(result.preview_content, isEmpty);
      expect(result.remaining_count, 0);
    });
  });
}
