// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/author_center/models/creator_backend_models.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 后端数据作品卡片
class BackendWorkCard extends StatelessWidget {
  final CreatorWorkModel work;
  final bool is_dark;
  final bool is_cjk;
  final VoidCallback on_tap;
  final VoidCallback? on_primary_action;

  const BackendWorkCard({
    super.key,
    required this.work,
    required this.is_dark,
    required this.is_cjk,
    required this.on_tap,
    this.on_primary_action,
  });

  @override
  Widget build(BuildContext context) {
    final Color status_color = _status_color();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: on_tap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: is_dark ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: is_dark ? Colors.white12 : Colors.grey[200]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(is_dark ? 0.14 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _build_cover(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 状态标签 - 修复溢出问题
                        _build_status_badge(status_color),
                        const SizedBox(height: 9),
                        // 标题
                        Text(
                          work.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: is_dark ? Colors.white : Colors.black87,
                            fontSize: 17,
                            height: 1.25,
                            fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 7),
                        // 类型标签
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          children: [
                            _build_meta_pill(work.work_type_text),
                            if (work.is_published)
                              _build_meta_pill(work.serialization_status_text),
                          ],
                        ),
                        const SizedBox(height: 11),
                        // 统计信息
                        Text(
                          _build_content_summary(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: is_dark ? Colors.white54 : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                          ),
                        ),
                        const SizedBox(height: 5),
                        // 更新时间
                        Text(
                          '更新: ${_format_time(work.creator_update_time ?? work.create_time)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: is_dark ? Colors.white38 : Colors.grey[400],
                            fontSize: 11,
                            fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Divider(height: 1, color: is_dark ? Colors.white12 : Colors.grey[200]),
              const SizedBox(height: 11),
              _build_action_row(),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建封面
  Widget _build_cover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: work.cover_url != null && work.cover_url!.isNotEmpty
          ? Image.network(
              work.cover_url!,
              width: 80,
              height: 106,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _build_default_cover(),
            )
          : _build_default_cover(),
    );
  }

  /// 构建默认封面
  Widget _build_default_cover() {
    final int palette_index = work.id.hashCode.abs() % 4;
    const List<List<Color>> palettes = [
      [Color(0xFF4D5F80), Color(0xFF202636)],
      [Color(0xFF926F5A), Color(0xFF382A27)],
      [Color(0xFF4A7A70), Color(0xFF1F3633)],
      [Color(0xFF7A5A8A), Color(0xFF2D1F36)],
    ];
    final List<Color> palette = palettes[palette_index];

    return Container(
      width: 80,
      height: 106,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          work.title.isNotEmpty ? work.title[0] : '?',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontConfig.adjustedWeight(FontWeight.bold),
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  /// 构建状态标签 - 修复溢出
  Widget _build_status_badge(Color status_color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status_color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        work.status_text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
          color: status_color,
        ),
      ),
    );
  }

  /// 构建元信息标签
  Widget _build_meta_pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: is_dark ? Colors.white12 : Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: is_dark ? Colors.white54 : Colors.grey[600],
        ),
      ),
    );
  }

  /// 构建内容摘要
  String _build_content_summary() {
    final parts = <String>[];
    if (work.chapter_count > 0) parts.add('${work.chapter_count}章');
    if (work.word_count > 0) parts.add('${work.word_count}字');
    if (work.read_count > 0) parts.add('${work.read_count}阅读');
    if (work.favorite_count > 0) parts.add('${work.favorite_count}收藏');
    return parts.isEmpty ? '暂无数据' : parts.join(' · ');
  }

  /// 构建操作行
  Widget _build_action_row() {
    return Row(
      children: [
        // 驳回原因提示
        if (work.is_rejected && work.pending_submission != null)
          Expanded(
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.red[300]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '已驳回',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red[300],
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          const Spacer(),
        const SizedBox(width: 10),
        // 编辑按钮
        OutlinedButton(
          onPressed: on_tap,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(72, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            foregroundColor: is_dark ? Colors.white70 : Colors.black87,
            side: BorderSide(
              color: is_dark ? Colors.white24 : Colors.grey[300]!,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          child: Text(
            is_cjk ? '编辑' : 'Edit',
            style: TextStyle(
              fontSize: is_cjk ? 12 : 10.5,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 主操作按钮
        FilledButton.icon(
          onPressed: on_primary_action ?? on_tap,
          icon: Icon(
            work.is_long_novel ? Icons.edit_note_rounded : Icons.subject_rounded,
            size: 17,
          ),
          label: Text(
            work.is_long_novel
                ? (is_cjk ? '写章节' : 'Write')
                : (is_cjk ? '编辑内容' : 'Edit'),
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size(96, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: const Color(0xFF1A1A18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
            textStyle: TextStyle(
              fontSize: is_cjk ? 12 : 10.5,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  /// 获取状态颜色
  Color _status_color() {
    if (work.is_draft) return Colors.grey;
    if (work.is_reviewing) return Colors.orange;
    if (work.is_rejected) return Colors.red;
    if (work.is_published) return Colors.green;
    if (work.is_off_shelf) return Colors.red[300]!;
    return Colors.grey;
  }

  /// 格式化时间
  String _format_time(String time_str) {
    try {
      final time = DateTime.parse(time_str);
      return DateFormat('MM-dd HH:mm').format(time);
    } catch (e) {
      return time_str;
    }
  }
}
