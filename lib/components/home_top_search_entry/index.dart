import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/config/font_config.dart';

import 'package:app/components/home/style.dart';
import 'package:app/stores/home_store.dart';

/// 首页顶部搜索条。
///
/// 该组件用于替换首页头部左侧 logo，
/// 让搜索能力直接融入顶部语言切换区域。
class HomeTopSearchEntry extends StatelessWidget {
  /// 点击搜索条的回调。
  final VoidCallback on_tap;

  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 首页全局数据仓库。
  final HomeBannerStore _home_store = Get.find<HomeBannerStore>();

  HomeTopSearchEntry({
    super.key,
    required this.on_tap,
    required this.is_dark,
  });

  /// 获取当前搜索栏提示文字。
  ///
  /// 如果 [search_list] 不为空则循环展示列表标题，
  /// 否则使用默认占位文案。
  String _get_hint_text() {
    final String cycling_hint = _home_store.current_search_hint;
    if (cycling_hint.isNotEmpty) return cycling_hint;
    return easy.tr('search.entry_hint');
  }

  /// 构建从下往上滑入的过渡动画。
  ///
  /// 新内容从底部滑入，旧内容向上滑出。
  Widget _build_slide_transition(
    Widget child,
    Animation<double> animation,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      )),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    /// 搜索条背景颜色。
    final Color background_color = is_dark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.05);

    /// 搜索条边框颜色。
    final Color border_color = is_dark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.05);

    /// 搜索条提示文字颜色。
    final Color text_color = is_dark
        ? Colors.white.withValues(alpha: 0.78)
        : const Color(0xFF697180);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Style.top_search_entry_radius),
        onTap: on_tap,
        child: Ink(
          width: double.infinity,
          height: Style.top_search_entry_height,
          padding: Style.top_search_entry_padding,
          decoration: BoxDecoration(
            color: background_color,
            borderRadius: BorderRadius.circular(Style.top_search_entry_radius),
            border: Border.all(color: border_color),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.search_rounded,
                color: text_color,
                size: Style.top_search_entry_icon_size,
              ),
              const SizedBox(width: Style.top_search_entry_gap),
              Expanded(
                child: ClipRect(
                  child: Obx(() {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 800),
                      switchInCurve: Curves.easeInOutCubic,
                      switchOutCurve: Curves.easeInOutCubic,
                      transitionBuilder: _build_slide_transition,
                      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                        return Stack(
                          alignment: Alignment.centerLeft,
                          children: <Widget>[
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      child: Text(
                        _get_hint_text(),
                        key: ValueKey<String>(_get_hint_text()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: text_color,
                          fontSize: Style.top_search_entry_font_size,
                          fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
