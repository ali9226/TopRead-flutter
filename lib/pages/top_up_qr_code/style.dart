import 'package:flutter/material.dart';

/// TODO 充值二维码页样式常量。
/// 统一管理当前页面的边距、圆角、字号和装饰尺寸，
/// 这样 index.dart 只负责结构拼装和状态判断，不直接散落大量硬编码。
class Style {
  // TODO 页面主体滚动区域的基础边距。
  static const double pageHorizontalPadding = 18;
  static const double pageBottomPadding = 28;
  static const double bottomNoticeTopSpacing = 16;
  static const double bottomNoticeTopRadius = 24;
  static const double bottomNoticeEstimatedHeight = 240;

  // TODO 主卡片与次卡片之间的标准垂直间距。
  static const double sectionSpacing = 18;

  // TODO 页面卡片通用大圆角。
  static const double cardRadius = 28;

  // TODO 页面卡片通用阴影参数。
  // 统一使用这一组阴影值可以让金额卡、二维码卡、注意事项卡保持同一空间层级。
  static const double cardShadowBlur = 22;
  static const double cardShadowOffsetY = 10;

  // TODO 顶部金额 Hero 卡片内边距。
  // 这个卡片承担主视觉焦点，所以边距要比普通信息卡更舒展。
  static const EdgeInsets heroPadding = EdgeInsets.fromLTRB(20, 18, 20, 18);

  // TODO 二维码信息卡内容边距。
  // 单独定义是为了让类型条、二维码区域、地址区域之间的呼吸感更稳定。
  static const EdgeInsets qrCardPadding = EdgeInsets.fromLTRB(18, 18, 18, 18);

  // TODO 注意事项卡内容边距。
  // 注意事项文案较长，单独控制内边距有利于保证阅读舒适度。
  static const EdgeInsets noticeCardPadding = EdgeInsets.fromLTRB(
    18,
    16,
    18,
    16,
  );
  static const EdgeInsets bottomNoticeCardPadding = EdgeInsets.fromLTRB(
    18,
    16,
    18,
    16,
  );

  // TODO 顶部金额主数字字号。
  // 这里的金额是用户最先关注的信息，所以字号需要明显大于普通正文。
  static const double amountValueSize = 34;

  // TODO 通知标题和正文的字号。
  // 标题和正文分开定义后，后续如果要提高注意事项的警示感，可以只调这里。
  static const double noticeTitleSize = 15;
  static const double noticeBodySize = 13;

  // TODO 完成按钮高度。
  // 抽成常量后，所有 CTA 按钮在同页面内都可以保持统一触控面积。
  static const double doneButtonHeight = 54;
}
