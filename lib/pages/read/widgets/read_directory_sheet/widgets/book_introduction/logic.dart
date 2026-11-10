/// TODO 只整理展示所需的空白和标签，不改写作品简介或凭空生成内容。
class DirectoryBookIntroductionContent {
  const DirectoryBookIntroductionContent._({
    required this.tags,
    required this.paragraphs,
  });

  final List<String> tags;
  final List<String> paragraphs;

  /// TODO 保留标签顺序、段内单换行，并兼容不同平台的换行符。
  factory DirectoryBookIntroductionContent.from({
    required List<String> tags,
    required String description,
  }) {
    final normalized = description
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    return DirectoryBookIntroductionContent._(
      tags: tags
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .toList(),
      paragraphs: normalized.isEmpty
          ? const []
          : normalized
                .split(RegExp(r'\n[ \t]*\n+'))
                .map((paragraph) => paragraph.trim())
                .where((paragraph) => paragraph.isNotEmpty)
                .toList(),
    );
  }
}
