import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/components/work_genres_section/index.dart';

/// 阅读页标签区块组件。
///
/// 展示小说的分类标签（如：奇幻、玄幻、都市等）。
/// 与漫画、短篇共用完整宽度的分类卡片。
class ReadTagSection extends StatelessWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 标签文本列表。
  final List<String> tag_list;
  final int content_id;

  const ReadTagSection({
    super.key,
    required this.is_dark,
    required this.tag_list,
    this.content_id = 0,
  });

  @override
  Widget build(BuildContext context) => WorkGenresSection(
    title: easy.tr('comics.genres'),
    tags: tag_list,
    is_dark: is_dark,
    content_id: content_id,
  );
}
