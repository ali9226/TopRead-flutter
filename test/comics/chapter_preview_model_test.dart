// ignore_for_file: non_constant_identifier_names

import 'package:app/models/comics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('轻量章节首图保留 URL 与尺寸，不需要完整图片列表', () {
    final chapter = ComicChapter.from_json({
      'id': 8,
      'first_image': {
        'image_url': 'https://example.com/chapter-8.webp',
        'width': '1200',
        'height': 1800,
      },
    });

    expect(chapter.images, isEmpty);
    expect(
      chapter.preview_image?.image_url,
      'https://example.com/chapter-8.webp',
    );
    expect(chapter.preview_image?.width, 1200);
    expect(chapter.preview_image?.height, 1800);
  });

  test('首图优先使用目录元数据，旧接口兼容图片数组', () {
    final chapter = ComicChapter.from_json({
      'first_image': {'image_url': 'https://example.com/first.webp'},
      'images': [
        {'image_url': 'https://example.com/legacy.webp'},
        {'image_url': 'https://example.com/second.webp'},
      ],
    });
    expect(chapter.preview_image?.image_url, 'https://example.com/first.webp');

    for (final first_image in [null, '', <String, dynamic>{}]) {
      final legacy = ComicChapter.from_json({
        'first_image': first_image,
        'images': [
          {'url': 'https://example.com/legacy.webp'},
        ],
      });
      expect(
        legacy.preview_image?.image_url,
        'https://example.com/legacy.webp',
      );
    }
  });

  test('缺少首图与完整图片列表的旧目录正常返回空预览', () {
    expect(ComicChapter.from_json({'id': 3}).preview_image, isNull);
    expect(ComicChapter.from_json({'first_image': null}).first_image, isNull);
  });
}
