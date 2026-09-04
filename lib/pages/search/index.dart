// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/api/post_request.dart';
import 'package:app/components/fixed_bottom_navigation/style.dart'
    as fixed_nav_style;
import 'package:app/components/floating_back_to_top/index.dart';
import 'package:app/components/floating_back_to_top/style.dart'
    as floating_back_to_top_style;
import 'package:app/components/language_selection/index.dart';
import 'package:app/components/recommend_book_card/animated_waterfall.dart';
import 'package:app/components/recommend_book_card/book_list_item.dart';
import 'package:app/components/recommend_book_card/logic.dart';
import 'package:app/components/top_header_gradient/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/popular_search_item.dart';
import 'package:app/models/recommend_ranking_item.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/home_store.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/novel_navigation/index.dart';
import 'package:app/util/router/router_back.dart';
import 'package:app/util/router/router_util.dart';

import 'logic.dart';
import 'style.dart';
import 'package:app/pages/search/widgets/cycling_hint_overlay.dart';
import 'package:app/pages/search/widgets/search_result_waterfall.dart';

/// 小说搜索页。
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  /// 页面逻辑层。
  late Logic logic;

  /// 搜索输入控制器。
  late TextEditingController search_controller;

  /// 搜索输入框焦点节点。
  late FocusNode search_focus_node;

  /// 滚动控制器。
  final ScrollController _scroll_controller = ScrollController();

  /// 设备主题仓库。
  final DeviceInfo device_info = Get.find<DeviceInfo>();

  /// 首页全局数据仓库。
  final HomeBannerStore _home_store = Get.find<HomeBannerStore>();

  /// 当前输入内容。
  String keyword = '';

  /// 当前实际搜索的关键词（用于显示搜索结果标题）。
  String _current_search_keyword = '';

  /// 是否已点击搜索按钮（控制显示瀑布流还是搜索结果）。
  bool _has_submitted = false;

  /// 搜索结果列表。
  List<BookListItem> _search_results = <BookListItem>[];

  /// 是否正在加载搜索结果。
  bool _is_search_loading = false;

  /// 是否正在加载更多。
  bool _is_loading_more = false;

  /// 是否还有更多数据。
  bool _has_more = true;

  /// 当前搜索请求版本。
  ///
  /// 新搜索、重置和页面销毁时递增，防止旧请求覆盖最新页面状态。
  int _search_request_generation = 0;

  /// 每次加载的数据量。
  static const int _page_size = 20;

  /// 距离底部多少像素时触发自动加载更多。
  static const double _load_more_trigger_distance = 800;

  /// 返回顶部按钮是否可见。
  bool _is_back_to_top_visible = false;

  /// 瀑布流组件的 GlobalKey（用于推荐列表）。
  final GlobalKey<AnimatedRecommendWaterfallState> _recommend_waterfall_key =
      GlobalKey();

  /// 标签颜色池。
  static const List<Color> _tag_color_pool = <Color>[
    Color(0xFF2FBF9B),
    Color(0xFF5F8BFF),
    Color(0xFFF56C6C),
    Color(0xFFFF9F5A),
    Color(0xFF8B7CFF),
    Color(0xFFE6A23C),
  ];

  @override
  void initState() {
    super.initState();
    logic = Logic(context);
    search_controller = TextEditingController();
    search_focus_node = FocusNode();
    _scroll_controller.addListener(_handle_scroll);
  }

  @override
  void dispose() {
    _search_request_generation++;
    _scroll_controller.removeListener(_handle_scroll);
    _scroll_controller.dispose();
    search_focus_node.dispose();
    search_controller.dispose();
    super.dispose();
  }

  /// 处理滚动事件。
  void _handle_scroll() {
    // 控制返回顶部按钮显隐
    final bool should_show_back_to_top =
        _scroll_controller.hasClients && _scroll_controller.offset > 300;

    if (_is_back_to_top_visible != should_show_back_to_top) {
      setState(() {
        _is_back_to_top_visible = should_show_back_to_top;
      });
    }

    // 触发加载更多
    if (_has_submitted &&
        !_is_search_loading &&
        !_is_loading_more &&
        _has_more) {
      // 搜索结果的自动加载更多
      if (_scroll_controller.position.pixels >=
          _scroll_controller.position.maxScrollExtent -
              _load_more_trigger_distance) {
        _load_more_search();
      }
    } else if (!_has_submitted) {
      // 热门推荐瀑布流的自动加载更多
      if (_scroll_controller.position.pixels >=
          _scroll_controller.position.maxScrollExtent -
              _load_more_trigger_distance) {
        _recommend_waterfall_key.currentState?.load_more();
      }
    }
  }

  /// 平滑滚动到顶部。
  void _scroll_to_top() {
    if (!_scroll_controller.hasClients) return;

    _scroll_controller.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  /// 点击页面空白区域时收起键盘并取消输入框焦点。
  void on_background_tap() {
    FocusScope.of(context).unfocus();
  }

  /// 获取当前搜索栏提示文字。
  String _get_hint_text() {
    final String cycling_hint = _home_store.current_search_hint;
    if (cycling_hint.isNotEmpty) return cycling_hint;
    return easy.tr('search.input_hint');
  }

  /// 获取当前应提交的搜索关键字。
  String _get_submit_keyword() {
    final String trimmed = keyword.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return _get_hint_text();
  }

  /// 执行搜索操作。
  Future<void> _perform_search(String search_keyword) async {
    if (search_keyword.isEmpty) return;
    final int request_generation = ++_search_request_generation;

    setState(() {
      _is_search_loading = true;
      _is_loading_more = false;
      _has_submitted = true;
      _current_search_keyword = search_keyword;
      _search_results.clear();
      _has_more = true;
    });

    try {
      final results = await postRequest<List<RecommendRankingItem>>(
        path: 'novel_search/search',
        showTips: false,
        parameter: <String, dynamic>{
          'keyword': search_keyword,
          'limit': _page_size,
        },
        fromJsonList: (List<dynamic> json) =>
            RecommendRankingItem.from_json_list(json),
      );

      if (!mounted || request_generation != _search_request_generation) {
        return;
      }

      if (results.status && results.content != null) {
        final List<BookListItem> search_results =
            RecommendBookCardLogic.exclude_duplicate_items(
              candidates: _map_to_book_list_items(results.content!),
            );
        setState(() {
          _search_results = search_results;
          _is_search_loading = false;
          _has_more =
              results.content!.length >= _page_size &&
              search_results.isNotEmpty;
        });
      } else {
        setState(() {
          _is_search_loading = false;
          _has_more = false;
        });
      }
    } catch (e) {
      if (!mounted || request_generation != _search_request_generation) {
        return;
      }
      setState(() {
        _is_search_loading = false;
        _has_more = false;
      });
    }
  }

  /// 加载更多搜索结果。
  Future<void> _load_more_search() async {
    if (_is_search_loading ||
        _is_loading_more ||
        !_has_more ||
        _current_search_keyword.isEmpty) {
      return;
    }
    final int request_generation = _search_request_generation;
    final String search_keyword = _current_search_keyword;

    setState(() {
      _is_loading_more = true;
    });

    try {
      // 收集已加载的小说 ID 作为排除参数。
      final List<int> no_ids = _search_results
          .map((BookListItem item) => item.story_id)
          .toList();

      final results = await postRequest<List<RecommendRankingItem>>(
        path: 'novel_search/search',
        showTips: false,
        parameter: <String, dynamic>{
          'keyword': search_keyword,
          'limit': _page_size,
          'no_ids': no_ids,
        },
        fromJsonList: (List<dynamic> json) =>
            RecommendRankingItem.from_json_list(json),
      );

      if (!mounted || request_generation != _search_request_generation) {
        return;
      }

      if (results.status && results.content != null) {
        final List<BookListItem> new_items =
            RecommendBookCardLogic.exclude_duplicate_items(
              candidates: _map_to_book_list_items(results.content!),
              existing_items: _search_results,
            );
        setState(() {
          _search_results.addAll(new_items);
          _is_loading_more = false;
          _has_more =
              results.content!.length >= _page_size && new_items.isNotEmpty;
        });
      } else {
        setState(() {
          _is_loading_more = false;
          _has_more = false;
        });
      }
    } catch (e) {
      if (!mounted || request_generation != _search_request_generation) {
        return;
      }
      setState(() {
        _is_loading_more = false;
        _has_more = false;
      });
    }
  }

  /// 按小说ID搜索。
  Future<void> _perform_search_by_id(int novel_id) async {
    if (novel_id <= 0) return;
    final int request_generation = ++_search_request_generation;

    setState(() {
      _is_search_loading = true;
      _is_loading_more = false;
      _has_submitted = true;
      _current_search_keyword = 'ID: $novel_id';
      _search_results.clear();
    });

    try {
      final results = await postRequest<List<RecommendRankingItem>>(
        path: 'novel_search/search',
        showTips: false,
        parameter: <String, dynamic>{'novel_id': novel_id, 'limit': 1},
        fromJsonList: (List<dynamic> json) =>
            RecommendRankingItem.from_json_list(json),
      );

      if (!mounted || request_generation != _search_request_generation) {
        return;
      }

      if (results.status &&
          results.content != null &&
          results.content!.isNotEmpty) {
        // 直接跳转到小说详情页
        final novel = results.content!.first;
        navigate_to_novel(
          id: novel.id,
          title: novel.title,
          publish_status: novel.publish_status,
        );
        // 重置搜索状态
        setState(() {
          _has_submitted = false;
          _is_search_loading = false;
        });
      } else {
        setState(() {
          _is_search_loading = false;
        });
      }
    } catch (e) {
      if (!mounted || request_generation != _search_request_generation) {
        return;
      }
      setState(() {
        _is_search_loading = false;
      });
    }
  }

  /// 将推荐榜数据映射为 BookListItem 列表。
  List<BookListItem> _map_to_book_list_items(
    List<RecommendRankingItem> source,
  ) {
    return source.map((RecommendRankingItem item) {
      final List<BookListTagItem> tags = item.category_list
          .take(2)
          .toList()
          .asMap()
          .entries
          .map((MapEntry<int, String> entry) {
            final Color color =
                _tag_color_pool[(item.id * 7 + entry.key * 3) %
                    _tag_color_pool.length];
            return BookListTagItem(label: entry.value, color: color);
          })
          .toList();

      String meta_text = '';
      if (item.score > 0) {
        final String scoreText = item.score.toStringAsFixed(2)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '');
        meta_text = '${scoreText}分';
      }

      return BookListItem(
        id: 'search_${item.id}',
        story_id: item.id,
        type: BookListItemType.book,
        title: item.title,
        description: item.introduction,
        cover_url: item.cover_url,
        cover_width: item.cover_width,
        cover_height: item.cover_height,
        cover_badge: item.publish_status == 2 ? '完结' : '',
        cover_meta_text: meta_text,
        tag_list: tags,
        ad_image_url_list: const <String>[],
        publish_status: item.publish_status,
      );
    }).toList();
  }

  /// 重置搜索状态，返回推荐列表。
  void _reset_search() {
    _search_request_generation++;
    setState(() {
      _has_submitted = false;
      _is_search_loading = false;
      _is_loading_more = false;
      _search_results.clear();
      _current_search_keyword = '';
      _has_more = true;
    });
  }

  /// 处理热门搜索标签点击事件。
  void _on_popular_search_tap(PopularSearchItem item) {
    if (item.type == 1) {
      // type=1: 分类，跳转到完整榜单页面（推荐榜），并传入分类ID
      routerUtil(
        path: '/ranking_full_list?id=148&category_id=${item.id}',
        type: 'push',
      );
    } else if (item.type == 2) {
      // type=2: 小说，按ID搜索并跳转
      _perform_search_by_id(item.id);
    } else if (item.type == 3) {
      // type=3: 榜单，跳转到完整榜单页面，选中对应tab
      routerUtil(path: '/ranking_full_list?id=${item.id}', type: 'push');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool is_dark = device_info.theme.value == ThemeMode.dark;
      final String language_code = easy.EasyLocalization.of(
        context,
      )!.locale.languageCode;
      final bool is_cjk = LanguageUtil.is_cjk_language(language_code);
      final double title_size = is_cjk
          ? Style.title_size_cjk
          : Style.title_size_alphabetic;
      final double section_title_size = is_cjk
          ? Style.section_title_size_cjk
          : Style.section_title_size_alphabetic;
      final double hot_keyword_text_size = is_cjk
          ? Style.hot_keyword_text_size_cjk
          : Style.hot_keyword_text_size_alphabetic;
      final EdgeInsets chip_padding = is_cjk
          ? Style.chip_padding_cjk
          : Style.chip_padding_alphabetic;
      final double hot_keyword_spacing = is_cjk
          ? Style.hot_keyword_spacing_cjk
          : Style.hot_keyword_spacing_alphabetic;
      final double hot_keyword_run_spacing = is_cjk
          ? Style.hot_keyword_run_spacing_cjk
          : Style.hot_keyword_run_spacing_alphabetic;
      final double search_submit_button_text_size = is_cjk
          ? Style.search_submit_button_text_size_cjk
          : Style.search_submit_button_text_size_alphabetic;
      final Color background_color = is_dark
          ? ColorConstants.nightBackgroundColor
          : Style.light_page_background;
      final Color card_color = is_dark
          ? Style.dark_card_background
          : Colors.white;
      final Color primary_text_color = is_dark
          ? ColorConstants.whiteColor
          : ColorConstants.lightTextColor;
      final Color secondary_text_color = is_dark
          ? ColorConstants.whiteColor.withValues(
              alpha: Style.secondary_text_dark_alpha,
            )
          : ColorConstants.hintColor;
      final double status_bar_height = MediaQuery.paddingOf(context).top;

      // 从 store 获取热门搜索标签列表
      final List<PopularSearchItem> popular_searches =
          _home_store.popular_searches;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: on_background_tap,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: background_color,
          body: Stack(
            children: <Widget>[
              Positioned(
                top: Style.top_glow_one_top,
                right: Style.top_glow_one_right,
                child: Container(
                  width: Style.top_glow_one_size,
                  height: Style.top_glow_one_size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: is_dark
                        ? Style.top_glow_one_dark_color.withValues(
                            alpha: Style.top_glow_one_dark_alpha,
                          )
                        : ColorConstants.themeColor.withValues(
                            alpha: Style.top_glow_one_light_alpha,
                          ),
                  ),
                ),
              ),
              Positioned(
                top: Style.top_glow_two_top,
                left: Style.top_glow_two_left,
                child: Container(
                  width: Style.top_glow_two_size,
                  height: Style.top_glow_two_size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: is_dark
                        ? Style.top_glow_two_dark_color.withValues(
                            alpha: Style.top_glow_two_dark_alpha,
                          )
                        : ColorConstants.themeColor.withValues(
                            alpha: Style.top_glow_two_light_alpha,
                          ),
                  ),
                ),
              ),
              ListView(
                controller: _scroll_controller,
                padding: Style.page_padding.copyWith(
                  top:
                      status_bar_height +
                      Style.top_bar_height +
                      Style.page_top_padding,
                ),
                children: <Widget>[
                  /// 页面主标题。
                  Text(
                    easy.tr('search.header_title'),
                    style: TextStyle(
                      color: primary_text_color,
                      fontSize: title_size,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: Style.search_header_gap),
                  Container(
                    height: Style.search_bar_height,
                    decoration: BoxDecoration(
                      color: card_color,
                      borderRadius: BorderRadius.circular(Style.card_radius),
                    ),
                    padding: Style.search_bar_padding.copyWith(right: 7),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.search_rounded,
                          size: Style.search_icon_size,
                          color: secondary_text_color,
                        ),
                        const SizedBox(width: Style.search_bar_inner_gap),
                        Expanded(
                          child: ClipRect(
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: <Widget>[
                                TextField(
                                  controller: search_controller,
                                  focusNode: search_focus_node,
                                  onTapOutside: (_) => on_background_tap(),
                                  onChanged: (String value) {
                                    setState(() {
                                      keyword = value;
                                    });
                                    if (value.trim().isEmpty &&
                                        _has_submitted) {
                                      _reset_search();
                                    }
                                  },
                                  onSubmitted: (String value) {
                                    _perform_search(_get_submit_keyword());
                                  },
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    hintText: '',
                                    suffixIcon: AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds:
                                            Style.search_clear_fade_duration_ms,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      opacity: keyword.trim().isNotEmpty
                                          ? Style.one
                                          : Style.zero,
                                      child: IgnorePointer(
                                        ignoring: keyword.trim().isEmpty,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.translucent,
                                          onTap: () {
                                            setState(() {
                                              keyword = '';
                                              search_controller.clear();
                                            });
                                            search_controller.selection =
                                                const TextSelection.collapsed(
                                                  offset: 0,
                                                );
                                            if (_has_submitted) _reset_search();
                                          },
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: Style.search_clear_icon_size,
                                            color: secondary_text_color,
                                          ),
                                        ),
                                      ),
                                    ),
                                    suffixIconConstraints: const BoxConstraints(
                                      minWidth: Style.search_clear_button_size,
                                      minHeight: Style.search_clear_button_size,
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: primary_text_color,
                                    fontSize: Style.search_input_font_size,
                                    fontWeight: FontConfig.adjustedWeight(
                                      FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IgnorePointer(
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: double.infinity,
                                    child: AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      opacity: keyword.trim().isEmpty
                                          ? 1.0
                                          : 0.0,
                                      child: CyclingHintOverlay(
                                        hint_text: _get_hint_text(),
                                        text_style: TextStyle(
                                          color: secondary_text_color,
                                          fontSize:
                                              Style.search_input_hint_font_size,
                                          fontWeight: FontConfig.adjustedWeight(
                                            FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: Style.search_bar_inner_gap),
                        SizedBox(
                          height: Style.search_submit_button_height,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Style
                                    .search_submit_button_horizontal_padding,
                              ),
                              backgroundColor: ColorConstants.themeColor,
                              foregroundColor: Colors.black,
                              elevation: Style.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Style.chip_radius,
                                ),
                              ),
                            ),
                            onPressed: () {
                              on_background_tap();
                              final String submit_keyword =
                                  _get_submit_keyword();
                              search_controller.text = submit_keyword;
                              setState(() {
                                keyword = submit_keyword;
                              });
                              _perform_search(submit_keyword);
                            },
                            child: Text(
                              easy.tr('search.submit'),
                              style: TextStyle(
                                fontSize: search_submit_button_text_size,
                                fontWeight: FontConfig.adjustedWeight(
                                  FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Style.section_spacing),
                  if (!_has_submitted) ...[
                    /// 热门搜索标题。
                    Text(
                      easy.tr('search.hot_title'),
                      style: TextStyle(
                        color: primary_text_color,
                        fontSize: section_title_size,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: Style.section_title_top_gap),

                    /// 热门搜索标签（从 store 获取）。
                    if (popular_searches.isNotEmpty)
                      Wrap(
                        spacing: hot_keyword_spacing,
                        runSpacing: hot_keyword_run_spacing,
                        children: popular_searches.map((
                          PopularSearchItem item,
                        ) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(
                              Style.chip_radius,
                            ),
                            onTap: () => _on_popular_search_tap(item),
                            child: Container(
                              padding: chip_padding,
                              decoration: BoxDecoration(
                                color: is_dark
                                    ? Colors.white.withValues(
                                        alpha: Style
                                            .hot_keyword_dark_background_alpha,
                                      )
                                    : Style.hot_keyword_light_background,
                                borderRadius: BorderRadius.circular(
                                  Style.chip_radius,
                                ),
                              ),
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  color: primary_text_color,
                                  fontSize: hot_keyword_text_size,
                                  fontWeight: FontConfig.adjustedWeight(
                                    FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: Style.section_spacing),

                    /// 热门推荐标题。
                    Text(
                      easy.tr('search.recommend_title'),
                      style: TextStyle(
                        color: primary_text_color,
                        fontSize: section_title_size,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: Style.section_title_top_gap),

                    /// 推荐瀑布流区域。
                    AnimatedRecommendWaterfall(
                      key: _recommend_waterfall_key,
                      waterfall_id: 'search_recommend',
                      is_dark: is_dark,
                    ),
                  ] else ...[
                    /// 搜索结果标题。
                    Text(
                      easy.tr(
                        'search.search_result_title',
                        namedArgs: <String, String>{
                          'keyword': _current_search_keyword,
                        },
                      ),
                      style: TextStyle(
                        color: primary_text_color,
                        fontSize: section_title_size,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: Style.section_title_top_gap),
                    if (_is_search_loading)
                      _build_search_skeleton(is_dark)
                    else if (_search_results.isEmpty)
                      _build_empty_result(secondary_text_color)
                    else ...[
                      SearchResultWaterfall(
                        items: _search_results,
                        is_dark: is_dark,
                      ),

                      /// 加载更多 / 没有了 底部组件。
                      _build_load_more_footer(is_dark),
                    ],
                  ],
                ],
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TopHeaderGradient(
                  background_color: is_dark
                      ? ColorConstants.nightBackgroundColor
                      : Style.light_page_background,
                  height: Style.header_gradient_height,
                  start_opacity: Style.header_gradient_start_opacity,
                  middle_opacity: Style.header_gradient_middle_opacity,
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LanguageSelection(
                  onLeftTapOverride: () => routerBack(context),
                  userInfoContrastText: false,
                  horizontalPadding: Style.page_padding.left,
                  useSafeAreaTop: false,
                  topOffset: status_bar_height,
                  darkBackground: is_dark,
                ),
              ),
              // 返回顶部按钮
              FloatingBackToTop(
                show: _is_back_to_top_visible,
                isDark: is_dark,
                onTap: _scroll_to_top,
                right: floating_back_to_top_style.FloatingBackToTopStyle.right,
                visibleBottom:
                    fixed_nav_style.Style.bar_height +
                    floating_back_to_top_style
                        .FloatingBackToTopStyle
                        .offset_from_bottom_nav +
                    MediaQuery.paddingOf(context).bottom,
                hiddenBottom:
                    fixed_nav_style.Style.bar_height +
                    floating_back_to_top_style
                        .FloatingBackToTopStyle
                        .hidden_offset +
                    MediaQuery.paddingOf(context).bottom,
              ),
            ],
          ),
        ),
      );
    });
  }

  /// 构建加载更多底部组件。
  Widget _build_load_more_footer(bool is_dark) {
    if (_is_loading_more) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                is_dark ? Colors.white54 : Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    if (!_has_more) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            easy.tr('home.book_list_footer.no_more'),
            style: TextStyle(
              color: is_dark ? Colors.white54 : Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _build_search_skeleton(bool is_dark) {
    final Color base_color = is_dark
        ? const Color(0xFF252836)
        : const Color(0xFFF0F1F5);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(3, (int index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Container(
                  height: 200 + (index % 2) * 30.0,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: base_color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 220 - (index % 2) * 20.0,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    color: base_color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _build_empty_result(Color secondary_text_color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: <Widget>[
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: secondary_text_color,
            ),
            const SizedBox(height: 16),
            Text(
              easy.tr('common.empty_data'),
              style: TextStyle(color: secondary_text_color, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
