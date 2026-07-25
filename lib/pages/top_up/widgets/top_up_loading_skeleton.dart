import 'package:flutter/material.dart';
import '../style.dart';

/// 充值页骨架屏。
///
/// 这个组件把首次加载占位 UI 从主页面抽离出去，
/// 好处是页面状态切换逻辑更清晰，骨架屏样式也方便后续单独调整。
class TopUpLoadingSkeleton extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  const TopUpLoadingSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      // 给骨架屏一个稳定 key，方便 AnimatedSwitcher 在骨架和真实内容之间做平滑切换。
      key: const ValueKey<String>('top_up_loading_skeleton'),
      children: <Widget>[
        _TopUpSkeletonCard(
          isDark: isDark,
          padding: Style.heroPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 第一张骨架卡模拟 Hero 标题。
              _TopUpSkeletonBar(width: 150, height: 24, isDark: isDark),
              const SizedBox(height: 12),
              _TopUpSkeletonBar(width: 210, height: 13, isDark: isDark),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  // 两根骨架条分别模拟主按钮和记录入口。
                  Expanded(
                    child: _TopUpSkeletonBar(
                      width: double.infinity,
                      height: 40,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _TopUpSkeletonBar(width: 84, height: 40, isDark: isDark),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Style.heroBottomSpacing),
        _TopUpSkeletonCard(
          isDark: isDark,
          padding: Style.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 第二张骨架卡模拟充值方式选择区。
              _TopUpSkeletonBar(width: 120, height: 16, isDark: isDark),
              const SizedBox(height: 10),
              _TopUpSkeletonBar(width: 190, height: 12, isDark: isDark),
              const SizedBox(height: 18),
              _TopUpSkeletonBar(
                width: double.infinity,
                height: Style.typeSelectorHeight,
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: Style.sectionSpacing),
        _TopUpSkeletonCard(
          isDark: isDark,
          padding: Style.amountSectionPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 第三张骨架卡模拟金额网格。
              _TopUpSkeletonBar(width: 108, height: 16, isDark: isDark),
              const SizedBox(height: 10),
              _TopUpSkeletonBar(width: 176, height: 12, isDark: isDark),
              const SizedBox(height: 18),
              Wrap(
                spacing: Style.amountGridSpacing,
                runSpacing: Style.amountGridSpacing,
                children: List<Widget>.generate(6, (int index) {
                  return _TopUpSkeletonBar(
                    width: 102,
                    height: Style.amountTileHeight,
                    isDark: isDark,
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopUpSkeletonCard extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 骨架卡内部留白。
  final EdgeInsetsGeometry padding;

  /// 具体骨架内容。
  final Widget child;

  const _TopUpSkeletonCard({
    required this.isDark,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171926) : Colors.white,
        borderRadius: BorderRadius.circular(Style.cardRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}

class _TopUpSkeletonBar extends StatelessWidget {
  /// 骨架条宽度。
  final double width;

  /// 骨架条高度。
  final double height;

  /// 当前是否为深色主题。
  final bool isDark;

  const _TopUpSkeletonBar({
    required this.width,
    required this.height,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
