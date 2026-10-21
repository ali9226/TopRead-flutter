import 'package:app/components/expandable_synopsis/text_viewport.dart';

/// 保留旧类型入口，正文裁切布局由所有作品类型共享。
class ComicAboutTextViewport extends ExpandableSynopsisTextViewport {
  const ComicAboutTextViewport({
    super.key,
    required super.description,
    required super.expanded,
    required super.style,
    required super.on_collapse,
  }) : super(key_prefix: 'comic_about');
}
