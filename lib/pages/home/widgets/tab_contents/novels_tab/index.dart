// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/components/fixed_bottom_navigation/style.dart'
    as fixed_nav_style;
import 'package:app/components/floating_back_to_top/index.dart';
import 'package:app/components/floating_back_to_top/style.dart'
    as floating_style;
import 'package:app/config/color_config.dart';
import 'package:app/models/novel_discovery.dart';
import 'package:app/pages/novel_discovery/style.dart';
import 'package:app/pages/novel_discovery/widgets/empty_state.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/services/recommendation_refresh/index.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/util/language_util/language_change_handler.dart';
import 'package:app/util/router/router_util.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'logic.dart';
import 'section.dart';
import 'skeleton.dart';
import 'style.dart';

/// 首页小说分组推荐：分类来自服务端，每组独立换批，更多进入分类浏览页。
class NovelsTabContent extends StatefulWidget {
  const NovelsTabContent({
    super.key,
    this.controller,
    this.on_more,
    this.on_open,
    this.is_active = true,
  });

  /// 外部注入时由调用方管理控制器生命周期，正式首页默认使用真实请求。
  final NovelsTabLogic? controller;
  final ValueChanged<int>? on_more;
  final ValueChanged<NovelDiscoveryItem>? on_open;
  final bool is_active;

  @override
  State<NovelsTabContent> createState() => _NovelsTabContentState();
}

