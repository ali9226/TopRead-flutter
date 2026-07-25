import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import 'package:app/stores/device_info.dart';
import 'package:app/stores/preference_store.dart';
import 'package:app/models/preference.dart';
import 'package:app/components/category_filter/category_filter_bar.dart';
import 'package:app/components/category_filter/filter_popup.dart';
import 'package:app/components/category_filter/logic.dart';

/// 分类筛选组件。
///
/// 封装横向滚动分类标签栏和全屏筛选弹窗，提供完整的分类筛选功能。
///
/// 页面结构：
/// 1. 顶部固定分类筛选栏（不随列表滚动）
/// 2. 点击右侧箭头弹出全屏筛选弹窗
/// 3. 支持单选模式，点击已选中分类取消选中
///
/// 使用方式：
/// ```dart
/// CategoryFilter(
///   on_category_changed: (int? category_id) {
///     // 处理分类切换
///   },
/// )
/// ```
class CategoryFilter extends StatefulWidget {
  /// 分类切换时的回调，参数为当前选中的分类 id（null 表示未选中）。
  final ValueChanged<int?> on_category_changed;

  /// 外部传入的横向标签滚动控制器（可选，用于自动滚动到选中项）。
  final ScrollController? category_scroll_controller;

  /// 初始选中的分类 id（可选，用于从外部传入默认选中项）。
  final int? initial_category_id;

  const CategoryFilter({
    super.key,
    required this.on_category_changed,
    this.category_scroll_controller,
    this.initial_category_id,
  });

  @override
  State<CategoryFilter> createState() => _CategoryFilterState();
}

class _CategoryFilterState extends State<CategoryFilter> {
  /// 横向分类标签列表的滚动控制器。
  late final ScrollController _category_scroll_controller;

  /// 筛选弹窗网格区域的滚动控制器。
  final ScrollController _popup_scroll_controller = ScrollController();

  /// 逻辑层控制器。
  late CategoryFilterLogic _logic;

  /// 上一次构建时的语言代码，用于检测语种切换。
  String _last_language_code = '';

  /// 每个分类标签的 GlobalKey，用于读取实际渲染位置和尺寸。
  final Map<int, GlobalKey> _tag_keys = <int, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _category_scroll_controller =
        widget.category_scroll_controller ?? ScrollController();
    _logic = CategoryFilterLogic(context, initial_category_id: widget.initial_category_id);
    
