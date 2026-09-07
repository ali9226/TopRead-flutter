// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/author_center/store.dart';
import 'package:app/pages/author_center/models/creator_backend_models.dart';
import 'package:app/pages/author_center/logic.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 章节编辑页面
class ChapterEditorPage extends StatefulWidget {
  final int novelId;
  final int novelLanguageId;
  final CreatorChapterModel? chapter;

  const ChapterEditorPage({
    super.key,
    required this.novelId,
    required this.novelLanguageId,
    this.chapter,
  });

  @override
  State<ChapterEditorPage> createState() => _ChapterEditorPageState();
}

class _ChapterEditorPageState extends State<ChapterEditorPage> {
  final CreatorStore _store = Get.find<CreatorStore>();
  final TextEditingController _title_controller = TextEditingController();
  final TextEditingController _content_controller = TextEditingController();

  bool _is_saving = false;
  bool _has_unsaved_changes = false;
  int? _lock_version;

  @override
  void initState() {
    super.initState();
    if (widget.chapter != null) {
      _title_controller.text = widget.chapter!.title;
      _lock_version = widget.chapter!.id;
      // TODO: 加载章节内容
    }
    _title_controller.addListener(_on_content_changed);
    _content_controller.addListener(_on_content_changed);
  }

  @override
  void dispose() {
    _title_controller.removeListener(_on_content_changed);
    _content_controller.removeListener(_on_content_changed);
    _title_controller.dispose();
    _content_controller.dispose();
    super.dispose();
  }

  void _on_content_changed() {
    if (!_has_unsaved_changes) {
      setState(() => _has_unsaved_changes = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool is_dark = Theme.of(context).brightness == Brightness.dark;
    final bool is_cjk = LanguageUtil.is_cjk_language(context.locale.languageCode);

    return Scaffold(
      backgroundColor: is_dark ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        title: Text(
          widget.chapter != null ? '编辑章节' : '新建章节',
          style: TextStyle(
            fontSize: is_cjk ? 16 : 14,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
          ),
        ),
        backgroundColor: is_dark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: is_dark ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          // 字数统计
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Obx(() {
                final word_count = _content_controller.text.replaceAll(RegExp(r'\s+'), '').length;
                return Text(
                  '$word_count字',
                  style: TextStyle(
                    fontSize: 12,
                    color: word_count < 500 ? Colors.red : Colors.grey,
                  ),
                );
              }),
            ),
          ),
          // 保存按钮
          IconButton(
            icon: _is_saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _is_saving ? null : _save_draft,
            tooltip: '保存',
          ),
          // 更多选项
          PopupMenuButton<String>(
            onSelected: _handle_menu_action,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'submit',
                child: Text('提交审核'),
              ),
              if (widget.chapter != null && widget.chapter!.is_draft)
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('删除草稿', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 章节状态提示
          if (widget.chapter != null) _build_status_banner(is_dark, is_cjk),

          // 编辑区
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 标题输入
                  TextField(
                    controller: _title_controller,
                    decoration: InputDecoration(
                      hintText: '章节标题',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: is_cjk ? 16 : 14,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                    ),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 12),

                  // 正文输入
                  Expanded(
                    child: TextField(
                      controller: _content_controller,
                      decoration: InputDecoration(
                        hintText: '开始写作...\n\n提示：每章建议500-20000字',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        alignLabelWithHint: true,
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(
                        fontSize: is_cjk ? 15 : 14,
                        height: 1.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 底部工具栏
          _build_toolbar(is_dark, is_cjk),
        ],
      ),
    );
  }

  /// 构建状态提示
  Widget _build_status_banner(bool is_dark, bool is_cjk) {
    if (widget.chapter == null) return const SizedBox.shrink();

    Color color;
    String text;

    if (widget.chapter!.is_draft) {
      color = Colors.blue;
      text = '草稿状态';
    } else if (widget.chapter!.is_reviewing) {
      color = Colors.orange;
      text = '审核中，无法编辑';
    } else if (widget.chapter!.is_rejected) {
      color = Colors.red;
      text = '已驳回：${widget.chapter!.status_text}';
    } else if (widget.chapter!.is_published) {
      color = Colors.green;
      text = '已发布';
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: color.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: is_cjk ? 13 : 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部工具栏
  Widget _build_toolbar(bool is_dark, bool is_cjk) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: is_dark ? const Color(0xFF2A2A2A) : Colors.grey[50],
        border: Border(
          top: BorderSide(
            color: is_dark ? Colors.white12 : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          // 自动保存状态
          if (_has_unsaved_changes)
            Text(
              '未保存',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[300],
              ),
            )
          else
            Text(
              '已保存',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[300],
              ),
            ),

          const Spacer(),

          // 保存按钮
          ElevatedButton.icon(
            onPressed: _is_saving ? null : _save_draft,
            icon: const Icon(Icons.save, size: 18),
            label: Text(is_cjk ? '保存' : 'Save'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
          const SizedBox(width: 12),

          // 提交审核按钮
          OutlinedButton.icon(
            onPressed: _submit_for_review,
            icon: const Icon(Icons.send, size: 18),
            label: Text(is_cjk ? '提交' : 'Submit'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// 保存草稿
  Future<void> _save_draft() async {
    if (_is_saving) return;

    final title = _title_controller.text.trim();
    final content = _content_controller.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入章节标题')),
      );
      return;
    }

    setState(() => _is_saving = true);

    try {
      if (widget.chapter != null) {
        // 更新现有章节
        final result = await CreatorLogic.saveChapterDraft(
          revisionId: widget.chapter!.id,
          title: title,
          wordCount: content.replaceAll(RegExp(r'\s+'), '').length,
          lockVersion: _lock_version,
        );

        if (result != null) {
          _lock_version = result['lock_version'];
          setState(() => _has_unsaved_changes = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('保存成功')),
            );
          }
        }
      } else {
        // 创建新章节
        final result = await CreatorLogic.createChapterDraft(
          novelId: widget.novelId,
          novelLanguageId: widget.novelLanguageId,
          title: title,
        );

        if (result != null) {
          _lock_version = result['revision_id'];
          setState(() => _has_unsaved_changes = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('创建成功')),
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _is_saving = false);
      }
    }
  }

  /// 提交审核
  void _submit_for_review() {
    final title = _title_controller.text.trim();
    final content = _content_controller.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标题和正文')),
      );
      return;
    }

    if (content.replaceAll(RegExp(r'\s+'), '').length < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正文至少500字')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提交审核'),
        content: const Text('确定要提交审核吗？提交后将无法修改。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _do_submit();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 执行提交
  Future<void> _do_submit() async {
    if (_lock_version == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先保存草稿')),
      );
      return;
    }

    final result = await CreatorLogic.submitChapters(
      novelId: widget.novelId,
      chapterRevisionIds: [_lock_version!],
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('提交成功')),
      );
      Navigator.pop(context);
    }
  }

  /// 处理菜单操作
  void _handle_menu_action(String action) {
    switch (action) {
      case 'submit':
        _submit_for_review();
        break;
      case 'delete':
        _delete_draft();
        break;
    }
  }

  /// 删除草稿
  void _delete_draft() {
    if (widget.chapter == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除草稿'),
        content: const Text('确定要删除这个章节草稿吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await CreatorLogic.deleteChapterDraft(widget.chapter!.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('删除成功')),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
