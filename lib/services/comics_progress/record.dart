// ignore_for_file: non_constant_identifier_names

import 'package:app/models/comics.dart';

/// TODO 同一份记录服务阅读、详情和历史，页码从0开始，时间明确以UTC解析。
class ComicProgressRecord {
  final int comic_id;
  final int chapter_id;
  final String chapter_title;
  final int page_index;
  final String language;
  final int comic_language_id;
  final DateTime? updated_at;
  final double page_fraction;
  final Map<String, dynamic> image_dimensions;
  final bool pending_sync;
  final bool server_confirmed;

  const ComicProgressRecord({
    required this.comic_id,
    required this.chapter_id,
    required this.page_index,
    this.chapter_title = '',
    this.language = '',
    this.comic_language_id = 0,
    this.updated_at,
    this.page_fraction = 0,
    this.image_dimensions = const <String, dynamic>{},
    this.pending_sync = false,
    this.server_confirmed = false,
  });

  /// TODO 数据库无时区后缀的DATETIME也代表UTC，不能交给设备本地时区解释。
  static DateTime? utc_time(dynamic value) {
    if (value is DateTime) return value.toUtc();
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    final normalized = text.replaceFirst(' ', 'T');
    final zoned = RegExp(
      r'(Z|[+-]\d{2}:?\d{2})$',
      caseSensitive: false,
    ).hasMatch(normalized);
    return DateTime.tryParse(zoned ? normalized : '${normalized}Z')?.toUtc();
  }

  factory ComicProgressRecord.from_json(Map<String, dynamic> value) =>
      ComicProgressRecord(
        comic_id: comics_int(value['comic_id']),
        chapter_id: comics_int(value['chapter_id']),
        chapter_title: value['chapter_title']?.toString() ?? '',
        page_index: comics_int(value['page_index']).clamp(0, 1000000),
        language: value['language']?.toString() ?? '',
        comic_language_id: comics_int(
          value['comic_language_id'] ?? value['language_id'],
        ),
        updated_at: utc_time(value['updated_at'] ?? value['update_time']),
        page_fraction: (double.tryParse('${value['page_fraction']}') ?? 0)
            .clamp(0, 1),
        image_dimensions: comics_map(value['image_dimensions']),
        pending_sync: value['pending_sync'] == true,
        server_confirmed: value['server_confirmed'] == true,
      );

  Map<String, dynamic> to_json() => <String, dynamic>{
    'comic_id': comic_id,
    'chapter_id': chapter_id,
    'chapter_title': chapter_title,
    'page_index': page_index,
    'language': language,
    'comic_language_id': comic_language_id,
    if (updated_at != null) 'updated_at': updated_at!.toUtc().toIso8601String(),
    'page_fraction': page_fraction,
    'image_dimensions': image_dimensions,
    'pending_sync': pending_sync,
    'server_confirmed': server_confirmed,
  };
}