    // 如果有初始分类 id，在首帧后滚动到对应位置
    if (widget.initial_category_id != null && widget.initial_category_id! > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scroll_to_selected_category();
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.category_scroll_controller == null) {
      _category_scroll_controller.dispose();
    }
    _popup_scroll_controller.dispose();
    super.dispose();
  }

  /// 将横向分类标签列表滚动到当前选中的分类位置（居中显示）。
  ///
  /// ListView 设置了 cacheExtent: double.infinity，所有标签均有 RenderBox，
  /// 直接读取实际渲染位置和尺寸，不依赖文字宽度测量，适配所有语种。
  void _scroll_to_selected_category() {
    if (!_category_scroll_controller.hasClients) return;

    final int? selected_id = _logic.selected_category_id.value;
    if (selected_id == null) return;

    final GlobalKey? key = _tag_keys[selected_id];
    if (key == null) return;

    final BuildContext? tag_context = key.currentContext;
    if (tag_context == null) return;

    final RenderBox? tag_box = tag_context.findRenderObject() as RenderBox?;
    if (tag_box == null || !tag_box.attached) return;

    final RenderObject? viewport_object =
        _category_scroll_controller.position.context.storageContext.findRenderObject();
    if (viewport_object == null || viewport_object is! RenderBox || !viewport_object.attached) return;

    final double tag_screen_x = tag_box.localToGlobal(Offset.zero).dx;
    final double list_screen_x = viewport_object.localToGlobal(Offset.zero).dx;
    final double tag_content_x = tag_screen_x - list_screen_x + _category_scroll_controller.offset;
    final double tag_width = tag_box.size.width;
    final double viewport_width = viewport_object.size.width;

    final double target_offset = tag_content_x - (viewport_width - tag_width) / 2;
    final double max_offset = _category_scroll_controller.position.maxScrollExtent;
    final double safe_offset = target_offset.clamp(0.0, max_offset);

    _category_scroll_controller.animateTo(
      safe_offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  /// 打开全屏筛选弹窗。
  void _open_filter_popup() {
    _logic.open_filter_popup();

    final DeviceInfo device_info = Get.find<DeviceInfo>();
    final bool is_dark = device_info.theme.value == ThemeMode.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return CategoryFilterPopup(
          temp_selected_id: _logic.temp_selected_id,
          category_list: _logic.category_list,
          is_dark: is_dark,
          on_toggle_category: (int item_id) {
            _logic.toggle_popup_category(item_id);
          },
          on_clear: () {
            _logic.clear_popup_selection();
          },
          on_confirm: () {
            _logic.confirm_popup_selection();
            widget.on_category_changed(_logic.selected_category_id.value);
          },
          on_close: () {
            Navigator.of(buildContext).pop();
          },
          scroll_controller: _popup_scroll_controller,
          language_code: context.locale.languageCode,
        );
      },
      transitionBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) {
        return child;
      },
    ).then((_) {
      _logic.close_filter_popup();

      /// 弹窗完全关闭后，等待 widget tree 重建完成再滚动到选中项。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scroll_to_selected_category();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    /// 获取全局主题状态。
    final DeviceInfo device_info = Get.find<DeviceInfo>();

    return Obx(() {
      /// 读取夜间模式状态。
      final bool is_dark = device_info.theme.value == ThemeMode.dark;

      /// 读取当前选中的分类 id（单选）。
      final int? selected_id = _logic.selected_category_id.value;

      /// 检测语种切换，标签文字宽度变化后需要重新滚动到选中项。
      final String language_code = context.locale.languageCode;
      if (language_code != _last_language_code && _last_language_code.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scroll_to_selected_category();
        });
      }
      _last_language_code = language_code;

      /// 偏好数据未加载完成或正在刷新时，展示骨架屏。
      final PreferenceStore preference_store = Get.find<PreferenceStore>();
      final bool show_skeleton = !preference_store.loaded.value || preference_store.is_loading.value;
      if (show_skeleton) {
        return _build_skeleton_bar(is_dark);
      }

      /// 确保每个分类项都有对应的 GlobalKey。
      final List<PreferenceItem> category_list = _logic.category_list;
      for (final PreferenceItem item in category_list) {
        _tag_keys.putIfAbsent(item.id, () => GlobalKey());
      }

      return CategoryFilterBar(
        selected_id: selected_id,
        category_list: category_list,
        on_tag_tap: (int item_id) {
          _logic.toggle_category(item_id);
          widget.on_category_changed(_logic.selected_category_id.value);
        },
        on_arrow_tap: _open_filter_popup,
        is_dark: is_dark,
        scroll_controller: _category_scroll_controller,
        language_code: language_code,
        tag_keys: _tag_keys,
      );
    });
  }

  /// 构建分类筛选栏骨架屏。
  ///
  /// 在 redis/get 接口请求期间展示，模拟真实标签栏的布局，
  /// 包含多个横向排列的圆角色块和右侧箭头占位，带闪烁动画。
  Widget _build_skeleton_bar(bool is_dark) {
    final Color shimmer_base = is_dark ? const Color(0xFF252836) : const Color(0xFFF0F1F5);
    final Color shimmer_highlight = is_dark ? const Color(0xFF2E3145) : const Color(0xFFF8F8FA);
    final double bar_height = is_dark ? 30.0 : 28.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 7.0),
      child: SizedBox(
        height: bar_height,
        child: Row(
          children: <Widget>[
            /// 左侧骨架标签占位。
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16.0, right: 26.0),
                itemCount: 6,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _SkeletonTag(
                      width: 56.0 + (index % 3) * 16.0,
                      height: bar_height - 4,
                      shimmer_base: shimmer_base,
                      shimmer_highlight: shimmer_highlight,
                    ),
                  );
                },
              ),
            ),

            /// 右侧箭头占位。
            Container(
              width: 44,
              alignment: Alignment.center,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: shimmer_base,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 分类标签骨架屏组件。
///
/// 在 redis/get 接口请求期间展示，模拟单个标签的圆角色块，
/// 带有从左到右循环扫过的渐变高光动画。
class _SkeletonTag extends StatefulWidget {
  /// 色块宽度。
  final double width;

  /// 色块高度。
  final double height;

  /// 骨架基础色。
  final Color shimmer_base;

  /// 骨架高光色。
  final Color shimmer_highlight;

  const _SkeletonTag({
    required this.width,
    required this.height,
    required this.shimmer_base,
    required this.shimmer_highlight,
  });

  @override
  State<_SkeletonTag> createState() => _SkeletonTagState();
}

class _SkeletonTagState extends State<_SkeletonTag>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer_controller;

  @override
  void initState() {
    super.initState();
    _shimmer_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer_controller,
      builder: (BuildContext context, Widget? child) {
        final double position = _shimmer_controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: <double>[
                (position - 0.3).clamp(0.0, 1.0),
                position.clamp(0.0, 1.0),
                (position + 0.3).clamp(0.0, 1.0),
              ],
              colors: <Color>[
                widget.shimmer_base,
                widget.shimmer_highlight,
                widget.shimmer_base,
              ],
            ),
          ),
        );
      },
    );
  }
}
