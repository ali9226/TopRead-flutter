import 'package:flutter/material.dart';
import 'package:app/models/user_bill.dart';

import '../style.dart';
import '../utils/display_bill_number.dart';
import '../utils/format_bill_amount.dart';
import '../utils/format_bill_update_time.dart';
import '../utils/get_bill_type_icon.dart';
import '../utils/get_bill_type_text.dart';
import 'bill_bottom_action.dart';
import 'bill_empty_state.dart';
import 'bill_hero_card.dart';
import 'bill_loading_skeleton.dart';
import 'bill_record_card.dart';

/// 账单页滚动内容层。
///
/// 这里集中处理“空状态 / 骨架屏 / 列表 / 分页按钮”的切换，
/// 让主页面不必再直接拼装大量列表节点。
class BillPageContent extends StatelessWidget {
  /// 当前主题是否为深色模式。
  final bool isDark;

  /// 页面当前是否处于请求中。
  final bool loading;

  /// 页面是否允许继续加载更多。
  final bool hasMore;

  /// 当前已经拿到的账单列表数据。
  final List<UserBillItem> list;

  /// 由父页面传进来的滚动控制器。
  final ScrollController scrollController;

  /// 列表整体内边距。
  final EdgeInsets padding;

  /// 下拉刷新回调。
  final Future<void> Function() onRefresh;

  /// 手动点击“加载更多”时的回调。
  final VoidCallback onLoadMore;

  /// 点击复制流水号时的回调。
  final ValueChanged<String> onCopySerialNumber;

  const BillPageContent({
    super.key,
    required this.isDark,
    required this.loading,
    required this.hasMore,
    required this.list,
    required this.scrollController,
    required this.padding,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onCopySerialNumber,
  });

  @override
  Widget build(BuildContext context) {
    /// 读取当前语言 code 作为列表 key。
    ///
    /// 这样当用户切换语言时，列表节点会以新 key 重新建立，
    /// 确保卡片中的多语种文本能够跟着刷新。
    final String currentLanguageCode = Localizations.localeOf(
      context,
    ).languageCode;

    return RefreshIndicator(
      /// 下拉刷新时重新触发父页面提供的刷新逻辑。
      onRefresh: onRefresh,
      child: ListView(
        /// 绑定语言相关 key，辅助多语种切换时刷新节点。
        key: ValueKey<String>(currentLanguageCode),

        /// 使用父页面统一维护的滚动控制器。
        controller: scrollController,

        /// 即使内容不够一屏，也允许下拉触发刷新。
        physics: const AlwaysScrollableScrollPhysics(),

        /// 应用父页面计算好的安全区和头部占位边距。
        padding: padding,
        children: <Widget>[
          /// 页面顶部引导卡片。
          BillHeroCard(isDark: isDark),
          const SizedBox(height: Style.heroBottomSpacing),

          /// 首次进入且列表为空时，显示骨架屏。
          if (list.isEmpty && loading)
            BillLoadingSkeleton(isDark: isDark)
          /// 没有数据且当前不在加载时，显示空状态。
          else if (list.isEmpty)
            BillEmptyState(
              isDark: isDark,
              emptyNumberText: displayBillNumber(0),
              onReload: onRefresh,
            )
          /// 有数据时，展示真实账单列表和底部操作区。
          else
            AnimatedOpacity(
              /// 列表淡入动画时长。
              duration: const Duration(milliseconds: 220),

              /// 列表淡入曲线。
              curve: Curves.easeOutCubic,

              /// 当前场景下内容已经可见，所以固定为完全不透明。
              opacity: 1,
              child: Column(
                children: <Widget>[
                  /// 把每条账单数据映射成卡片组件。
                  ...list.map(buildRecordCard),
                  const SizedBox(height: Style.listBottomSpacing),

                  /// 列表底部加载更多 / 已经到底的操作区。
                  BillBottomAction(
                    isDark: isDark,
                    hasMore: hasMore,
                    loading: loading,
                    onTapLoadMore: onLoadMore,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 把账单数据模型转换成单条卡片组件。
  ///
  /// 这层转换单独抽出来后，
  /// 页面列表只需要关心“渲染哪一组 item”，
  /// 不必再在 `map` 闭包里塞进大量格式化细节。
  Widget buildRecordCard(UserBillItem item) {
    return BillRecordCard(
      isDark: isDark,

      /// 账单业务类型对应的展示文案。
      title: getBillTypeText(item.type),

      /// 账单图标优先遵循业务类型，其次才按金额正负兜底。
      iconName: getBillTypeIcon(type: item.type, amount: item.amount),

      /// 金额展示文本，会补齐正负号和千分位。
      amountText: formatBillAmount(item.amount),

      /// 金额是否为增加，用来控制颜色和涨跌徽标。
      isIncrease: item.amount >= 0,

      /// 后端返回的流水号原文，复制时直接使用这个值。
      serialNumber: item.serialNumber,

      /// 把 UTC 时间转成适合当前设备时区阅读的文本。
      updateTimeText: formatBillUpdateTime(item.updateTime),
      onCopySerialNumber: () {
        /// 把具体流水号继续透传给父页面，由父页面统一处理复制成功提示。
        onCopySerialNumber(item.serialNumber);
      },
    );
  }
}
