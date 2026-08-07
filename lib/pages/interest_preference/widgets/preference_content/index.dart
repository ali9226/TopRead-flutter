// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as easy;

import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/components/login_required_dialog/index.dart';
import 'package:app/pages/interest_preference/logic.dart';
import 'package:app/pages/interest_preference/style.dart';
import 'package:app/pages/interest_preference/widgets/title_section/index.dart';
import 'package:app/pages/interest_preference/widgets/preference_section/index.dart';
import 'package:app/pages/interest_preference/widgets/top_bar/index.dart';
import 'package:app/pages/interest_preference/widgets/loading_indicator/index.dart';
import 'package:app/models/preference.dart';
import 'package:app/components/page_top_gradient_overlay/index.dart';
import 'package:app/util/dialog/show_message.dart';

/// 兴趣偏好公共内容组件。
///
/// 普通兴趣偏好页面与注册完成专用页面共用此组件，只通过回调决定退出、
/// 保存成功和跳过后的导航目标，避免业务入口之间互相影响。
///
/// 内容结构：
/// - 顶部导航栏（固定，含返回和保存按钮）
/// - 可滚动内容区（标题区 + 各偏好分类区块）
/// - 加载中指示器（居中显示，不遮挡内容）
class InterestPreferenceContent extends StatefulWidget {
  /// 返回、放弃修改或保存成功后的统一退出回调。
  final VoidCallback onExit;

  /// 可选的跳过回调。
  ///
  /// 非空时顶部栏在保存按钮右侧展示“跳过”按钮。
  final VoidCallback? onSkip;

  /// 是否拦截路由系统的默认 pop。
  ///
  /// 注册专用页面必须拦截，避免系统返回或 iOS 侧滑回到注册页。
  final bool interceptSystemBack;

  const InterestPreferenceContent({
    super.key,
    required this.onExit,
    this.onSkip,
    this.interceptSystemBack = false,
  });

  @override
  State<InterestPreferenceContent> createState() =>
      _InterestPreferenceContentState();
}

class _InterestPreferenceContentState extends State<InterestPreferenceContent> {
  /// 逻辑层：管理主题切换和偏好数据操作。
  late InterestPreferenceLogic _logic;

  /// 滚动控制器：用于检测内容是否与返回按钮重叠。
  late ScrollController _scrollController;

  /// 内容是否已滚动到与顶部导航栏重叠（控制返回按钮背景显隐）。
  bool _scrolled = false;

  /// 保存按钮是否正在提交中（防止重复点击）。
  bool _saving = false;

  /// 页面初始加载状态（true 时显示加载指示器）。
  bool _loading = true;

  /// 接口数据是否已回显完成。
  ///
  /// 在 [_load_user_preferences] 成功返回后置为 true，
  /// 用于保证保存按钮在数据回显前始终不可点击。
  bool _data_loaded = false;

  /// 各偏好分类的选中项。
  ///
  /// key 为偏好类别 id，value 为该类别下已选中的选项 id 集合。
  /// 用于驱动标签的选中/未选中状态。
  final Map<int, Set<int>> _selected_map = <int, Set<int>>{};

  /// 接口返回的初始已选 id 集合。
  ///
  /// 用于与当前选择比较，判断用户是否修改过选择，
  /// 从而决定保存按钮是否可点击。
  Set<int> _initial_ids = <int>{};

  /// 判断保存按钮是否可点击。
  ///
  /// 条件（必须全部满足）：
  /// 1. 接口数据已回显完成（_data_loaded 为 true）
  /// 2. 不在提交中（_saving 为 false）
  /// 3. 与初始状态不同（用户做过修改）
  bool get _can_save {
    if (!_data_loaded || _saving) return false;
    return !_set_equals(_current_ids, _initial_ids);
  }

  /// 执行实际的页面返回导航。
  ///
  /// 导航目标由页面容器通过 [InterestPreferenceContent.onExit] 决定。
  void _navigate_back() {
    if (!mounted) return;
    widget.onExit();
  }

  /// 返回按钮点击 / 侧滑返回的统一入口。
  ///
  /// 当用户已登录且有未保存的修改时，弹出确认弹窗；
  /// 否则直接返回。
  void _on_back() {
    if (_can_save) {
      showMessage(
        message: easy.tr('interest_preference.exit_dialog_title'),
        showHelperText: false,
        leftButtonText: easy.tr('interest_preference.exit_dialog_discard'),
        rightButtonText: easy.tr('interest_preference.exit_dialog_save'),
        onLeftPressed: () async {
          _navigate_back();
        },
        onRightPressed: () async {
          await _on_save();
        },
      );
      return;
    }

    /// 没有修改，直接返回。
    _navigate_back();
  }

