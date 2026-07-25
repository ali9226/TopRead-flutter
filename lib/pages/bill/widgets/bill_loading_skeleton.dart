import 'package:flutter/material.dart';

import '../style.dart';

/// 账单页骨架屏。
///
/// 在真实账单数据还没回来之前，先用结构接近真实卡片的占位块稳定页面布局，
/// 避免用户看到内容区域突然大面积跳变。
class BillLoadingSkeleton extends StatelessWidget {
  /// 当前主题是否为深色模式。
  final bool isDark;

  const BillLoadingSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(4, (int index) {
        /// 让每一行骨架条宽度有轻微差异，
        /// 模拟真实文本长短不一的效果，避免四张骨架卡片看起来完全机械复制。
        final double titleWidth = 120 + (index % 3) * 36;
        final double subWidth = 180 - (index % 2) * 28;

        return Container(
          /// 骨架卡片之间保持和真实账单卡片一致的底部间距，
          /// 这样真实内容替换进来时不会产生布局闪动。
          margin: const EdgeInsets.only(bottom: Style.billCardBottomMargin),

          /// 内边距也和真实卡片保持一致，让骨架位置更贴近最终内容排布。
          padding: Style.billCardPadding,
          decoration: BoxDecoration(
            /// 骨架卡片底色。
            color: isDark ? const Color(0xFF171926) : Colors.white,
            borderRadius: BorderRadius.circular(Style.billCardRadius),
            border: Border.all(
              /// 用轻描边维持卡片边界。
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// 模拟账单类型标题。
              _BillSkeletonBar(width: titleWidth, height: 16, isDark: isDark),
              const SizedBox(height: 12),

              /// 模拟副文案或时间信息。
              _BillSkeletonBar(width: subWidth, height: 12, isDark: isDark),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _BillSkeletonBar(
                      /// 模拟底部左侧较长的信息块。
                      width: double.infinity,
                      height: 34,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),

                  /// 模拟右侧金额徽标区域。
                  _BillSkeletonBar(width: 70, height: 34, isDark: isDark),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// 单条骨架条组件。
///
/// 把占位条抽出来后，父级只需要关心“这里放一条多宽多高的骨架”，
/// 不需要每次重复写圆角和颜色。
class _BillSkeletonBar extends StatelessWidget {
  /// 骨架条宽度。
  final double width;

  /// 骨架条高度。
  final double height;

  /// 当前主题是否为深色模式。
  final bool isDark;

  const _BillSkeletonBar({
    required this.width,
    required this.height,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      /// 所有骨架条统一左对齐，模拟真实内容阅读方向。
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          /// 骨架条颜色故意比真实文字更弱，
          /// 让用户知道这里只是占位而不是可阅读内容。
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.06),

          /// 用大圆角做成胶囊形态，骨架观感会更柔和。
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
