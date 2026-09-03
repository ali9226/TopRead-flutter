// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/pages/installation/author_style.dart';
import 'package:app/pages/installation/chapter_editor/index.dart';
import 'package:app/pages/installation/models/creator_work.dart';
import 'package:app/pages/installation/widgets/author_work_card.dart';
import 'package:app/pages/installation/work_editor/index.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 已认证作者的创作工作台。
class AuthorView extends StatefulWidget {
  const AuthorView({super.key});

  @override
  State<AuthorView> createState() => _AuthorViewState();
}

class _AuthorViewState extends State<AuthorView>
    with SingleTickerProviderStateMixin {
  final DeviceInfo _device_info = Get.find<DeviceInfo>();
  final UserInformation _user_information = Get.find<UserInformation>();

  late List<CreatorWorkDraft> _works;
  late TabController _tab_controller;

  /// 外层滚动控制器，用于追踪头部折叠状态。
  late ScrollController _outer_scroll_controller;

  /// 头部是否已折叠。
  bool _header_collapsed = false;

  static const double _collapseThreshold = 60;

  @override
  void initState() {
    super.initState();
    _works = kDebugMode ? _build_demo_works() : <CreatorWorkDraft>[];
    _tab_controller = TabController(length: 6, vsync: this);
    _outer_scroll_controller = ScrollController()
      ..addListener(_on_outer_scroll);
  }

  @override
  void dispose() {
    _outer_scroll_controller.removeListener(_on_outer_scroll);
    _outer_scroll_controller.dispose();
    _tab_controller.dispose();
    super.dispose();
  }

  void _on_outer_scroll() {
    final bool collapsed =
        _outer_scroll_controller.offset > _collapseThreshold;
    if (collapsed != _header_collapsed) {
      setState(() => _header_collapsed = collapsed);
    }
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
    final CreatorWorkDraft? result = await Navigator.of(context)
        .push<CreatorWorkDraft>(
          MaterialPageRoute<CreatorWorkDraft>(
            builder: (BuildContext context) => const CreatorWorkEditorPage(),
          ),
        );
    if (result == null || !mounted) return;
    setState(() => _works.insert(0, result));
  }

  Future<void> _edit_work(CreatorWorkDraft work) async {
    final CreatorWorkDraft? result = await Navigator.of(context)
        .push<CreatorWorkDraft>(
          MaterialPageRoute<CreatorWorkDraft>(
            builder: (BuildContext context) =>
                CreatorWorkEditorPage(initial_work: work),
          ),
        );
    if (result == null || !mounted) return;
    final int index = _works.indexWhere(
      (CreatorWorkDraft item) => item.local_id == work.local_id,
    );
    if (index < 0) return;
    setState(() => _works[index] = result);
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
    if (drafts.isEmpty) {
      await _create_work();
      return;
    }
    await _continue_writing(drafts.first);
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );

    return Obx(() {
      final bool is_dark = _device_info.dark.value;
      final Color bg = AuthorStyle.background(is_dark);

      return Scaffold(
        backgroundColor: bg,
        floatingActionButton: _header_collapsed
            ? _build_create_button(is_dark)
            : const SizedBox.shrink(),
        body: NestedScrollView(
          controller: _outer_scroll_controller,
          headerSliverBuilder: (
            BuildContext context,
            bool inner_box_is_scrolled,
          ) {
            return <Widget>[
              SliverAppBar(
                pinned: true,
                expandedHeight: is_cjk ? 340 : 360,
                backgroundColor: bg,
                surfaceTintColor: Colors.transparent,
                foregroundColor: AuthorStyle.primary_text(is_dark),
                elevation: 0,
                title: _build_appbar_title(is_dark),
                actions: <Widget>[
                  IconButton(
                    tooltip: easy.tr('creator_center.creator_guide'),
                    onPressed: () => _show_creator_guide(is_dark),
                    icon: const Icon(Icons.help_outline_rounded, size: 22),
                  ),
                  const SizedBox(width: 4),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AuthorStyle.page_padding,
                        kToolbarHeight + 12,
                        AuthorStyle.page_padding,
                        0,
                      ),
                      child: _build_unified_card(is_dark, is_cjk),
                    ),
                  ),
                ),
                bottom: _build_tab_bar(is_dark, is_cjk),
              ),
            ];
          },
          body: TabBarView(
            controller: _tab_controller,
            children: List<Widget>.generate(
              6,
              (int i) => _build_tab_content(i, is_dark, is_cjk),
            ),
          ),
        ),
      );
    });
  }

  /// AppBar 标题：折叠时内嵌紧凑指标。
  Widget _build_appbar_title(bool is_dark) {
    if (!_header_collapsed) {
      return Text(
        easy.tr('creator_center.title'),
        style: TextStyle(
          fontSize: 19,
          fontWeight: AuthorStyle.title_weight,
        ),
      );
    }

    return Row(
      children: <Widget>[
        Text(
          easy.tr('creator_center.title'),
          style: TextStyle(
            fontSize: 19,
            fontWeight: AuthorStyle.title_weight,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: <Widget>[
                _collapsed_stat(
                  _works.where((w) => !w.is_demo).length.toString(),
                  easy.tr('creator_center.stats_works'),
                  AuthorStyle.blue,
                  is_dark,
                ),
                const SizedBox(width: 12),
                _collapsed_stat(
                  kDebugMode ? '12.8K' : '—',
                  easy.tr('creator_center.stats_favorites'),
                  AuthorStyle.gold,
                  is_dark,
                ),
                const SizedBox(width: 12),
                _collapsed_stat(
                  kDebugMode ? '246' : '—',
                  easy.tr('creator_center.stats_comments'),
                  AuthorStyle.coral,
                  is_dark,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _collapsed_stat(String value, String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
            color: AuthorStyle.primary_text(isDark),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: AuthorStyle.body_weight,
            color: AuthorStyle.secondary_text(isDark),
          ),
        ),
      ],
    );
  }

  // ──────────── 统一卡片：hero + 指标 + 操作按钮 ────────────

  Widget _build_unified_card(bool is_dark, bool is_cjk) {
    final String name =
        _user_information.userInfo.value?.name.trim().isNotEmpty == true
        ? _user_information.userInfo.value!.name.trim()
        : easy.tr('creator_center.author_fallback_name');

    final int works_count = _works.where((w) => !w.is_demo).length;
    final double btn_fs = is_cjk
        ? AuthorStyle.button_font_size_cjk
        : AuthorStyle.button_font_size_alphabetic;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AuthorStyle.hero_gradient(is_dark),
        borderRadius: BorderRadius.circular(AuthorStyle.section_radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          /// 顶部：认证徽章 + 问候语。
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AuthorStyle.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AuthorStyle.pill_radius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.verified_rounded,
                      color: is_dark
                          ? AuthorStyle.gold
                          : AuthorStyle.deep_gold,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      easy.tr('creator_center.verified'),
                      style: TextStyle(
                        color: is_dark
                            ? AuthorStyle.gold
                            : AuthorStyle.deep_gold,
                        fontSize: is_cjk ? 11 : 10,
                        fontWeight: AuthorStyle.emphasis_weight,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                easy.tr(
                  'creator_center.greeting',
                  namedArgs: <String, String>{'name': name},
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AuthorStyle.secondary_text(is_dark),
                  fontSize: 12,
                  fontWeight: AuthorStyle.body_weight,
                ),
              ),
            ],
          ),

          /// 标题 + 副标题。
          const SizedBox(height: 14),
          Text(
            easy.tr('creator_center.hero_title'),
            style: TextStyle(
              color: AuthorStyle.primary_text(is_dark),
              fontSize: is_cjk
                  ? AuthorStyle.hero_title_size_cjk
                  : AuthorStyle.hero_title_size_alphabetic,
              height: is_cjk ? 1.25 : 1.3,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            easy.tr('creator_center.hero_subtitle'),
            style: TextStyle(
              color: AuthorStyle.secondary_text(is_dark),
              fontSize: is_cjk ? 13 : 12,
              height: is_cjk ? 1.4 : 1.5,
              fontWeight: AuthorStyle.body_weight,
            ),
          ),

          /// 指标行：三个统计嵌入卡片内，用分隔线分隔。
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: AuthorStyle.surface(is_dark).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: <Widget>[
                _card_stat(
                  works_count.toString(),
                  easy.tr('creator_center.stats_works'),
                  AuthorStyle.blue,
                  is_dark,
                  onTap: () => _tab_controller.animateTo(0),
                ),
                _card_stat_divider(is_dark),
                _card_stat(
                  kDebugMode ? '12.8K' : '—',
                  easy.tr('creator_center.stats_favorites'),
                  AuthorStyle.gold,
                  is_dark,
                ),
                _card_stat_divider(is_dark),
                _card_stat(
                  kDebugMode ? '246' : '—',
                  easy.tr('creator_center.stats_comments'),
                  AuthorStyle.coral,
                  is_dark,
                ),
              ],
            ),
          ),

          /// 操作按钮。
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _create_work,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(easy.tr('creator_center.create_work')),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(120, 40),
                  backgroundColor: AuthorStyle.gold,
                  foregroundColor: const Color(0xFF1A1A18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                  textStyle: TextStyle(
                    fontSize: btn_fs,
                    fontWeight: AuthorStyle.title_weight,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _continue_latest_draft,
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: Text(easy.tr('creator_center.continue_writing')),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(120, 40),
                  foregroundColor: AuthorStyle.primary_text(is_dark),
                  side: BorderSide(
                    color: AuthorStyle.primary_text(
                      is_dark,
                    ).withValues(alpha: 0.14),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                  textStyle: TextStyle(
                    fontSize: btn_fs,
                    fontWeight: AuthorStyle.emphasis_weight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 卡片内单个统计项。
  Widget _card_stat(
    String value,
    String label,
    Color color,
    bool is_dark, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AuthorStyle.primary_text(is_dark),
                fontSize: 18,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: AuthorStyle.emphasis_weight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 卡片内统计项之间的竖线分隔符。
  Widget _card_stat_divider(bool is_dark) {
    return Container(
      width: 0.5,
      height: 28,
      color: AuthorStyle.secondary_text(is_dark).withValues(alpha: 0.2),
    );
  }

  // ───────────────────── tab bar ─────────────────────

  PreferredSize _build_tab_bar(bool is_dark, bool is_cjk) {
    final List<String> titles = <String>[
      easy.tr('creator_center.filter_all'),
      easy.tr('creator_center.filter_draft'),
      easy.tr('creator_center.filter_reviewing'),
      easy.tr('creator_center.filter_scheduled'),
      easy.tr('creator_center.filter_published'),
      easy.tr('creator_center.filter_rejected'),
    ];

    final Color unselected = is_dark
        ? AuthorStyle.dark_secondary_text
        : AuthorStyle.light_secondary_text;
    final double fs = is_cjk ? 14.0 : 12.0;

    return PreferredSize(
      preferredSize: const Size.fromHeight(44),
      child: Container(
        color: AuthorStyle.background(is_dark),
        child: TabBar(
          controller: _tab_controller,
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(horizontal: 14),
          labelStyle: TextStyle(
            fontSize: fs,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: fs,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
          ),
          labelColor: is_dark ? Colors.white : Colors.black,
          unselectedLabelColor: unselected,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(width: 3, color: ColorConstants.themeColor),
            insets: const EdgeInsets.only(bottom: -0.5),
          ),
          dividerHeight: 0.5,
          dividerColor: AuthorStyle.border(is_dark),
          tabAlignment: TabAlignment.start,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: List<Widget>.generate(
            titles.length,
            (int i) => Tab(text: titles[i]),
          ),
        ),
      ),
    );
  }

  // ───────────────────── tab content ─────────────────────

  Widget _build_tab_content(int tab_index, bool is_dark, bool is_cjk) {
    final List<CreatorWorkDraft> works = _filtered_works(tab_index);

    if (works.isEmpty) {
      return KeyedSubtree(
        key: PageStorageKey<String>('creator_empty_$tab_index'),
        child: _build_empty_state(is_dark),
      );
    }

    return ListView.separated(
      key: PageStorageKey<String>('creator_tab_$tab_index'),
      padding: EdgeInsets.fromLTRB(
        AuthorStyle.page_padding,
        14,
        AuthorStyle.page_padding,
        110 + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: works.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final CreatorWorkDraft work = works[index];
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AuthorStyle.content_max_width,
            ),
            child: AuthorWorkCard(
              work: work,
              is_dark: is_dark,
              is_cjk: is_cjk,
              on_tap: () => _edit_work(work),
              on_primary_action: () => _continue_writing(work),
            ),
          ),
        );
      },
    );
  }

  Widget _build_empty_state(bool is_dark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 140),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AuthorStyle.gold.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.auto_stories_outlined,
                size: 32,
                color: is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              easy.tr('creator_center.empty_title'),
              style: TextStyle(
                color: AuthorStyle.primary_text(is_dark),
                fontSize: 17,
                fontWeight: AuthorStyle.title_weight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              easy.tr('creator_center.empty_subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AuthorStyle.secondary_text(is_dark),
                fontSize: 13,
                height: 1.55,
                fontWeight: AuthorStyle.body_weight,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _create_work,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(easy.tr('creator_center.create_first_work')),
              style: FilledButton.styleFrom(
                backgroundColor: AuthorStyle.gold,
                foregroundColor: const Color(0xFF1A1A18),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────── FAB ─────────────────────

  Widget _build_create_button(bool is_dark) {
    const double size = 50;
    const BorderRadius radius = BorderRadius.all(Radius.circular(25));

    final Color fill = is_dark
        ? ColorConstants.themeColor.withValues(alpha: 0.88)
        : ColorConstants.themeColor;
    final Color icon_color = Colors.black.withValues(
      alpha: is_dark ? 0.92 : 0.88,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _create_work,
          borderRadius: radius,
          splashColor: Colors.white.withValues(alpha: 0.24),
          highlightColor: Colors.white.withValues(alpha: 0.14),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: fill,
              border: Border.all(
                color: Colors.white.withValues(alpha: is_dark ? 0.26 : 0.42),
                width: 1.1,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: ColorConstants.themeColor.withValues(
                    alpha: is_dark ? 0.24 : 0.18,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: is_dark ? 0.14 : 0.08,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.92),
                          radius: 1.08,
                          colors: <Color>[
                            Colors.white.withValues(
                              alpha: is_dark ? 0.28 : 0.34,
                            ),
                            Colors.white.withValues(
                              alpha: is_dark ? 0.08 : 0.06,
                            ),
                            Colors.white.withValues(alpha: 0),
                          ],
                          stops: const <double>[0.0, 0.46, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: SvgIcon(
                    name: 'add',
                    width: 22,
                    height: 22,
                    color: icon_color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        categories: <String>['奇幻'],
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
        categories: <String>['悬疑'],
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
        categories: <String>['科幻'],
        short_content: '',
        chapters: const <CreatorChapterDraft>[],
        status: CreatorWorkStatus.scheduled,
        release_mode: CreatorReleaseMode.scheduled,
        scheduled_publish_time: now.add(const Duration(days: 2)),
        update_time: now.subtract(const Duration(days: 3)),
        is_demo: true,
      ),
    ];
  }
}
