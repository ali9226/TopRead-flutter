// ignore_for_file: non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:app/pages/top_up/style.dart';
import 'package:flutter_test/flutter_test.dart';

/// 充值页样式常量导出 smoke：保证页面视觉参数仍从统一 Style 出口暴露。
void main() {
  test('充值页样式常量导出并复用全局布局阶梯', () {
    // 页面横向边距必须引用全局配置，不能漂移成局部数值。
    expect(Style.pageHorizontalPadding, LayoutConfig.page_horizontal_padding);
    expect(Style.pageBottomPadding, LayoutConfig.space_28);

    // 卡片圆角与阴影参数可被子组件直接复用。
    expect(Style.cardRadius, LayoutConfig.radius_26);
    expect(Style.cardShadowBlur, 22);
    expect(Style.cardShadowOffsetY, 10);

    // 底部操作区预留高度与间距。
    expect(Style.bottomActionReserveHeight, 144);
    expect(Style.bottomActionTopSpacing, LayoutConfig.space_14);

    // Hero 卡片参数。
    expect(Style.heroBottomSpacing, LayoutConfig.space_18);
    expect(Style.heroTitleSize, 24);
    expect(Style.heroSubtitleSize, 13);
  });
}
