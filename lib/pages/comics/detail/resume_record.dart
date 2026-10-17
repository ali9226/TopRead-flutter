// ignore_for_file: non_constant_identifier_names

import 'package:app/models/comics.dart';
import 'package:app/services/comics_progress/record.dart';

/// 详情页唯一的续读结果，始终指向当前语种仍可阅读的目录条目。
class ComicResumeRecord {
  final ComicChapter chapter;
  final int page_index;
  final Map<String, dynamic> record;

  const ComicResumeRecord({
    required this.chapter,
    required this.page_index,
    required this.record,
  });
}

/// 空图章节和已隐藏章节不能成为公开阅读入口；目录由服务端按访问者权限过滤。
List<ComicChapter> comic_readable_chapters(ComicDetail detail) => detail
    .chapters
    .where(
      (chapter) =>
          chapter.id > 0 &&
          chapter.page_count > 0 &&
          chapter.status != 'hidden',
    )
    .toList(growable: false);

/// 合并本地和服务端记录：先验证作品、账号、语种、章节，再决定优先级。
/// 未同步的当前设备阅读优先；已同步记录按UTC时间择新，避免旧设备缓存覆盖跨设备进度。
ComicResumeRecord? resolve_comic_resume(
  ComicDetail detail, {
  Map<String, dynamic> local_record = const <String, dynamic>{},
  Map<String, dynamic>? server_record,
  int? user_id,
}) {
  final chapters = comic_readable_chapters(detail);
  ComicResumeRecord? validate(Map<String, dynamic> raw) {
    if (raw.isEmpty) return null;
    final record = ComicProgressRecord.from_json(raw);
    if (record.comic_id > 0 && record.comic_id != detail.comic.id) return null;
    if (user_id != null &&
        raw['user_id'] != null &&
        comics_int(raw['user_id']) != user_id) {
      return null;
    }
    if (record.comic_language_id > 0 &&
        record.comic_language_id != detail.selected_language_id) {
      return null;
    }
    final record_language = record.language.trim().toLowerCase().replaceAll(
      '_',
      '-',
    );
    final current_language =
        detail.selected_language?.language.trim().toLowerCase().replaceAll(
          '_',
          '-',
        ) ??
        '';
    if (record_language.isNotEmpty && record_language != current_language) {
      return null;
    }
    ComicChapter? chapter;
    for (final candidate in chapters) {
      if (candidate.id == record.chapter_id) {
        chapter = candidate;
        break;
      }
    }
    if (chapter == null) return null;
    final page_index = record.page_index.clamp(0, chapter.page_count - 1);
    return ComicResumeRecord(
      chapter: chapter,
      page_index: page_index,
      record: <String, dynamic>{
        ...raw,
        'comic_id': detail.comic.id,
        'chapter_id': chapter.id,
        'chapter_title': chapter.title,
        'page_index': page_index,
        'language': detail.selected_language?.language ?? '',
        'comic_language_id': detail.selected_language_id,
      },
    );
  }

  final local = validate(local_record);
  final server = validate(server_record ?? detail.read_record);
  if (local == null) return server;
  if (server == null) return local;
  final local_progress = ComicProgressRecord.from_json(local.record);
  final server_progress = ComicProgressRecord.from_json(server.record);
  if (local_progress.pending_sync) return local;
  // 旧版设备时间没有服务器确认，不能凭2099等失准时钟压过真实服务器记录。
  if (local.record['server_confirmed'] != true) return server;
  if (local_progress.updated_at == null) return server;
  if (server_progress.updated_at == null) return local;
  return local_progress.updated_at!.isAfter(server_progress.updated_at!)
      ? local
      : server;
}
