import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/pages/read/widgets/content/index.dart';
import 'package:app/stores/novel_reading_store.dart';
import './style.dart';

/// 阅读页主滚动列表组件。
///
/// 将“封面信息 + 热门书评 + 正文阅读”组织成一个可滚动主列表。
/// 它是页面的主要内容容器，管理着内容区块的布局顺序和边距。
class ReadMainList extends StatelessWidget {
  /// 页面逻辑层。
  final Logic logic;

  /// 页面滚动控制器，用于驱动阅读状态与进度计算。
  final ScrollController scroll_controller;

  /// 状态栏高度，用于顶部安全区域布局计算。
  final double status_bar_height;

  /// 当前是否为夜间主题，用于传递给子组件进行配色。
  final bool is_dark;

  /// 详情数据，用于渲染头图、信息区与评论区。
  final ReadDetail detail;

  /// 正文内容项列表，用于渲染阅读内容。
  final List<ReadingContentItem> reading_items;

  /// 正文锚点 key，用于点击“上滑开始阅读”时定位到正文。
  final GlobalKey reading_section_key;

  /// 正文点击回调。
  final GestureTapDownCallback on_reading_tap_down;

  /// 当前小说唯一的原生广告配置。
  final AdConfig? native_ad_config;

  /// 当前小说是否正在请求原生广告配置。
  final bool is_native_ad_config_loading;

  /// 原生广告产生真实展示后的统计回调。
  final VoidCallback? on_native_ad_impression;

  /// 长篇小说展示视频广告的概率（0~100），控制"看视频免广告"提示是否展示。
  final int ads_read_video_ad_probability;

  /// 点击"看视频免广告"提示的回调。
  final VoidCallback? on_video_ad_hint_tap;

  /// 当前免广告到期时间监听器。
  ///
  /// 有效时在每个章节底部展示到期时间和继续叠加入口。
  final ValueListenable<DateTime?> ad_free_expire_time_listenable;

  const ReadMainList({
    super.key,
    required this.logic,
    required this.scroll_controller,
    required this.status_bar_height,
    required this.is_dark,
    required this.detail,
    required this.reading_items,
    required this.reading_section_key,
    required this.on_reading_tap_down,
    this.native_ad_config,
    this.is_native_ad_config_loading = false,
    this.on_native_ad_impression,
    this.ads_read_video_ad_probability = 0,
    required this.ad_free_expire_time_listenable,
    this.on_video_ad_hint_tap,
  });

  @override
  Widget build(BuildContext context) {
    // 页面列表底部预留阅读进度遮罩高度，避免正文被遮挡。
    final EdgeInsets list_padding = EdgeInsets.fromLTRB(
      MainListStyle.page_horizontal_padding,
      status_bar_height + MainListStyle.top_padding,
      MainListStyle.page_horizontal_padding,
      MainListStyle.reading_mask_height,
    );

    return ListView(
      controller: scroll_controller,
      physics: const BouncingScrollPhysics(),
      padding: list_padding,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 顶部加一段间距，让封面与状态栏保持视觉呼吸感。
            SizedBox(
              height: math.max(
                0,
                status_bar_height + MainListStyle.cover_top_spacing,
              ),
            ),
            ReadContent(
              logic: logic,
              is_dark: is_dark,
              detail: detail,
              reading_items: reading_items,
              scroll_controller: scroll_controller,
              reading_section_key: reading_section_key,
              on_reading_tap_down: on_reading_tap_down,
              native_ad_config: native_ad_config,
              is_native_ad_config_loading: is_native_ad_config_loading,
              on_native_ad_impression: on_native_ad_impression,
              ads_read_video_ad_probability: ads_read_video_ad_probability,
              ad_free_expire_time_listenable: ad_free_expire_time_listenable,
              on_video_ad_hint_tap: on_video_ad_hint_tap,
            ),
          ],
        ),
      ],
    );
  }
}
