// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';

import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/author_center/logic.dart';
import 'package:app/pages/author_center/chapter_editor/index.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/author_center/widgets/creator_header.dart';
import 'package:app/pages/author_center/widgets/creator_work_tab.dart';
import 'package:app/pages/author_center/widgets/nickname_badge.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/router/router_back.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 支持在首次创建 ScrollPosition 前更新初始偏移的控制器。
class _CreatorTabScrollController extends ScrollController {
  double _prepared_initial_scroll_offset = 0;
  bool _has_created_position = false;

  _CreatorTabScrollController({required super.debugLabel});

  /// 仅在目标 Tab 从未布局时设置首帧偏移。
  void prepare_initial_scroll_offset(double offset) {
    if (_has_created_position) return;
    _prepared_initial_scroll_offset = offset;
  }

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    final double initial_pixels = _has_created_position
        ? initialScrollOffset
        : _prepared_initial_scroll_offset;
    _has_created_position = true;
    return ScrollPositionWithSingleContext(
      physics: physics,
      context: context,
      initialPixels: initial_pixels,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

/// 已认证作者的创作工作台。
class AuthorView extends StatefulWidget {
  const AuthorView({super.key});

  @override
  State<AuthorView> createState() => _AuthorViewState();
}

class _AuthorViewState extends State<AuthorView> with TickerProviderStateMixin {
  final DeviceInfo _device_info = Get.find<DeviceInfo>();
  final UserInformation _user_information = Get.find<UserInformation>();

  late List<CreatorWorkDraft> _works;
  late TabController _tab_controller;

  /// Dashboard统计数据
  int _total_works = 0;
  int _total_favorites = 0;
  int _total_comments = 0;

  /// 每个 Tab 独占的滚动控制器。
  late final List<_CreatorTabScrollController> _tab_scroll_controllers;

  /// 合并 Tab 切换动画与全部独立滚动位置，驱动共享头部绘制。
  late final Listenable _header_listenable;

  /// 横向切换 Tab 期间锁定的头部纵向距离。
  late final ValueNotifier<double?> _horizontal_header_offset_lock;

  /// 横向切换完成后用于平滑恢复目标 Tab 头部位置。
  late final AnimationController _header_transition_controller;

  /// 当前头部过渡的折叠距离动画。
  Animation<double>? _header_transition_animation;

  /// 用于忽略旧横向手势延迟触发的解锁回调。
  int _horizontal_scroll_generation = 0;

  /// 上一个已稳定记录的 Tab 索引。
  int _active_tab_index = 0;

  /// 目标 Tab 尚未完成布局时，临时保持共享头部吸顶。
  bool _preserve_pinned_header_on_tab_change = false;

  /// 头部从展开到吸顶需要的滚动距离。
  late double _header_collapse_range;

  /// 头部最大展开高度（含状态栏）。
  late double _header_max_extent;

  /// 头部最小高度（折叠态）。
  late double _header_min_extent;

  /// 创作中心固定状态 Tab 数量。
  static const int _tab_count = 6;

  /// 是否有本地草稿。
  bool _has_draft = false;

  /// 随机头像索引（0-9）。
  late final int _random_avatar_index;

  @override
  void initState() {
    _random_avatar_index = NicknameBadge.generate_random_index();
    super.initState();
    _works = kDebugMode ? _build_demo_works() : <CreatorWorkDraft>[];

    /// 加载本地草稿。
    _load_local_drafts();
    _tab_controller = TabController(length: _tab_count, vsync: this);
    _tab_scroll_controllers = List<_CreatorTabScrollController>.generate(
      _tab_count,
      (int index) => _CreatorTabScrollController(
        debugLabel: 'creator_center_content_tab_$index',
      ),
      growable: false,
    );
    _horizontal_header_offset_lock = ValueNotifier<double?>(null);
    _header_transition_controller = AnimationController(
      vsync: this,
      duration: AuthorStyle.header_tab_transition_duration,
    );
    _header_listenable = Listenable.merge(<Listenable>[
      _tab_controller.animation!,
      _horizontal_header_offset_lock,
      _header_transition_controller,
      ..._tab_scroll_controllers,
    ]);
    _tab_controller.addListener(_on_tab_index_changed);

    // TODO 加载Dashboard统计数据
    _load_dashboard_data();
  }

  /// 加载Dashboard统计数据
  Future<void> _load_dashboard_data() async {
    try {
      final result = await CreatorLogic.getDashboard();
      if (result != null && mounted) {
        setState(() {
          _total_works = result['total_works'] ?? 0;
          _total_favorites = result['total_favorites'] ?? 0;
          _total_comments = result['total_comments'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('加载Dashboard失败: $e');
    }
  }

  /// 检查后端是否有草稿。
  Future<void> _load_local_drafts() async {
    try {
      // 使用专用的草稿列表接口检查是否有草稿
      final result = await CreatorLogic.getDraftList(page: 1, pageSize: 1);

      if (!mounted) return;

      final hasDrafts = result != null &&
          (result['list'] as List? ?? []).isNotEmpty;

      setState(() {
        _has_draft = hasDrafts;
      });
    } catch (e) {
      debugPrint('检查后端草稿失败: $e');
    }
  }

  /// 测量文本在给定宽度下的实际行数。
  static int _measure_line_count(
    String text,
    TextStyle style,
    double maxWidth,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter.computeLineMetrics().length;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final double status_bar = MediaQuery.paddingOf(context).top;
    _header_min_extent = status_bar +
        AuthorStyle.header_toolbar_height +
        AuthorStyle.header_tab_bar_height;

    // 测量标题和副标题行数，动态计算高度。
    // 基础360 = 单行标题 + 2行副标题。
    // 标题每多一行 +30，副标题超过2行每多一行 +15。
    final bool is_cjk = LanguageUtil.is_cjk_language(context.locale.languageCode);
    final String title_text = easy.tr('creator_center.hero_title');
    final String subtitle_text = easy.tr('creator_center.hero_subtitle');
    final TextStyle title_style = TextStyle(
      fontSize: is_cjk ? AuthorStyle.hero_title_size_cjk : AuthorStyle.hero_title_size_alphabetic,
      height: is_cjk ? 1.24 : 1.28,
      fontWeight: AuthorStyle.title_weight,
      letterSpacing: is_cjk ? 0.2 : -0.2,
    );
    final TextStyle subtitle_style = TextStyle(
      fontSize: is_cjk ? 12.5 : 11.5,
      height: is_cjk ? 1.42 : 1.48,
      fontWeight: AuthorStyle.body_weight,
    );
    final double content_width = MediaQuery.sizeOf(context).width -
        AuthorStyle.header_content_padding * 2;
    final int title_lines = _measure_line_count(title_text, title_style, content_width);
    final int subtitle_lines = _measure_line_count(subtitle_text, subtitle_style, content_width);
    final int title_extra = title_lines - 1;
    final int subtitle_extra = subtitle_lines - 2;
    _header_max_extent = status_bar + 360 + title_extra * 30 + subtitle_extra * 15;
    _header_collapse_range = _header_max_extent - _header_min_extent;

    debugPrint('[AuthorView] title_lines=$title_lines, title_extra=$title_extra, subtitle_lines=$subtitle_lines, subtitle_extra=$subtitle_extra, _header_max_extent=$_header_max_extent');
  }

  @override
  void dispose() {
    _tab_controller.removeListener(_on_tab_index_changed);
    for (final ScrollController controller in _tab_scroll_controllers) {
      controller.dispose();
    }
    _header_transition_controller.dispose();
    _horizontal_header_offset_lock.dispose();
    _tab_controller.dispose();
    super.dispose();
  }

  CreatorWorkStatus? _status_for_tab(int index) {
    const List<CreatorWorkStatus?> statuses = <CreatorWorkStatus?>[
      null,
      CreatorWorkStatus.draft,
      CreatorWorkStatus.reviewing,
      CreatorWorkStatus.scheduled,
      CreatorWorkStatus.published,
      CreatorWorkStatus.rejected,
    ];
    return statuses[index];
  }

  List<CreatorWorkDraft> _filtered_works(int tab_index) {
    final CreatorWorkStatus? status = _status_for_tab(tab_index);
    if (status == null) return List<CreatorWorkDraft>.unmodifiable(_works);
    return _works
        .where((CreatorWorkDraft work) => work.status == status)
        .toList(growable: false);
  }

  Future<void> _create_work() async {
    final CreatorWorkDraft? result =
        await context.push<CreatorWorkDraft>('/work_editor');
    if (result == null || !mounted) return;
    setState(() {
      _works.insert(0, result);
      _has_draft =
          _works.any((w) => w.status == CreatorWorkStatus.draft);
    });
  }

  Future<void> _edit_work(CreatorWorkDraft work) async {
    final CreatorWorkDraft? result =
        await context.push<CreatorWorkDraft>('/work_editor', extra: work);
    if (result == null || !mounted) return;

    final int index = _works.indexWhere(
      (CreatorWorkDraft item) => item.local_id == work.local_id,
    );

    setState(() {
      if (index >= 0) {
        _works[index] = result;
      } else {
        _works.insert(0, result);
      }
      /// 刷新草稿状态。
      _has_draft =
          _works.any((w) => w.status == CreatorWorkStatus.draft);
    });
  }

  Future<void> _continue_writing(CreatorWorkDraft work) async {
    if (work.work_type == CreatorWorkType.short) {
      await _edit_work(work);
      return;
    }
    final CreatorChapterDraft? chapter = await Navigator.of(context)
        .push<CreatorChapterDraft>(
          MaterialPageRoute<CreatorChapterDraft>(
            builder: (BuildContext context) =>
                ChapterEditorPage(chapter_number: work.chapters.length + 1),
          ),
        );
    if (chapter == null || !mounted) return;
    final int index = _works.indexWhere(
      (CreatorWorkDraft item) => item.local_id == work.local_id,
    );
    if (index < 0) return;
    setState(() {
      _works[index] = work.copy_with(
        chapters: <CreatorChapterDraft>[...work.chapters, chapter],
        status: CreatorWorkStatus.draft,
        update_time: DateTime.now(),
        is_demo: false,
      );
    });
  }

  Future<void> _continue_latest_draft() async {
    try {
      // 使用专用的草稿列表接口
      final result = await CreatorLogic.getDraftList(page: 1, pageSize: 1);

      if (result != null) {
        final list = result['list'] as List? ?? [];
        if (list.isNotEmpty) {
          final draftData = list.first as Map<String, dynamic>;
          final workDraft = _buildDraftFromBackend(draftData, null, []);

          if (mounted) {
            await _edit_work(workDraft);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('获取后端草稿失败: $e');
    }

    // 后端没有草稿，尝试从本地内存中查找
    final List<CreatorWorkDraft> drafts =
        _works
            .where(
              (CreatorWorkDraft work) => work.status == CreatorWorkStatus.draft,
            )
            .toList(growable: false)
          ..sort(
            (CreatorWorkDraft left, CreatorWorkDraft right) =>
                right.update_time.compareTo(left.update_time),
          );

    if (drafts.isNotEmpty) {
      await _edit_work(drafts.first);
      return;
    }

    // 都没有，创建新作品
    await _create_work();
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

  /// 从作品列表数据构建 CreatorWorkDraft（无详细草稿数据时）
  CreatorWorkDraft _buildDraftFromWorkData(
    Map<String, dynamic> workData,
    List<dynamic> categories,
  ) {
    final List<int> categoryIds = categories
        .map((c) => _parseInt(c['category_id']))
        .where((id) => id > 0)
        .toList();

    return CreatorWorkDraft(
      local_id: 'work_${workData['id']}',
      novel_id: _parseIntNullable(workData['id']),
      title: workData['title']?.toString() ?? '',
      introduction: workData['introduction']?.toString() ?? '',
      work_type: _parseInt(workData['work_type']) == 1
          ? CreatorWorkType.long
          : CreatorWorkType.short,
      is_completed: _parseInt(workData['serialization_status']) == 2,
      language_code: 'zh',
      category_ids: categoryIds,
      short_content: '',
      chapters: const [],
      status: CreatorWorkStatus.draft,
      release_mode: CreatorReleaseMode.immediate,
      scheduled_publish_time: null,
      update_time: DateTime.now(),
      cover_url: workData['cover_url']?.toString(),
      saved_step: 0,
      preferences: const {},
      rights_confirmed: false,
    );
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );

    return Obx(() {
      final bool is_dark = _device_info.dark.value;
      final Color background = AuthorStyle.background(is_dark);
      final String author_name =
          _user_information.userInfo.value?.name.trim().isNotEmpty == true
          ? _user_information.userInfo.value!.name.trim()
          : easy.tr('creator_center.author_fallback_name');
      final int works_count = kDebugMode
          ? _works.length
          : _works.where((CreatorWorkDraft work) => !work.is_demo).length;

      return Scaffold(
        backgroundColor: background,
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: NotificationListener<ScrollNotification>(
                onNotification: _on_tab_view_scroll_notification,
                child: TabBarView(
                  controller: _tab_controller,
                  physics: const BouncingScrollPhysics(),
                  children: List<Widget>.generate(
                    _tab_count,
                    (int tab_index) => CreatorWorkTab(
                      key: ValueKey<String>('creator_work_tab_$tab_index'),
                      tab_index: tab_index,
                      works: _filtered_works(tab_index),
                      is_dark: is_dark,
                      is_cjk: is_cjk,
                      scroll_controller: _tab_scroll_controllers[tab_index],
                      header_spacer_height: _header_max_extent,
                      minimum_header_height: _header_min_extent,
                      minimum_scroll_extent: _header_max_extent - _header_min_extent,
                      on_create_work: _create_work,
                      on_edit_work: _edit_work,
                      on_primary_action: _continue_writing,
                    ),
                    growable: false,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _header_listenable,
                builder: (BuildContext context, Widget? child) {
                  final double current_height = _current_header_height(
                    maximum_extent: _header_max_extent,
                    minimum_extent: _header_min_extent,
                  );

                  return CreatorHeaderOverlay(
                    tab_controller: _tab_controller,
                    current_height: current_height,
                    is_dark: is_dark,
                    is_cjk: is_cjk,
                    author_name: author_name,
                    works_count: _total_works,
                    favorites_count: _total_favorites.toString(),
                    comments_count: _total_comments.toString(),
                    on_back: () => routerBack(context),
                    on_create_work: _create_work,
                    on_continue_writing: _continue_latest_draft,
                    on_open_guide: () => _show_creator_guide(is_dark),
                    has_draft: _has_draft,
                    avatar_url: _user_information.userInfo.value?.avatarUrl,
                    random_avatar_index: _random_avatar_index,
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 读取当前头部应该展示的纵向折叠距离。
  ///
  /// 横向手势期间始终使用手势开始时的固定值，不再在两个
  /// Tab 的不同滚动位置之间插值，避免横滑带动头部纵向位移。
  double _effective_header_scroll_offset() {
    final double? locked_offset = _horizontal_header_offset_lock.value;
    if (locked_offset != null) return locked_offset;
    if (_header_transition_controller.isAnimating &&
        _header_transition_animation != null) {
      return _header_transition_animation!.value;
    }
    if (_preserve_pinned_header_on_tab_change) {
      return _header_collapse_range;
    }
    return _tab_scroll_offset(_active_tab_index);
  }

  /// 监听 TabBarView 的横向滚动，切换期间锁定头部高度。
  bool _on_tab_view_scroll_notification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.horizontal) return false;

    if (notification is ScrollStartNotification) {
      _horizontal_scroll_generation += 1;
      _lock_horizontal_header_offset();
    } else if (notification is ScrollEndNotification) {
      final int completed_generation = _horizontal_scroll_generation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || completed_generation != _horizontal_scroll_generation) {
          return;
        }
        _release_horizontal_header_offset_with_transition();
      });
    }
    return false;
  }

  /// 保存横向切换开始时的头部折叠位置。
  void _lock_horizontal_header_offset() {
    if (_horizontal_header_offset_lock.value != null) return;

    final double current_offset =
        _header_transition_controller.isAnimating &&
            _header_transition_animation != null
        ? _header_transition_animation!.value
        : _preserve_pinned_header_on_tab_change
        ? _header_collapse_range
        : _tab_scroll_offset(_active_tab_index);
    _header_transition_controller.stop();
    _horizontal_header_offset_lock.value = current_offset.clamp(
      0.0,
      _header_collapse_range,
    );
    if (current_offset >=
        _header_collapse_range - AuthorStyle.scroll_extent_tolerance) {
      _prepare_tabs_for_pinned_header();
    }
  }

  /// 在吸顶状态的横向手势开始时预先对齐其他 Tab。
  ///
  /// 未创建的 Tab 直接使用吸顶偏移创建 ScrollPosition；
  /// 已布局的 Tab 在进入屏幕前即完成对齐，避免首帧空白。
  void _prepare_tabs_for_pinned_header() {
    for (int index = 0; index < _tab_count; index++) {
      if (index == _active_tab_index) continue;

      final _CreatorTabScrollController controller =
          _tab_scroll_controllers[index];
      controller.prepare_initial_scroll_offset(_header_collapse_range);
      if (!controller.hasClients ||
          !controller.position.hasContentDimensions ||
          controller.position.maxScrollExtent +
                  AuthorStyle.scroll_extent_tolerance <
              _header_collapse_range ||
          controller.offset + AuthorStyle.scroll_extent_tolerance >=
              _header_collapse_range) {
        continue;
      }
      controller.jumpTo(_header_collapse_range);
    }
  }

  /// 从横向手势的锁定位置平滑过渡到目标 Tab 的保存位置。
  void _release_horizontal_header_offset_with_transition() {
    final double? begin_offset = _horizontal_header_offset_lock.value;
    if (begin_offset == null) return;

    final double target_offset =
        (_preserve_pinned_header_on_tab_change
                ? _header_collapse_range
                : _tab_scroll_offset(_active_tab_index))
            .clamp(0.0, _header_collapse_range);
    if ((target_offset - begin_offset).abs() <=
        AuthorStyle.scroll_extent_tolerance) {
      _horizontal_header_offset_lock.value = null;
      return;
    }

    _header_transition_animation =
        Tween<double>(begin: begin_offset, end: target_offset).animate(
          CurvedAnimation(
            parent: _header_transition_controller,
            curve: Curves.easeOutCubic,
          ),
        );
    _header_transition_controller.forward(from: 0);
    _horizontal_header_offset_lock.value = null;
  }

  /// 读取指定 Tab 的滚动距离；尚未挂载的 Tab 从顶部开始。
  double _tab_scroll_offset(int tab_index) {
    final ScrollController controller = _tab_scroll_controllers[tab_index];
    if (!controller.hasClients) return 0;
    return controller.offset;
  }

  /// 在已吸顶状态下切换 Tab 时，让目标 Tab 继续保持吸顶。
  ///
  /// 只补齐头部折叠所需的距离，目标 Tab 原有的内容滚动距离
  /// 若更大则完全保留，不会被覆盖。
  void _on_tab_index_changed() {
    final int next_index = _tab_controller.index;
    if (next_index == _active_tab_index) return;

    if (_tab_controller.indexIsChanging) {
      _lock_horizontal_header_offset();
    }

    final bool keep_header_pinned =
        _tab_scroll_offset(_active_tab_index) >=
        _header_collapse_range - AuthorStyle.scroll_extent_tolerance;
    _active_tab_index = next_index;
    _preserve_pinned_header_on_tab_change = keep_header_pinned;

    if (keep_header_pinned) {
      _tab_scroll_controllers[next_index].prepare_initial_scroll_offset(
        _header_collapse_range,
      );
    }
    if (keep_header_pinned && !_try_pin_tab_header(next_index)) {
      _restore_pinned_header(next_index, attempt: 0);
    }
  }

  /// 在目标 Tab 已完成布局时立即对齐吸顶距离。
  bool _try_pin_tab_header(int tab_index) {
    final ScrollController controller = _tab_scroll_controllers[tab_index];
    if (!controller.hasClients) return false;

    final double maximum_offset = controller.position.maxScrollExtent;
    if (maximum_offset + AuthorStyle.scroll_extent_tolerance <
        _header_collapse_range) {
      return false;
    }

    if (controller.offset + AuthorStyle.scroll_extent_tolerance <
        _header_collapse_range) {
      controller.jumpTo(_header_collapse_range);
    }
    _preserve_pinned_header_on_tab_change = false;
    return true;
  }

  /// 在目标 Tab 完成布局后恢复吸顶距离。
  void _restore_pinned_header(int tab_index, {required int attempt}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _tab_controller.index != tab_index) return;

      final ScrollController controller = _tab_scroll_controllers[tab_index];
      if (!controller.hasClients) {
        if (attempt < AuthorStyle.pin_restore_max_attempts) {
          _restore_pinned_header(tab_index, attempt: attempt + 1);
        }
        return;
      }

      if (_try_pin_tab_header(tab_index)) return;

      if (attempt < AuthorStyle.pin_restore_max_attempts) {
        _restore_pinned_header(tab_index, attempt: attempt + 1);
        return;
      }

      final double maximum_offset = controller.position.maxScrollExtent;
      final double target_offset = _header_collapse_range.clamp(
        controller.position.minScrollExtent,
        maximum_offset,
      );
      if (controller.offset + AuthorStyle.scroll_extent_tolerance <
          target_offset) {
        controller.jumpTo(target_offset);
      }
      _preserve_pinned_header_on_tab_change = false;
    });
  }

  /// 将当前 Tab 的滚动距离转换为共享头部可见高度。
  double _current_header_height({
    required double maximum_extent,
    required double minimum_extent,
  }) {
    final double collapse_range = maximum_extent - minimum_extent;
    if (collapse_range <= 0) return minimum_extent;
    final double collapsed_distance = _effective_header_scroll_offset().clamp(
      0.0,
      collapse_range,
    );
    return maximum_extent - collapsed_distance;
  }

  // ───────────────────── guide sheet ─────────────────────

  Future<void> _show_creator_guide(bool is_dark) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            decoration: BoxDecoration(
              color: AuthorStyle.surface(is_dark),
              borderRadius: BorderRadius.circular(AuthorStyle.section_radius),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AuthorStyle.border(is_dark),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  easy.tr('creator_center.creator_guide'),
                  style: TextStyle(
                    color: AuthorStyle.primary_text(is_dark),
                    fontSize: 19,
                    fontWeight: AuthorStyle.title_weight,
                  ),
                ),
                const SizedBox(height: 16),
                _guide_item(
                  is_dark,
                  Icons.cloud_done_outlined,
                  easy.tr('creator_center.guide_draft_title'),
                  easy.tr('creator_center.guide_draft_desc'),
                ),
                _guide_item(
                  is_dark,
                  Icons.fact_check_outlined,
                  easy.tr('creator_center.guide_review_title'),
                  easy.tr('creator_center.guide_review_desc'),
                ),
                _guide_item(
                  is_dark,
                  Icons.schedule_rounded,
                  easy.tr('creator_center.guide_schedule_title'),
                  easy.tr('creator_center.guide_schedule_desc'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _guide_item(
    bool is_dark,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AuthorStyle.gold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: AuthorStyle.primary_text(is_dark),
                    fontSize: 14,
                    fontWeight: AuthorStyle.emphasis_weight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AuthorStyle.secondary_text(is_dark),
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: AuthorStyle.body_weight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── demo data ─────────────────────

  List<CreatorWorkDraft> _build_demo_works() {
    final DateTime now = DateTime.now();

    return <CreatorWorkDraft>[
      CreatorWorkDraft(
        local_id: 'demo_long_draft',
        title: '雾海拾光',
        introduction: '在遗忘之海寻找被时间带走的名字。',
        work_type: CreatorWorkType.long,
        is_completed: false,
        language_code: 'zh',
        category_ids: const <int>[],
        short_content: '',
        chapters: <CreatorChapterDraft>[
          CreatorChapterDraft(
            local_id: 'demo_chapter_1',
            title: '潮汐来信',
            content: '这是用于展示章节管理交互的本地示例正文。' * 60,
            update_time: now.subtract(const Duration(hours: 2)),
          ),
          CreatorChapterDraft(
            local_id: 'demo_chapter_2',
            title: '没有影子的灯塔',
            content: '雾从海面升起，灯塔却没有留下任何影子。' * 50,
            update_time: now.subtract(const Duration(hours: 1)),
          ),
        ],
        status: CreatorWorkStatus.draft,
        release_mode: CreatorReleaseMode.immediate,
        scheduled_publish_time: null,
        update_time: now.subtract(const Duration(minutes: 38)),
        is_demo: true,
      ),
      CreatorWorkDraft(
        local_id: 'demo_short_reviewing',
        title: '第七码头',
        introduction: '末班船离港以后，码头才真正醒来。',
        work_type: CreatorWorkType.short,
        is_completed: true,
        language_code: 'zh',
        category_ids: const <int>[],
        short_content: '用于展示短篇投稿状态的本地示例正文。' * 120,
        chapters: const <CreatorChapterDraft>[],
        status: CreatorWorkStatus.reviewing,
        release_mode: CreatorReleaseMode.immediate,
        scheduled_publish_time: null,
        update_time: now.subtract(const Duration(days: 1)),
        is_demo: true,
      ),
      CreatorWorkDraft(
        local_id: 'demo_long_scheduled',
        title: '星轨之外',
        introduction: '当星图失效，真正的远方才第一次出现。',
        work_type: CreatorWorkType.long,
        is_completed: false,
        language_code: 'zh',
        category_ids: const <int>[],
        short_content: '',
        chapters: const <CreatorChapterDraft>[],
        status: CreatorWorkStatus.scheduled,
        release_mode: CreatorReleaseMode.scheduled,
        scheduled_publish_time: now.add(const Duration(days: 2)),
        update_time: now.subtract(const Duration(days: 3)),
        is_demo: true,
      ),
      CreatorWorkDraft(
        local_id: 'demo_short_draft_winter',
        title: '未寄出的冬天',
        introduction: '一封在二十年后才找到收件人的信。',
        work_type: CreatorWorkType.short,
        is_completed: false,
        language_code: 'zh',
        category_ids: const <int>[],
        short_content: '这是用于测试草稿列表滚动的本地正文。' * 90,
        chapters: const <CreatorChapterDraft>[],
        status: CreatorWorkStatus.draft,
        release_mode: CreatorReleaseMode.immediate,
        scheduled_publish_time: null,
        update_time: now.subtract(const Duration(hours: 5)),
        is_demo: true,
      ),
      CreatorWorkDraft(
        local_id: 'demo_long_draft_archive',
        title: '月下档案',
        introduction: '城市档案馆每到月圆时就会多出一份不存在的档案。',
        work_type: CreatorWorkType.long,
        is_completed: false,
        language_code: 'zh',
        category_ids: const <int>[],
        short_content: '',
        chapters: <CreatorChapterDraft>[
          CreatorChapterDraft(
            local_id: 'demo_archive_chapter_1',
            title: '第一份档案',
            content: '闭馆铃声响起时，书架后传来了纸页翻动的声音。' * 70,
            update_time: now.subtract(const Duration(hours: 8)),
          ),
        ],
        status: CreatorWorkStatus.draft,
        release_mode: CreatorReleaseMode.immediate,
        scheduled_publish_time: null,
        update_time: now.subtract(const Duration(hours: 8)),
        is_demo: true,
      ),
      CreatorWorkDraft(
        local_id: 'demo_long_reviewing_mountain',
        title: '山城来信',
        introduction: '每一级台阶都通往一个被遗忘的故事。',
        work_type: CreatorWorkType.long,
        is_completed: true,
        language_code: 'zh',
        category_ids: const <int>[],
        short_content: '',
        chapters: <CreatorChapterDraft>[
          CreatorChapterDraft(
            local_id: 'demo_mountain_chapter_1',
            title: '雨后的三百级台阶',
            content: '雨水沿着青石板一路向下，送来很多年前的声音。' * 80,
            update_time: now.subtract(const Duration(days: 2)),
          ),
        ],
        status: CreatorWorkStatus.reviewing,
        release_mode: CreatorReleaseMode.immediate,
        scheduled_publish_time: null,
        update_time: now.subtract(const Duration(days: 2)),
        is_demo: true,
      ),
      CreatorWorkDraft(
        local_id: 'demo_short_scheduled_flower',
        title: '凌晨四点的花店',
        introduction: '这家花店只为即将告别的人开门。',
        work_type: CreatorWorkType.short,
        is_completed: true,
        language_code: 'zh',
        category_ids: const <int>[],
        short_content: '凌晨四点，巷口的灯第一次亮了起来。' * 100,
        chapters: const <CreatorChapterDraft>[],
        status: CreatorWorkStatus.scheduled,
        release_mode: CreatorReleaseMode.scheduled,
        scheduled_publish_time: now.add(const Duration(hours: 16)),
        update_time: now.subtract(const Duration(hours: 12)),
        is_demo: true,
      ),
      CreatorWorkDraft(
        local_id: 'demo_short_published_galaxy',
        title: '纸上银河',
        introduction: '一名绘图员在旧星图上画出了归家的路。',
        work_type: CreatorWorkType.short,
        is_completed: true,
        language_code: 'zh',
        category_ids: const <int>[],
        short_content: '银河从铅笔尖流出，穿过了桌面上所有无人命名的星球。' * 110,
        chapters: const <CreatorChapterDraft>[],
        status: CreatorWorkStatus.published,
        release_mode: CreatorReleaseMode.immediate,
        scheduled_publish_time: null,
        update_time: now.subtract(const Duration(days: 4)),
        is_demo: true,
      ),
      CreatorWorkDraft(
        local_id: 'demo_long_published_station',
        title: '旧车站',
        introduction: '停运十年的列车，在某个夏夜重新驶入站台。',
        work_type: CreatorWorkType.long,
        is_completed: true,
        language_code: 'zh',
        category_ids: const <int>[],
        short_content: '',
        chapters: <CreatorChapterDraft>[
          CreatorChapterDraft(
            local_id: 'demo_station_chapter_1',
            title: '末班车之后',
            content: '钟表停在十一点四十七分，铁轨却开始轻轻震动。' * 120,
            update_time: now.subtract(const Duration(days: 6)),
          ),
        ],
        status: CreatorWorkStatus.published,
        release_mode: CreatorReleaseMode.immediate,
        scheduled_publish_time: null,
        update_time: now.subtract(const Duration(days: 6)),
        is_demo: true,
      ),
      CreatorWorkDraft(
        local_id: 'demo_short_rejected_island',
        title: '逆风岛',
        introduction: '岛上所有的风都朝着海心吹去。',
        work_type: CreatorWorkType.short,
        is_completed: true,
        language_code: 'zh',
        category_ids: const <int>[],
        short_content: '渔船离开码头后，才发现帆上的风始终来自前方。' * 80,
        chapters: const <CreatorChapterDraft>[],
        status: CreatorWorkStatus.rejected,
        release_mode: CreatorReleaseMode.immediate,
        scheduled_publish_time: null,
        update_time: now.subtract(const Duration(days: 5)),
        is_demo: true,
      ),
      CreatorWorkDraft(
        local_id: 'demo_short_rejected_glass_rain',
        title: '玻璃雨',
        introduction: '一场只有镜子能看见的雨落进了城市。',
        work_type: CreatorWorkType.short,
        is_completed: false,
        language_code: 'zh',
        category_ids: const <int>[],
        short_content: '窗外万里无云，镜子里的行人却都撑起了伞。' * 95,
        chapters: const <CreatorChapterDraft>[],
        status: CreatorWorkStatus.rejected,
        release_mode: CreatorReleaseMode.immediate,
        scheduled_publish_time: null,
        update_time: now.subtract(const Duration(days: 7)),
        is_demo: true,
      ),
    ];
  }
}
