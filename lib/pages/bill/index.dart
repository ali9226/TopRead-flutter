import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/floating_back_to_top/style.dart'
    as floating_back_to_top_style;
import 'package:app/config/color_config.dart';
import 'package:app/config/theme.dart';
import 'package:app/models/user_bill.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/clipboard/clipboard.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/layout/page_header_spacing.dart';
import 'logic.dart';
import 'style.dart';
import 'utils/check_bill_token.dart';
import 'widgets/bill_page_back_to_top.dart';
import 'widgets/bill_page_background.dart';
import 'widgets/bill_page_content.dart';
import 'widgets/bill_page_header.dart';
import 'widgets/bill_page_loading_overlay.dart';

/// 账单记录页面。
///
/// 页面自身只负责三件事：
/// 1. 管理账单分页状态。
/// 2. 协调滚动监听和刷新行为。
/// 3. 把数据交给子组件渲染。
///
/// 视觉层、格式化层、鉴权层都尽量下沉到同级文件，
/// 这样后续维护时可以更快定位问题。
class Bill extends StatefulWidget {
  const Bill({super.key});

  @override
  State<Bill> createState() => _BillState();
}

class _BillState extends State<Bill> {
  /// 单次请求最多向后端拿多少条账单。
  ///
  /// 这个值不仅决定接口的 `page_size`，
  /// 还决定前端怎么判断“后面大概率还有没有下一页”。
  static const int pageSize = Style.pageSize;

  /// 账单页逻辑层实例。
  ///
  /// 页面不直接拼网络请求，统一通过 `logic.dart` 做数据入口，
  /// 这样后面要改接口参数或容错策略时不会把 UI 文件越改越乱。
  late Logic logic;

  /// 全局设备信息仓库。
  ///
  /// 这里主要读取深浅色状态，
  /// 让账单页主题切换时能跟随全局设置自动刷新。
  final DeviceInfo deviceInfo = Get.find<DeviceInfo>();

  /// 当前页面已经加载出来的账单列表。
  ///
  /// 之所以放在页面状态里，而不是直接依赖 FutureBuilder，
  /// 是因为这里同时存在：
  /// 1. 首次加载
  /// 2. 下拉刷新
  /// 3. 触底分页
  /// 三种不同的更新来源，需要显式管理累积数据。
  final List<UserBillItem> list = <UserBillItem>[];

  /// 主滚动控制器。
  ///
  /// 用于监听触底加载和返回顶部按钮显隐。
  final ScrollController scrollController = ScrollController();

  /// 是否有中的网络请求。
  ///
  /// 仅用于「首屏骨架 / 加载更多遮罩 / 底部分页按钮转圈」，
  /// 下拉刷新时不置 true，与 `/withdraw_record` 一致，只依赖 `RefreshIndicator`。
  bool loading = false;

  /// 任意账单列表请求是否尚未结束（含下拉刷新）。
  ///
  /// 与 `loading` 分离：刷新过程中不展示骨架与全屏转圈，但仍需拦住并发请求与触底分页。
  bool _fetchInProgress = false;

  /// 后端是否可能还有下一页数据。
  bool hasMore = true;

  /// 返回顶部按钮是否显示。
  bool showBackToTop = false;