  /// 获取当前所有已选中的 id 集合。
  ///
  /// 遍历 [_selected_map] 中所有分类的选中项，合并为一个扁平 Set。
  Set<int> get _current_ids {
    final Set<int> result = <int>{};
    for (final Set<int> selectedSet in _selected_map.values) {
      result.addAll(selectedSet);
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _logic = InterestPreferenceLogic();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    /// 注册统一后退处理器，拦截安卓系统后退手势。
    AppRouter.setBackHandler(() {
      _on_back();
      return true;
    });

    /// 页面初始化时检查登录态，未登录则跳过查询。
    _init_with_login_check();
  }

  @override
  void dispose() {
    /// 清理后退处理器，避免旧 State 的闭包继续被调用。
    AppRouter.clearBackHandler();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 监听滚动事件，判断内容是否与返回按钮区域重叠。
  ///
  /// 当滚动偏移量超过 11 像素时认为已重叠，
  /// 触发返回按钮显示半透明圆圈背景。
  void _onScroll() {
    final bool newScrolled = _scrollController.offset > 11;
    if (newScrolled != _scrolled) {
      setState(() {
        _scrolled = newScrolled;
      });
    }
  }

  /// 获取指定类别的当前选中集合。
  ///
  /// 若该类别无选中项则返回空 Set，避免 null 判断。
  Set<int> _get_selected_set(int preference_id) {
    return _selected_map[preference_id] ?? <int>{};
  }

  /// 页面初始化时检查登录态，未登录则跳过查询并设置加载完成。
  Future<void> _init_with_login_check() async {
    final bool is_logged_in = await showLoginRequiredDialog(
      title: easy.tr('interest_preference.login_required'),
    );
    if (!mounted) return;

    /// 未登录时直接结束加载状态，不请求接口。
    if (!is_logged_in) {
      setState(() {
        _loading = false;
      });
      return;
    }

    /// 已登录，正常查询用户偏好。
    await _load_user_preferences();
  }

  /// 页面加载时查询用户已保存的偏好。
  ///
  /// 调用 [InterestPreferenceLogic.fetch_user_preferences] 获取接口返回的 id 列表，
  /// 将 id 列表按偏好分类分配到 [_selected_map] 中以高亮对应标签，
  /// 同时记录到 [_initial_ids] 用于后续比较。
  Future<void> _load_user_preferences() async {
    final List<int> ids = await _logic.fetch_user_preferences();

    /// 组件可能在异步等待期间被销毁，需提前返回。
    if (!mounted) return;

    /// 遍历所有偏好分类，将 id 分配到对应的分类中。
    /// 只有在分类数据中存在的 id 才算有效选择，
    /// 避免接口返回的孤儿 id 导致初始状态与当前状态不一致。
    final List<Preference> list = _logic.preference_list;
    for (final Preference pref in list) {
      final Set<int> matched = <int>{};
      for (final PreferenceItem item in pref.data_list) {
        if (ids.contains(item.id)) {
          matched.add(item.id);
        }
      }
      if (matched.isNotEmpty) {
        _selected_map[pref.id] = matched;
      }
    }

    /// 初始 id 只保留实际存在于分类数据中的项，
    /// 保证与 _current_ids 的计算口径一致。
    _initial_ids = _current_ids;

    setState(() {
      _loading = false;
      _data_loaded = true;
    });
  }

  /// 比较两个 Set 是否相等（元素相同，与顺序无关）。
  bool _set_equals(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  /// 切换标签选中状态并刷新 UI。
  ///
  /// 根据 [preference] 的 single_select 决定单选或多选行为，
  /// 将新的选中集合更新到 [_selected_map] 中。
  void _on_toggle(Preference preference, int item_id) {
    final Set<int> current = _get_selected_set(preference.id);
    final Set<int> next = _logic.toggle(
      preference: preference,
      item_id: item_id,
      current_selected: current,
    );
    setState(() {
      _selected_map[preference.id] = next;
    });
  }

  /// 保存偏好选择。
  ///
  /// 调用接口提交用户选中的偏好 id 列表，
  /// 成功后调用页面容器提供的退出回调。
  /// 提交期间显示 loading 状态，防止重复提交。
  Future<void> _on_save() async {
    /// 正在提交时不重复触发。
    if (_saving) return;

    /// 保存前检查登录态，未登录则弹出提示。
    final bool is_logged_in = await showLoginRequiredDialog(
      title: easy.tr('interest_preference.login_required'),
    );
    if (!is_logged_in) return;

    setState(() {
      _saving = true;
    });

    try {
      final bool success = await _logic.save(_selected_map);
      if (!success) return;

      /// 保存成功，执行导航。
      if (!mounted) return;
      widget.onExit();
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool is_dark = _logic.is_dark;
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    final Widget page = Scaffold(
      backgroundColor: InterestPreferenceStyle.backgroundColor(isDark: is_dark),
      body: Stack(
        children: <Widget>[
          /// 背景装饰光斑（纯视觉装饰，不可交互）。
          _build_background_decorations(is_dark),

          /// 可滚动内容区（延伸到状态栏下方）。
          _build_scrollable_content(is_dark, statusBarHeight),

          /// 顶部渐变过渡遮罩（平滑过渡背景与内容）。
          PageTopGradientOverlay(
            background_color: InterestPreferenceStyle.backgroundColor(
              isDark: is_dark,
            ),
          ),

          /// 顶部导航栏（固定在状态栏下方，背景透明）。
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopBar(
              isDark: is_dark,
              scrolled: _scrolled,
              statusBarHeight: statusBarHeight,
              isLoading: _loading || _saving,
              canSave: _can_save,
              onSave: _on_save,
              onBack: _on_back,
              onSkip: widget.onSkip,
              isSkipEnabled: !_saving,
            ),
          ),

          /// 加载中指示器（居中显示，在加载或提交保存时可见）。
          if (_loading || _saving)
            Positioned.fill(child: LoadingIndicator(isDark: is_dark)),
        ],
      ),
    );

    /// 普通页面不额外注册 PopScope，保持现有 iOS 侧滑和默认 pop 行为。
    if (!widget.interceptSystemBack) {
      return page;
    }

    /// 注册专用页面禁止默认 pop，所有系统返回统一进入页面返回逻辑。
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _on_back();
      },
      child: page,
    );
  }

  /// 构建背景装饰光斑。
  ///
  /// 右上角黄色光斑和左侧绿色光斑，纯装饰用途，
  /// 使用 IgnorePointer 确保不拦截触摸事件。
  Widget _build_background_decorations(bool isDark) {
    return Stack(
      children: <Widget>[
        /// 右上角黄色装饰光斑。
        Positioned(
          top: -80,
          right: -50,
          child: IgnorePointer(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFFF8D02D,
                ).withValues(alpha: isDark ? 0.08 : 0.15),
              ),
            ),
          ),
        ),

        /// 左侧绿色装饰光斑。
        Positioned(
          top: 200,
          left: -60,
          child: IgnorePointer(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF67C23A,
                ).withValues(alpha: isDark ? 0.05 : 0.08),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建可滚动内容区。
  ///
  /// 包含标题区和所有偏好分类区块。
  /// 加载中时不禁用滚动，但保存按钮处于禁用状态。
  Widget _build_scrollable_content(bool isDark, double statusBarHeight) {
    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        InterestPreferenceStyle.pageHorizontalPadding,
        statusBarHeight + InterestPreferenceStyle.topBarHeight - 12,
        InterestPreferenceStyle.pageHorizontalPadding,
        InterestPreferenceStyle.pageBottomPadding,
      ),
      children: <Widget>[
        /// 页面标题区（主标题 + 副标题）。
        TitleSection(isDark: isDark),
        const SizedBox(height: 36),

        /// 动态渲染所有偏好分类区块。
        ..._build_dynamic_sections(isDark),
      ],
    );
  }

  /// 动态构建所有偏好分类区块。
  ///
  /// 遍历 [InterestPreferenceLogic.preference_list]，
  /// 为每个分类创建一个 [PreferenceSection] 组件，
  /// 分类之间使用固定间距分隔。
  List<Widget> _build_dynamic_sections(bool isDark) {
    final List<Preference> list = _logic.preference_list;
    if (list.isEmpty) return <Widget>[];

    final List<Widget> sections = <Widget>[];
    for (int i = 0; i < list.length; i++) {
      final Preference pref = list[i];

      sections.add(
        PreferenceSection(
          preference: pref,
          selectedSet: _get_selected_set(pref.id),
          isDark: isDark,
          onToggle: (int index) {
            final int item_id = pref.data_list[index].id;
            _on_toggle(pref, item_id);
          },
        ),
      );

      /// 分类之间添加间距（最后一个分类后不添加）。
      if (i < list.length - 1) {
        sections.add(
          const SizedBox(height: InterestPreferenceStyle.sectionSpacing),
        );
      }
    }
    return sections;
  }
}
