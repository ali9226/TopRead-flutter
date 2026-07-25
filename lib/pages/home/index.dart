import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app/config/color_config.dart';
import 'package:app/components/home_header_bar/index.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/pages/home/widgets/tabs/home_tabs.dart';
import 'package:app/pages/home/widgets/home_tab_bar/index.dart';
import 'package:app/components/top_decoration/index.dart';
import 'package:app/pages/home/widgets/full_screen_skeleton/index.dart';
import 'package:app/stores/home_store.dart';

/// 首页主页面。
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>
    with TickerProviderStateMixin {
  final DeviceInfo deviceInfo = Get.find<DeviceInfo>();
  TabController? _tab_controller;
  late Worker _classification_worker;
  late Worker _loading_worker;
  late Worker _theme_worker;

  @override
  void initState() {
    super.initState();
    _init_controller();
    _classification_worker = ever(
      Get.find<HomeBannerStore>().home_classification_list,
      (_) => _on_data_changed(),
    );
    _loading_worker = ever(
      Get.find<HomeBannerStore>().is_loading,
      (_) => _on_data_changed(),
    );
    _theme_worker = ever(
      deviceInfo.theme,
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _classification_worker.dispose();
    _loading_worker.dispose();
    _theme_worker.dispose();
    _tab_controller?.removeListener(_on_tab_index_changed);
    _tab_controller?.dispose();
    super.dispose();
  }

  void _init_controller() {
    final HomeBannerStore home_store = Get.find<HomeBannerStore>();
    final list = home_store.home_classification_list;

    /// 优先从全局仓库恢复上次的 tab 索引，
    /// 这样即使 Widget 被整个销毁重建（比如 BackAwarePage 切换 PopScope 包裹），
    /// 也能回到用户上次所在的 tab。
    final int previous_index = _tab_controller?.index ?? home_store.home_tab_index;
    _tab_controller?.removeListener(_on_tab_index_changed);
    _tab_controller?.dispose();

    if (list.isNotEmpty && !home_store.is_loading.value) {
      final int safe_index = previous_index.clamp(0, list.length - 1);
      _tab_controller = TabController(
        length: list.length,
        vsync: this,
        initialIndex: safe_index,
      );
      _tab_controller!.addListener(_on_tab_index_changed);
      /// 同步一次初始索引到全局仓库。
      home_store.home_tab_index = safe_index;
    } else {
      _tab_controller = null;
    }
  }

  /// 当用户手动滑动或点击切换 tab 时，把最新索引写回全局仓库。
  void _on_tab_index_changed() {
    if (_tab_controller != null && !_tab_controller!.indexIsChanging) {
      Get.find<HomeBannerStore>().home_tab_index = _tab_controller!.index;
    }
  }

  void _on_data_changed() {
    if (!mounted) return;
    _init_controller();
    setState(() {});
  }

  void _open_search_page() {
    routerUtil(path: '/search', type: 'push');
  }

  void _open_language_page() {
    routerUtil(path: '/selection_language', type: 'push');
  }

  @override
  Widget build(BuildContext context) {
    final bool is_dark = deviceInfo.theme.value == ThemeMode.dark;

    // 当分类数据正在加载时，展示全屏骨架屏，
    // 模拟首页完整的布局结构，减少用户等待焦虑。
    if (_tab_controller == null) {
      return FullScreenSkeleton(
        is_dark: is_dark,
        on_search_tap: _open_search_page,
        on_language_tap: _open_language_page,
      );
    }

    final double status_bar_height = MediaQuery.paddingOf(context).top;
    final bool has_status_bar_spacing = !kIsWeb && status_bar_height > 0;
    final Color bg_color = is_dark
        ? ColorConstants.nightBackgroundColor
        : const Color(0xFFF6F7FB);

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        color: bg_color,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TopDecoration(is_dark: is_dark),
            ),
            Column(
              children: <Widget>[
                if (has_status_bar_spacing)
                  SizedBox(height: status_bar_height),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: HomeHeaderBar(
                    is_dark: is_dark,
                    on_search_tap: _open_search_page,
                    on_language_tap: _open_language_page,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -5),
                  child: SizedBox(
                    width: double.infinity,
                    height: 41,
                    child: HomeTabBar(
                      tab_controller: _tab_controller!,
                      is_dark: is_dark,
                      language_code: context.locale.languageCode,
                    ),
                  ),
                ),
                Expanded(
                  child: HomeTabs(tab_controller: _tab_controller!),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