  @override
  void initState() {
    /// 先执行父类初始化，保证 State 生命周期正常建立。
    super.initState();

    /// 初始化账单页逻辑层实例。
    logic = Logic();

    /// 监听滚动事件。
    ///
    /// 后续所有“接近底部自动加载更多”和“显示返回顶部按钮”的判断，
    /// 都依赖这里注册的滚动监听。
    scrollController.addListener(handleScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      /// 等首帧渲染完成后再开始拉数据。
      ///
      /// 这样做的原因是：
      /// 1. 避免在 `initState` 里直接触发异步刷新，影响首帧稳定性。
      /// 2. 某些依赖上下文的界面逻辑，在首帧后执行更安全。
      initPage();
    });
  }

  @override
  void dispose() {
    /// 页面销毁前先移除滚动监听，避免控制器释放后仍有回调。
    scrollController.removeListener(handleScroll);

    /// 释放滚动控制器，避免内存泄漏。
    scrollController.dispose();

    /// 最后执行父类销毁逻辑。
    super.dispose();
  }

  Future<void> initPage() async {
    /// 首次进入页面时，先确认本地是否还有有效 token。
    final bool hasToken = await checkBillToken();

    /// 没有 token 说明工具函数里已经负责跳去登录页，这里直接结束初始化。
    if (!hasToken) return;

    /// 首次进入统一按“刷新模式”拉取数据。
    ///
    /// 这样可以复用同一套清空旧数据、重置分页状态的逻辑。
    await fetchBillList(isRefresh: true, showLoadingMask: true);
  }

  /// 拉取账单列表。
  ///
  /// [isRefresh] 为 true 时表示从第一页重新拉取；为 false 时为分页追加。
  /// [showLoadingMask] 仅在首屏进入时为 true：显示骨架屏 / 全屏遮罩；
  /// 下拉刷新传 false，保持列表可见，仅 `RefreshIndicator` 表示加载中（与提现记录页一致）。
  ///
  /// 返回 true 表示接口业务成功（含列表为空）；false 表示未发起、token 无效或请求失败。
  Future<bool> fetchBillList({
    bool isRefresh = false,
    bool showLoadingMask = false,
  }) async {
    /// 如果已经有请求在路上，就直接拦截。
    ///
    /// 这是为了避免：
    /// 1. 用户连续下拉触发重复请求。
    /// 2. 滚动到底部时短时间内多次触发分页。
    if (_fetchInProgress) return false;

    /// 每次请求前都重新校验 token。
    ///
    /// 不只首次进入要校验，因为用户停留在页面期间 token 也可能已经失效。
    final bool hasToken = await checkBillToken();

    /// 没有 token 时中止请求，避免继续访问接口。
    if (!hasToken) return false;

    /// 组装要排除的账单 id 列表。
    ///
    /// 这里不是传统的 `page` 分页，而是把已经拿到的 id 传给后端过滤掉，
    /// 这样后端只需要继续返回“还没给过前端的记录”。
    final List<int> noIds = isRefresh
        /// 刷新模式要重新从头拿最新数据，所以不排除任何旧 id。
        ? <int>[]
        /// 分页模式要把当前列表已有 id 都传过去，避免后端重复返回。
        : list.map((UserBillItem item) => item.id).toList();

    _fetchInProgress = true;

    /// 首屏或分页加载需要骨架 / 遮罩 / 底部 loading；下拉刷新不进入此分支。
    final bool showFullLoadingUi = showLoadingMask || !isRefresh;

    if (showFullLoadingUi && mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      if (isRefresh && mounted) {
        setState(() {
          /// 仅首屏刷新前清空列表以显示骨架；下拉刷新保留旧数据直到新数据返回。
          if (showLoadingMask) {
            list.clear();
          }

          /// 刷新时把“还有更多”的状态先重置成 true。
          ///
          /// 原因是上一轮分页结果可能已经把 `hasMore` 置成了 false，
          /// 但刷新后数据集可能变了，必须重新根据最新返回结果判断。
          hasMore = true;
        });
      }

      /// 真正向逻辑层请求账单列表。
      final ({List<UserBillItem> items, bool requestOk}) billFetch =
          await logic.getBillList(
        noIds: noIds,
        pageSize: pageSize,
      );

      /// 如果页面已经销毁，就不要再继续更新状态。
      if (!mounted) return false;

      /// 请求失败时不改列表，避免下拉刷新把旧数据误清空；也不提示刷新成功。
      if (!billFetch.requestOk) {
        return false;
      }

      final List<UserBillItem> newList = billFetch.items;

      /// 根据本次返回条数，推导下一次是否还允许继续分页。
      ///
      /// 为什么是 `>= pageSize`：
      /// 1. 如果后端这次返回数量已经小于请求条数，通常说明剩余数据不足一页，
      ///    也就意味着后面大概率没有更多了。
      /// 2. 如果返回数量刚好等于一页，不能证明一定还有下一页，
      ///    但至少说明“可能还有”，所以这里继续保留加载更多能力。
      /// 3. 这个变量最终会赋值给 `hasMore`，
      ///    用来控制触底自动加载和底部“加载更多”按钮是否还能继续工作。
      final bool nextHasMore = newList.length >= pageSize;

      setState(() {
        if (isRefresh) {
          /// 再次清空一次，是为了兜底保证刷新结果只展示最新列表。
          ///
          /// 上面在请求前也清过一次，这里保留是为了让状态收口在同一处，
          /// 后续如果刷新前的展示策略调整，这里仍然能保证最终结果正确覆盖。
          list.clear();
        }

        /// 把本次接口返回的新账单追加进当前列表。
        list.addAll(newList);

        /// 更新“是否还有更多”的页面状态。
        ///
        /// 这个值会直接影响：
        /// 1. 滚动到底部时是否继续自动请求。
        /// 2. 底部操作区展示“加载更多”还是“已经到底”。
        hasMore = nextHasMore;
      });
      return true;
    } finally {
      _fetchInProgress = false;
      if (mounted) {
        setState(() {
          /// 无论成功失败，请求结束后都要关闭 loading。
          ///
          /// 否则页面会一直卡在加载态，并且后续分页请求会被错误的 loading 拦住。
          loading = false;
        });
      }
    }
  }

  /// 下拉刷新成功后提示「刷新成功」（多语种 `constant.refresh_success`，与 `/withdraw_record` 一致）。
  Future<void> _handlePullRefresh() async {
    final bool ok = await fetchBillList(isRefresh: true);
    if (!mounted || !ok) return;
    showBottomTip(easy.tr('constant.refresh_success'));
  }

  void handleScroll() {
    /// 如果控制器还没真正挂到列表上，或者页面已经销毁，就不继续处理。
    if (!scrollController.hasClients || !mounted) return;

    /// 计算当前距离列表底部还剩多少像素。
    ///
    /// 这个值越小，说明用户越接近列表末尾。
    final double distanceToBottom =
        scrollController.position.maxScrollExtent - scrollController.offset;

    /// 满足以下条件时自动加载更多：
    /// 1. `hasMore` 为 true，说明前端判断后面可能还有数据。
    /// 2. `!loading`，说明当前没有请求进行中。
    /// 3. `list.isNotEmpty`，说明不是首屏空状态。
    /// 4. 距离底部已经小于预加载阈值，应该提前请求下一批数据。
    if (hasMore &&
        !_fetchInProgress &&
        list.isNotEmpty &&
        distanceToBottom <= Style.autoLoadMoreTriggerDistance) {
      /// 触发一次分页请求。
      fetchBillList();
    }

    /// 以屏幕高度的一半作为返回顶部按钮的出现阈值。
    ///
    /// 这样用户只在真正往下看了较多内容后，才会看到悬浮按钮。
    final double screenHalfHeight =
        MediaQuery.of(context).size.height * Style.backToTopThresholdRatio;

    /// 根据当前滚动距离，判断按钮理论上是否应该显示。
    final bool shouldShow = scrollController.offset > screenHalfHeight;

    /// 如果目标状态和当前状态一样，就不触发多余的 `setState`。
    if (shouldShow == showBackToTop) return;

    setState(() {
      /// 同步更新返回顶部按钮显隐状态。
      showBackToTop = shouldShow;
    });
  }

  Future<void> scrollToTop() async {
    /// 没有挂载到滚动视图时，无法执行滚动动画。
    /// 正在加载时也不强制滚动，避免用户误以为请求被打断。
    /// 仅在全屏加载（首屏骨架 / 分页遮罩）时禁止滚动；下拉刷新不设 `loading`，仍可返回顶部。
    if (!scrollController.hasClients || loading) return;

    await scrollController.animateTo(
      /// 滚到列表最顶部位置。
      0,

      /// 使用统一动画时长，保证不同页面返回顶部体验一致。
      duration: const Duration(milliseconds: Style.scrollToTopDurationMs),

      /// 使用更柔和的缓动曲线，避免突然停顿。
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> copyBillNo(String value) async {
    /// 先调用通用剪贴板工具执行复制。
    final bool status = await copyToClipboard(value);

    /// 页面已经销毁时不再弹出提示，避免异步回调落到失效页面。
    if (!mounted) return;

    /// 只有复制成功时才提示用户。
    if (status) {
      showBottomTip(easy.tr('bill.copy_success'));
    }
  }

  @override
  Widget build(BuildContext context) {
    /// 读取当前页面的媒体信息，用来计算安全区和顶部留白。
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    /// 安全区内边距，避免内容被刘海、状态栏、底部横条遮挡。
    final EdgeInsets safePadding = mediaQuery.padding;

    /// 计算滚动内容真正的顶部起始位置。
    ///
    /// 这里要把：
    /// 1. 固定头部占位高度
    /// 2. 页面需要的额外呼吸空间
    /// 一起算进去，保证第一张卡片不会顶到悬浮头部下面。
    final double contentTopPadding =
        resolvePageHeaderContentTopPadding(mediaQuery: mediaQuery) + 10;

    return Obx(() {
      /// 读取当前是否深色模式。
      final bool isDark = deviceInfo.dark.value;

      /// 根据主题模式切换页面底色。
      final Color backgroundColor = isDark
          ? ColorConstants.nightBackgroundColor
          : ColorConstants.lightBackgroundColor;

      return Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: ThemeConstants.animationTime),
          curve: Curves.easeInOut,
          color: backgroundColor,
          child: Stack(
            children: <Widget>[
              /// 最底层视觉背景。
              BillPageBackground(isDark: isDark),

              /// 主滚动内容层。
              BillPageContent(
                isDark: isDark,
                loading: loading,
                hasMore: hasMore,
                list: list,
                scrollController: scrollController,
                padding: EdgeInsets.fromLTRB(
                  Style.pageHorizontalPadding + safePadding.left,
                  contentTopPadding,
                  Style.pageHorizontalPadding + safePadding.right,
                  Style.pageBottomPadding + safePadding.bottom,
                ),
                onRefresh: _handlePullRefresh,
                onLoadMore: fetchBillList,
                onCopySerialNumber: copyBillNo,
              ),

              /// 固定在顶部的标题层。
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: BillPageHeader(
                  isDark: isDark,
                  backgroundColor: backgroundColor,
                ),
              ),

              /// 页面已经有内容时，额外请求期间显示居中加载遮罩。
              if (loading && list.isNotEmpty)
                Positioned.fill(child: BillPageLoadingOverlay(isDark: isDark)),

              /// 右下角返回顶部按钮层。
              Positioned(
                right:
                    floating_back_to_top_style.FloatingBackToTopStyle.right +
                    safePadding.right,
                bottom:
                    floating_back_to_top_style
                        .FloatingBackToTopStyle
                        .page_bottom +
                    safePadding.bottom,
                child: BillPageBackToTop(
                  isDark: isDark,
                  visible: showBackToTop,
                  onTap: scrollToTop,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