class _NovelsTabContentState extends State<NovelsTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final NovelsTabLogic _logic = widget.controller ?? NovelsTabLogic();
  final ScrollController _scroll_controller = ScrollController();
  late final LanguageRefreshSubscription _language_subscription;
  Worker? _identity_worker;
  late final RecommendationRefreshSubscription _recommendation_subscription;
  late final RecommendationPendingRefresh _pending_refresh;
  bool _needs_context_refresh = false;
  String? _identity_signature;
  String? _language;
  String? _pipeline_language;
  bool _back_to_top_visible = false;

  @override
  void initState() {
    super.initState();
    _scroll_controller.addListener(_handle_scroll);
    _recommendation_subscription = RecommendationRefreshSubscription(
      is_visible: () =>
          mounted &&
          widget.is_active &&
          (AppRouter.currentPath().isEmpty || AppRouter.currentPath() == '/') &&
          !LanguageChangeHandler.is_refreshing.value,
      on_refresh: () => _refresh(clear: _needs_context_refresh),
    );
    _pending_refresh = RecommendationPendingRefresh(
      is_visible: _recommendation_subscription.is_visible,
      context_key: () => (_identity_signature, _language),
      can_refresh: () => !_logic.loading && _logic.error == null,
      content_changes: _logic,
      on_refresh: () => _refresh(pending_retry: true),
    );
    _language_subscription = LanguageChangeHandler.register_refresh_task(
      phase: LanguageRefreshPhase.content,
      on_prepare: (refresh) {
        _pending_refresh.reset();
        _pipeline_language = refresh.language_code;
        _language = refresh.language_code;
        _logic.prepare_refresh(language: refresh.language_code);
        _reset_scroll();
      },
      on_refresh: (refresh) async {
        if (!mounted || !refresh.is_current) return;
        await _refresh(language: refresh.language_code, clear: true);
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
        // 语种切换流水线会使用最新身份发起内容请求，避免提前重复请求。
        if (LanguageChangeHandler.is_refreshing.value) return;
        _reset_scroll();
        if (widget.is_active &&
            (AppRouter.currentPath().isEmpty ||
                AppRouter.currentPath() == '/')) {
          unawaited(_refresh(clear: true));
        } else {
          _needs_context_refresh = true;
          _logic.prepare_refresh(language: _language);
          _recommendation_subscription.invalidate();
        }
      });
    }
  }

  String _identity(UserInformation user) =>
      '${user.auth_identity_revision}:${user.userInfo.value?.id ?? 0}:${user.isLoggedIn.value}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (_language == language) return;
    final initial = _language == null;
    _language = language;
    if (_pipeline_language == language) return;
    if (initial && _logic.has_loaded) return;
    if (widget.is_active) {
      unawaited(_refresh(language: language, clear: !initial));
    } else {
      _needs_context_refresh = true;
    }
  }

  @override
  void didUpdateWidget(covariant NovelsTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.is_active || oldWidget.is_active) return;
    if (_needs_context_refresh || (!_logic.has_loaded && !_logic.loading)) {
      unawaited(_refresh(clear: true));
    } else {
      _recommendation_subscription.check();
    }
  }

  Future<void> _refresh({
    String? language,
    bool clear = false,
    bool pending_retry = false,
  }) async {
    if (!pending_retry) _pending_refresh.reset();
    final revision = _recommendation_subscription.revision;
    final scope = (_identity_signature, _language);
    _needs_context_refresh = false;
    final request = _logic.refresh(
      language: language ?? _language,
      clear: clear,
    );
    final request_revision = _logic.request_revision;
    await request;
    if (mounted &&
        scope == (_identity_signature, _language) &&
        request_revision == _logic.request_revision) {
      _recommendation_subscription.acknowledge(revision);
      _pending_refresh.observe(_logic.error == null && _logic.profile_pending);
    }
  }

  @override
  void dispose() {
    _identity_worker?.dispose();
    _recommendation_subscription.dispose();
    _pending_refresh.dispose();
    _language_subscription.dispose();
    _scroll_controller.removeListener(_handle_scroll);
    _scroll_controller.dispose();
    if (widget.controller == null) _logic.dispose();
    super.dispose();
  }

  void _reset_scroll() {
    if (_scroll_controller.hasClients) _scroll_controller.jumpTo(0);
  }

  /// 分组全部由服务端一次返回，滚动只控制回顶入口，不发分页请求。
  void _handle_scroll() {
    if (!_scroll_controller.hasClients) return;
    final position = _scroll_controller.position;
    final show = position.pixels > position.viewportDimension;
    if (_back_to_top_visible != show && mounted) {
      setState(() => _back_to_top_visible = show);
    }
  }

  void _scroll_to_top() {
    if (!_scroll_controller.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll_controller.jumpTo(0);
    } else {
      _scroll_controller.animateTo(
        0,
        duration: NovelsTabStyle.scroll_to_top_duration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _open_more(int category_id) {
    if (widget.on_more != null) {
      widget.on_more!(category_id);
      return;
    }
    routerUtil(path: '/novel/browse?category_id=$category_id');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimatedBuilder(
      animation: _logic,
      builder: (context, _) {
        final dark = NovelDiscoveryStyle.is_dark(context);
        final safe_bottom = MediaQuery.paddingOf(context).bottom;
        return Stack(
          children: [
            Positioned.fill(
              child: RefreshIndicator(
                onRefresh: () => _refresh(),
                color: ColorConstants.themeColor,
                child: CustomScrollView(
                  key: const PageStorageKey('novels_home_sections_scroll'),
                  controller: _scroll_controller,
                  physics: NovelsTabStyle.list_scroll_physics,
                  slivers: [
                    const SliverToBoxAdapter(
                      child: SizedBox(height: NovelsTabStyle.first_section_top),
                    ),
                    if (_logic.sections.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: NovelsTabStyle.horizontal_padding,
                        ),
                        sliver: SliverToBoxAdapter(
                          // 相邻Tab可能已可见但尚未激活请求；未取得结果不等于无数据。
                          child:
                              _logic.loading ||
                                  _needs_context_refresh ||
                                  (!_logic.has_loaded && _logic.error == null)
                              ? NovelsHomeSectionsSkeleton(is_dark: dark)
                              : NovelDiscoveryEmptyState(
                                  error: _logic.error,
                                  message: easy.tr('novel_discovery.empty'),
                                  on_retry: () => _refresh(),
                                ),
                        ),
                      )
                    else ...[
                      if (_logic.error != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: NovelsTabStyle.horizontal_padding,
                            ),
                            child: TextButton.icon(
                              onPressed: () => _refresh(),
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(easy.tr('novel_discovery.retry')),
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: NovelsTabStyle.horizontal_padding,
                        ),
                        sliver: SliverList.builder(
                          itemCount: _logic.sections.length,
                          findChildIndexCallback: (key) {
                            final index = _logic.sections.indexWhere(
                              (section) =>
                                  key ==
                                  ValueKey('novels_home_section_${section.id}'),
                            );
                            return index < 0 ? null : index;
                          },
                          itemBuilder: (context, index) {
                            final section = _logic.sections[index];
                            return NovelsHomeSection(
                              key: ValueKey(
                                'novels_home_section_${section.id}',
                              ),
                              section: section,
                              revision: _logic.section_revision(section.id),
                              shuffling: _logic.is_shuffling(section.id),
                              error: _logic.shuffle_error(section.id),
                              on_shuffle: () => _logic.shuffle(section.id),
                              on_more: () => _open_more(section.id),
                              on_open: widget.on_open,
                            );
                          },
                        ),
                      ),
                    ],
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: NovelsTabStyle.list_bottom_base + safe_bottom,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FloatingBackToTop(
              show: _back_to_top_visible,
              isDark: dark,
              onTap: _scroll_to_top,
              visibleBottom:
                  fixed_nav_style.Style.bar_height +
                  floating_style.FloatingBackToTopStyle.offset_from_bottom_nav +
                  safe_bottom,
              hiddenBottom:
                  fixed_nav_style.Style.bar_height +
                  floating_style.FloatingBackToTopStyle.hidden_offset +
                  safe_bottom,
            ),
          ],
        );
      },
    );
  }
}
