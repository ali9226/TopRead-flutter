// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/author_center/store.dart';
import 'package:app/pages/author_center/models/creator_backend_models.dart';
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
  void _navigate_to_edit() {
    // TODO: 导航到作品编辑页面
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
