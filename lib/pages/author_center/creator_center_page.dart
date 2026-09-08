// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/author_center/logic.dart';
import 'package:app/pages/author_center/store.dart';
import 'package:app/pages/author_center/models/creator_backend_models.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/author_center/widgets/backend_work_card.dart';
import 'package:app/pages/author_center/work_detail_page.dart';
import 'package:app/pages/work_editor/index.dart';
import 'package:app/config/font_config.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 创作者中心页面（对接后端API）
class CreatorCenterPage extends StatefulWidget {
  const CreatorCenterPage({super.key});

  @override
  State<CreatorCenterPage> createState() => _CreatorCenterPageState();
}

class _CreatorCenterPageState extends State<CreatorCenterPage> with SingleTickerProviderStateMixin {
  final DeviceInfo _device_info = Get.find<DeviceInfo>();
  late final CreatorStore _store;
  late TabController _tab_controller;

  /// Tab列表
  static const List<String> _tab_keys = [
    '全部',
    '草稿',
    '审核中',
    '已发布',
    '已驳回',
  ];

  @override
  void initState() {
    super.initState();
    // 确保Store被初始化
    if (Get.isRegistered<CreatorStore>()) {
      _store = Get.find<CreatorStore>();
    } else {
      _store = Get.put(CreatorStore());
    }
    _tab_controller = TabController(length: _tab_keys.length, vsync: this);
    _tab_controller.addListener(_on_tab_changed);
  }

  @override
  void dispose() {
    _tab_controller.removeListener(_on_tab_changed);
    _tab_controller.dispose();
    super.dispose();
  }

