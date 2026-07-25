import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/language_selection/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/theme.dart';
import 'package:app/models/transaction_inquire_type.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/layout/page_header_spacing.dart';
import 'package:app/util/router/router_util.dart';
import 'logic.dart';
import 'style.dart';
import 'utils/format_top_up_amount_text.dart';
import 'utils/get_top_up_type_display_text.dart';
import 'widgets/top_up_amount_section.dart';
import 'widgets/top_up_bottom_action_bar.dart';
import 'widgets/top_up_hero_card.dart';
import 'widgets/top_up_loading_skeleton.dart';
import 'widgets/top_up_type_picker_sheet.dart';
import 'widgets/top_up_type_section.dart';

/// 充值页面。
///
/// 页面自身负责：
/// 1. 拉取充值方式与金额配置。
/// 2. 记录当前选中的支付类型和金额。
/// 3. 发起创建充值订单并跳转二维码页。
///
/// 这里故意把“充值方式弹层”“金额展示”“底部提交栏”“骨架屏”拆成独立组件，
/// 这样路由页只保留页面级状态和流程编排，后续维护时不需要在一个大文件里来回跳。
class TopUp extends StatefulWidget {
  /// 是否仅用于后台预热页面结构。
  ///
  /// 打开真实页面时为 false。
  /// 当为 true 时，只预构建页面 UI 壳层和骨架，不触发接口请求，
  /// 这样就能把首次进入 `/top_up` 的布局成本提前吃掉，同时避免后台误请求。
  final bool warmUpOnly;
  const TopUp({super.key}) : warmUpOnly = false;

  const TopUp.warm_up({super.key}) : warmUpOnly = true;

  @override
  State<TopUp> createState() => _TopUpState();
}

class _TopUpState extends State<TopUp> {
  /// 页面逻辑对象。
  ///
  /// 网络请求和接口交互统一放在 logic.dart，避免页面层直接拼接请求细节。
  late Logic logic;

  /// 设备信息仓库。
  ///
  /// 主要依赖其中的深浅色状态来切换整页主题。
  final DeviceInfo deviceInfo = Get.find<DeviceInfo>();

  /// 后端返回的充值配置总数据。
  TransactionInquireTypeResponse? inquireType;

  /// 当前选中的充值方式。
  TransactionInquireTypeItem? selectedType;

  /// 当前选中的金额。
  double? selectedAmount;

  /// 页面是否处于请求中。
  ///
  /// 这里统一覆盖“初始化拉取配置”和“提交充值订单”两类请求状态。
  bool loading = false;

  /// 是否处于“首次进入页面且配置还没回来”的初始加载态。
  ///
  /// 这个布尔值单独拆出来，是为了让页面区分两种 loading：
  /// 1. 首次加载时展示骨架屏。
  /// 2. 已有内容后再次请求时展示半透明遮罩。
  bool get isInitialLoading =>
      loading && inquireType == null && selectedType == null;

