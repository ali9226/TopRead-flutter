// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/components/window_content_layout/index.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/browse/logic.dart';
import 'package:app/pages/comics/browse/style.dart';
import 'package:app/pages/comics/browse/widgets/category_list.dart';
import 'package:app/pages/comics/browse/widgets/category_tabs.dart';
import 'package:app/pages/comics/browse/widgets/inline_error.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/comics/widgets/empty_state.dart';
import 'package:app/pages/comics/widgets/discovery_grid/skeleton.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/services/recommendation_refresh/index.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/util/language_util/language_change_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 首页“更多”进入真实分类分页；新路由保留首页本身的分组与滚动位置。
class ComicBrowsePage extends StatefulWidget {
  const ComicBrowsePage({
    super.key,
    this.initial_category_id = 0,
    this.controller,
    this.on_open,
  });
  final int initial_category_id;
  final ComicBrowseLogic? controller;
  final ValueChanged<ComicItem>? on_open;

  @override
  State<ComicBrowsePage> createState() => _ComicBrowsePageState();
}

class _ComicBrowsePageState extends State<ComicBrowsePage>
    with TickerProviderStateMixin {
  late final ComicBrowseLogic _logic =
      widget.controller ??
      ComicBrowseLogic(initial_category_id: widget.initial_category_id);
  TabController? _tabs;
  List<int> _tab_ids = [];
  bool _initialized = false;
  late final LanguageRefreshSubscription _language_subscription;
  Worker? _identity_worker;
  late final RecommendationRefreshSubscription _recommendation_subscription;
  late final RecommendationPendingRefresh _pending_refresh;
  String? _identity_signature;
  String? _language;
  String? _pipeline_language;

  @override
  void initState() {
    super.initState();
    _logic.addListener(_on_logic_changed);
    _recommendation_subscription = RecommendationRefreshSubscription(
      is_visible: () =>
          mounted &&
          (AppRouter.currentPath().isEmpty ||
              AppRouter.currentPath() == '/comics/browse') &&
          !LanguageChangeHandler.is_refreshing.value,
      on_refresh: () => _refresh_recommendations(),
    );
    _pending_refresh = RecommendationPendingRefresh(
      is_visible: _recommendation_subscription.is_visible,
      context_key: () => (
        _identity_signature,
        _language,
        _logic.context_revision,
        _logic.selected_category_id,
      ),
      can_refresh: () {
        final state = _logic.state_for(_logic.selected_category_id);
        return state.loaded &&
            !state.busy &&
            state.page <= 1 &&
            state.error == null;
      },
      content_changes: _logic,
      on_refresh: () => _logic.refresh(
        _logic.selected_category_id,
        keep_if_pending: true,
      ),
    );
    _language_subscription = LanguageChangeHandler.register_refresh_task(
      phase: LanguageRefreshPhase.content,
      on_prepare: (refresh) {
        _pending_refresh.reset();
        _language = refresh.language_code;
        _pipeline_language = refresh.language_code;
        _logic.prepare_context(language: refresh.language_code);
      },
      on_refresh: (refresh) async {
        if (!mounted || !refresh.is_current) return;
        await _refresh_recommendations(
          language: refresh.language_code,
          reset: false,
        );
        if (_pipeline_language == refresh.language_code) {
          _pipeline_language = null;
        }
      },
    );
    if (Get.isRegistered<UserInformation>()) {
      final user = Get.find<UserInformation>();
      _identity_signature = _identity(user);
      _identity_worker = everAll([user.userInfo, user.isLoggedIn], (_) {
        final signature = _identity(user);
        if (_identity_signature == signature) return;
        _identity_signature = signature;
        _pending_refresh.reset();
        if (LanguageChangeHandler.is_refreshing.value) return;
        unawaited(_refresh_recommendations(language: _language));
      });
    }
  }

  String _identity(UserInformation user) =>
      '${user.auth_identity_revision}:${user.userInfo.value?.id ?? 0}:${user.isLoggedIn.value}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync_tabs();
    final language = Localizations.localeOf(context).languageCode;
    final language_changed = _language != language;
    _language = language;
    if (!_initialized) {
      _initialized = true;
      if (_pipeline_language != language) {
        unawaited(_logic.initialize(language: language));
      }
    } else if (language_changed && _pipeline_language != language) {
      unawaited(_refresh_recommendations(language: language));
    }
  }

  void _sync_tabs() {
    final ids = _logic.categories
        .map((category) => comics_int(category['id']))
        .toList();
    final changed =
        ids.length != _tab_ids.length ||
        List.generate(
          ids.length,
          (index) => ids[index] != _tab_ids[index],
        ).any((changed) => changed);
    if (changed) {
      _tabs?.removeListener(_on_tab_changed);
      _tabs?.dispose();
      _tab_ids = ids;
      _tabs = ids.isEmpty
          ? null
          : TabController(
              length: ids.length,
              vsync: this,
              initialIndex: _logic.selected_index < 0
                  ? 0
                  : _logic.selected_index,
              animationDuration: ComicBrowseStyle.reduce_motion(context)
                  ? Duration.zero
                  : ComicBrowseStyle.tab_duration,
            );
      _tabs?.addListener(_on_tab_changed);
    } else if (_tabs != null &&
        _logic.selected_index >= 0 &&
        _tabs!.index != _logic.selected_index) {
      _tabs!.animateTo(_logic.selected_index);
    }
  }

  void _on_tab_changed() {
    final tabs = _tabs;
    if (tabs != null && tabs.index < _tab_ids.length) {
      _logic.select_category(_tab_ids[tabs.index]);
    }
  }

  void _on_logic_changed() {
    if (!mounted) return;
    _sync_tabs();
    final state = _logic.state_for(_logic.selected_category_id);
    if (state.loaded && !state.busy) {
      // 翻到后续页后不再替换首屏，避免把新排名拼接到旧分页。
      _pending_refresh.observe(
        state.page <= 1 && state.error == null && state.profile_pending,
      );
    }
    setState(() {});
  }

  Future<void> _refresh_recommendations({
    String? language,
    bool reset = true,
  }) async {
    _pending_refresh.reset();
    final revision = _recommendation_subscription.revision;
    await _logic.refresh_context(language: language ?? _language, reset: reset);
    _recommendation_subscription.acknowledge(revision);
  }

  @override
  void dispose() {
    _tabs?.removeListener(_on_tab_changed);
    _tabs?.dispose();
    _identity_worker?.dispose();
    _recommendation_subscription.dispose();
    _pending_refresh.dispose();
    _language_subscription.dispose();
    _logic.removeListener(_on_logic_changed);
    if (widget.controller == null) _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = ComicsStyle.is_dark(context);
    final tabs = _tabs;
    return Scaffold(
      backgroundColor: ComicBrowseStyle.background(dark),
      appBar: WindowAppBar(
        child: AppBar(
          backgroundColor: ComicBrowseStyle.background(dark),
          foregroundColor: ComicBrowseStyle.foreground(dark),
          surfaceTintColor: ComicBrowseStyle.background(dark),
          elevation: 0,
          title: Text(
            tr('comics.discovery_title'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ComicBrowseStyle.title(context, dark),
          ),
        ),
      ),
      body: Column(
        children: [
          if (tabs != null)
            ComicBrowseCategoryTabs(
              categories: _logic.categories,
              controller: tabs,
              is_dark: dark,
            ),
          if (_logic.categories_error != null)
            ComicBrowseInlineError(
              key: const ValueKey('comic_browse_categories_error'),
              is_dark: dark,
              message: tr('comics.discovery_categories_failed'),
              on_retry: () => unawaited(_logic.load_categories()),
            ),
          Expanded(
            child: WindowContentLayout(
              max_width: ComicsStyle.content_width,
              child: tabs != null
                  ? TabBarView(
                      controller: tabs,
                      children: [
                        for (final id in _tab_ids)
                          ComicBrowseCategoryList(
                            key: ValueKey(
                              'comic_browse_category_page_${id}_${_logic.context_revision}',
                            ),
                            category_id: id,
                            logic: _logic,
                            is_dark: dark,
                            on_open: widget.on_open,
                          ),
                      ],
                    )
                  : _logic.selected_category_id > 0
                  ? ComicBrowseCategoryList(
                      key: ValueKey(
                        'comic_browse_category_page_${_logic.selected_category_id}_${_logic.context_revision}',
                      ),
                      category_id: _logic.selected_category_id,
                      logic: _logic,
                      is_dark: dark,
                      on_open: widget.on_open,
                    )
                  : RefreshIndicator(
                      onRefresh: _logic.load_categories,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          if (_logic.loading_categories ||
                              (!_logic.categories_loaded &&
                                  _logic.categories_error == null))
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                ComicBrowseStyle.horizontal_padding,
                                ComicBrowseStyle.content_top_gap,
                                ComicBrowseStyle.horizontal_padding,
                                MediaQuery.paddingOf(context).bottom +
                                    ComicBrowseStyle.content_bottom_gap,
                              ),
                              sliver: ComicDiscoverySliverSkeleton(
                                key: const ValueKey(
                                  'comic_browse_initial_skeleton',
                                ),
                                is_dark: dark,
                              ),
                            )
                          else
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: ComicsEmptyState(
                                message: tr('comics.empty_discover'),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