  /// Tab切换回调
  void _on_tab_changed() {
    if (!_tab_controller.indexIsChanging) return;

    switch (_tab_controller.index) {
      case 0: // 全部
        _store.clearFilter();
        break;
      case 1: // 草稿
        _store.setFilter(auditStatus: 1);
        break;
      case 2: // 审核中
        _store.setFilter(auditStatus: 2);
        break;
      case 3: // 已发布
        _store.setFilter(publicStatus: 2);
        break;
      case 4: // 已驳回
        _store.setFilter(auditStatus: 4);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool is_dark = Theme.of(context).brightness == Brightness.dark;
    final bool is_cjk = LanguageUtil.is_cjk_language(context.locale.languageCode);

    return Scaffold(
      backgroundColor: is_dark ? const Color(0xFF1A1A1A) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          easy.tr('creator_center.title'),
          style: TextStyle(
            fontSize: is_cjk ? 18 : 16,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
          ),
        ),
        backgroundColor: is_dark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: is_dark ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _show_create_work_dialog(context),
            tooltip: easy.tr('creator_center.create_work'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 统计卡片
          _build_stats_card(is_dark, is_cjk),

          // Tab栏
          Container(
            color: is_dark ? const Color(0xFF1A1A1A) : Colors.white,
            child: TabBar(
              controller: _tab_controller,
              isScrollable: true,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: is_dark ? Colors.white60 : Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: _tab_keys.map((key) => Tab(text: key)).toList(),
            ),
          ),

          // 作品列表
          Expanded(
            child: Obx(() {
              if (_store.isWorksLoading.value && _store.works.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                  ),
                );
              }

              if (_store.works.isEmpty) {
                return _build_empty_state(is_dark, is_cjk);
              }

              return RefreshIndicator(
                onRefresh: _store.refreshWorks,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _store.works.length + (_store.currentPage.value < _store.totalPages.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    // 加载更多
                    if (index == _store.works.length) {
                      _store.loadMoreWorks();
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final work = _store.works[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BackendWorkCard(
                        work: work,
                        is_dark: is_dark,
                        is_cjk: is_cjk,
                        on_tap: () => _navigate_to_work_detail(work),
                        on_primary_action: () => _navigate_to_work_detail(work),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 构建统计卡片
  Widget _build_stats_card(bool is_dark, bool is_cjk) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Obx(() {
        final dashboard = _store.dashboardData.value;
        final totalWorks = dashboard?['total_works'] ?? 0;
        final totalFavorites = dashboard?['total_favorites'] ?? 0;
        final totalComments = dashboard?['total_comments'] ?? 0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _build_stat_item(
              easy.tr('creator_center.stats_works'),
              totalWorks.toString(),
              is_cjk,
            ),
            _build_stat_item(
              easy.tr('creator_center.stats_favorites'),
              totalFavorites.toString(),
              is_cjk,
            ),
            _build_stat_item(
              easy.tr('creator_center.stats_comments'),
              totalComments.toString(),
              is_cjk,
            ),
          ],
        );
      }),
    );
  }

  /// 构建统计项
  Widget _build_stat_item(String label, String value, bool is_cjk) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: is_cjk ? 24 : 20,
            fontWeight: FontConfig.adjustedWeight(FontWeight.bold),
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: is_cjk ? 12 : 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  /// 构建空状态
  Widget _build_empty_state(bool is_dark, bool is_cjk) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 64,
            color: is_dark ? Colors.white24 : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            easy.tr('creator_center.empty_title'),
            style: TextStyle(
              fontSize: is_cjk ? 16 : 14,
              color: is_dark ? Colors.white54 : Colors.grey,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            easy.tr('creator_center.empty_subtitle'),
            style: TextStyle(
              fontSize: is_cjk ? 14 : 12,
              color: is_dark ? Colors.white38 : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _show_create_work_dialog(context),
            icon: const Icon(Icons.add),
            label: Text(easy.tr('creator_center.create_work')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示创建作品对话框
  void _show_create_work_dialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CreateWorkSheet(store: _store),
    );
  }

  /// 导航到作品详情
  void _navigate_to_work_detail(CreatorWorkModel work) {
    _store.selectWork(work);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatorWorkDetailPage(work: work),
      ),
    );
  }
}

/// 创建作品底部弹窗
class _CreateWorkSheet extends StatefulWidget {
  final CreatorStore store;

  const _CreateWorkSheet({required this.store});

  @override
  State<_CreateWorkSheet> createState() => _CreateWorkSheetState();
}

class _CreateWorkSheetState extends State<_CreateWorkSheet> {
  int _selected_type = 1; // 1=长篇, 2=短篇
  final TextEditingController _title_controller = TextEditingController();
  final TextEditingController _intro_controller = TextEditingController();
  bool _is_creating = false;

  @override
  void dispose() {
    _title_controller.dispose();
    _intro_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(context.locale.languageCode);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              easy.tr('creator_center.create_work'),
              style: TextStyle(
                fontSize: is_cjk ? 18 : 16,
                fontWeight: FontConfig.adjustedWeight(FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 作品类型选择
          Text(
            easy.tr('creator_center.work_type'),
            style: TextStyle(
              fontSize: is_cjk ? 14 : 12,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _build_type_option(1, easy.tr('creator_center.work_type_long'), Icons.book, is_cjk),
              const SizedBox(width: 12),
              _build_type_option(2, easy.tr('creator_center.work_type_short'), Icons.article, is_cjk),
            ],
          ),
          const SizedBox(height: 16),

          // 标题输入
          TextField(
            controller: _title_controller,
            decoration: InputDecoration(
              labelText: easy.tr('creator_center.title_label'),
              hintText: easy.tr('creator_center.title_hint'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLength: 80,
          ),
          const SizedBox(height: 12),

          // 简介输入
          TextField(
            controller: _intro_controller,
            decoration: InputDecoration(
              labelText: easy.tr('creator_center.intro_label'),
              hintText: easy.tr('creator_center.intro_hint'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 3,
            maxLength: 2000,
          ),
          const SizedBox(height: 20),

          // 创建按钮
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _is_creating ? null : _create_work,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _is_creating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      easy.tr('creator_center.create_work'),
                      style: TextStyle(
                        fontSize: is_cjk ? 16 : 14,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 构建类型选项
  Widget _build_type_option(int type, String label, IconData icon, bool is_cjk) {
    final bool is_selected = _selected_type == type;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selected_type = type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: is_selected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: is_selected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300]!,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: is_selected
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: is_cjk ? 14 : 12,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                  color: is_selected
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 创建作品
  Future<void> _create_work() async {
    final title = _title_controller.text.trim();
    final intro = _intro_controller.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(easy.tr('creator_center.title_required'))),
      );
      return;
    }

    if (intro.length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(easy.tr('creator_center.intro_too_short'))),
      );
      return;
    }

    setState(() => _is_creating = true);

    try {
      final work = await widget.store.createWork(
        workType: _selected_type,
        languageId: 1, // 默认中文
        title: title,
        introduction: intro,
      );

      if (work != null && mounted) {
        Navigator.pop(context);

        // 导航到编辑器页面
        final CreatorWorkDraft workDraft = CreatorWorkDraft(
          local_id: 'work_${work.id}',
          novel_id: work.id,
          title: title,
          introduction: intro,
          work_type: _selected_type == 1
              ? CreatorWorkType.long
              : CreatorWorkType.short,
          is_completed: false,
          language_code: 'zh',
          category_ids: const [],
          short_content: '',
          chapters: const [],
          status: CreatorWorkStatus.draft,
          release_mode: CreatorReleaseMode.immediate,
          scheduled_publish_time: null,
          update_time: DateTime.now(),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreatorWorkEditorPage(initial_work: workDraft),
          ),
        ).then((result) {
          // 返回时刷新作品列表
          if (result != null) {
            widget.store.refreshWorks();
          }
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(easy.tr('creator_center.create_failed'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _is_creating = false);
      }
    }
  }
}