  @override
  void initState() {
    super.initState();

    // 初始化逻辑层对象，后续请求都通过它发起。
    logic = Logic(context);

    if (widget.warmUpOnly) {
      // 预热模式只保留骨架状态，不触发任何真实接口，避免后台误创建订单或无意义请求。
      loading = true;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 等首帧结束后再拉配置，避免 initState 同步阶段直接触发异步请求影响首屏节奏。
      initPage();
    });
  }

  Future<void> initPage() async {
    // 如果页面已经在请求中，就不再重复触发初始化，防止并发拉取配置。
    if (loading) return;

    setState(() {
      // 标记进入配置加载态，驱动骨架屏或遮罩显示。
      loading = true;
    });

    try {
      // 拉取后端返回的充值方式和金额配置。
      final TransactionInquireTypeResponse? results = await logic
          .getRechargeInquireType();

      // 异步结束后页面可能已经销毁，必须先判断 mounted。
      if (!mounted) return;

      // 从接口结果里分别拆出支付类型列表和金额列表，
      // 后面页面初始化默认值时会直接使用这两组数据。
      final List<TransactionInquireTypeItem> dataList =
          results?.dataList ?? <TransactionInquireTypeItem>[];
      final List<double> amountList = results?.amountList ?? <double>[];

      // 只要任一关键配置为空，就说明当前充值能力不可用，
      // 直接提示并跳离，避免留在一个无法提交的空壳页面。
      if (results == null || dataList.isEmpty || amountList.isEmpty) {
        showBottomTip(easy.tr('top_up_page.unavailable'));
        routerUtil(path: '/user_info', type: 'replace');
        return;
      }

      setState(() {
        // 保存整份配置，供后续类型区和金额区继续读取。
        inquireType = results;

        // 默认选择第一种支付方式，让页面一进来就处于可操作状态。
        selectedType = dataList.first;

        // 默认选择第一档金额，减少用户第一次进入时还要额外点一次金额。
        selectedAmount = amountList.first;
      });
    } finally {
      if (mounted) {
        setState(() {
          // 无论成功失败，请求结束后都要退出 loading。
          loading = false;
        });
      }
    }
  }

  Future<void> submitRecharge() async {
    // 只要页面在请求中，或关键参数还没选好，就禁止提交。
    if (loading || selectedType == null || selectedAmount == null) return;

    setState(() {
      // 开启提交 loading，锁住按钮，避免重复创建充值订单。
      loading = true;
    });

    try {
      // 提交当前选中的支付类型和金额，创建充值订单。
      final results = await logic.addRecharge(
        payTypeId: selectedType!.id,
        amount: selectedAmount!,
      );

      // 页面销毁或接口失败时，不再继续往下跳转。
      if (!mounted || results == null) return;

      // 把后端生成的订单 id 带到二维码页，
      // 后续二维码页会用这个 id 继续查询订单详情。
      final String query = Uri(
        path: '/top_up_qr_code',
        queryParameters: <String, String>{'id': '${results.id}'},
      ).toString();
      routerUtil(path: query);
    } finally {
      if (mounted) {
        setState(() {
          // 提交结束后恢复按钮可点击状态。
          loading = false;
        });
      }
    }
  }

  Future<void> showTypePicker(List<TransactionInquireTypeItem> dataList) async {
    // 没有支付类型可选时，不弹出空白底部弹层。
    if (dataList.isEmpty) return;

    // 读取当前主题，保证底部弹层和页面主题保持一致。
    final bool isDark = deviceInfo.dark.value;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return TopUpTypePickerSheet(
          isDark: isDark,
          dataList: dataList,
          selectedType: selectedType,
          onSelected: (TransactionInquireTypeItem item) {
            setState(() {
              // 用户在弹层中点击某个支付类型后，回写当前选中项。
              selectedType = item;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 当前主题是否为深色模式，影响整页背景、文字和卡片颜色。
      final bool isDark = deviceInfo.dark.value;

      // 竖屏和横屏的底部操作条布局不同，需要提前判断。
      final bool isPortrait =
          MediaQuery.of(context).orientation == Orientation.portrait;

      // 页面基础背景色，供顶栏渐变和整体底板共用。
      final Color backgroundColor = isDark
          ? ColorConstants.nightBackgroundColor
          : ColorConstants.lightBackgroundColor;

      // 统一读取屏幕尺寸和安全区信息，避免重复调用 MediaQuery。
      final MediaQueryData mediaQuery = MediaQuery.of(context);
      final EdgeInsets safePadding = mediaQuery.padding;

      // 通过公共方法计算内容区顶部起始位置，
      // 让正文从固定标题栏的渐变底部之后开始，避免视觉重叠。
      final double contentTopPadding = resolvePageHeaderContentTopPadding(
        mediaQuery: mediaQuery,
        headerBottomFadeSpacing: 22,
      );

      // 把接口返回的数据安全兜底为列表，后续 UI 就不需要再写 null 判断。
      final List<TransactionInquireTypeItem> dataList =
          inquireType?.dataList ?? <TransactionInquireTypeItem>[];
      final List<double> amountList = inquireType?.amountList ?? <double>[];

      // 只有“当前不在请求中”且“类型、金额都已就绪”时，底部按钮才允许点击。
      final bool canSubmit =
          !loading && selectedType != null && selectedAmount != null;

      return Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: ThemeConstants.animationTime),
          curve: Curves.easeInOut,
          color: backgroundColor,
          child: Stack(
            children: <Widget>[
              // 页面最底层背景渐变。
              // 这个层只负责铺底色氛围，不参与交互，
              // 这样后面的卡片、悬浮按钮和头部渐变都能在统一底板上叠加。
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? const <Color>[
                              Color(0xFF191C2A),
                              Color(0xFF11131D),
                              Color(0xFF0C0D14),
                            ]
                          : const <Color>[
                              Color(0xFFF6F0D8),
                              Color(0xFFF8F8F4),
                              Color(0xFFFFFFFF),
                            ],
                    ),
                  ),
                ),
              ),
              // 右上角装饰光斑。
              // 纯视觉元素，目的是让顶部区域更有层次感，避免大面积纯色显得单薄。
              Positioned(
                top: -40,
                right: -24,
                child: IgnorePointer(
                  child: Container(
                    width: Style.decorCircleOneSize,
                    height: Style.decorCircleOneSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Style.accentColor.withValues(
                        alpha: Style.decorCircleOpacity,
                      ),
                    ),
                  ),
                ),
              ),
              // 左侧辅助光斑。
              // 和右上角光斑形成对角呼应，平衡页面重心。
              Positioned(
                top: 120,
                left: -36,
                child: IgnorePointer(
                  child: Container(
                    width: Style.decorCircleTwoSize,
                    height: Style.decorCircleTwoSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorConstants.successColor.withValues(
                        alpha: Style.decorCircleOpacity,
                      ),
                    ),
                  ),
                ),
              ),
              // 主内容滚动层。
              // 这里承载骨架屏、Hero 卡片、类型选择、金额选择以及非横屏时底部预留空间。
              ListView(
                padding: EdgeInsets.fromLTRB(
                  Style.pageHorizontalPadding + safePadding.left,
                  contentTopPadding,
                  Style.pageHorizontalPadding + safePadding.right,
                  Style.pageBottomPadding +
                      (isPortrait ? Style.bottomActionReserveHeight : 0) +
                      safePadding.bottom,
                ),
                children: <Widget>[
                  // 内容区根据是否首次加载在“骨架屏”和“真实内容”之间切换。
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    child: isInitialLoading
                        ? TopUpLoadingSkeleton(isDark: isDark)
                        : AnimatedOpacity(
                            key: const ValueKey<String>('top_up_content'),
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            opacity: 1,
                            child: Column(
                              children: <Widget>[
                                TopUpHeroCard(
                                  isDark: isDark,
                                  onTapRecords: () {
                                    routerUtil(path: '/top_up_record');
                                  },
                                ),
                                const SizedBox(height: Style.heroBottomSpacing),
                                TopUpTypeSection(
                                  isDark: isDark,
                                  selectedType: selectedType,
                                  // 当前没有默认支付方式时，显示提示文案而不是空白。
                                  selectedTitleText: selectedType == null
                                      ? easy.tr('top_up_page.type_hint')
                                      : getTopUpTypeDisplayText(selectedType!),
                                  onTap: () => showTypePicker(dataList),
                                ),
                                const SizedBox(height: Style.sectionSpacing),
                                TopUpAmountSection(
                                  isDark: isDark,
                                  amountList: amountList,
                                  selectedAmount: selectedAmount,
                                  amountTextBuilder: formatTopUpAmountText,
                                  onTapAmount: (double amount) {
                                    setState(() {
                                      // 点击金额卡片后，立即更新当前金额选择。
                                      selectedAmount = amount;
                                    });
                                  },
                                ),
                                if (!isPortrait) ...<Widget>[
                                  const SizedBox(
                                    height: Style.bottomActionTopSpacing,
                                  ),
                                  TopUpBottomActionBar(
                                    isDark: isDark,
                                    floating: false,
                                    typeValue: selectedType == null
                                        ? '--'
                                        : getTopUpTypeDisplayText(
                                            selectedType!,
                                          ),
                                    amountValue: selectedAmount == null
                                        ? '--'
                                        : formatTopUpAmountText(
                                            selectedAmount!,
                                          ),
                                    enabled: canSubmit,
                                    loading: loading,
                                    onSubmit: submitRecharge,
                                  ),
                                ],
                              ],
                            ),
                          ),
                  ),
                ],
              ),
              // 顶部固定标题层。
              // 用一层从实到虚的渐变把 LanguageSelection 和滚动内容柔和衔接起来。
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          backgroundColor.withValues(alpha: 0.98),
                          backgroundColor.withValues(alpha: 0.82),
                          backgroundColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: LanguageSelection(
                      darkBackground: isDark,
                      title: easy.tr('top_up_page.title'),
                    ),
                  ),
                ),
              ),
              // 页面内二次加载遮罩。
              // 首次加载已经由骨架屏兜底，所以这里只覆盖“已有内容时再次请求”的场景。
              if (loading && !isInitialLoading)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(
                        alpha: Style.loadingMaskOpacity,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.all(Style.loadingCardPadding),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A1D2B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(
                            Style.loadingCardRadius,
                          ),
                        ),
                        child: const CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
              // 竖屏时底部悬浮操作条。
              // 横屏下改为插入内容流中，竖屏下则单独悬浮，保证按钮始终易触达。
              if (isPortrait && !isInitialLoading)
                Positioned(
                  left: Style.bottomActionHorizontal + safePadding.left,
                  right: Style.bottomActionHorizontal + safePadding.right,
                  bottom: Style.bottomActionBottom + safePadding.bottom,
                  child: TopUpBottomActionBar(
                    isDark: isDark,
                    floating: true,
                    typeValue: selectedType == null
                        ? '--'
                        : getTopUpTypeDisplayText(selectedType!),
                    amountValue: selectedAmount == null
                        ? '--'
                        : formatTopUpAmountText(selectedAmount!),
                    enabled: canSubmit,
                    loading: loading,
                    onSubmit: submitRecharge,
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
