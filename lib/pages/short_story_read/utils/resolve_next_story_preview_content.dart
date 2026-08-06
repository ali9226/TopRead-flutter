/// 获取下一篇短篇小说的预览文字。
///
/// 列表接口返回的 [description] 可以在目录加载完成后立即展示，
/// 因此优先用它避免正文异步预加载期间出现空白。
/// 仅当简介为空时，才使用已预加载的 [preloaded_content] 作为兜底。
String resolve_next_story_preview_content({
  required String description,
  required String preloaded_content,
}) {
  final String normalized_description = description.trim();
  if (normalized_description.isNotEmpty) {
    return normalized_description;
  }

  return preloaded_content.trim();
}
