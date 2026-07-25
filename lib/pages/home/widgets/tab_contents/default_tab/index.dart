import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app/components/recommend_book_card/animated_waterfall.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/home_store.dart';

/// 默认 Tab 内容组件。
///
/// 非推荐页面共用此组件，直接展示推荐瀑布流列表。
/// 内部使用 [ListView] 包裹以支持滚动。
class DefaultTabContent extends StatefulWidget {
  /// Tab 标题，用于显示页面名称。
  final String title;

  const DefaultTabContent({super.key, required this.title});

  @override
  State<DefaultTabContent> createState() => _DefaultTabContentState();
}

class _DefaultTabContentState extends State<DefaultTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// 瀑布流组件的 GlobalKey。
  final GlobalKey<AnimatedRecommendWaterfallState> _recommend_waterfall_key =
      GlobalKey();

  /// 滚动控制器。
  final ScrollController _scroll_controller = ScrollController();

  /// 首页数据仓库。
  final HomeBannerStore _home_store = Get.find<HomeBannerStore>();

  /// 距离底部多少像素时触发自动加载更多。
  static const double _load_more_trigger_distance = 300;

  @override
  void initState() {
    super.initState();
    _scroll_controller.addListener(_handle_scroll);
  }

  @override
  void dispose() {
    _scroll_controller.removeListener(_handle_scroll);
    _scroll_controller.dispose();
    super.dispose();
  }

  /// 处理滚动事件：关闭推荐弹窗、触发加载更多。
  void _handle_scroll() {
    // 滚动时关闭推荐卡片弹窗
    if (_home_store.is_recommend_overlay_open.value) {
      _recommend_waterfall_key.currentState?.close_overlay();
    }

    // 检查是否需要加载更多数据
    if (_scroll_controller.position.pixels >=
        _scroll_controller.position.maxScrollExtent - _load_more_trigger_distance) {
      _recommend_waterfall_key.currentState?.load_more();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 要求调用

    /// 获取全局主题状态。
    final DeviceInfo deviceInfo = Get.find<DeviceInfo>();
    final bool isDark = deviceInfo.theme.value == ThemeMode.dark;

    return ListView(
      controller: _scroll_controller,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: <Widget>[
        AnimatedRecommendWaterfall(
          key: _recommend_waterfall_key,
          is_dark: isDark,
        ),
      ],
    );
  }
}
