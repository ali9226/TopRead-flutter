// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:app/api/paragraph_comment.dart';
import 'package:app/models/paragraph_anchor.dart';
import 'package:app/models/paragraph_text_selection.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

/// 可注入章节段落读取器，测试无需请求真实接口。
typedef ChapterParagraphMetadataLoader =
    Future<ParagraphMetadata?> Function(
      String chapter_id, {
      required int novel_id,
    });

/// 可注入段评提交器，偏移始终使用完整章节正文的 UTF-16 坐标。
typedef ParagraphCommentSender =
    Future<int?> Function({
      required int novel_id,
      required String paragraph_id,
      required String content,
      required List<String> images,
      required int selection_start,
      required int selection_end,
    });

/// 章节段评的身份验证、请求去重及服务端计数同步。
mixin ReadParagraphCommentMixin {
  /// 当前书籍的正文、目录及同版段落缓存。
  NovelReadingStore get store;

  /// 使用章节数据库 ID 读取元数据，可注入离线测试实现。
  ChapterParagraphMetadataLoader get chapter_paragraph_metadata_loader;

  /// 提交文字、图片及完整正文选区，返回服务端确认的段评总数。
  ParagraphCommentSender get paragraph_comment_sender;

  /// 同一章节进行中的元数据请求，避免预加载与长按触发重复请求。
  final Map<String, Future<ParagraphMetadata?>> _paragraph_metadata_requests =
      {};

  /// 页面关闭后即使网络请求成功也不能继续修改阅读状态。
  bool _paragraph_state_closed = false;

  /// 关闭页面后拒绝异步回调继续修改阅读状态。
  void close_paragraph_state() {
    _paragraph_state_closed = true;
    _paragraph_metadata_requests.clear();
  }

  /// 元数据失败不阻断正文阅读；同一章节的并发查询共享一次请求。
  Future<ParagraphMetadata?> load_chapter_paragraph_metadata(
    String chapter_id, {
    required int novel_id,
  }) async {
    if (_paragraph_state_closed || chapter_id.isEmpty) return null;
    final pending = _paragraph_metadata_requests[chapter_id];
    if (pending != null) return pending;
    final request = _read_paragraph_metadata(chapter_id, novel_id: novel_id);
    _paragraph_metadata_requests[chapter_id] = request;
    try {
      return await request;
    } finally {
      if (identical(_paragraph_metadata_requests[chapter_id], request)) {
        _paragraph_metadata_requests.remove(chapter_id);
      }
    }
  }

  /// 捕获离线、接口未升级等错误，使阅读和后续重试保持可用。
  Future<ParagraphMetadata?> _read_paragraph_metadata(
    String chapter_id, {
    required int novel_id,
  }) async {
    try {
      return await chapter_paragraph_metadata_loader(
        chapter_id,
        novel_id: novel_id,
      );
    } catch (_) {
      return null;
    }
  }

  /// 检查被点击的段落仍属于当前窗口中的同一章节、同一正文和同一偏移。
  bool _is_current_paragraph_item(ReadingContentItem item) {
    if (_paragraph_state_closed ||
        item.is_title ||
        item.chapter_index < 0 ||
        item.chapter_index >= store.chapter_list.length ||
        item.chapter_id != store.chapter_list[item.chapter_index].id) {
      return false;
    }
    final content = store.get_cached_chapter_content(item.chapter_index);
    if (content == null ||
        item.start_offset < 0 ||
        item.start_offset >= item.end_offset ||
        item.end_offset > content.length ||
        item.body_content_hash !=
            sha256.convert(utf8.encode(content)).toString() ||
        content.substring(item.start_offset, item.end_offset) != item.text) {
      return false;
    }
    return store.reading_items.any(
      (current) =>
          !current.is_title &&
          current.chapter_id == item.chapter_id &&
          current.body_content_hash == item.body_content_hash &&
          current.start_offset == item.start_offset &&
          current.end_offset == item.end_offset &&
          current.text == item.text,
    );
  }

  /// 使用段落偏移与文字摘要定位真实数据库锚点，不使用目录索引猜测 ID。
  ParagraphAnchor? _find_paragraph_anchor(
    ReadingContentItem item,
    ParagraphMetadata metadata,
  ) {
    if (metadata.content_hash != item.body_content_hash) return null;
    final hash = sha256.convert(utf8.encode(item.text)).toString();
    for (final anchor in metadata.paragraphs) {
      if (anchor.start_offset == item.start_offset &&
          anchor.end_offset == item.end_offset &&
          anchor.content_hash == hash) {
        return anchor;
      }
    }
    return null;
  }

  /// 元数据暂时不可用时允许重试，只给完整正文版本匹配的段落开放段评。
  Future<ParagraphAnchor?> resolve_paragraph_anchor(
    ReadingContentItem item, {
    required int novel_id,
  }) async {
    if (!_is_current_paragraph_item(item)) return null;
    var metadata = store.get_chapter_paragraph_metadata(item.chapter_index);
    if (metadata == null) {
      metadata = await load_chapter_paragraph_metadata(
        item.chapter_id,
        novel_id: novel_id,
      );
      if (!_is_current_paragraph_item(item) ||
          metadata == null ||
          !store.set_chapter_paragraph_metadata(item.chapter_index, metadata)) {
        return null;
      }
    }
    return _find_paragraph_anchor(item, metadata);
  }

  /// 将选区转为完整章节偏移，跨段评论始终归属最后选中的段落。
  Future<bool> send_paragraph_comment({
    required ReadingContentItem item,
    required ParagraphAnchor anchor,
    required TextSelection selection,
    required String text,
    required List<String> images,
    required int novel_id,
  }) async {
    if (!selection.isValid ||
        selection.isCollapsed ||
        selection.start < 0 ||
        selection.end > item.text.length) {
      return false;
    }
    final current_anchor = await resolve_paragraph_anchor(
      item,
      novel_id: novel_id,
    );
    if (current_anchor == null ||
        current_anchor.id != anchor.id ||
        current_anchor.start_offset != anchor.start_offset ||
        current_anchor.end_offset != anchor.end_offset ||
        current_anchor.content_hash != anchor.content_hash) {
      return false;
    }
    // 元数据解析可能等待网络；必须在解析完成后核对当前完整正文。
    if (selection is ParagraphTextSelection &&
        (!_is_current_paragraph_item(item) ||
            !selection.matches_paragraph(
              content:
                  store.get_cached_chapter_content(item.chapter_index) ?? '',
              paragraph_start: item.start_offset,
              paragraph_end: item.end_offset,
            ))) {
      return false;
    }
    final count = await paragraph_comment_sender(
      novel_id: novel_id,
      paragraph_id: anchor.id,
      content: text,
      images: images,
      selection_start: selection is ParagraphTextSelection
          ? selection.content_start
          : item.start_offset + selection.start,
      selection_end: selection is ParagraphTextSelection
          ? selection.content_end
          : item.start_offset + selection.end,
    );
    if (count == null) return false;
    update_paragraph_comment_count(
      item: item,
      paragraph_id: anchor.id,
      count: count,
    );
    return true;
  }

  /// 段评面板的新增、删除操作只更新当前段落，不修改整本书评论数。
  void update_paragraph_comment_count({
    required ReadingContentItem item,
    required String paragraph_id,
    required int count,
  }) {
    if (count < 0 || !_is_current_paragraph_item(item)) return;
    final metadata = store.get_chapter_paragraph_metadata(item.chapter_index);
    if (metadata == null ||
        _find_paragraph_anchor(item, metadata)?.id != paragraph_id) {
      return;
    }
    store.set_chapter_paragraph_metadata(
      item.chapter_index,
      ParagraphMetadata(
        body_id: metadata.body_id,
        published_revision_id: metadata.published_revision_id,
        content_hash: metadata.content_hash,
        paragraphs: metadata.paragraphs
            .map(
              (anchor) => anchor.id == paragraph_id
                  ? anchor.with_comment_count(count)
                  : anchor,
            )
            .toList(growable: false),
      ),
    );
  }
}
