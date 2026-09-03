// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/installation/author_style.dart';
import 'package:app/pages/installation/models/creator_work.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'style.dart';

/// TODO 长篇章节编辑页面。
///
/// 当前只维护本地 UI 草稿，点击保存后把章节模型返回给作品编辑页。
class ChapterEditorPage extends StatefulWidget {
  /// TODO 正在编辑的章节；为空表示新增章节。
  final CreatorChapterDraft? initial_chapter;

  /// TODO 章节在作品中的展示序号。
  final int chapter_number;

  const ChapterEditorPage({
    super.key,
    required this.chapter_number,
    this.initial_chapter,
  });

  @override
  State<ChapterEditorPage> createState() => _ChapterEditorPageState();
}

class _ChapterEditorPageState extends State<ChapterEditorPage> {
  /// TODO 设备主题状态。
  final DeviceInfo _device_info = Get.find<DeviceInfo>();

  /// TODO 章节标题输入控制器。
  late final TextEditingController _title_controller;

  /// TODO 章节正文输入控制器。
  late final TextEditingController _content_controller;

  /// TODO 正文输入焦点。
  final FocusNode _content_focus_node = FocusNode();

  @override
  void initState() {
    super.initState();
    _title_controller = TextEditingController(
      text: widget.initial_chapter?.title ?? '',
    );
    _content_controller = TextEditingController(
      text: widget.initial_chapter?.content ?? '',
    );
  }

  @override
  void dispose() {
    _title_controller.dispose();
    _content_controller.dispose();
    _content_focus_node.dispose();
    super.dispose();
  }

  /// TODO 计算当前正文的非空白字符数。
  int get _word_count {
    return _content_controller.text.replaceAll(RegExp(r'\s+'), '').length;
  }

  /// TODO 校验并返回章节草稿。
  void _save_chapter() {
    final String title = _title_controller.text.trim();
    final String content = _content_controller.text.trim();

    if (title.isEmpty) {
      showBottomTip(easy.tr('creator_center.required_chapter_title'));
      return;
    }
    if (content.isEmpty) {
      showBottomTip(easy.tr('creator_center.required_chapter_content'));
      return;
    }

    final DateTime now = DateTime.now();
    final CreatorChapterDraft chapter = CreatorChapterDraft(
      local_id:
          widget.initial_chapter?.local_id ??
          'chapter_${now.microsecondsSinceEpoch}',
      title: title,
      content: content,
      update_time: now,
    );

    showBottomTip(easy.tr('creator_center.chapter_saved'));
    Navigator.of(context).pop<CreatorChapterDraft>(chapter);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool is_dark = _device_info.dark.value;

      return Scaffold(
        backgroundColor: AuthorStyle.background(is_dark),
        appBar: AppBar(
          backgroundColor: AuthorStyle.background(is_dark),
          surfaceTintColor: Colors.transparent,
          foregroundColor: AuthorStyle.primary_text(is_dark),
          elevation: 0,
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                easy.tr('creator_center.chapter_editor_title'),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: AuthorStyle.title_weight,
                ),
              ),
              Text(
                easy.tr(
                  'creator_center.chapter_number',
                  namedArgs: <String, String>{
                    'number': widget.chapter_number.toString(),
                  },
                ),
                style: TextStyle(
                  color: AuthorStyle.secondary_text(is_dark),
                  fontSize: 11,
                  fontWeight: AuthorStyle.body_weight,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: _save_chapter,
              child: Text(
                easy.tr('creator_center.save_chapter'),
                style: TextStyle(
                  color: is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold,
                  fontWeight: AuthorStyle.emphasis_weight,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    ChapterEditorStyle.page_padding,
                    14,
                    ChapterEditorStyle.page_padding,
                    30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextField(
                        controller: _title_controller,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _content_focus_node.requestFocus(),
                        maxLength: 80,
                        cursorColor: ColorConstants.themeColor,
                        style: TextStyle(
                          color: AuthorStyle.primary_text(is_dark),
                          fontSize: ChapterEditorStyle.title_font_size,
                          fontWeight: AuthorStyle.title_weight,
                        ),
                        decoration: InputDecoration(
                          hintText: easy.tr(
                            'creator_center.chapter_title_hint',
                          ),
                          hintStyle: TextStyle(
                            color: AuthorStyle.secondary_text(is_dark),
                            fontWeight: AuthorStyle.body_weight,
                          ),
                          counterText: '',
                          border: InputBorder.none,
                        ),
                      ),
                      Divider(color: AuthorStyle.border(is_dark)),
                      TextField(
                        controller: _content_controller,
                        focusNode: _content_focus_node,
                        minLines: 18,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        cursorColor: ColorConstants.themeColor,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          color: AuthorStyle.primary_text(is_dark),
                          fontSize: ChapterEditorStyle.content_font_size,
                          height: ChapterEditorStyle.content_line_height,
                          fontWeight: FontConfig.adjustedWeight(
                            FontWeight.w400,
                          ),
                        ),
                        decoration: InputDecoration(
                          hintText: easy.tr(
                            'creator_center.chapter_content_hint',
                          ),
                          hintStyle: TextStyle(
                            color: AuthorStyle.secondary_text(is_dark),
                            height: ChapterEditorStyle.content_line_height,
                            fontWeight: AuthorStyle.body_weight,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: ChapterEditorStyle.toolbar_height,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: AuthorStyle.surface(is_dark),
                  border: Border(
                    top: BorderSide(color: AuthorStyle.border(is_dark)),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.cloud_done_outlined,
                        size: 18,
                        color: AuthorStyle.secondary_text(is_dark),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          easy.tr('creator_center.local_autosave_hint'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AuthorStyle.secondary_text(is_dark),
                            fontSize: 12,
                            fontWeight: AuthorStyle.body_weight,
                          ),
                        ),
                      ),
                      Text(
                        easy.tr(
                          'creator_center.word_count',
                          namedArgs: <String, String>{
                            'count': _word_count.toString(),
                          },
                        ),
                        style: TextStyle(
                          color: AuthorStyle.secondary_text(is_dark),
                          fontSize: 12,
                          fontWeight: AuthorStyle.emphasis_weight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
