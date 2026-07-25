// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/page_background_decor/index.dart';
import 'package:app/components/page_top_gradient_overlay/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/language_info.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/stores/redis_request.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/language_util/language_change_handler.dart';
import 'package:app/util/router/router_back.dart';
import 'package:app/util/storage_util/index.dart';

import 'logic.dart';
import 'style.dart';
import 'widgets/language_card.dart';
import 'widgets/selection_language_header.dart';

/// 语言选择页面。
///
/// 页面负责：
/// 1. 展示当前应用支持的语言列表。
/// 2. 记录用户正在选择的语言 code。
/// 3. 在用户确认后持久化语言设置并切换当前 locale。
class SelectionLanguage extends StatefulWidget {
  const SelectionLanguage({super.key});

  @override
  State<SelectionLanguage> createState() => _SelectionLanguageState();
}

class _SelectionLanguageState extends State<SelectionLanguage> {
  /// 页面逻辑层。
  late Logic logic;

  /// 当前页面选择中的语言 code。
  late String selectionCode;

  /// 设备主题仓库。
  final DeviceInfo deviceInfo = Get.find<DeviceInfo>();

  /// 语种状态仓库。
  final LanguageStore languageStore = Get.find<LanguageStore>();

  /// 是否已经完成依赖初始化。
  bool initDone = false;

  @override
  void initState() {
    super.initState();
    logic = Logic(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initDone) {
      /// 进入页面时默认选中当前应用语言。
      selectionCode = context.locale.languageCode;
      initDone = true;
    }
  }

  Future<void> submit() async {
    /// 如果用户没有改动语言，直接关闭页面。
    if (context.locale.languageCode == selectionCode) {
      routerBack(context);
      return;
    }

    /// 记录一次语言切换日志，方便排查语种切换链路。
    logUtil(msg: '切换语种: $selectionCode');

    /// 把选择结果持久化到本地并切换 locale。
    final RedisRequestStore redisRequestStore = Get.find<RedisRequestStore>();
    await StorageUtil.saveData(LanguageStore.language_key, selectionCode);
    if (context.mounted) {
      await context.setLocale(Locale(selectionCode));
    }

    // 触发语种变化处理（更新 FCM Token 语言代码等）。
    await LanguageChangeHandler.onLanguageChanged(selectionCode);

    if (!mounted) return;

    /// 立即返回，不等待网络请求。
    routerBack(context);

    /// 后台刷新 redis 数据，不阻塞导航。
    redisRequestStore.fetch_redis_data(showTips: false);
  }

  @override
  Widget build(BuildContext context) {
    /// 当前是否为深色模式。
    final bool isDark = deviceInfo.theme.value == ThemeMode.dark;

    /// 媒体信息。
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final EdgeInsets safePadding = mediaQuery.padding;

    /// 页面底色。
    final Color backgroundColor = isDark
        ? ColorConstants.nightBackgroundColor
        : const Color(0xFFF6F7FB);

    /// 主标题颜色。
    final Color titleColor = isDark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;

    /// 当前用户是否做了语言改动。
    final bool changed = context.locale.languageCode != selectionCode;

    /// 头部实际占位高度。
    final double headerOverlayHeight =
        safePadding.top +
        Style.headerPadding.top +
        Style.headerActionSize +
        Style.headerPadding.bottom;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: <Widget>[
          // 公共背景装饰点缀。
          PageBackgroundDecor(is_dark: isDark),
          // 主内容区。
          Stack(
            children: <Widget>[
              // 可滚动列表。
              _build_language_list(headerOverlayHeight),
              // 顶部渐变过渡遮罩。
              PageTopGradientOverlay(background_color: backgroundColor),
              // 顶部固定操作栏。
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SelectionLanguageHeader(
                  isDark: isDark,
                  backgroundColor: backgroundColor,
                  titleColor: titleColor,
                  changed: changed,
                  onTapClose: () => routerBack(context),
                  onTapDone: submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建语言列表主体。
  Widget _build_language_list(double headerOverlayHeight) {
    return Obx(() {
      final List<LanguageInfo> language_list =
          languageStore.visible_language_list.toList();

      return ListView.builder(
        padding: EdgeInsets.fromLTRB(
          Style.pageHorizontalPadding.left,
          headerOverlayHeight + Style.listTopSpacing,
          Style.pageHorizontalPadding.right,
          Style.listBottomSpacing,
        ),
        itemCount: language_list.length,
        itemBuilder: (BuildContext context, int index) {
          final LanguageInfo langItem = language_list[index];
          return LanguageCard(
            isDark: deviceInfo.theme.value == ThemeMode.dark,
            isSelected: langItem.language_code == selectionCode,
            languageInfo: langItem,
            title: langItem.title,
            subtitle: langItem.remark,
            onTap: () {
              setState(() {
                /// 点击时只更新本地选中状态。
                selectionCode = langItem.language_code.isEmpty
                    ? selectionCode
                    : langItem.language_code;
              });
            },
          );
        },
      );
    });
  }
}
