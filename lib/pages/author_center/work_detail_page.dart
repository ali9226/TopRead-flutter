// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:app/pages/author_center/logic.dart';
import 'package:app/pages/author_center/store.dart';
import 'package:app/pages/author_center/models/creator_backend_models.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/index.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 作品详情页面
class CreatorWorkDetailPage extends StatefulWidget {
  final CreatorWorkModel work;

  const CreatorWorkDetailPage({super.key, required this.work});

  @override
  State<CreatorWorkDetailPage> createState() => _CreatorWorkDetailPageState();
}

class _CreatorWorkDetailPageState extends State<CreatorWorkDetailPage> {
  final CreatorStore _store = Get.find<CreatorStore>();

  @override
  void initState() {
    super.initState();
    _store.selectWork(widget.work);
  }

  @override
  Widget build(BuildContext context) {
    final bool is_dark = Theme.of(context).brightness == Brightness.dark;
    final bool is_cjk = LanguageUtil.is_cjk_language(context.locale.languageCode);

    return Scaffold(
      backgroundColor: is_dark ? const Color(0xFF1A1A1A) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.work.title,
          style: TextStyle(
            fontSize: is_cjk ? 16 : 14,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
          ),
        ),
        backgroundColor: is_dark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: is_dark ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          if (widget.work.is_draft || widget.work.is_rejected)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigate_to_edit(),
              tooltip: '编辑',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 作品信息卡片
            _build_work_info_card(is_dark, is_cjk),

            const SizedBox(height: 12),

            // 操作按钮
            _build_action_buttons(is_dark, is_cjk),

            const SizedBox(height: 12),

            // 章节列表（长篇）
            if (widget.work.is_long_novel) _build_chapter_section(is_dark, is_cjk),

            // 短篇正文（短篇）
            if (widget.work.is_short_novel) _build_short_story_section(is_dark, is_cjk),

            // 审核记录
            _build_submission_history(is_dark, is_cjk),
          ],
        ),
      ),
    );
  }

  /// 构建作品信息卡片
  Widget _build_work_info_card(bool is_dark, bool is_cjk) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: is_dark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 封面
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: widget.work.cover_url != null && widget.work.cover_url!.isNotEmpty
                ? Image.network(
                    widget.work.cover_url!,
                    width: 100,
                    height: 133,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _build_default_cover(is_dark),
                  )
                : _build_default_cover(is_dark),
          ),
          const SizedBox(width: 16),

          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  widget.work.title,
                  style: TextStyle(
                    fontSize: is_cjk ? 18 : 16,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),

                // 类型和状态
                Row(
                  children: [
                    _build_tag(widget.work.work_type_text, Colors.blue),
                    const SizedBox(width: 8),
                    _build_tag(widget.work.status_text, _get_status_color()),
                    if (widget.work.is_published) ...[
                      const SizedBox(width: 8),
                      _build_tag(widget.work.serialization_status_text, Colors.green),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // 统计
                Row(
                  children: [
                    _build_stat('章节', '${widget.work.chapter_count}'),
                    const SizedBox(width: 16),
                    _build_stat('字数', '${widget.work.word_count}'),
                    const SizedBox(width: 16),
                    _build_stat('阅读', '${widget.work.read_count}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _build_stat('点赞', '${widget.work.like_count}'),
                    const SizedBox(width: 16),
                    _build_stat('收藏', '${widget.work.favorite_count}'),
                    const SizedBox(width: 16),
                    _build_stat('评论', '${widget.work.comment_count}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建默认封面
  Widget _build_default_cover(bool is_dark) {
    return Container(
      width: 100,
      height: 133,
      decoration: BoxDecoration(
        color: is_dark ? Colors.white12 : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.book,
        size: 40,
        color: is_dark ? Colors.white24 : Colors.grey[400],
      ),
    );
  }

  /// 构建标签
  Widget _build_tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
        ),
      ),
    );
  }

  /// 构建统计项
  Widget _build_stat(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  /// 获取状态颜色
  Color _get_status_color() {
    if (widget.work.is_draft) return Colors.grey;
    if (widget.work.is_reviewing) return Colors.orange;
    if (widget.work.is_rejected) return Colors.red;
    if (widget.work.is_published) return Colors.green;
    return Colors.grey;
  }

  /// 构建操作按钮
  Widget _build_action_buttons(bool is_dark, bool is_cjk) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (widget.work.is_draft || widget.work.is_rejected) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _submit_for_review(),
                icon: const Icon(Icons.send, size: 18),
                label: Text(is_cjk ? '提交审核' : 'Submit'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
          if (widget.work.is_long_novel) ...[
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _add_chapter(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(is_cjk ? '新建章节' : 'Add Chapter'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建章节列表
  Widget _build_chapter_section(bool is_dark, bool is_cjk) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: is_dark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '章节列表',
                  style: TextStyle(
                    fontSize: is_cjk ? 16 : 14,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                  ),
                ),
                Text(
                  '${_store.chapters.length}章',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Obx(() {
            if (_store.isChaptersLoading.value) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (_store.chapters.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    '还没有章节',
                    style: TextStyle(
                      fontSize: is_cjk ? 14 : 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _store.chapters.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final chapter = _store.chapters[index];
                return _build_chapter_item(chapter, is_dark, is_cjk);
              },
            );
          }),
        ],
      ),
    );
  }

  /// 构建章节项
  Widget _build_chapter_item(CreatorChapterModel chapter, bool is_dark, bool is_cjk) {
    return ListTile(
      leading: chapter.chapter_no != null
          ? Text(
              '${chapter.chapter_no}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                color: Theme.of(context).primaryColor,
              ),
            )
          : const Icon(Icons.edit_note, color: Colors.grey),
      title: Text(
        chapter.title,
        style: TextStyle(
          fontSize: is_cjk ? 14 : 13,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Text(
            '${chapter.word_count}字',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          _build_tag(chapter.status_text, _get_chapter_status_color(chapter)),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _navigate_to_chapter(chapter),
    );
  }

  /// 获取章节状态颜色
  Color _get_chapter_status_color(CreatorChapterModel chapter) {
    if (chapter.is_draft) return Colors.grey;
    if (chapter.is_reviewing) return Colors.orange;
    if (chapter.is_rejected) return Colors.red;
    if (chapter.is_published) return Colors.green;
    return Colors.grey;
  }

  /// 构建短篇正文区域
  Widget _build_short_story_section(bool is_dark, bool is_cjk) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: is_dark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '正文',
            style: TextStyle(
              fontSize: is_cjk ? 16 : 14,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _edit_short_story(),
              icon: const Icon(Icons.edit, size: 18),
              label: Text(is_cjk ? '编辑正文' : 'Edit Content'),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建审核记录
  Widget _build_submission_history(bool is_dark, bool is_cjk) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: is_dark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '审核记录',
              style: TextStyle(
                fontSize: is_cjk ? 16 : 14,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
              ),
            ),
          ),
          const Divider(height: 1),
          // TODO: 显示审核记录列表
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                '暂无审核记录',
                style: TextStyle(
                  fontSize: is_cjk ? 14 : 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 提交审核
  void _submit_for_review() {
    // TODO: 实现提交审核逻辑
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
              // TODO: 调用提交审核API
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 添加章节
  void _add_chapter() {
    // TODO: 导航到章节编辑页面
  }

  /// 导航到编辑页面
  Future<void> _navigate_to_edit() async {
    // 加载作品详情获取草稿数据
    final info = await CreatorLogic.getWorkInfo(widget.work.id);
    if (info == null || !mounted) return;

    final draftData = info['draft'] as Map<String, dynamic>?;
    final novelData = info['novel'] as Map<String, dynamic>?;
    final categories = info['categories'] as List<dynamic>? ?? [];

    // 构建 CreatorWorkDraft 对象
    final CreatorWorkDraft workDraft;

    if (draftData != null) {
      // 从后端草稿数据构建
      workDraft = _buildDraftFromBackend(draftData, novelData, categories);
    } else {
      // 没有草稿，使用作品基本信息
      workDraft = _buildDraftFromNovel(novelData, categories);
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatorWorkEditorPage(initial_work: workDraft),
      ),
    ).then((result) {
      // 返回时刷新作品详情
      if (result != null && mounted) {
        setState(() {});
        _store.refreshWorks();
      }
    });
  }

  /// 从后端草稿数据构建 CreatorWorkDraft
  CreatorWorkDraft _buildDraftFromBackend(
    Map<String, dynamic> draft,
    Map<String, dynamic>? novel,
    List<dynamic> categories,
  ) {
    // 解析偏好数据
    Map<String, List<int>> preferences = {};
    if (draft['preferences'] != null) {
      try {
        dynamic raw = draft['preferences'];
        // 处理 JSON 字符串
        if (raw is String) {
          raw = jsonDecode(raw);
        }
        if (raw is Map) {
          raw.forEach((key, value) {
            if (value is List) {
              preferences[key.toString()] =
                  value.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList();
            }
          });
        }
      } catch (_) {}
    }

    // 解析分类ID
    final List<int> categoryIds = categories
        .map((c) => _parseInt(c['category_id']))
        .where((id) => id > 0)
        .toList();

    // 解析定时发布时间
    DateTime? scheduledTime;
    if (draft['scheduled_publish_time'] != null) {
      try {
        final timeStr = draft['scheduled_publish_time'].toString();
        // 处理 MySQL datetime 格式 (YYYY-MM-DD HH:MM:SS)
        if (timeStr.contains(' ')) {
          scheduledTime = DateTime.parse(timeStr.replaceFirst(' ', 'T'));
        } else {
          scheduledTime = DateTime.parse(timeStr);
        }
      } catch (_) {}
    }

    // 解析语言ID转语言代码
    final int languageId = _parseInt(draft['language_id']);
    final String languageCode = _getLanguageCode(languageId);

    // 解析短篇内容（短篇使用 temp_chapter_content 存储正文）
    final int workType = _parseInt(draft['work_type']);
    final String shortContent = workType == 2
        ? (draft['temp_chapter_content']?.toString() ?? '')
        : '';

    // 解析长篇临时章节内容
    final String chapterTitle = workType == 1
        ? (draft['temp_chapter_title']?.toString() ?? '')
        : '';
    final String chapterContent = workType == 1
        ? (draft['temp_chapter_content']?.toString() ?? '')
        : '';

    return CreatorWorkDraft(
      local_id: 'work_${draft['novel_id']}',
      novel_id: _parseIntNullable(draft['novel_id']),
      revision_id: _parseIntNullable(draft['id']),
      novel_language_id: _parseIntNullable(draft['novel_language_id']),
      lock_version: _parseIntNullable(draft['lock_version']),
      title: draft['title']?.toString() ?? '',
      introduction: draft['introduction']?.toString() ?? '',
      work_type: workType == 1
          ? CreatorWorkType.long
          : CreatorWorkType.short,
      is_completed: _parseInt(draft['serialization_status']) == 2,
      language_code: languageCode,
      category_ids: categoryIds,
      short_content: shortContent,
      chapters: const [],
      status: CreatorWorkStatus.draft,
      release_mode: _parseInt(draft['release_mode']) == 1
          ? CreatorReleaseMode.immediate
          : CreatorReleaseMode.scheduled,
      scheduled_publish_time: scheduledTime,
      update_time: DateTime.now(),
      cover_url: draft['cover_url']?.toString(),
      saved_step: _parseInt(draft['saved_step']),
      preferences: preferences,
      rights_confirmed: _parseInt(draft['rights_confirmed']) == 1,
      chapter_title: chapterTitle,
      chapter_content: chapterContent,
    );
  }

  /// 安全解析整数
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  /// 安全解析可空整数
  int? _parseIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  /// 语言ID转语言代码
  String _getLanguageCode(int languageId) {
    const Map<int, String> languageMap = {
      1: 'zh',
      2: 'en',
      3: 'fr',
      4: 'es',
      5: 'ar',
      6: 'pt',
      7: 'id',
      8: 'ja',
      9: 'ko',
      10: 'de',
      11: 'it',
      12: 'tr',
      13: 'th',
      14: 'vi',
      15: 'ms',
      16: 'sw',
    };
    return languageMap[languageId] ?? 'en';
  }

  /// 从作品基本信息构建 CreatorWorkDraft（无草稿时）
  CreatorWorkDraft _buildDraftFromNovel(
    Map<String, dynamic>? novel,
    List<dynamic> categories,
  ) {
    final List<int> categoryIds = categories
        .map((c) => _parseInt(c['category_id']))
        .where((id) => id > 0)
        .toList();

    return CreatorWorkDraft(
      local_id: 'work_${widget.work.id}',
      novel_id: widget.work.id,
      title: widget.work.title,
      introduction: widget.work.introduction ?? '',
      work_type: widget.work.is_long_novel
          ? CreatorWorkType.long
          : CreatorWorkType.short,
      is_completed: widget.work.serialization_status == 2,
      language_code: 'zh',
      category_ids: categoryIds,
      short_content: '',
      chapters: const [],
      status: CreatorWorkStatus.draft,
      release_mode: CreatorReleaseMode.immediate,
      scheduled_publish_time: null,
      update_time: DateTime.now(),
      cover_url: widget.work.cover_url,
      saved_step: 0,
      preferences: const {},
      rights_confirmed: false,
    );
  }

  /// 导航到章节页面
  void _navigate_to_chapter(CreatorChapterModel chapter) {
    // TODO: 导航到章节编辑页面
  }

  /// 编辑短篇正文
  void _edit_short_story() {
    // TODO: 导航到短篇编辑页面
  }
}
